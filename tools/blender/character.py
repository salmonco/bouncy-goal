# 캐릭터 모델을 만들어 assets/models/character.glb 로 내보냅니다.
#
#   사용법: blender -b -P tools/blender/character.py -- <출력.glb> [미리보기.png]
#
# 머리가 키의 절반쯤 되는 2.5등신입니다. 노란 머리에 뾰족한 앞머리, 흰 카라 반팔 셔츠, 연보라 청바지,
# 고양이 얼굴 슬리퍼를 신고, 눈 행성(라비네)에 맞춰 목도리를 둘렀습니다.
# 크기는 Godot 단위 그대로입니다. 키 50 (Character 의 눈높이 40 기준).
#
# Godot 에서 쓰는 약속:
#   - 재질 "Team" 은 목도리입니다. CharacterView 가 팀 색으로 바꿔 칠합니다.
#   - 오브젝트 "Head" 는 목을 원점으로 하는 머리입니다. 고개 각도(pitch)만큼 X 축으로 돌립니다.
#   - 얼굴은 Blender 의 +Y 를 봅니다. glTF 로 나가면 Godot 의 앞(-Z)이 됩니다.
#   - 오브젝트 "Face" 는 머리 중심을 원점으로 하는 피부입니다. 눈·입·볼터치는 모델에 없고,
#     툰 셰이더(assets/materials/toon.gdshader)가 이 원점 기준 좌표로 얼굴 위에 그립니다.

import sys
import math
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
output_path = args[0] if args else "character.glb"
preview_paths = args[1:]

bpy.ops.wm.read_factory_settings(use_empty=True)

NECK_HEIGHT = 25.0
HEAD_CENTER = Vector((0, 0, 37.5))
HEAD_RADII = Vector((10.6, 9.8, 11.6))


def material(name, color, roughness=0.8):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


TEAM = material("Team", (0.85, 0.85, 0.9))
SKIN = material("Skin", (1.0, 0.92, 0.84))
HAIR = material("Hair", (1.0, 0.85, 0.45), roughness=0.6)
SHIRT = material("Shirt", (0.98, 0.98, 0.97))
JEANS = material("Jeans", (0.62, 0.65, 0.98))
SLIPPER = material("Slipper", (1.0, 1.0, 1.0))
INK = material("Ink", (0.10, 0.08, 0.10), roughness=0.3)


def finish(obj, mat, parent=None):
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if parent:
        # 방금 바꾼 위치·회전이 matrix_world 에 반영되도록 먼저 갱신합니다.
        bpy.context.view_layer.update()
        world = obj.matrix_world.copy()
        obj.parent = parent
        obj.matrix_world = world
    return obj


def blob(name, location, radii, mat, parent=None, segments=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments // 2, radius=1.0, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = radii
    # 크기만 굳힙니다. 기본값은 위치·회전까지 굳혀서 기준점이 월드 원점으로 가 버립니다.
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, parent)


def rounded_box(name, center, size, bevel, mat, parent=None, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    # 크기만 굳힙니다. 기본값은 위치·회전까지 굳혀서 기준점이 월드 원점으로 가 버립니다.
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Bevel", "BEVEL")
    modifier.width = bevel
    modifier.segments = 5
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.rotation_euler = rotation
    return finish(obj, mat, parent)


def ring(name, location, major, minor, mat, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=40, minor_segments=16, location=location)
    obj = bpy.context.active_object
    obj.name = name
    return finish(obj, mat, parent)


def _aim(obj, start, end):
    direction = Vector(end) - Vector(start)
    obj.location = (Vector(start) + Vector(end)) / 2
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    return direction.length


def capsule(name, start, end, radius, mat, parent=None):
    """start 에서 end 까지 이어지는 둥근 막대입니다."""
    length = (Vector(end) - Vector(start)).length
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (radius, radius, length / 2 + radius)
    # 크기만 굳힙니다. 기본값은 위치·회전까지 굳혀서 기준점이 월드 원점으로 가 버립니다.
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    _aim(obj, start, end)
    return finish(obj, mat, parent)


def spike(name, base, tip, radius, mat, parent=None, flat_normal=None, flatness=0.3, tip_radius=0.0):
    """base 에서 tip 쪽으로 가늘어지는 원뿔입니다.
    flat_normal 을 주면 그 방향으로 납작하게 눌러, 표면을 따라 덮는 머리카락 가닥이 됩니다."""
    length = (Vector(tip) - Vector(base)).length
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=radius, radius2=tip_radius, depth=length)
    obj = bpy.context.active_object
    obj.name = name
    if flat_normal is None:
        _aim(obj, base, tip)
        return finish(obj, mat, parent)
    # 원뿔의 z 는 가닥 방향, x 는 표면 바깥 방향으로 맞춘 뒤 x 로 눌러 납작하게 만듭니다.
    z_axis = (Vector(tip) - Vector(base)).normalized()
    x_axis = (Vector(flat_normal) - z_axis * Vector(flat_normal).dot(z_axis)).normalized()
    y_axis = z_axis.cross(x_axis)
    rotation = Matrix((x_axis, y_axis, z_axis)).transposed()
    obj.data.transform(Matrix.Diagonal((flatness, 1.0, 1.0, 1.0)))
    obj.data.transform(rotation.to_4x4())
    obj.location = (Vector(base) + Vector(tip)) / 2
    return finish(obj, mat, parent)


def on_head(angle_deg, z, outward=0.0):
    """머리 둘레에서 정면(+Y)으로부터 angle 만큼 돈 곳의 표면 위치입니다."""
    a = math.radians(angle_deg)
    dz = (z - HEAD_CENTER.z) / HEAD_RADII.z
    ring_scale = math.sqrt(max(0.0, 1 - dz * dz))
    return Vector((
        math.sin(a) * (HEAD_RADII.x * ring_scale + outward),
        math.cos(a) * (HEAD_RADII.y * ring_scale + outward),
        z,
    ))


# --- 몸 ---------------------------------------------------------------------
shirt = rounded_box("Shirt", (0, 0, 19.5), (13.0, 8.0, 11.0), 2.6, SHIRT)
# 카라: 목 앞에서 양옆으로 접힌 두 장입니다.
for side in (-1, 1):
    rounded_box(f"Collar.{side}", (side * 1.9, 3.9, 23.6), (3.4, 0.9, 2.4), 0.4, SHIRT, shirt,
        rotation=(math.radians(-20), 0, math.radians(side * -25)))
# 팔: 짧은 소매 아래로 가는 맨팔이 곧게 내려옵니다.
for side in (-1, 1):
    capsule(f"Sleeve.{side}", (side * 6.2, 0, 23.0), (side * 7.6, 0, 19.0), 2.4, SHIRT, shirt)
    capsule(f"Arm.{side}", (side * 7.7, 0, 19.0), (side * 8.0, 0.3, 13.6), 1.5, SKIN, shirt)
    blob(f"Hand.{side}", (side * 8.0, 0.3, 12.6), (1.8, 1.8, 1.9), SKIN, shirt, segments=16)

hips = rounded_box("Hips", (0, 0, 13.6), (9.6, 7.0, 3.4), 1.4, JEANS, shirt)
for side in (-1, 1):
    capsule(f"Leg.{side}", (side * 2.4, 0, 13.0), (side * 2.4, 0, 3.8), 2.3, JEANS, shirt)
    # 고양이 얼굴 슬리퍼: 둥근 신발 위에 귀 두 개, 앞에 점 눈 두 개.
    slipper = blob(f"Slipper.{side}", (side * 2.8, 1.0, 1.8), (2.9, 4.2, 1.9), SLIPPER, shirt, segments=24)
    for ear in (-1, 1):
        spike(f"SlipperEar.{side}.{ear}", (side * 2.8 + ear * 1.3, 2.4, 3.0), (side * 2.8 + ear * 1.4, 2.4, 4.9), 0.75, SLIPPER, slipper)
        blob(f"SlipperEye.{side}.{ear}", (side * 2.8 + ear * 1.0, 4.9, 2.4), (0.35, 0.2, 0.35), INK, slipper, segments=10)

# 목도리: 목에 감긴 고리와 앞으로 늘어진 끝자락입니다. 팀 색으로 칠해집니다.
ring("Scarf", (0, 0, NECK_HEIGHT + 0.6), 5.0, 1.9, TEAM, shirt)
capsule("ScarfTail", (2.6, 4.4, 24.6), (3.2, 5.0, 19.6), 1.5, TEAM, shirt)

# --- 머리 (목을 원점으로) -----------------------------------------------------
bpy.ops.object.empty_add(location=(0, 0, NECK_HEIGHT))
head = bpy.context.active_object
head.name = "Head"
head.parent = shirt
bpy.context.view_layer.update()
head.matrix_world.translation = (0, 0, NECK_HEIGHT)

blob("Face", HEAD_CENTER, HEAD_RADII, SKIN, head)

# 머리카락: 머리보다 살짝 큰 구에서 아래쪽을 잘라냅니다. 자르는 높이는 앞(이마)에서 높고 뒤(목덜미)로 갈수록 낮습니다.
FOREHEAD_Z = 39.0
NAPE_Z = 28.0
hair = blob("Hair", HEAD_CENTER + Vector((0, -0.4, 0.5)), HEAD_RADII + Vector((0.9, 0.9, 0.8)), HAIR, head, segments=64)


def hair_cut_z(y):
    # y 가 앞(+)일수록 1, 뒤(-)일수록 0 으로 부드럽게 섞습니다.
    t = max(0.0, min(1.0, (y / HEAD_RADII.y + 0.6) / 1.2))
    t = t * t * (3 - 2 * t)
    return NAPE_Z + (FOREHEAD_Z - NAPE_Z) * t


# 잘릴 부분은 지우지 않고 피부 안쪽으로 밀어 넣습니다. 면을 지우거나 한 번에 밀면 경계가 계단처럼 각지므로,
# 자르는 높이보다 깊을수록 조금씩 더 밀어 넣어 머리카락이 피부 속으로 비스듬히 스며들게 합니다.
bpy.context.view_layer.update()
to_local = hair.matrix_world.inverted()
for vertex in hair.data.vertices:
    world = hair.matrix_world @ vertex.co
    depth = hair_cut_z(world.y) - world.z
    if depth > 0:
        sink = min(1.0, depth / 3.0)
        vertex.co = to_local @ (HEAD_CENTER + (world - HEAD_CENTER) * (1.0 - 0.12 * sink))
# 뾰족한 앞머리: 뿌리는 머리카락 속에 묻고, 끝만 이마로 빠져나와 눈썹 아래까지 내려옵니다.
for i, (angle, tip_z, width) in enumerate([
    (-70, 29.0, 2.6), (-52, 32.4, 2.8), (-34, 34.0, 2.6), (-17, 33.0, 2.8), (0, 34.4, 2.6),
    (17, 32.8, 2.8), (34, 34.2, 2.6), (52, 32.2, 2.8), (70, 29.0, 2.6),
]):
    # 이마가 앞으로 볼록해서 곧은 가닥은 가운데가 파묻히므로, 두 마디로 나눠 곡면을 따라 꺾습니다.
    middle_z = (43.0 + tip_z) / 2
    # 뿌리는 머리카락 속에 묻어, 뿌리의 윗 테두리가 외곽선으로 그려지지 않게 합니다.
    base = on_head(angle, 45.5, outward=0.1)
    middle = on_head(angle, middle_z, outward=0.7)
    tip = on_head(angle, tip_z, outward=0.7)
    normal = (on_head(angle, middle_z, outward=1.0) - on_head(angle, middle_z)).normalized()
    spike(f"Bang.{i}.root", base, middle, width, HAIR, head, flat_normal=normal, tip_radius=width * 0.6)
    spike(f"Bang.{i}", middle, tip, width * 0.6, HAIR, head, flat_normal=normal)

# --- 내보내기 ---------------------------------------------------------------
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=output_path, export_format="GLB", use_selection=False, export_apply=True)

if preview_paths:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_shadows = True
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    # 기본 색 변환(AgX)은 파스텔 색을 회색으로 바래게 하므로, Godot 처럼 표준으로 봅니다.
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("World")
    world.color = (0.85, 0.88, 0.98)
    scene.world = world
    bpy.ops.object.camera_add()
    cam = bpy.context.active_object
    cam.data.lens = 60
    scene.camera = cam
    # 미리보기를 여러 장 주면 정면, 비스듬히, 옆 순서로 찍습니다.
    for path, location in zip(preview_paths, [(0, 120, 27), (60, 95, 34), (120, 0, 27)]):
        cam.location = location
        cam.rotation_mode = "QUATERNION"
        cam.rotation_quaternion = (Vector((0, 0, 26)) - cam.location).to_track_quat("-Z", "Y")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
