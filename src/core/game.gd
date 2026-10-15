class_name Game
extends RefCounted

var ball: Ball
var goals: Array[Goal]

func _init() -> void:
    ball = Ball.new()
    goals = [Goal.new(Vector3(0, 0, -999)), Goal.new(Vector3(0, 0, 999))]

func start() -> void:
    ball.position = Vector3.ZERO
