class_name FieldWallsView
extends Node3D

# 코어(Game)의 경기장 경계에 투명한 유리벽을 세웁니다. 벽 안쪽 면이 경계선에 맞도록 바깥으로 두께의 절반만큼 밀어둡니다.
# 코어는 높이와 상관없이 경계에서 공을 튕기므로 유리벽도 공이 뜨는 높이까지 세웁니다.
# 앞뒤 벽은 골대 입구(Goal.WIDTH)만큼 비워두되, 크로스바(Goal.HEIGHT) 위로는 막혀 있으므로 유리로 채웁니다.
# 유리 바닥에는 낮은 얼음 턱을 둘러, 투명한 벽이 어디 서 있는지 바닥에서 알아볼 수 있게 합니다.

const THICKNESS := 10.0
# 공이 가장 높이 떴을 때(위로 MAX_PITCH, 약 312)에 공 지름을 더해도 넘지 않을 만큼.
const GLASS_HEIGHT := 400.0
const GLASS_COLOR := Color(0.8, 0.9, 1.0, 0.12)
const CURB_HEIGHT := 5.0
const CURB_COLOR := Color(0.78, 0.88, 1.0)

func _ready() -> void:
    var half_width := Game.FIELD_WIDTH / 2
    var half_length := Game.FIELD_LENGTH / 2

    for side in [-1, 1]:
        var x: float = side * (half_width + THICKNESS / 2)
        _add_wall(Vector2(THICKNESS, Game.FIELD_LENGTH + THICKNESS * 2), x, 0, 0)

    var segment_length := (Game.FIELD_WIDTH - Goal.WIDTH) / 2
    for end in [-1, 1]:
        var z: float = end * (half_length + THICKNESS / 2)
        for side in [-1, 1]:
            var x: float = side * (Goal.WIDTH / 2 + segment_length / 2)
            _add_wall(Vector2(segment_length, THICKNESS), x, z, 0)
        _add_wall(Vector2(Goal.WIDTH, THICKNESS), 0, z, Goal.HEIGHT)

# footprint 는 바닥 면적(x 너비, z 길이)이고, bottom 높이부터 GLASS_HEIGHT 까지 유리벽을 세웁니다.
# 땅에서 시작하는 벽에는 얼음 턱을 함께 둡니다.
func _add_wall(footprint: Vector2, x: float, z: float, bottom: float) -> void:
    var glass := Shapes.box(Vector3(footprint.x, GLASS_HEIGHT - bottom, footprint.y), GLASS_COLOR)
    glass.position = Vector3(x, (bottom + GLASS_HEIGHT) / 2, z)
    # 유리벽이 경기장에 큰 그림자를 드리우지 않게 합니다.
    glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(glass)
    if bottom == 0:
        var curb := Shapes.box(Vector3(footprint.x, CURB_HEIGHT, footprint.y), CURB_COLOR)
        curb.position = Vector3(x, CURB_HEIGHT / 2, z)
        add_child(curb)
