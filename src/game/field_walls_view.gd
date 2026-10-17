class_name FieldWallsView
extends Node3D

# 코어(Game)의 경기장 경계에 낮은 벽을 세웁니다. 벽 안쪽 면이 경계선에 맞도록 바깥으로 두께의 절반만큼 밀어둡니다.
# 앞뒤 벽은 골대 입구(Goal.WIDTH)만큼 비워둡니다.

# 공(지름 Ball.RADIUS * 2)이 넘어가 보이지 않을 만큼, 골대(GoalView.POST_HEIGHT)보다는 낮게.
const HEIGHT := 50.0
const THICKNESS := 10.0
const COLOR := Color(0.9, 0.9, 0.9)

func _ready() -> void:
    var half_width := Game.FIELD_WIDTH / 2
    var half_length := Game.FIELD_LENGTH / 2

    for side in [-1, 1]:
        _add_wall(
            Vector3(THICKNESS, HEIGHT, Game.FIELD_LENGTH + THICKNESS * 2),
            Vector3(side * (half_width + THICKNESS / 2), HEIGHT / 2, 0)
        )

    var segment_length := (Game.FIELD_WIDTH - Goal.WIDTH) / 2
    for end in [-1, 1]:
        for side in [-1, 1]:
            _add_wall(
                Vector3(segment_length, HEIGHT, THICKNESS),
                Vector3(side * (Goal.WIDTH / 2 + segment_length / 2), HEIGHT / 2, end * (half_length + THICKNESS / 2))
            )

func _add_wall(size: Vector3, center: Vector3) -> void:
    var wall := Shapes.box(size, COLOR)
    wall.position = center
    add_child(wall)
