class_name Ball
extends RefCounted

const POSITION := Vector3.ZERO

var position: Vector3

func _init(_position: Vector3 = POSITION) -> void:
    position = _position
