extends Node3D

# 코어(Game)를 매 프레임 진행시키고, 그 상태를 화면에 그립니다.

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _score_label: Label = $HUD/Score
@onready var _message_label: Label = $HUD/Message
@onready var _field: MeshInstance3D = $Field
@onready var _center_line: MeshInstance3D = $Field/CenterLine

const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 40.0

var game: Game
var _player: Character
var _npc: Npc

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    _sun.rotation_degrees = Vector3(-55, 30, 0)

    # 경기장 크기는 코어(Game)의 상수를 따릅니다. 씬의 값은 에디터 미리보기용입니다.
    (_field.mesh as PlaneMesh).size = Vector2(Game.FIELD_WIDTH, Game.FIELD_LENGTH)
    (_center_line.mesh as BoxMesh).size.x = Game.FIELD_WIDTH

    # 시작 위치는 game.start() 에서 팀이 정해질 때 배치됩니다.
    _player = Character.new()
    _npc = Npc.new()
    var characters: Array[Character] = [_player, _npc]
    game = Game.new(characters)

    for goal in game.goals:
        add_child(GoalView.new(goal))
    # 1인칭이라 내 캐릭터는 카메라를 가리지 않게 숨깁니다.
    var player_view := CharacterView.new(_player, Color.ROYAL_BLUE)
    player_view.visible = false
    add_child(player_view)
    add_child(CharacterView.new(_npc, Color.CRIMSON))
    add_child(BallView.new(game.ball))

    game.start()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseMotion:
        _player.turn(-event.relative.x * MOUSE_SENSITIVITY)
    if event.is_action_pressed("bounce"):
        _player.bounce(game.ball)
    if event.is_action_pressed("restart") and game.status == GameStatus.OVER:
        game.start()

func _process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    _player.move_input = Vector3(input_vector.x, 0, input_vector.y)
    _npc.think(game.ball, game.opponent_goal_of(_npc.team))
    game.tick(delta)
    _camera.position = _player.position + Vector3.UP * EYE_HEIGHT
    _camera.look_at(_camera.position + _player.facing)
    var opponent_team := game.opponent_goal_of(_player.team).team
    _score_label.text = "나 %d : %d 상대   %s" % [game.score_of(_player.team), game.score_of(opponent_team), _format_time(game.remaining_time())]
    _message_label.text = _message()

func _message() -> String:
    match game.status:
        GameStatus.GOAL:
            return "GOAL!"
        GameStatus.OVER:
            return "%s\nR 키로 다시 시작" % _result()
    return ""

func _result() -> String:
    var winner := game.winner()
    if winner == Character.NO_TEAM:
        return "DRAW"
    if winner == _player.team:
        return "WIN"
    return "LOSE"

func _format_time(seconds: float) -> String:
    # 종료 직전 마지막 tick 에서 살짝 음수가 될 수 있어 0 에서 멈춥니다.
    var total := ceili(maxf(seconds, 0.0))
    @warning_ignore("integer_division")
    return "%02d:%02d" % [total / 60, total % 60]
