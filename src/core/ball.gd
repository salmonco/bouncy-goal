class_name Ball
extends RefCounted

const POSITION := Vector3.ZERO
const RADIUS := 25.0
const FRICTION := 100.0
const GRAVITY := 300.0
const RESTITUTION := 0.8
const MIN_BOUNCE_SPEED := 15.0

var position: Vector3
var velocity: Vector3 = Vector3.ZERO

func _init(_position: Vector3 = POSITION) -> void:
    position = _position

func move(delta: float) -> void:
    var is_resting := position.y <= 0 and velocity.y <= 0
    if not is_resting:
        velocity.y -= GRAVITY * delta
    var horizontal := Vector3(velocity.x, 0, velocity.z).move_toward(Vector3.ZERO, FRICTION * delta)
    velocity = Vector3(horizontal.x, velocity.y, horizontal.z)
    position += velocity * delta
    if position.y < 0:
        position.y = 0
        velocity.y = -velocity.y * RESTITUTION
        if velocity.y < MIN_BOUNCE_SPEED:
            velocity.y = 0

func reset() -> void:
    position = POSITION
    velocity = Vector3.ZERO

func snapshot() -> Dictionary:
    return {
        "position": position,
        "velocity": velocity
    }
