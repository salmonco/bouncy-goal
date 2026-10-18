class_name Server
extends Node3D

const PORT := 8080
const MAX_CLIENTS := 32

const MAX_PLAYERS_IN_BATTLE := 2

var games: Array[Game] = []
var characters: Array[Character] = []
var waitings: Array[Character] = []

func _ready() -> void:
    _create_peer()
    multiplayer.peer_connected.connect(on_peer_connected)
    multiplayer.peer_disconnected.connect(on_peer_disconnected)

func _process(delta: float) -> void:
    for game in games:
        game.tick(delta)
        for character in game.characters:
            screen_changed.rpc_id(character.peer_id, game.snapshot(character.peer_id))

func _create_peer() -> void:
    var peer := ENetMultiplayerPeer.new()
    peer.create_server(PORT, MAX_CLIENTS)
    multiplayer.multiplayer_peer = peer
    print("server listen on %d" % PORT)

func on_peer_connected(id: int) -> void:
    print("피어 접속: %d" % id)
    var character := Character.new(Vector3.ZERO, Vector3.FORWARD, id)
    characters.append(character)
    waitings.append(character)

func on_peer_disconnected(id: int) -> void:
    var game := game_of(id)
    var player := character_of(id)
    if game != null:
        if game.characters.size() == 2:
            games.erase(game)
            for character in game.characters:
                if character != player:
                    waitings.append(character)
                    opponent_left.rpc_id(character.peer_id)
        game.characters.erase(player)
    characters.erase(player)
    waitings.erase(player)

@rpc("any_peer", "call_remote", "reliable")
func request_game_start() -> void:
    if not _can_start_game():
        return
    var game := game_of(multiplayer.get_remote_sender_id())
    game.start()
    for player in game.characters:
        game_started.rpc_id(player.peer_id, game.snapshot(player.peer_id))

@rpc("any_peer", "call_remote", "reliable")
func request_game_restart() -> void:
    var peer_id := multiplayer.get_remote_sender_id()
    var game := game_of(peer_id) 
    if game == null or game.status != GameStatus.OVER:
        return
    game.start()

@rpc("any_peer", "call_remote", "unreliable")
func request_move_input(input_vector: Vector2) -> void:
    var peer_id := multiplayer.get_remote_sender_id()
    character_of(peer_id).move_input = Vector3(input_vector.x, 0, input_vector.y)

@rpc("any_peer", "call_remote", "reliable")
func request_turn(angle: float) -> void:
    var peer_id := multiplayer.get_remote_sender_id()
    character_of(peer_id).turn(angle)

@rpc("any_peer", "call_remote", "reliable")
func request_tilt(angle: float) -> void:
    var peer_id := multiplayer.get_remote_sender_id()
    character_of(peer_id).tilt(angle)

@rpc("any_peer", "call_remote", "reliable")
func request_bounce() -> void:
    var peer_id := multiplayer.get_remote_sender_id()
    var game := game_of(peer_id)
    if game == null or not character_of(peer_id).bounce(game.ball):
        return
    for character in game.characters:
        kicked.rpc_id(character.peer_id, peer_id)

@rpc("authority", "call_remote", "reliable")
func game_started(_snapshot: Dictionary) -> void:
    pass

@rpc("authority", "call_remote", "unreliable_ordered")
func screen_changed(_snapshot: Dictionary) -> void:
    pass

@rpc("authority", "call_remote", "reliable")
func kicked(_peer_id: int) -> void:
    pass

@rpc("authority", "call_remote", "reliable")
func opponent_left() -> void:
    pass

func character_of(peer_id: int) -> Character:
    for character in characters:
        if character.peer_id == peer_id:
            return character
    return null

func game_of(peer_id: int) -> Game:
    for game in games:
        if character_of(peer_id) in game.characters:
            return game
    return null

func _can_start_game() -> bool:
    if waitings.size() < MAX_PLAYERS_IN_BATTLE:
        return false
    var players: Array[Character] = []
    for i in range(MAX_PLAYERS_IN_BATTLE):
        players.append(waitings.pop_front())
    var game := Game.new(players)
    games.append(game)
    return true
