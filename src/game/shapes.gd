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

# 여섯 갈래로 뻗은 납작한 눈 결정(❄)입니다. XY 평면에 놓이고 앞(-Z)을 봅니다.
# 가운데 육각형에서 가는 마름모 갈래 여섯 개가 뻗고, 갈래마다 바깥쪽으로 비스듬한 곁가지 두 개가 달립니다.
# 앞뒤 어느 쪽에서도 보이도록, 쓰는 쪽 재질에서 뒷면 제거를 꺼야 합니다.
static func snowflake_mesh(radius: float) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_normal(Vector3.BACK)
    for i in 6:
        var corner := _polar(radius * 0.22, TAU * i / 6.0)
        var next := _polar(radius * 0.22, TAU * (i + 1) / 6.0)
        for v in [Vector2.ZERO, corner, next]:
            surface.add_vertex(Vector3(v.x, v.y, 0))
    for i in 6:
        var angle := TAU * i / 6.0 + TAU / 12.0
        _add_diamond(surface, Vector2.ZERO, _polar(radius, angle), radius * 0.09)
        var branch_root := _polar(radius * 0.55, angle)
        for side in [-1, 1]:
            _add_diamond(surface, branch_root, branch_root + _polar(radius * 0.32, angle + side * PI / 4), radius * 0.06)
    return surface.commit()

static func _polar(length: float, angle: float) -> Vector2:
    return Vector2(sin(angle), cos(angle)) * length

# from 에서 to 로 뻗는 가는 마름모입니다. 가장 넓은 곳은 길이의 35% 지점이고, 그 폭의 절반이 half_width 입니다.
static func _add_diamond(surface: SurfaceTool, from: Vector2, to: Vector2, half_width: float) -> void:
    var along := to - from
    var side := Vector2(-along.y, along.x).normalized() * half_width
    var widest := from + along * 0.35
    for v in [from, widest + side, to, from, to, widest - side]:
        surface.add_vertex(Vector3(v.x, v.y, 0))

static func box(size: Vector3, color: Color) -> MeshInstance3D:
    var primitive := BoxMesh.new()
    primitive.size = size
    return mesh(primitive, color)
