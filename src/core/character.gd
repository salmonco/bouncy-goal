class_name Character
extends RefCounted

const BOUNCE_RANGE := 80.0
const POWER := 300.0
const LIFT_POWER := 500.0
const MIN_PITCH := deg_to_rad(-30)
const MAX_PITCH := deg_to_rad(60)
const SPEED := 250.0
const NO_TEAM := -1

signal bounced

var position: Vector3
var facing: Vector3
var pitch: float = 0.0
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
    var direction := aim()
    ball.velocity = Vector3(direction.x * POWER, direction.y * LIFT_POWER, direction.z * POWER)
    bounced.emit()
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
    pitch = 0.0
    move_input = Vector3.ZERO

func turn(angle: float) -> void:
    facing = facing.rotated(Vector3.UP, angle).normalized()

func tilt(angle: float) -> void:
    pitch = clampf(pitch + angle, MIN_PITCH, MAX_PITCH)

func aim() -> Vector3:
    var right := facing.cross(Vector3.UP).normalized()
    return facing.rotated(right, pitch)
