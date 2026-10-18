class_name BlizzardEffect
extends Node3D

# 골 축하 연출입니다. 이나즈마 일레븐의 '이터널 블리자드'처럼 얼음 눈보라가 휘몰아치다 터집니다.
#   - 눈보라 회오리: 눈송이가 나선을 그리며 솟구치고, 후반에는 바깥으로 확 흩어집니다.
#   - 얼음 파편: 투명한 얼음 조각이 사방으로 튀며 돌다가 떨어집니다.
#   - 냉기 충격파: 바닥을 따라 푸른 고리가 퍼져 나갑니다.
# 기본 파티클은 소용돌이 궤도를 그리기 어려워, 조각마다 궤도를 직접 계산합니다. 연출이 끝나면 스스로 사라집니다.
# 회오리의 눈송이는 여섯 갈래 눈 결정이고, 저마다 다른 축으로 빙글빙글 돌아 각도에 따라 반짝이듯 보입니다.

const DURATION := 2.4

const FLAKE_COUNT := 650
const FLAKE_COLORS: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.82, 0.93, 1.0), Color(0.62, 0.84, 1.0)]
# 회오리가 감기는 속도(라디안/초)와 솟는 속도, 시작 반지름입니다.
const VORTEX_SPIN := 11.0
const VORTEX_RISE := 75.0
const VORTEX_RADIUS := 80.0
# 눈 결정이 제자리에서 구르는 빠르기(라디안/초)입니다.
const FLAKE_TUMBLE := 8.0
# 이 시점(DURATION 에 대한 비율)부터 회오리가 바깥으로 흩어집니다.
const SCATTER_AT := 0.55

const SHARD_COUNT := 40
const SHARD_COLOR := Color(0.70, 0.88, 1.0, 0.85)
const SHARD_SPEED := 380.0
const SHARD_GRAVITY := 420.0

const RING_COLOR := Color(0.75, 0.90, 1.0)
const RING_MAX_RADIUS := 420.0
const RING_DURATION := 1.4

var _time := 0.0
var _rng := RandomNumberGenerator.new()

var _flakes: MultiMesh
# 눈송이마다 처음 각도, 반지름, 높이, 감기는 빠르기, 솟는 빠르기, 크기입니다.
var _flake_angle := PackedFloat32Array()
var _flake_radius := PackedFloat32Array()
var _flake_height := PackedFloat32Array()
var _flake_spin := PackedFloat32Array()
var _flake_rise := PackedFloat32Array()
var _flake_size := PackedFloat32Array()
var _flake_axis: Array[Vector3] = []
var _flake_tumble := PackedFloat32Array()

var _shards: Array[MeshInstance3D] = []
var _shard_velocity: Array[Vector3] = []
var _shard_spin: Array[Vector3] = []

var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D

func _ready() -> void:
    _rng.randomize()
    _build_flakes()
    _build_shards()
    _build_ring()

func _process(delta: float) -> void:
    _time += delta
    if _time >= DURATION:
        queue_free()
        return
    _update_flakes()
    _update_shards(delta)
    _update_ring()

# 끝날 무렵 조각들이 작아지며 사라지게 하는 비율입니다(1 → 0).
func _fade(start: float) -> float:
    return 1.0 - smoothstep(start, 1.0, _time / DURATION)

func _build_flakes() -> void:
    var flake := Shapes.snowflake_mesh(1.0)
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    flake.surface_set_material(0, material)
    _flakes = MultiMesh.new()
    _flakes.transform_format = MultiMesh.TRANSFORM_3D
    _flakes.use_colors = true
    _flakes.mesh = flake
    _flakes.instance_count = FLAKE_COUNT
    for i in FLAKE_COUNT:
        _flake_angle.append(_rng.randf_range(0, TAU))
        _flake_radius.append(VORTEX_RADIUS * _rng.randf_range(0.3, 1.2))
        _flake_height.append(_rng.randf_range(0, 40))
        _flake_spin.append(VORTEX_SPIN * _rng.randf_range(0.6, 1.3))
        _flake_rise.append(VORTEX_RISE * _rng.randf_range(0.4, 1.4))
        _flake_size.append(_rng.randf_range(3.0, 6.5))
        _flake_axis.append(Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized())
        _flake_tumble.append(FLAKE_TUMBLE * _rng.randf_range(0.5, 1.5))
        _flakes.set_instance_color(i, FLAKE_COLORS[_rng.randi_range(0, FLAKE_COLORS.size() - 1)])
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = _flakes
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(instance)

func _update_flakes() -> void:
    var t := _time
    var progress := _time / DURATION
    # 흩어지는 단계에서는 반지름이 빠르게 커집니다.
    var scatter := maxf(0.0, progress - SCATTER_AT) / (1.0 - SCATTER_AT)
    var fade := _fade(0.75)
    for i in FLAKE_COUNT:
        var angle := _flake_angle[i] + _flake_spin[i] * t * (1.0 - scatter * 0.5)
        var radius := _flake_radius[i] * (0.5 + progress * 1.4) + scatter * scatter * 420.0
        var height := _flake_height[i] + _flake_rise[i] * t
        var at := Vector3(cos(angle) * radius, height, sin(angle) * radius)
        var basis := Basis(_flake_axis[i], _flake_angle[i] + _flake_tumble[i] * t).scaled(Vector3.ONE * _flake_size[i] * fade)
        _flakes.set_instance_transform(i, Transform3D(basis, at))

func _build_shards() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = SHARD_COLOR
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in SHARD_COUNT:
        var mesh := PrismMesh.new()
        mesh.size = Vector3(_rng.randf_range(6, 12), _rng.randf_range(20, 44), _rng.randf_range(6, 12))
        mesh.material = material
        var shard := MeshInstance3D.new()
        shard.mesh = mesh
        shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        shard.position = Vector3(0, 40, 0)
        add_child(shard)
        _shards.append(shard)
        var around := _rng.randf_range(0, TAU)
        var outward := Vector3(cos(around), _rng.randf_range(0.6, 1.6), sin(around)).normalized()
        _shard_velocity.append(outward * SHARD_SPEED * _rng.randf_range(0.5, 1.0))
        _shard_spin.append(Vector3(_rng.randf_range(-8, 8), _rng.randf_range(-8, 8), _rng.randf_range(-8, 8)))

func _update_shards(delta: float) -> void:
    var fade := _fade(0.5)
    for i in _shards.size():
        _shard_velocity[i].y -= SHARD_GRAVITY * delta
        var shard := _shards[i]
        shard.position += _shard_velocity[i] * delta
        shard.rotation += _shard_spin[i] * delta
        shard.scale = Vector3.ONE * fade

func _build_ring() -> void:
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.85
    mesh.outer_radius = 1.0
    mesh.rings = 48
    _ring_material = StandardMaterial3D.new()
    _ring_material.albedo_color = RING_COLOR
    _ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = _ring_material
    _ring = MeshInstance3D.new()
    _ring.mesh = mesh
    _ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _ring.position.y = 1.0
    add_child(_ring)

func _update_ring() -> void:
    var t := clampf(_time / RING_DURATION, 0.0, 1.0)
    var radius := lerpf(10.0, RING_MAX_RADIUS, ease(t, 0.3))
    # 고리 굵기는 그대로 두고 둘레만 넓히도록, 높이(y)는 얇게 눌러 둡니다.
    _ring.scale = Vector3(radius, 3.0, radius)
    _ring_material.albedo_color.a = 0.9 * (1.0 - t * t)
