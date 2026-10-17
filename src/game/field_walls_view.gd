class_name FieldWallsView
extends Node3D

# 코어(Game)의 경기장 경계에 낮은 벽을 세웁니다. 벽 안쪽 면이 경계선에 맞도록 바깥으로 두께의 절반만큼 밀어둡니다.
# 앞뒤 벽은 골대 입구(Goal.WIDTH)만큼 비워둡니다.
#
# 코어는 높이와 상관없이 경계에서 공을 튕기므로, 낮은 벽 위로 투명한 유리벽을 쌓아 그 경계를 보여줍니다.
# 골대 입구도 크로스바(Goal.HEIGHT) 위로는 막혀 있으므로 유리벽으로 채웁니다.

# 공(지름 Ball.RADIUS * 2)이 넘어가 보이지 않을 만큼, 골대(GoalView.POST_HEIGHT)보다는 낮게.
const HEIGHT := 50.0
const THICKNESS := 10.0
const COLOR := Color(0.9, 0.9, 0.9)
# 공이 가장 높이 떴을 때(위로 MAX_PITCH, 약 312)에 공 지름을 더해도 넘지 않을 만큼.
const GLASS_HEIGHT := 400.0
const GLASS_COLOR := Color(0.8, 0.9, 1.0, 0.12)

func _ready() -> void:
    var half_width := Game.FIELD_WIDTH / 2
    var half_length := Game.FIELD_LENGTH / 2

    for side in [-1, 1]:
        var x: float = side * (half_width + THICKNESS / 2)
        var footprint := Vector2(THICKNESS, Game.FIELD_LENGTH + THICKNESS * 2)
        _add_wall(footprint, x, 0, 0, HEIGHT, COLOR)
        _add_wall(footprint, x, 0, HEIGHT, GLASS_HEIGHT, GLASS_COLOR)

    var segment_length := (Game.FIELD_WIDTH - Goal.WIDTH) / 2
    for end in [-1, 1]:
        var z: float = end * (half_length + THICKNESS / 2)
        for side in [-1, 1]:
            var x: float = side * (Goal.WIDTH / 2 + segment_length / 2)
            var footprint := Vector2(segment_length, THICKNESS)
            _add_wall(footprint, x, z, 0, HEIGHT, COLOR)
            _add_wall(footprint, x, z, HEIGHT, GLASS_HEIGHT, GLASS_COLOR)
        _add_wall(Vector2(Goal.WIDTH, THICKNESS), 0, z, Goal.HEIGHT, GLASS_HEIGHT, GLASS_COLOR)

# footprint 는 바닥 면적(x 너비, z 길이)이고, bottom 에서 top 높이까지 세웁니다.
func _add_wall(footprint: Vector2, x: float, z: float, bottom: float, top: float, color: Color) -> void:
    var wall := Shapes.box(Vector3(footprint.x, top - bottom, footprint.y), color)
    wall.position = Vector3(x, (bottom + top) / 2, z)
    # 유리벽이 경기장에 큰 그림자를 드리우지 않도록 반투명한 벽은 그림자를 끕니다.
    if color.a < 1.0:
        wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(wall)
