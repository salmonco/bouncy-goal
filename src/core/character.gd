class_name Character
extends RefCounted

const BOUNCE_RANGE := 50.0
const POWER := 10.0
const SPEED := 200.0

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
    if move_input == Vector3.ZERO:
        return Vector3.ZERO
    var angle := Vector3.FORWARD.signed_angle_to(move_input, Vector3.UP)
    return facing.rotated(Vector3.UP, angle)

func move(delta: float) -> void:
    position += world_move_direction() * Character.SPEED * delta

func turn(angle: float) -> void:
    facing = facing.rotated(Vector3.UP, angle).normalized()
