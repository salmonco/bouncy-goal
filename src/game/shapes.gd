class_name Shapes
extends RefCounted

# 에셋이 생기기 전까지 쓰는 기본 도형 헬퍼입니다.

static func mesh(primitive: PrimitiveMesh, color: Color) -> MeshInstance3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    if color.a < 1.0:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    primitive.material = material
    var instance := MeshInstance3D.new()
    instance.mesh = primitive
    return instance

static func box(size: Vector3, color: Color) -> MeshInstance3D:
    var primitive := BoxMesh.new()
    primitive.size = size
    return mesh(primitive, color)
