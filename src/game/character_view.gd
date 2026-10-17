class_name CharacterView
extends Node3D

# 캐릭터 모델(tools/blender/character.py 로 만든 glb)을 코어(Character)의 위치·방향·고개 각도에 맞춰 그립니다.
# 모델의 재질은 모두 툰 셰이더와 외곽선으로 바꿔 그림 같은 느낌을 냅니다.
# "Team" 재질(목도리)은 팀 색으로 칠하고, "Face" 에는 눈·입을 그리고, "Head" 노드는 고개 각도만큼 끄덕입니다.

const MODEL: PackedScene = preload("res://assets/models/character.glb")
const TOON_SHADER := preload("res://assets/materials/toon.gdshader")
const OUTLINE_SHADER := preload("res://assets/materials/outline.gdshader")
const TEAM_MATERIAL_NAME := "Team"
const HEAD_NODE_NAME := "Head"
const FACE_NODE_NAME := "Face"
# 공을 튀길 수 있는 범위입니다. 코어 판정(facing.dot(to_ball) > 0)대로 앞쪽 반원만 그립니다.
const RANGE_ALPHA := 0.18
const RANGE_SEGMENTS := 32

var character: Character

# 팀은 game.start() 때마다 다시 정해지므로, 바뀌면 다시 칠합니다.
var _painted_team: int = Character.NO_TEAM
var _team_material: ShaderMaterial
var _outline_material: ShaderMaterial
var _range_material: StandardMaterial3D
var _head: Node3D

func _init(_character: Character) -> void:
    character = _character

func _ready() -> void:
    var model: Node3D = MODEL.instantiate()
    add_child(model)
    _head = model.find_child(HEAD_NODE_NAME, true, false)
    _outline_material = ShaderMaterial.new()
    _outline_material.shader = OUTLINE_SHADER
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

func _process(_delta: float) -> void:
    if character.team != _painted_team:
        _paint()
    position = character.position
    if character.facing != Vector3.ZERO:
        basis = Basis.looking_at(character.facing)
    # 모델은 -Z 를 보므로, X 축으로 양수만큼 돌리면 고개를 듭니다.
    if _head:
        _head.rotation.x = character.pitch

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
        var toon := ShaderMaterial.new()
        toon.shader = TOON_SHADER
        toon.set_shader_parameter("albedo", original.albedo_color)
        toon.set_shader_parameter("draw_face", mesh_instance.name == FACE_NODE_NAME)
        toon.next_pass = _outline_material
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
    var color := TeamColors.of(character.team)
    if _team_material:
        _team_material.set_shader_parameter("albedo", color)
    _range_material.albedo_color = Color(color, RANGE_ALPHA)
    _painted_team = character.team
