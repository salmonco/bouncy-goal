class_name Character
extends RefCounted

const BOUNCE_RANGE := 50.0
const POWER := 10.0
const SPEED := 5.0

var position: Vector3
var facing: Vector3
var move_input: Vector3 = Vector3.ZERO

func _init(_position = Vector3.ZERO, _facing = Vector3.FORWARD) -> void:
    position = _position
    facing = _facing

func bounce(ball: Ball) -> bool:
    var to_ball := ball.position - position
    if to_ball.length() > BOUNCE_RANGE or facing.dot(to_ball) <= 0:
        return false
    ball.position += facing * POWER
    return true

func world_move_direction() -> Vector3:
    if move_input == Vector3.FORWARD:
        return facing.rotated(Vector3.UP, deg_to_rad(0))
    if move_input == Vector3.BACK:
        return facing.rotated(Vector3.UP, deg_to_rad(180))
    if move_input == Vector3.LEFT:
        return facing.rotated(Vector3.UP, deg_to_rad(90))
    if move_input == Vector3.RIGHT:
        return facing.rotated(Vector3.UP, deg_to_rad(-90))
    return Vector3.ZERO
