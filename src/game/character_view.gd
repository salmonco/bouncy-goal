class_name CharacterView
extends Node3D

# 캐릭터 모델(tools/blender/character.py 로 만든 glb)을 코어(Character)의 위치·방향·고개 각도에 맞춰 그립니다.
# 모델의 재질은 모두 툰 셰이더와 외곽선으로 바꿔 그림 같은 느낌을 냅니다.
# "Team" 재질(목도리)은 팀 색으로 칠하고, "Face" 에는 눈·입을 그리고, "Head" 노드는 고개 각도만큼 끄덕입니다.
#
# 동작은 모델의 관절 노드(Torso, ArmL/R, LegL/R)를 X 축으로 돌려 코드로 만듭니다. 양수로 돌리면 팔다리는 앞으로,
# 몸통은 뒤로 젖혀집니다. 걷기는 실제로 움직인 거리를 따르므로, 나중에 네트워크로 위치만 받아도 그대로 걷습니다.

const MODEL: PackedScene = preload("res://assets/models/character.glb")
const TEAM_MATERIAL_NAME := "Team"
const HEAD_NODE_NAME := "Head"
const FACE_NODE_NAME := "Face"

# 걷기: 이 거리를 갈 때마다 다리가 한 번 앞뒤로 흔들립니다.
const STRIDE := 34.0
const LEG_SWING := deg_to_rad(32)
const ARM_SWING := deg_to_rad(26)
const WALK_BOB := 1.0
# 멈추거나 걷기 시작할 때 동작이 툭 끊기지 않도록 걷는 정도를 이만큼 빠르게 따라갑니다.
const WALK_BLEND_SPEED := 10.0
# 서 있을 때 숨 쉬듯 몸이 살짝 들썩입니다.
const BREATH_BOB := 0.25
const BREATH_SPEED := 2.2
# 공 차기: 오른발을 뒤로 당겼다(WINDUP) 앞으로 차올리고(STRIKE) 돌아옵니다. 비율은 KICK_DURATION 에 대한 시점입니다.
const KICK_DURATION := 0.42
const KICK_WINDUP_END := 0.25
const KICK_STRIKE_END := 0.5
const KICK_WINDUP_ANGLE := deg_to_rad(-30)
const KICK_STRIKE_ANGLE := deg_to_rad(70)
const KICK_LEAN := 0.25
# 공을 튀길 수 있는 범위입니다. 코어 판정(facing.dot(to_ball) > 0)대로 앞쪽 반원만 그립니다.
const RANGE_ALPHA := 0.18
const RANGE_SEGMENTS := 32

var _snapshot: Dictionary

# 팀은 game.start() 때마다 다시 정해지므로, 바뀌면 다시 칠합니다.
var _painted_team: int = Character.NO_TEAM
var _team_material: ShaderMaterial
var _range_material: StandardMaterial3D
var _head: Node3D
var _torso: Node3D
var _torso_rest: Vector3
var _arms: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _last_position: Vector3
var _walk_amount := 0.0
var _walk_phase := 0.0
var _time := 0.0
# 공 차기 동작이 시작된 뒤 지난 시간입니다. 음수면 차고 있지 않습니다.
var _kick_time := -1.0

func render(snapshot: Dictionary) -> void:
    _snapshot = snapshot

func kick() -> void:
    _kick_time = 0.0

func _ready() -> void:
    var model: Node3D = MODEL.instantiate()
    add_child(model)
    _head = model.find_child(HEAD_NODE_NAME, true, false)
    _torso = model.find_child("Torso", true, false)
    _torso_rest = _torso.position
    for side in ["L", "R"]:
        _arms.append(model.find_child("Arm" + side, true, false))
        _legs.append(model.find_child("Leg" + side, true, false))
    _last_position = _snapshot.position
    for mesh_instance in model.find_children("*", "MeshInstance3D", true, false):
        _apply_toon(mesh_instance)

    var range_marker := MeshInstance3D.new()
    range_marker.mesh = _front_half_disc(Character.BOUNCE_RANGE)
    _range_material = StandardMaterial3D.new()
    _range_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _range_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _range_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    range_marker.material_override = _range_material
    range_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    range_marker.position.y = 0.5
    add_child(range_marker)
    _paint()

func _process(delta: float) -> void:
    if _snapshot.team != _painted_team:
        _paint()
    position = _snapshot.position
    if _snapshot.facing != Vector3.ZERO:
        basis = Basis.looking_at(_snapshot.facing)
    # 모델은 -Z 를 보므로, X 축으로 양수만큼 돌리면 고개를 듭니다.
    _head.rotation.x = _snapshot.pitch
    _animate(delta)

func _animate(delta: float) -> void:
    _time += delta
    var moved := _snapshot.position as Vector3 - _last_position
    moved.y = 0
    _last_position = _snapshot.position
    # 리셋으로 순간 이동한 프레임은 걸음으로 치지 않습니다.
    var distance := moved.length() if moved.length() < Character.SPEED * 0.5 else 0.0
    var speed := distance / delta if delta > 0 else 0.0
    var target := clampf(speed / Character.SPEED, 0.0, 1.0)
    _walk_amount = lerpf(_walk_amount, target, 1.0 - exp(-WALK_BLEND_SPEED * delta))
    _walk_phase = fmod(_walk_phase + distance / STRIDE * TAU, TAU)

    var swing := sin(_walk_phase) * _walk_amount
    _legs[0].rotation.x = swing * LEG_SWING
    _legs[1].rotation.x = -swing * LEG_SWING
    _arms[0].rotation.x = -swing * ARM_SWING
    _arms[1].rotation.x = swing * ARM_SWING
    var bob := absf(sin(_walk_phase)) * WALK_BOB * _walk_amount
    var breath := sin(_time * BREATH_SPEED) * BREATH_BOB * (1.0 - _walk_amount)
    _torso.position = _torso_rest + Vector3.UP * (bob + breath)
    _torso.rotation.x = 0.0

    if _kick_time >= 0.0:
        _kick_time += delta
        var t := _kick_time / KICK_DURATION
        if t >= 1.0:
            _kick_time = -1.0
        else:
            var kick := _kick_angle(t)
            _legs[1].rotation.x = kick
            # 차는 발과 반대로 팔을 흔들고, 차올릴 때 몸을 살짝 뒤로 젖혀 균형을 잡습니다.
            _arms[0].rotation.x = kick * 0.5
            _arms[1].rotation.x = -kick * 0.5
            _torso.rotation.x = maxf(kick, 0.0) * KICK_LEAN

# 공 차기 동작 중 t(0~1) 시점의 오른 다리 각도입니다.
func _kick_angle(t: float) -> float:
    if t < KICK_WINDUP_END:
        return lerpf(0.0, KICK_WINDUP_ANGLE, ease(t / KICK_WINDUP_END, 0.5))
    if t < KICK_STRIKE_END:
        return lerpf(KICK_WINDUP_ANGLE, KICK_STRIKE_ANGLE, ease((t - KICK_WINDUP_END) / (KICK_STRIKE_END - KICK_WINDUP_END), 0.4))
    return lerpf(KICK_STRIKE_ANGLE, 0.0, ease((t - KICK_STRIKE_END) / (1.0 - KICK_STRIKE_END), 2.0))

# 모델의 재질을 같은 색의 툰 재질로 바꿔 끼웁니다. "Team" 재질은 이 캐릭터만의 것을 따로 두어 팀 색으로 칠합니다.
func _apply_toon(mesh_instance: MeshInstance3D) -> void:
    for surface in mesh_instance.mesh.get_surface_count():
        var original := mesh_instance.mesh.surface_get_material(surface) as BaseMaterial3D
        if original == null:
            continue
        var is_team := original.resource_name == TEAM_MATERIAL_NAME
        if is_team and _team_material:
            mesh_instance.set_surface_override_material(surface, _team_material)
            continue
        var toon := Shapes.toon_material(original.albedo_color)
        toon.set_shader_parameter("draw_face", mesh_instance.name == FACE_NODE_NAME)
        mesh_instance.set_surface_override_material(surface, toon)
        if is_team:
            _team_material = toon

# 캐릭터 앞(-Z)쪽 반원을 부채꼴 삼각형으로 만듭니다.
func _front_half_disc(radius: float) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in RANGE_SEGMENTS:
        var from := PI * i / RANGE_SEGMENTS
        var to := PI * (i + 1) / RANGE_SEGMENTS
        surface.add_vertex(Vector3.ZERO)
        surface.add_vertex(Vector3(cos(from), 0, -sin(from)) * radius)
        surface.add_vertex(Vector3(cos(to), 0, -sin(to)) * radius)
    return surface.commit()

func _paint() -> void:
    var color := TeamColors.of(_snapshot.team)
    if _team_material:
        _team_material.set_shader_parameter("albedo", color)
    _range_material.albedo_color = Color(color, RANGE_ALPHA)
    _painted_team = _snapshot.team
