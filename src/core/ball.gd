class_name Ball
extends RefCounted

const POSITION := Vector3.ZERO

var position: Vector3
var velocity: Vector3 = Vector3.ZERO

func _init(_position: Vector3 = POSITION) -> void:
    position = _position
