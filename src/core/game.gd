class_name Game
extends RefCounted

const DURATION: float = 60 * 10
const FIELD_WIDTH: float = 800

var ball: Ball
var goals: Array[Goal] = [Goal.new(Vector3(0, 0, -999)), Goal.new(Vector3(0, 0, 999))]
var characters: Array[Character]
var status: StringName = GameStatus.WAITING

var _elapsed_time: float = 0.0
var _forward_goal := goals[0]
var _back_goal := goals[1]

func _init(_characters: Array[Character] = []) -> void:
    ball = Ball.new()
    characters = _characters

func tick(delta: float) -> void:
    if status == GameStatus.WAITING or status == GameStatus.OVER:
        return
    _elapsed_time += delta
    if _elapsed_time > DURATION:
        status = GameStatus.OVER
    if _is_forward_goal():
        _forward_goal.score += 1
    if _is_back_goal():
        _back_goal.score += 1
    if is_goal():
        ball.reset()
    for character in characters:
        character.move(delta)
    ball.move(delta)
    if ball.position.x > FIELD_WIDTH / 2 or ball.position.x < -FIELD_WIDTH / 2:
        ball.velocity.x = -ball.velocity.x
        ball.position.x = clamp(ball.position.x, -FIELD_WIDTH / 2, FIELD_WIDTH / 2)

func start() -> void:
    ball.reset()
    status = GameStatus.PLAYING

func is_goal() -> bool:
    return _is_forward_goal() or _is_back_goal()

func _is_forward_goal() -> bool:
    var to_forward_goal := _forward_goal.position - ball.position
    return ball.position.distance_to(_forward_goal.position) < Goal.WIDTH / 2 and not Vector3.FORWARD.dot(to_forward_goal) > 0

func _is_back_goal() -> bool:
    var to_back_goal := _back_goal.position - ball.position
    return ball.position.distance_to(_back_goal.position) < Goal.WIDTH / 2 and not Vector3.BACK.dot(to_back_goal) > 0

func remaining_time() -> float:
    return DURATION - _elapsed_time
