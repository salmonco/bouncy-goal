class_name Game
extends RefCounted

var ball: Ball

func _init() -> void:
    ball = Ball.new()

func start() -> void:
    ball.position = Vector3.ZERO
