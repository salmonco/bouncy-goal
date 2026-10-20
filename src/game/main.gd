extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _planet_view: PlanetView = $PlanetView
@onready var _field_view: FieldView = $FieldView
@onready var _field_walls_view: FieldWallsView = $FieldWallsView
@onready var _hud_view: HudView = $HudView
@onready var _first_person_kick_view: FirstPersonKickView = $Camera3D/FirstPersonKickView

const MOUSE_SENSITIVITY := 0.003
const EYE_HEIGHT := 40.0

const KICK_SHAKE := 0.8
const GOAL_SHAKE := 3.0
const SHAKE_DECAY := 8.0

var peer_id: int

var _goal_views: Array[GoalView] = []
var _ball_view: BallView
var _character_views: Dictionary[int, CharacterView] = {}

var _sfx: Sfx
var _shake := 0.0
var _last_status: StringName

# 서버는 물리 틱마다 틱 번호를 붙여 스냅샷을 보내므로, 화면 주사율이 더 높으면 같은 장면이 여러 프레임 반복되어 끊겨 보입니다.
# 그래서 받은 스냅샷을 쌓아 두고, 일정하게 흐르는 렌더링 시계(틱 단위)가 가리키는 시점을 스냅샷 사이에서 보간해 그립니다.
# 도착 시각이 아니라 틱 번호를 기준으로 하므로, 도착 간격이 흔들려도 화면은 고르게 움직입니다.
# 도착이 조금 늦어도 보간할 다음 스냅샷이 있도록, 최신 틱보다 이만큼 늦게 그립니다.
const RENDER_DELAY_TICKS := 1.5
# 렌더링 시계가 목표(최신 틱 - RENDER_DELAY_TICKS)에서 벗어난 만큼을 스냅샷이 올 때마다 이 비율씩 메웁니다.
# 작을수록 도착 흔들림이 화면에 덜 옮겨집니다.
const CLOCK_CORRECTION := 0.05
# 이보다 크게 벗어나면(게임 시작, 오래 끊김) 바로 맞춥니다.
const CLOCK_SNAP_TICKS := 4.0
const SNAPSHOT_BUFFER_SIZE := 8

var _snapshots: Array[Dictionary] = []
var _render_tick := 0.0

func _ready() -> void:
    _create_peer()
    multiplayer.connected_to_server.connect(on_connected_to_server)

func _create_peer() -> void:
    var peer := ENetMultiplayerPeer.new()
    var address: String = ProjectSettings.get_setting_with_override("network/server_address")
    peer.create_client(address, Server.PORT)
    multiplayer.multiplayer_peer = peer

func on_connected_to_server() -> void:
    peer_id = multiplayer.get_unique_id()
    _show_waiting("상대를 기다리는 중")

@rpc("any_peer", "call_remote", "reliable")
func request_game_restart() -> void:
    pass

@rpc("any_peer", "call_remote", "unreliable")
func request_move_input(_input_vector: Vector2) -> void:
    pass

@rpc("any_peer", "call_remote", "reliable")
func request_turn(_angle: float) -> void:
    pass

@rpc("any_peer", "call_remote", "reliable")
func request_tilt(_angle: float) -> void:
    pass

@rpc("any_peer", "call_remote", "reliable")
func request_bounce() -> void:
    pass

@rpc("authority", "call_remote", "reliable")
func game_started(snapshot: Dictionary) -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _sun.rotation_degrees = Vector3(-55, 30, 0)
    _planet_view.visible = true
    _field_view.visible = true
    _field_walls_view.visible = true
    _hud_view.visible = true
    _hud_view.show_scoreboard(true)
    for goal in snapshot["goals"]:
        var goal_view := GoalView.new(goal.position, goal.team)
        goal_view.render(goal)
        add_child(goal_view)
        _goal_views.append(goal_view)
    for character in snapshot["characters"]:
        var character_view := CharacterView.new()
        character_view.render(character)
        # 1인칭이라 내 캐릭터는 카메라를 가리지 않게 숨깁니다.
        character_view.visible = character.peer_id != multiplayer.get_unique_id()
        add_child(character_view)
        _character_views[character.peer_id] = character_view
    _ball_view = BallView.new()
    _ball_view.render(snapshot["ball"])
    add_child(_ball_view)
    _sfx = Sfx.new()
    add_child(_sfx)
    _ball_view.landed.connect(func(at: Vector3): _sfx.play_at(Sfx.GROUND, at, -2.0))
    _last_status = snapshot["status"]
    _snapshots = [snapshot]
    _render_tick = snapshot["tick"] - RENDER_DELAY_TICKS

@rpc("authority", "call_remote", "unreliable_ordered")
func screen_changed(snapshot: Dictionary) -> void:
    if _ball_view == null:
        return
    if snapshot["status"] != _last_status and snapshot["status"] == GameStatus.GOAL:
        _on_goal(snapshot["status"], snapshot["result"])
    _hud_view.update_score(snapshot["player"].team, snapshot["score"], snapshot["opponent_team"], snapshot["opponent_score"])
    _hud_view.update_time(snapshot["remaining_time"])
    _show_message(snapshot["status"], snapshot["result"])
    for i in _goal_views.size():
        _goal_views[i].render(snapshot["goals"][i])
    _last_status = snapshot["status"]
    # 보간된 공은 땅에 정확히 닿는 순간이 그려지지 않을 수 있어, 착지는 받은 스냅샷 그대로 판정합니다.
    _ball_view.detect_landing(snapshot["ball"])
    _snapshots.append(snapshot)
    if _snapshots.size() > SNAPSHOT_BUFFER_SIZE:
        _snapshots.pop_front()
    var clock_error: float = snapshot["tick"] - RENDER_DELAY_TICKS - _render_tick
    if absf(clock_error) > CLOCK_SNAP_TICKS:
        _render_tick += clock_error
    else:
        _render_tick += clock_error * CLOCK_CORRECTION

# 움직이는 것(카메라, 공, 캐릭터)만 렌더링 시계 tick 을 사이에 둔 두 스냅샷에서 보간해 그립니다.
# tick 이 가장 최신 스냅샷보다 뒤면(도착이 많이 늦으면) 최신 스냅샷에 멈춰 있습니다.
func _render_moving(tick: float) -> void:
    var from: Dictionary = _snapshots[0]
    var to: Dictionary = _snapshots[0]
    for snapshot in _snapshots:
        to = snapshot
        if snapshot["tick"] >= tick:
            break
        from = snapshot
    var weight := 0.0
    if to["tick"] > from["tick"]:
        weight = clampf((tick - from["tick"]) / float(to["tick"] - from["tick"]), 0.0, 1.0)
    var player := _interpolate_character(from["player"], to["player"], weight)
    _camera.position = player.position + Vector3.UP * EYE_HEIGHT
    _camera.look_at(_camera.position + player.aim)
    _ball_view.render(_interpolate_ball(from["ball"], to["ball"], weight))
    for character in to["characters"]:
        var previous := _character_in(from, character.peer_id)
        if previous.is_empty():
            previous = character
        _character_views[character.peer_id].render(_interpolate_character(previous, character, weight))

func _interpolate_ball(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
    var ball := to.duplicate()
    ball.position = from.position.lerp(to.position, weight)
    ball.velocity = from.velocity.lerp(to.velocity, weight)
    return ball

func _interpolate_character(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
    var character := to.duplicate()
    character.position = from.position.lerp(to.position, weight)
    character.facing = from.facing.slerp(to.facing, weight)
    character.pitch = lerpf(from.pitch, to.pitch, weight)
    character.aim = from.aim.slerp(to.aim, weight)
    return character

func _character_in(snapshot: Dictionary, character_peer_id: int) -> Dictionary:
    for character in snapshot["characters"]:
        if character.peer_id == character_peer_id:
            return character
    return {}

@rpc("authority", "call_remote", "reliable")
func kicked(kicker_peer_id: int) -> void:
    _character_views[kicker_peer_id].kick()
    _sfx.play_at(Sfx.KICK, _ball_view.position + Vector3.UP * Ball.RADIUS)
    if kicker_peer_id == peer_id:
        _on_player_kick()

@rpc("authority", "call_remote", "reliable")
func opponent_left() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    for goal_view in _goal_views:
        goal_view.queue_free()
    _goal_views.clear()
    for character_view in _character_views.values():
        character_view.queue_free()
    _character_views.clear()
    _ball_view.queue_free()
    _ball_view = null
    _sfx.queue_free()
    _show_waiting("상대가 나갔습니다. 새 상대를 기다리는 중")

func _show_waiting(subtitle: String) -> void:
    _hud_view.visible = true
    _hud_view.show_scoreboard(false)
    _hud_view.show_message("WAITING", subtitle)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if not _is_connected():
        return
    if event is InputEventMouseMotion:
        request_turn.rpc_id(1, -event.relative.x * MOUSE_SENSITIVITY)
        request_tilt.rpc_id(1, -event.relative.y * MOUSE_SENSITIVITY)
    if event.is_action_pressed("bounce"):
        request_bounce.rpc_id(1)
    if event.is_action_pressed("restart"):
        request_game_restart.rpc_id(1)

func _process(delta: float) -> void:
    if not _is_connected():
        return
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    request_move_input.rpc_id(1, input_vector)
    if _ball_view != null:
        _render_tick += delta * Engine.physics_ticks_per_second
        # 뷰들은 자식이라 이 _process 다음에 그려지므로, 이번 프레임의 보간 결과를 그대로 씁니다.
        _render_moving(_render_tick)
    _shake_camera(delta)

func _is_connected() -> bool:
    return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _on_player_kick() -> void:
    _first_person_kick_view.kick()
    _shake = maxf(_shake, KICK_SHAKE)

func _on_goal(game_status: StringName, result: String) -> void:
    _sfx.play(Sfx.GOAL)
    _sfx.play(Sfx.BLIZZARD, -3.0)
    _shake = maxf(_shake, GOAL_SHAKE)
    _show_message(game_status, result)
    _hud_view.celebrate_goal()

func _shake_camera(delta: float) -> void:
    _shake = move_toward(_shake, 0.0, _shake * SHAKE_DECAY * delta + 0.001)
    _camera.h_offset = randf_range(-1, 1) * _shake
    _camera.v_offset = randf_range(-1, 1) * _shake

func _show_message(status: StringName, result: String) -> void:
    match status:
        GameStatus.GOAL:
            _hud_view.show_message("GOAL!")
        GameStatus.OVER:
            _hud_view.show_message(result, "R 키로 다시 시작")
        _:
            _hud_view.show_message("")
