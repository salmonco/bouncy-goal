extends Node3D

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _planet_view: PlanetView = $PlanetView
@onready var _field_view: FieldView = $FieldView
@onready var _field_walls_view: FieldWallsView = $FieldWallsView
@onready var _hud_view: HudView = $HudView
@onready var _first_person_kick_view: FirstPersonKickView = $Camera3D/FirstPersonKickView

const ADDRESS := "localhost"

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

func _ready() -> void:
    _create_peer()
    multiplayer.connected_to_server.connect(on_connected_to_server)

func _create_peer() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_client(ADDRESS, Server.PORT)
    multiplayer.multiplayer_peer = peer

func on_connected_to_server() -> void:
    peer_id = multiplayer.get_unique_id()
    request_game_start.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_game_start() -> void:
    pass

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
    for goal in snapshot["goals"]:
        var goal_view := GoalView.new(goal.position, goal.team)
        goal_view.render(goal)
        add_child(goal_view)
        _goal_views.append(goal_view)
    for character in snapshot["characters"]:
        var character_view := CharacterView.new()
        character_view.render(character)
        # 1인칭이라 내 캐릭터는 카메라를 가리지 않게 숨깁니다.
        character_view.visible = character.peer_id != peer_id
        add_child(character_view)
        _character_views[character.peer_id] = character_view
    _ball_view = BallView.new()
    _ball_view.render(snapshot["ball"])
    add_child(_ball_view)
    _sfx = Sfx.new()
    add_child(_sfx)
    _ball_view.landed.connect(func(at: Vector3): _sfx.play_at(Sfx.GROUND, at, -2.0))
    _last_status = snapshot["status"]

@rpc("authority", "call_remote", "unreliable_ordered")
func screen_changed(snapshot: Dictionary) -> void:
    if _ball_view == null:
        return
    if snapshot["status"] != _last_status and snapshot["status"] == GameStatus.GOAL:
        _on_goal(snapshot["status"], snapshot["result"])
    _camera.position = snapshot["player"].position + Vector3.UP * EYE_HEIGHT
    _camera.look_at(_camera.position + snapshot["player"].aim)
    _hud_view.update_score(snapshot["player"].team, snapshot["score"], snapshot["opponent_team"], snapshot["opponent_score"])
    _hud_view.update_time(snapshot["remaining_time"])
    _show_message(snapshot["status"], snapshot["result"])
    for i in _goal_views.size():
        _goal_views[i].render(snapshot["goals"][i])
    _ball_view.render(snapshot["ball"])
    for character in snapshot["characters"]:
        _character_views[character.peer_id].render(character)
    _last_status = snapshot["status"]

@rpc("authority", "call_remote", "reliable")
func kicked(kicker_peer_id: int) -> void:
    _character_views[kicker_peer_id].kick()
    _sfx.play_at(Sfx.KICK, _ball_view.position + Vector3.UP * Ball.RADIUS)
    if kicker_peer_id == peer_id:
        _on_player_kick()

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
