class_name Goal
extends RefCounted

const WIDTH := 100.0

var position: Vector3
var score: int = 0

func _init(_position: Vector3) -> void:
    position = _position
