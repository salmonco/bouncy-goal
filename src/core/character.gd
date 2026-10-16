class_name Character
extends RefCounted

const BOUNCE_RANGE := 50.0
const POWER := 10.0

var position: Vector3
var facing : Vector3

func _init(_position = Vector3.ZERO, _facing = Vector3.FORWARD) -> void:
    position = _position
    facing = _facing

func bounce(ball: Ball) -> bool:
    var to_ball := ball.position - position
    if to_ball.length() > BOUNCE_RANGE or facing.dot(to_ball) <= 0:
        return false
    ball.position += facing * POWER
    return true
