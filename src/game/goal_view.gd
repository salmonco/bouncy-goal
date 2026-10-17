class_name GoalView
extends Node3D

# 눈 행성(라비네)의 골대를 그립니다. 기둥과 크로스바 위에는 눈이 쌓이고, 크로스바 아래로 고드름이 매달립니다.
# 그물은 흰 밧줄의 마름모 그물코이고, 뒤·양옆·위 네 면이 바깥으로 살짝 처집니다. 골대 입구는 비어 있습니다.

const POST_HEIGHT := Goal.HEIGHT
const POST_THICKNESS := 5.0
const POST_COLOR := Color(0.98, 0.98, 1.0)
const SNOW_COLOR := Color(0.97, 0.98, 1.0)
const SNOW_CAP_HEIGHT := 2.5
const ICICLE_COLOR := Color(0.72, 0.88, 1.0)
# 눈과 얼음은 진한 기본 외곽선을 두르면 멀리서 검은 점처럼 보이므로, 눈뭉치 공처럼 푸른 회색으로 얇게 그립니다.
const ICE_OUTLINE_COLOR := Color(0.55, 0.64, 0.82)
const ICE_OUTLINE_WIDTH := 0.15
const ICICLE_COUNT := 14
const ICICLE_SEED := 3

# 그물은 흰 밧줄에 이 골대를 지키는 팀의 색을 살짝 섞어, 어느 팀 골대인지 알 수 있게 합니다.
const NET_COLOR := Color(0.96, 0.97, 1.0)
const NET_TEAM_TINT := 0.3
const NET_SAG := 6.0
# 처지는 모양이 매끄럽도록 그물 판을 잘게 나눕니다.
const NET_SUBDIVISIONS := 16
const NET_SHADER := preload("res://assets/materials/net.gdshader")

var goal: Goal

func _init(_goal: Goal) -> void:
    goal = _goal

func _ready() -> void:
    var half_width := Goal.WIDTH / 2
    # 골대 바깥쪽(경기장 밖) 방향. 그물은 이쪽으로 뻗습니다.
    var outward := signf(goal.position.z)

    for x in [-half_width, half_width]:
        var post := Shapes.box(Vector3(POST_THICKNESS, POST_HEIGHT, POST_THICKNESS), POST_COLOR)
        post.position = Vector3(x, POST_HEIGHT / 2, 0)
        add_child(post)

    var crossbar := Shapes.box(Vector3(Goal.WIDTH + POST_THICKNESS, POST_THICKNESS, POST_THICKNESS), POST_COLOR)
    crossbar.position = Vector3(0, POST_HEIGHT, 0)
    add_child(crossbar)
    _add_snow_and_icicles()

    var net := ShaderMaterial.new()
    net.shader = NET_SHADER
    net.set_shader_parameter("color", NET_COLOR.lerp(TeamColors.of(goal.team), NET_TEAM_TINT))
    # 뒤 판은 바깥으로, 옆 판은 각자 옆으로 부풀고, 위 판은 아래로 처집니다.
    _add_net(net, Vector2(Goal.WIDTH, POST_HEIGHT), PlaneMesh.FACE_Z, Vector3(0, POST_HEIGHT / 2, outward * Goal.DEPTH), outward * NET_SAG)
    for side in [-1, 1]:
        _add_net(net, Vector2(Goal.DEPTH, POST_HEIGHT), PlaneMesh.FACE_X, Vector3(side * half_width, POST_HEIGHT / 2, outward * Goal.DEPTH / 2), side * NET_SAG)
    _add_net(net, Vector2(Goal.WIDTH, Goal.DEPTH), PlaneMesh.FACE_Y, Vector3(0, POST_HEIGHT, outward * Goal.DEPTH / 2), -NET_SAG)

# size 는 판의 가로·세로이고, orientation 은 판이 바라보는 축입니다. sag 만큼 그 축 방향으로 처집니다.
func _add_net(material: ShaderMaterial, size: Vector2, orientation: PlaneMesh.Orientation, center: Vector3, sag: float) -> void:
    var panel := PlaneMesh.new()
    panel.orientation = orientation
    panel.size = size
    panel.subdivide_width = NET_SUBDIVISIONS
    panel.subdivide_depth = NET_SUBDIVISIONS
    var instance := MeshInstance3D.new()
    instance.mesh = panel
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instance.set_instance_shader_parameter("sag", sag)
    instance.position = center
    add_child(instance)

func _add_snow_and_icicles() -> void:
    var half_width := Goal.WIDTH / 2
    var ice_outline := Shapes.outline_material(ICE_OUTLINE_COLOR, ICE_OUTLINE_WIDTH)
    var cap_width := POST_THICKNESS + 2.0
    var cap_mesh := BoxMesh.new()
    cap_mesh.size = Vector3(Goal.WIDTH + cap_width, SNOW_CAP_HEIGHT, cap_width)
    var crossbar_cap := Shapes.mesh(cap_mesh, SNOW_COLOR, ice_outline)
    crossbar_cap.position.y = POST_HEIGHT + POST_THICKNESS / 2 + SNOW_CAP_HEIGHT / 2
    add_child(crossbar_cap)

    var rng := RandomNumberGenerator.new()
    rng.seed = ICICLE_SEED
    for i in ICICLE_COUNT:
        var length := rng.randf_range(4.0, 13.0)
        var icicle_mesh := CylinderMesh.new()
        icicle_mesh.top_radius = rng.randf_range(1.0, 1.6)
        icicle_mesh.bottom_radius = 0.0
        icicle_mesh.height = length
        icicle_mesh.radial_segments = 8
        var icicle := Shapes.mesh(icicle_mesh, ICICLE_COLOR, ice_outline)
        var x := lerpf(-half_width + 6, half_width - 6, (i + rng.randf_range(-0.3, 0.3)) / (ICICLE_COUNT - 1))
        icicle.position = Vector3(x, POST_HEIGHT - POST_THICKNESS / 2 - length / 2, 0)
        add_child(icicle)

func _process(_delta: float) -> void:
    position = goal.position
