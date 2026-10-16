class_name Npc
extends Character

const CHASE_SPEED := 150.0

func _init(_position = Vector3.ZERO, _facing = Vector3.FORWARD) -> void:
    super(_position, _facing)
    speed = CHASE_SPEED

func think(ball: Ball, target_goal: Goal) -> void:
    var to_goal := (target_goal.position - ball.position).normalized()
    var to_ball := ball.position - position
    var is_behind_ball := to_ball.dot(to_goal) > 0
    if not is_behind_ball:
        _go_to(ball.position - to_goal * BOUNCE_RANGE / 2)
        return
    if to_ball == Vector3.ZERO:
        return
    facing = to_ball.normalized()
    if to_ball.length() <= BOUNCE_RANGE:
        move_input = Vector3.ZERO
    else:
        move_input = Vector3.FORWARD
    bounce(ball)

func _go_to(target: Vector3) -> void:
    var to_target := target - position
    if to_target == Vector3.ZERO:
        return
    facing = to_target.normalized()
    move_input = Vector3.FORWARD
