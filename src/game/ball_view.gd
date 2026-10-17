class_name BallView
extends Node3D

# 겨울 컨셉의 눈뭉치 공을 그립니다. 표면을 노이즈로 울퉁불퉁하게 만들고, 굴러간 거리만큼 실제로 데굴데굴 돌립니다.
#
# 1인칭에서 공이 어디에 떨어질지 가늠하도록, 공 바로 아래 바닥에 위치 표시 고리를 그립니다.
# 태양 그림자는 비스듬히 떨어져서 낙하 지점을 알려주지 못합니다.

const SNOW_COLOR := Color(0.98, 0.99, 1.0)
# 눈의 그림자는 회색보다 푸르스름해야 차갑고 깨끗해 보입니다.
const SNOW_SHADE_COLOR := Color(0.78, 0.86, 1.0)
# 공은 1인칭에서 늘 코앞에 있어 기본 외곽선(진한 색, 월드 단위 굵기)이 너무 굵고 튀므로, 푸른 회색으로 얇게 그립니다.
const SNOW_OUTLINE_COLOR := Color(0.55, 0.64, 0.82)
const SNOW_OUTLINE_WIDTH := 0.15
# 눈을 손으로 뭉친 듯한 울퉁불퉁함입니다. LUMP_SIZE 는 혹의 크기, LUMP_DEPTH 는 혹이 튀어나오는 정도입니다.
const LUMP_SIZE := 9.0
const LUMP_DEPTH := 1.8
const LUMP_SEED := 7

# 경기장 바닥(높이 0)과 겹쳐 깜빡이지 않을 만큼만 띄웁니다.
const MARKER_HEIGHT := 0.6
const MARKER_COLOR := Color(1.0, 0.9, 0.2, 0.8)
# 도넛 모양을 납작하게 눌러 바닥에 깔린 고리처럼 보이게 합니다.
const MARKER_FLATNESS := 0.1
# 공이 이 높이 이상 뜨면 고리가 가장 작아집니다. 고리 크기로 공이 얼마나 떴는지 알 수 있습니다.
const MARKER_SHRINK_HEIGHT := 300.0
const MARKER_MIN_SCALE := 0.4

var ball: Ball

var _body: MeshInstance3D
var _marker: MeshInstance3D
var _last_position: Vector3

func _init(_ball: Ball) -> void:
    ball = _ball

func _ready() -> void:
    _body = Shapes.mesh(_snowball_mesh(), SNOW_COLOR, Shapes.outline_material(SNOW_OUTLINE_COLOR, SNOW_OUTLINE_WIDTH))
    (_body.material_override as ShaderMaterial).set_shader_parameter("shade_color", SNOW_SHADE_COLOR)
    # 코어의 position 은 공의 바닥 기준이라, 땅에 묻히지 않게 반지름만큼 띄웁니다.
    _body.position.y = Ball.RADIUS
    add_child(_body)

    var ring := TorusMesh.new()
    ring.inner_radius = Ball.RADIUS * 0.75
    ring.outer_radius = Ball.RADIUS
    _marker = Shapes.mesh(ring, MARKER_COLOR)
    _marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_marker)
    _last_position = ball.position

func _process(_delta: float) -> void:
    position = ball.position
    _roll()
    # 공을 따라 함께 뜨지 않도록, 공의 높이만큼 도로 내려 바닥에 붙입니다.
    _marker.position.y = MARKER_HEIGHT - ball.position.y
    var shrink := lerpf(1.0, MARKER_MIN_SCALE, clampf(ball.position.y / MARKER_SHRINK_HEIGHT, 0.0, 1.0))
    _marker.scale = Vector3(shrink, MARKER_FLATNESS, shrink)

# 수평으로 굴러간 거리만큼, 진행 방향에 수직인 축으로 공을 돌립니다(거리 = 반지름 × 각도).
func _roll() -> void:
    var moved := ball.position - _last_position
    moved.y = 0
    _last_position = ball.position
    # 킥오프 리셋처럼 순간 이동한 경우는 굴리지 않습니다.
    if moved.length() < 0.001 or moved.length() > Ball.RADIUS * 4:
        return
    var axis := Vector3.UP.cross(moved.normalized())
    _body.basis = (Basis(axis, moved.length() / Ball.RADIUS) * _body.basis).orthonormalized()

# 구의 정점을 노이즈만큼 바깥으로 밀어 울퉁불퉁한 눈뭉치를 만듭니다.
func _snowball_mesh() -> ArrayMesh:
    var sphere := SphereMesh.new()
    sphere.radius = Ball.RADIUS
    sphere.height = Ball.RADIUS * 2
    sphere.radial_segments = 48
    sphere.rings = 24
    var arrays := sphere.get_mesh_arrays()
    var noise := FastNoiseLite.new()
    noise.seed = LUMP_SEED
    noise.frequency = 1.0 / LUMP_SIZE
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for i in vertices.size():
        var v := vertices[i]
        vertices[i] = v + v.normalized() * noise.get_noise_3dv(v) * LUMP_DEPTH
    arrays[Mesh.ARRAY_VERTEX] = vertices
    # 혹에 맞춰 법선을 다시 계산합니다.
    arrays[Mesh.ARRAY_NORMAL] = null
    arrays[Mesh.ARRAY_TANGENT] = null
    var lumpy := ArrayMesh.new()
    lumpy.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var surface := SurfaceTool.new()
    surface.create_from(lumpy, 0)
    surface.generate_normals()
    return surface.commit()
