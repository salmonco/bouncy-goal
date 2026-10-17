class_name Shapes
extends RefCounted

# 기본 도형 헬퍼입니다. 불투명한 도형은 캐릭터와 같은 툰 셰이딩과 외곽선으로 칠해 화면 전체를 한 그림체로 맞춥니다.
# 반투명한 도형(유리벽, 김, 표시 고리 등)은 외곽선 없이 평범한 반투명 재질로 칠합니다.

const TOON_SHADER := preload("res://assets/materials/toon.gdshader")
const OUTLINE_SHADER := preload("res://assets/materials/outline.gdshader")

# 기본 외곽선 재질은 모두 같으므로 하나를 함께 씁니다.
static var _default_outline: ShaderMaterial

# outline 을 주지 않으면 기본(진한 색, 기본 굵기) 외곽선을 씁니다.
static func toon_material(color: Color, outline: ShaderMaterial = null) -> ShaderMaterial:
    if outline == null:
        if _default_outline == null:
            _default_outline = ShaderMaterial.new()
            _default_outline.shader = OUTLINE_SHADER
        outline = _default_outline
    var material := ShaderMaterial.new()
    material.shader = TOON_SHADER
    material.set_shader_parameter("albedo", color)
    material.next_pass = outline
    return material

# 기본과 다른 색·굵기의 외곽선입니다. 흰 물체처럼 진한 외곽선이 너무 튀는 경우에 씁니다.
static func outline_material(color: Color, width: float) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = OUTLINE_SHADER
    material.set_shader_parameter("color", color)
    material.set_shader_parameter("width", width)
    return material

# outline 은 불투명한 도형에만 쓰이고, 주지 않으면 기본 외곽선입니다.
static func mesh(primitive: Mesh, color: Color, outline: ShaderMaterial = null) -> MeshInstance3D:
    var material: Material
    if color.a < 1.0:
        var transparent := StandardMaterial3D.new()
        transparent.albedo_color = color
        transparent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material = transparent
    else:
        material = toon_material(color, outline)
    var instance := MeshInstance3D.new()
    instance.mesh = primitive
    instance.material_override = material
    return instance

static func box(size: Vector3, color: Color) -> MeshInstance3D:
    var primitive := BoxMesh.new()
    primitive.size = size
    return mesh(primitive, color)
