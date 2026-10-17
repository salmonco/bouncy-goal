class_name BallView
extends Node3D

# 1인칭에서 공이 어디에 떨어질지 가늠하도록, 공 바로 아래 바닥에 위치 표시 고리를 그립니다.
# 태양 그림자는 비스듬히 떨어져서 낙하 지점을 알려주지 못합니다.
# 경기장 중앙선(높이 0.5)에 묻히지 않을 만큼만 띄웁니다.
const MARKER_HEIGHT := 0.6
const MARKER_COLOR := Color(1.0, 0.9, 0.2, 0.8)
# 도넛 모양을 납작하게 눌러 바닥에 깔린 고리처럼 보이게 합니다.
const MARKER_FLATNESS := 0.1
# 공이 이 높이 이상 뜨면 고리가 가장 작아집니다. 고리 크기로 공이 얼마나 떴는지 알 수 있습니다.
const MARKER_SHRINK_HEIGHT := 300.0
const MARKER_MIN_SCALE := 0.4

var ball: Ball

var _marker: MeshInstance3D

func _init(_ball: Ball) -> void:
    ball = _ball

func _ready() -> void:
    var sphere := SphereMesh.new()
    sphere.radius = Ball.RADIUS
    sphere.height = Ball.RADIUS * 2
    var body := Shapes.mesh(sphere, Color.WHITE)
    # 코어의 position 은 공의 바닥 기준이라, 땅에 묻히지 않게 반지름만큼 띄웁니다.
    body.position.y = Ball.RADIUS
    add_child(body)

    var ring := TorusMesh.new()
    ring.inner_radius = Ball.RADIUS * 0.75
    ring.outer_radius = Ball.RADIUS
    _marker = Shapes.mesh(ring, MARKER_COLOR)
    _marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_marker)

func _process(_delta: float) -> void:
    position = ball.position
    # 공을 따라 함께 뜨지 않도록, 공의 높이만큼 도로 내려 바닥에 붙입니다.
    _marker.position.y = MARKER_HEIGHT - ball.position.y
    var shrink := lerpf(1.0, MARKER_MIN_SCALE, clampf(ball.position.y / MARKER_SHRINK_HEIGHT, 0.0, 1.0))
    _marker.scale = Vector3(shrink, MARKER_FLATNESS, shrink)
