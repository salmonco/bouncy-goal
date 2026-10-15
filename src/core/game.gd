class_name Game
extends RefCounted

const DURATION := 1000 * 60 * 10

var ball: Ball
var goals: Array[Goal]
var characters: Array[Character]
var status: StringName = GameStatus.WAITING
var _elapsed_time: float = 0.0

func _init(_character: Array[Character] = []) -> void:
    ball = Ball.new()
    goals = [Goal.new(Vector3(0, 0, -999)), Goal.new(Vector3(0, 0, 999))]
    characters = _character

func tick(delta: float) -> void:
    if status == GameStatus.WAITING:
        return
    _elapsed_time += delta
    if is_goal():
        goals[0].score += 1
        ball.position = Ball.POSITION
    if _elapsed_time > DURATION:
        status = GameStatus.OVER

func start() -> void:
    ball.position = Vector3.ZERO
    status = GameStatus.PLAYING

func is_goal() -> bool:
    var to_goal := goals[0].position - ball.position
    return ball.position.distance_to(goals[0].position) < Goal.WIDTH / 2 and not Vector3.FORWARD.dot(to_goal) > 0
