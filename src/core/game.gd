class_name Game
extends RefCounted

const DURATION: float = 60 * 10
const FIELD_WIDTH: float = 800
const FIELD_LENGTH: float = 2000
const GOAL_PAUSE: float = 2.0
const START_DISTANCE: float = 300
const START_SPACING: float = 100

var ball: Ball
var rng := RandomNumberGenerator.new()
var goals: Array[Goal] = [Goal.new(Vector3.FORWARD * FIELD_LENGTH / 2, 0), Goal.new(Vector3.BACK * FIELD_LENGTH / 2, 1)]
var characters: Array[Character]
var status: StringName = GameStatus.WAITING

var _elapsed_time: float = 0.0
var _goal_pause_remaining: float = 0.0
var _forward_goal := goals[0]
var _back_goal := goals[1]

func _init(_characters: Array[Character] = []) -> void:
    ball = Ball.new()
    characters = _characters
    rng.randomize()

func tick(delta: float) -> void:
    if status == GameStatus.WAITING or status == GameStatus.OVER:
        return
    _elapsed_time += delta
    if _elapsed_time > DURATION:
        status = GameStatus.OVER
        return
    if status == GameStatus.GOAL:
        _goal_pause_remaining -= delta
        if _goal_pause_remaining <= 0:
            _kickoff()
            return
    else:
        if _is_forward_goal():
            _forward_goal.score += 1
        if _is_back_goal():
            _back_goal.score += 1
        if is_goal():
            status = GameStatus.GOAL
            _goal_pause_remaining = GOAL_PAUSE
    for character in characters:
        character.move(delta)
        character.position.x = clamp(character.position.x, -FIELD_WIDTH / 2, FIELD_WIDTH / 2)
        character.position.z = clamp(character.position.z, -FIELD_LENGTH / 2, FIELD_LENGTH / 2)
    var was_past_goal_line := absf(ball.position.z) > FIELD_LENGTH / 2
    ball.move(delta)
    var half_width := Goal.WIDTH / 2 if was_past_goal_line else FIELD_WIDTH / 2
    if absf(ball.position.x) > half_width:
        ball.velocity.x = -ball.velocity.x
        ball.position.x = clamp(ball.position.x, -half_width, half_width)
    var is_within_goal_width := absf(ball.position.x) <= Goal.WIDTH / 2
    var half_length := FIELD_LENGTH / 2 + Goal.DEPTH if is_within_goal_width else FIELD_LENGTH / 2
    if absf(ball.position.z) > half_length:
        ball.velocity.z = -ball.velocity.z
        ball.position.z = clamp(ball.position.z, -half_length, half_length)

func start() -> void:
    _elapsed_time = 0.0
    for goal in goals:
        goal.reset()
    _form_teams()
    _kickoff()

func _form_teams() -> void:
    var shuffled := characters.duplicate()
    for i in range(shuffled.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp = shuffled[i]
        shuffled[i] = shuffled[j]
        shuffled[j] = temp
    for i in shuffled.size():
        shuffled[i].team = i % goals.size()
    for goal in goals:
        _line_up(shuffled.filter(func(c): return c.team == goal.team), goal)

func _line_up(members: Array, own_goal: Goal) -> void:
    var side := own_goal.position.normalized()
    for i in members.size():
        var offset := (i - (members.size() - 1) / 2.0) * START_SPACING
        members[i].place(side * START_DISTANCE + Vector3.RIGHT * offset, -side)

func _kickoff() -> void:
    ball.reset()
    for character in characters:
        character.reset()
    status = GameStatus.PLAYING

func goal_of(team: int) -> Goal:
    for goal in goals:
        if goal.team == team:
            return goal
    return null

func opponent_goal_of(team: int) -> Goal:
    for goal in goals:
        if goal.team != team:
            return goal
    return null

func is_goal() -> bool:
    return _is_forward_goal() or _is_back_goal()

func _is_forward_goal() -> bool:
    var to_forward_goal := _forward_goal.position - ball.position
    return ball.position.distance_to(_forward_goal.position) < Goal.WIDTH / 2 and not Vector3.FORWARD.dot(to_forward_goal) > 0

func _is_back_goal() -> bool:
    var to_back_goal := _back_goal.position - ball.position
    return ball.position.distance_to(_back_goal.position) < Goal.WIDTH / 2 and not Vector3.BACK.dot(to_back_goal) > 0

func remaining_time() -> float:
    return DURATION - _elapsed_time

func score_of(team: int) -> int:
    return opponent_goal_of(team).score

func winner() -> int:
    if status != GameStatus.OVER:
        return Character.NO_TEAM
    var teams := goals.map(func(g: Goal): return g.team)
    var max_score: int = teams.map(func(team: int): return score_of(team)).max()
    var leaders := teams.filter(func(team: int): return score_of(team) == max_score)
    if leaders.size() > 1:
        return Character.NO_TEAM
    return leaders[0]
