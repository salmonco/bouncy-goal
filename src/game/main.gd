extends Node3D

# 코어(Game)를 매 프레임 진행시키고, 그 상태를 화면에 그립니다.

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _score_label: RichTextLabel = $HUD/Score
@onready var _message_label: Label = $HUD/Message

const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 40.0
# 손맛: 공을 찰 때와 골이 들어갈 때 화면을 흔듭니다. 흔들림은 SHAKE_DECAY 로 빠르게 잦아듭니다.
const KICK_SHAKE := 0.8
const GOAL_SHAKE := 3.0
const SHAKE_DECAY := 8.0
# 골이 들어가면 화면이 서리 빛으로 번쩍였다 사라집니다.
const FROST_FLASH_COLOR := Color(0.88, 0.95, 1.0)
const FROST_FLASH_ALPHA := 0.75
const FROST_FLASH_DURATION := 0.7

var game: Game
var _player: Character
var _npc: Npc
var _sfx: Sfx
var _kick_view: FirstPersonKickView
var _shake := 0.0
var _frost_flash: ColorRect
var _last_status: StringName

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
    var ball_view := BallView.new(game.ball)
    add_child(ball_view)

    _sfx = Sfx.new()
    add_child(_sfx)
    for character in characters:
        character.bounced.connect(func(): _sfx.play_at(Sfx.KICK, game.ball.position + Vector3.UP * Ball.RADIUS))
    ball_view.landed.connect(func(at: Vector3): _sfx.play_at(Sfx.GROUND, at, -2.0))
    _kick_view = FirstPersonKickView.new()
    _camera.add_child(_kick_view)
    _player.bounced.connect(_on_player_kick)
    _frost_flash = ColorRect.new()
    _frost_flash.color = Color(FROST_FLASH_COLOR, 0.0)
    _frost_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    _frost_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(_frost_flash)
    # 번쩍임이 글자를 덮지 않도록 HUD 맨 뒤로 보냅니다.
    $HUD.move_child(_frost_flash, 0)

    game.start()
    _last_status = game.status

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
    if game.status != _last_status and game.status == GameStatus.GOAL:
        _on_goal()
    _last_status = game.status
    _camera.position = _player.position + Vector3.UP * EYE_HEIGHT
    _camera.look_at(_camera.position + _player.aim())
    _shake_camera(delta)
    var opponent_team := game.opponent_goal_of(_player.team).team
    # 1인칭이라 내 몸이 안 보이니, 점수를 각 팀 색으로 칠해 어느 편인지 알려줍니다.
    _score_label.text = "[center][color=%s]나 %d[/color] : [color=%s]%d 상대[/color]   %s[/center]" % [
        TeamColors.of(_player.team).to_html(false), game.score_of(_player.team),
        TeamColors.of(opponent_team).to_html(false), game.score_of(opponent_team),
        _format_time(game.remaining_time()),
    ]
    _message_label.text = _message()

func _on_player_kick() -> void:
    _kick_view.kick()
    _shake = maxf(_shake, KICK_SHAKE)

func _on_goal() -> void:
    _sfx.play(Sfx.GOAL)
    _sfx.play(Sfx.BLIZZARD, -3.0)
    _frost_flash.color.a = FROST_FLASH_ALPHA
    create_tween().tween_property(_frost_flash, "color:a", 0.0, FROST_FLASH_DURATION).set_ease(Tween.EASE_OUT)
    _shake = maxf(_shake, GOAL_SHAKE)
    # "GOAL!" 글자가 크게 튀어나왔다가 제자리로 돌아옵니다.
    _message_label.pivot_offset = _message_label.size / 2
    _message_label.scale = Vector2.ONE * 1.8
    create_tween().tween_property(_message_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# 카메라 위치는 그대로 두고 화면만 어긋나게(h_offset, v_offset) 흔듭니다.
func _shake_camera(delta: float) -> void:
    _shake = move_toward(_shake, 0.0, _shake * SHAKE_DECAY * delta + 0.001)
    _camera.h_offset = randf_range(-1, 1) * _shake
    _camera.v_offset = randf_range(-1, 1) * _shake

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
