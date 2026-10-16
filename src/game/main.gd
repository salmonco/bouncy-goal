extends Node3D

# 코어(Game)를 매 프레임 진행시키고, 그 상태를 화면에 그립니다.

@onready var _camera: Camera3D = $Camera3D
@onready var _sun: DirectionalLight3D = $Sun
@onready var _score_label: Label = $HUD/Score

var game: Game

func _ready() -> void:
    _camera.look_at(Vector3(0, 0, 250))
    _sun.rotation_degrees = Vector3(-55, 30, 0)

    var characters: Array[Character] = [
        Character.new(Vector3(0, 0, 300), Vector3.FORWARD),
        Character.new(Vector3(0, 0, -300), Vector3.BACK),
    ]
    game = Game.new(characters)

    for goal in game.goals:
        add_child(GoalView.new(goal))
    add_child(CharacterView.new(characters[0], Color.ROYAL_BLUE))
    add_child(CharacterView.new(characters[1], Color.CRIMSON))
    add_child(BallView.new(game.ball))

    game.start()

func _process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    game.characters[0].move_input = Vector3(input_vector.x, 0, input_vector.y)
    game.tick(delta)
    _score_label.text = "%d : %d   %s   %s" % [game.goals[0].score, game.goals[1].score, _format_time(game.remaining_time()), game.status]

func _format_time(seconds: float) -> String:
    # 종료 직전 마지막 tick 에서 살짝 음수가 될 수 있어 0 에서 멈춥니다.
    var total := ceili(maxf(seconds, 0.0))
    @warning_ignore("integer_division")
    return "%02d:%02d" % [total / 60, total % 60]
