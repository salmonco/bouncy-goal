extends Node3D

# 코어(Game)를 매 프레임 진행시키고, 그 상태를 화면에 그립니다.

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _score_label: RichTextLabel = $HUD/Score
@onready var _message_label: Label = $HUD/Message

const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 40.0

var game: Game
var _player: Character
var _npc: Npc

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    _sun.rotation_degrees = Vector3(-55, 30, 0)

    # 시작 위치는 game.start() 에서 팀이 정해질 때 배치됩니다.
    _player = Character.new()
    _npc = Npc.new()
    var characters: Array[Character] = [_player, _npc]
    game = Game.new(characters)

    add_child(PlanetView.new())
    add_child(FieldView.new())
    add_child(FieldWallsView.new())
    for goal in game.goals:
        add_child(GoalView.new(goal))
    # 1인칭이라 내 캐릭터는 카메라를 가리지 않게 숨깁니다.
    var player_view := CharacterView.new(_player)
    player_view.visible = false
    add_child(player_view)
    add_child(CharacterView.new(_npc))
    add_child(BallView.new(game.ball))

    game.start()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseMotion:
        _player.turn(-event.relative.x * MOUSE_SENSITIVITY)
        _player.tilt(-event.relative.y * MOUSE_SENSITIVITY)
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
    _camera.look_at(_camera.position + _player.aim())
    var opponent_team := game.opponent_goal_of(_player.team).team
    # 1인칭이라 내 몸이 안 보이니, 점수를 각 팀 색으로 칠해 어느 편인지 알려줍니다.
    _score_label.text = "[center][color=%s]나 %d[/color] : [color=%s]%d 상대[/color]   %s[/center]" % [
        TeamColors.of(_player.team).to_html(false), game.score_of(_player.team),
        TeamColors.of(opponent_team).to_html(false), game.score_of(opponent_team),
        _format_time(game.remaining_time()),
    ]
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
