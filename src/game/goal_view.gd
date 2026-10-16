class_name GoalView
extends Node3D

const POST_HEIGHT := 60.0
const POST_THICKNESS := 5.0

var goal: Goal

func _init(_goal: Goal) -> void:
    goal = _goal

func _ready() -> void:
    var half_width := Goal.WIDTH / 2
    # 골대 바깥쪽(경기장 밖) 방향. 그물은 이쪽으로 뻗습니다.
    var outward := signf(goal.position.z)

    for x in [-half_width, half_width]:
        var post := Shapes.box(Vector3(POST_THICKNESS, POST_HEIGHT, POST_THICKNESS), Color.WHITE)
        post.position = Vector3(x, POST_HEIGHT / 2, 0)
        add_child(post)

    var crossbar := Shapes.box(Vector3(Goal.WIDTH + POST_THICKNESS, POST_THICKNESS, POST_THICKNESS), Color.WHITE)
    crossbar.position = Vector3(0, POST_HEIGHT, 0)
    add_child(crossbar)

    var net := Shapes.box(Vector3(Goal.WIDTH, POST_HEIGHT, Goal.DEPTH), Color(1, 1, 1, 0.25))
    net.position = Vector3(0, POST_HEIGHT / 2, outward * Goal.DEPTH / 2)
    add_child(net)

func _process(_delta: float) -> void:
    position = goal.position
