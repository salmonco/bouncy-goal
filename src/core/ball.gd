class_name Ball
extends RefCounted

var position: Vector3

func _init(_position: Vector3 = Vector3.ZERO) -> void:
    position = _position
