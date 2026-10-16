class_name Ball
extends RefCounted

const POSITION := Vector3.ZERO
const FRICTION := 50.0

var position: Vector3
var velocity: Vector3 = Vector3.ZERO

func _init(_position: Vector3 = POSITION) -> void:
    position = _position

func move(delta: float) -> void:
    velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)
    position += velocity * delta

func reset() -> void:
    position = POSITION
    velocity = Vector3.ZERO
