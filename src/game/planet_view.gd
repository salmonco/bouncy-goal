class_name PlanetView
extends Node3D

# 경기장이 올라앉은 작은 눈 행성과 그 주변 풍경을 그립니다. 게임 규칙과는 상관없는 배경입니다.
# 에버플래닛의 눈과 얼음 행성 '라비네'의 분위기를 따릅니다: 눈 덮인 침엽수, 눈사람, 얼음 결정, 김 나는 온천.
# 행성은 경기장 바로 아래가 꼭대기가 되도록 놓여, 벽 너머로 지평선이 둥글게 말려 내려가 보입니다.

const RADIUS := 1800.0
const COLOR := Color(0.92, 0.95, 1.0)
# 꼭대기에서 이 각도 사이에만 소품을 둡니다. 안쪽은 경기장 받침대가 덮고, 바깥은 지평선 아래라 안 보입니다.
const PROP_MIN_ANGLE := deg_to_rad(42)
const PROP_MAX_ANGLE := deg_to_rad(75)
const TREE_COUNT := 40
const SNOWMAN_COUNT := 6
const CRYSTAL_COUNT := 14
const ROCK_COUNT := 12
const SPRING_COUNT := 2
const CLOUD_COUNT := 7
# 풍경이 실행할 때마다 바뀌지 않도록 고정된 씨앗을 씁니다.
const SEED := 20261017

const SNOW_COLOR := Color(0.97, 0.98, 1.0)
const TRUNK_COLOR := Color(0.50, 0.36, 0.32)
const PINE_COLORS: Array[Color] = [Color(0.24, 0.48, 0.50), Color(0.30, 0.56, 0.55), Color(0.36, 0.50, 0.62)]
const CRYSTAL_COLOR := Color(0.62, 0.86, 1.0, 0.75)
const ROCK_COLOR := Color(0.62, 0.66, 0.78)
const SPRING_COLOR := Color(0.55, 0.90, 0.95)
const STEAM_COLOR := Color(1.0, 1.0, 1.0, 0.45)
const CLOUD_COLOR := Color(1.0, 1.0, 1.0)

# 경기장 위로 내리는 눈송이입니다.
const SNOWFALL_AMOUNT := 900
const SNOWFALL_HEIGHT := 600.0

var _rng := RandomNumberGenerator.new()
var _center := Vector3(0, -RADIUS - 2, 0)

func _ready() -> void:
    _rng.seed = SEED

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2
    sphere.radial_segments = 96
    sphere.rings = 48
    var planet := Shapes.mesh(sphere, COLOR)
    planet.position = _center
    add_child(planet)

    for i in TREE_COUNT:
        _place_on_surface(_pine())
    for i in SNOWMAN_COUNT:
        _place_on_surface(_snowman())
    for i in CRYSTAL_COUNT:
        _place_on_surface(_crystal())
    for i in ROCK_COUNT:
        _place_on_surface(_rock())
    for i in SPRING_COUNT:
        _place_on_surface(_hot_spring())
    for i in CLOUD_COUNT:
        _add_cloud()
    _add_snowfall()

# 꼭대기에서 PROP_MIN_ANGLE ~ PROP_MAX_ANGLE 사이 아무 곳에, 행성 표면에 수직으로 세웁니다.
func _place_on_surface(prop: Node3D) -> void:
    var tilt := _rng.randf_range(PROP_MIN_ANGLE, PROP_MAX_ANGLE)
    var around := _rng.randf_range(0, TAU)
    var up := Vector3.UP.rotated(Vector3.RIGHT, tilt).rotated(Vector3.UP, around)
    prop.position = _center + up * RADIUS
    prop.basis = Basis(Quaternion(Vector3.UP, up)).rotated(up, _rng.randf_range(0, TAU))
    add_child(prop)

func _sphere(radius: float, color: Color, squash: float = 1.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2 * squash
    return Shapes.mesh(mesh, color)

func _cone(radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = radius
    mesh.height = height
    return Shapes.mesh(mesh, color)

# 원뿔 잎을 세 층 쌓고, 층마다 눈을 얹은 침엽수입니다.
func _pine() -> Node3D:
    var tree := Node3D.new()
    var size := _rng.randf_range(0.8, 1.5)
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 7 * size
    trunk_mesh.bottom_radius = 9 * size
    trunk_mesh.height = 30 * size
    var trunk := Shapes.mesh(trunk_mesh, TRUNK_COLOR)
    trunk.position.y = trunk_mesh.height / 2
    tree.add_child(trunk)
    var leaf_color: Color = PINE_COLORS[_rng.randi_range(0, PINE_COLORS.size() - 1)]
    for tier in 3:
        var radius := (48 - tier * 12) * size
        var height := (60 - tier * 10) * size
        var base := (24 + tier * 34) * size
        var leaves := _cone(radius, height, leaf_color)
        leaves.position.y = base + height / 2
        tree.add_child(leaves)
        # 잎 층 윗부분을 하얀 원뿔로 덮어 눈이 쌓인 것처럼 보이게 합니다.
        var snow := _cone(radius * 0.55, height * 0.55, SNOW_COLOR)
        snow.position.y = base + height - height * 0.55 / 2 + 0.5
        tree.add_child(snow)
    return tree

func _snowman() -> Node3D:
    var snowman := Node3D.new()
    var bottom := _sphere(26, SNOW_COLOR)
    bottom.position.y = 22
    snowman.add_child(bottom)
    var head := _sphere(18, SNOW_COLOR)
    head.position.y = 58
    snowman.add_child(head)
    for side in [-1, 1]:
        var eye := _sphere(2.5, Color(0.15, 0.15, 0.2))
        eye.position = Vector3(side * 6, 62, -16)
        snowman.add_child(eye)
    var nose := _cone(3, 14, Color(1.0, 0.55, 0.25))
    nose.rotation.x = -PI / 2
    nose.position = Vector3(0, 57, -22)
    snowman.add_child(nose)
    # 겨울 마을 느낌을 내는 털모자입니다.
    var hat := _cone(16, 22, Color(1.0, 0.55, 0.62))
    hat.position.y = 80
    snowman.add_child(hat)
    var pompom := _sphere(5, SNOW_COLOR)
    pompom.position.y = 92
    snowman.add_child(pompom)
    snowman.scale = Vector3.ONE * _rng.randf_range(0.9, 1.3)
    return snowman

# 땅에서 비스듬히 솟은 얼음 기둥 몇 개를 모읍니다.
func _crystal() -> Node3D:
    var cluster := Node3D.new()
    for i in 3:
        var mesh := PrismMesh.new()
        var height := _rng.randf_range(40, 90)
        mesh.size = Vector3(16, height, 16)
        var shard := Shapes.mesh(mesh, CRYSTAL_COLOR)
        shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        shard.position = Vector3((i - 1) * 14, height / 2 - 6, _rng.randf_range(-6, 6))
        shard.rotation = Vector3(0, _rng.randf_range(0, TAU), (i - 1) * 0.35)
        cluster.add_child(shard)
    return cluster

func _rock() -> Node3D:
    var rock := Node3D.new()
    var radius := _rng.randf_range(18, 34)
    var stone := _sphere(radius, ROCK_COLOR, 0.6)
    stone.scale = Vector3(1.3, 1, 1)
    rock.add_child(stone)
    var snow_cap := _sphere(radius * 0.9, SNOW_COLOR, 0.35)
    snow_cap.scale = Vector3(1.3, 1, 1)
    snow_cap.position.y = radius * 0.3
    rock.add_child(snow_cap)
    return rock

# 김이 피어오르는 작은 온천(라비네의 레벤 온천)입니다.
func _hot_spring() -> Node3D:
    var spring := Node3D.new()
    var pool_mesh := CylinderMesh.new()
    pool_mesh.top_radius = 70
    pool_mesh.bottom_radius = 70
    pool_mesh.height = 4
    spring.add_child(Shapes.mesh(pool_mesh, SPRING_COLOR))
    for i in 10:
        var around := TAU * i / 10
        var stone := _sphere(_rng.randf_range(12, 16), ROCK_COLOR, 0.7)
        stone.position = Vector3(cos(around), 0, sin(around)) * 74
        spring.add_child(stone)
    for i in 4:
        var steam := _sphere(_rng.randf_range(16, 26), STEAM_COLOR)
        steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        steam.position = Vector3(_rng.randf_range(-30, 30), 25 + i * 22, _rng.randf_range(-30, 30))
        spring.add_child(steam)
    return spring

func _add_cloud() -> void:
    var cloud := Node3D.new()
    for i in 4:
        var puff := _sphere(_rng.randf_range(50, 90), CLOUD_COLOR, 0.7)
        puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        puff.position = Vector3((i - 1.5) * 70, _rng.randf_range(-15, 15), _rng.randf_range(-30, 30))
        cloud.add_child(puff)
    var around := _rng.randf_range(0, TAU)
    cloud.position = Vector3(cos(around), 0, sin(around)) * _rng.randf_range(1300, 2200) + Vector3.UP * _rng.randf_range(450, 800)
    cloud.rotation.y = _rng.randf_range(0, TAU)
    add_child(cloud)

# 경기장 위 넓은 상자에서 눈송이가 천천히 흩날리며 내립니다.
func _add_snowfall() -> void:
    # 눈 결정 모양이 잘 보이도록 늘 카메라를 보게 하고, 저마다 다른 각도로 천천히 돌게 합니다.
    var flake := Shapes.snowflake_mesh(3.4)
    var material := StandardMaterial3D.new()
    material.albedo_color = SNOW_COLOR
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    flake.surface_set_material(0, material)
    var snowfall := CPUParticles3D.new()
    snowfall.mesh = flake
    snowfall.angle_min = 0.0
    snowfall.angle_max = 60.0
    snowfall.angular_velocity_min = -45.0
    snowfall.angular_velocity_max = 45.0
    snowfall.amount = SNOWFALL_AMOUNT
    snowfall.lifetime = 12.0
    snowfall.preprocess = 12.0
    snowfall.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    snowfall.emission_box_extents = Vector3(Game.FIELD_WIDTH, 1, Game.FIELD_LENGTH) * 0.6
    snowfall.direction = Vector3.DOWN
    snowfall.spread = 25.0
    snowfall.initial_velocity_min = 30.0
    snowfall.initial_velocity_max = 50.0
    snowfall.gravity = Vector3.ZERO
    snowfall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    snowfall.position.y = SNOWFALL_HEIGHT
    add_child(snowfall)
