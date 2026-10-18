class_name Goal
extends RefCounted

const WIDTH := 250.0
const DEPTH := 70.0
const HEIGHT := 150.0

var position: Vector3
var score: int = 0
var team: int

func _init(_position: Vector3, _team: int = Character.NO_TEAM) -> void:
    position = _position
    team = _team

func reset() -> void:
    score = 0

func snapshot() -> Dictionary:
    return {
        "position": position,
        "score": score,
        "team": team
    }
