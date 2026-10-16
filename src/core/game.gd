class_name Game
extends RefCounted

const DURATION: float = 60 * 5
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
        var character_from := character.position
        character.move(delta)
        character.position = _confine(character.position, character_from, 0)
    var ball_from := ball.position
    ball.move(delta)
    var confined := _confine(ball.position, ball_from, Ball.RADIUS)
    if confined.x != ball.position.x:
        ball.velocity.x = -ball.velocity.x
    if confined.z != ball.position.z:
        ball.velocity.z = -ball.velocity.z
    ball.position = confined

# 경기장 벽과 골망 벽 안으로 위치를 되돌립니다. 골대 입구로는 골망 안까지 들어갈 수 있습니다.
# from 은 이동 전 위치로, 이미 골망 안에 있었는지 판단하는 데 씁니다.
# radius 만큼 크기가 있으면 가장자리가 벽에 닿는 곳에서 멈춥니다.
func _confine(position: Vector3, from: Vector3, radius: float) -> Vector3:
    var was_past_goal_line := absf(from.z) > FIELD_LENGTH / 2 - radius
    var half_width := (Goal.WIDTH / 2 if was_past_goal_line else FIELD_WIDTH / 2) - radius
    var x := clampf(position.x, -half_width, half_width)
    var is_within_goal_width := absf(x) <= Goal.WIDTH / 2 - radius
    var half_length := (FIELD_LENGTH / 2 + Goal.DEPTH if is_within_goal_width else FIELD_LENGTH / 2) - radius
    var z := clampf(position.z, -half_length, half_length)
    return Vector3(x, position.y, z)

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
