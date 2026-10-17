class_name Character
extends RefCounted

const BOUNCE_RANGE := 50.0
const POWER := 250.0
const LIFT := 200.0
const SPEED := 250.0
const NO_TEAM := -1

var position: Vector3
var facing: Vector3
var move_input: Vector3 = Vector3.ZERO
var speed: float = SPEED
var team: int = NO_TEAM

var _start_position: Vector3
var _start_facing: Vector3

func _init(_position = Vector3.ZERO, _facing = Vector3.FORWARD) -> void:
    position = _position
    facing = _facing
    _start_position = _position
    _start_facing = _facing

func bounce(ball: Ball) -> bool:
    var to_ball := ball.position - position
    if to_ball.length() > BOUNCE_RANGE or facing.dot(to_ball) <= 0:
        return false
    ball.velocity = facing * POWER + Vector3.UP * LIFT
    return true

func world_move_direction() -> Vector3:
    if move_input == Vector3.ZERO:
        return Vector3.ZERO
    var angle := Vector3.FORWARD.signed_angle_to(move_input, Vector3.UP)
    return facing.rotated(Vector3.UP, angle)

func move(delta: float) -> void:
    position += world_move_direction() * speed * delta

func place(_position: Vector3, _facing: Vector3) -> void:
    _start_position = _position
    _start_facing = _facing
    reset()

func reset() -> void:
    position = _start_position
    facing = _start_facing
    move_input = Vector3.ZERO

func turn(angle: float) -> void:
    facing = facing.rotated(Vector3.UP, angle).normalized()
