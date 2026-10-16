extends Node3D

# 코어(Game)를 매 프레임 진행시키고, 그 상태를 화면에 그립니다.

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _score_label: Label = $HUD/Score

const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 40.0

var game: Game
var _player: Character

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    _sun.rotation_degrees = Vector3(-55, 30, 0)

    var characters: Array[Character] = [
        Character.new(Vector3(0, 0, 300), Vector3.FORWARD),
        Character.new(Vector3(0, 0, -300), Vector3.BACK),
    ]
    game = Game.new(characters)
    _player = characters[0]

    for goal in game.goals:
        add_child(GoalView.new(goal))
    # 1인칭이라 내 캐릭터는 카메라를 가리지 않게 숨깁니다.
    var player_view := CharacterView.new(_player, Color.ROYAL_BLUE)
    player_view.visible = false
    add_child(player_view)
    add_child(CharacterView.new(characters[1], Color.CRIMSON))
    add_child(BallView.new(game.ball))

    game.start()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseMotion:
        _player.turn(-event.relative.x * MOUSE_SENSITIVITY)
    if event.is_action_pressed("bounce"):
        _player.bounce(game.ball)

func _process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    _player.move_input = Vector3(input_vector.x, 0, input_vector.y)
    game.tick(delta)
    _camera.position = _player.position + Vector3.UP * EYE_HEIGHT
    _camera.look_at(_camera.position + _player.facing)
    _score_label.text = "%d : %d   %s   %s" % [game.goals[0].score, game.goals[1].score, _format_time(game.remaining_time()), game.status]

func _format_time(seconds: float) -> String:
    # 종료 직전 마지막 tick 에서 살짝 음수가 될 수 있어 0 에서 멈춥니다.
    var total := ceili(maxf(seconds, 0.0))
    @warning_ignore("integer_division")
    return "%02d:%02d" % [total / 60, total % 60]
