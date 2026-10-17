class_name FieldView
extends Node3D

# 경기장 바닥을 그립니다. 경기장은 작은 눈 행성(PlanetView) 꼭대기에 놓인 얼음 바위 받침대 위에 있습니다.
# 잔디 줄무늬와 라인은 셰이더로 그려서 코어(Game, Goal) 크기가 바뀌어도 그대로 따라갑니다.

# 받침대는 벽과 골망 바깥까지 덮을 만큼 경기장보다 넓게 깝니다.
const PLATFORM_MARGIN := 60.0
# 행성 표면이 경기장 가장자리에서 내려앉는 만큼보다 깊게 박아, 받침대 아래로 틈이 보이지 않게 합니다.
const PLATFORM_DEPTH := 500.0
const PLATFORM_TOP_HEIGHT := 6.0
# 받침대 윗면은 눈, 옆면은 푸르스름한 얼음 바위입니다.
const PLATFORM_TOP_COLOR := Color(0.97, 0.98, 1.0)
const PLATFORM_SOIL_COLOR := Color(0.55, 0.62, 0.78)

const FIELD_SHADER := preload("res://assets/materials/field.gdshader")

func _ready() -> void:
    var plane := PlaneMesh.new()
    plane.size = Vector2(Game.FIELD_WIDTH, Game.FIELD_LENGTH)
    var material := ShaderMaterial.new()
    material.shader = FIELD_SHADER
    material.set_shader_parameter("field_size", plane.size)
    material.set_shader_parameter("goal_width", Goal.WIDTH)
    plane.material = material
    var field := MeshInstance3D.new()
    field.mesh = plane
    add_child(field)

    var platform_size := Vector2(
        Game.FIELD_WIDTH + (FieldWallsView.THICKNESS + PLATFORM_MARGIN) * 2,
        Game.FIELD_LENGTH + (Goal.DEPTH + PLATFORM_MARGIN) * 2
    )
    # 잔디 윗면은 경기장 바로 아래에 깔아 경기장과 겹쳐 깜빡이지 않게 합니다.
    var top := Shapes.box(Vector3(platform_size.x, PLATFORM_TOP_HEIGHT, platform_size.y), PLATFORM_TOP_COLOR)
    top.position.y = -0.5 - PLATFORM_TOP_HEIGHT / 2
    add_child(top)
    var soil := Shapes.box(Vector3(platform_size.x, PLATFORM_DEPTH, platform_size.y), PLATFORM_SOIL_COLOR)
    soil.position.y = -0.5 - PLATFORM_TOP_HEIGHT - PLATFORM_DEPTH / 2
    add_child(soil)
