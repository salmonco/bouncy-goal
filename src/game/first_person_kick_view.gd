class_name FirstPersonKickView
extends Node3D

# 1인칭에서 내가 공을 찰 때 화면 아래로 차올라오는 오른발입니다. 카메라의 자식으로 붙입니다.
# 캐릭터 모델에서 오른 다리(LegR)만 떼어 와서, 엉덩이 관절을 카메라 앞 아래쪽에 두고 앞으로 차올립니다.
# 평소에는 다리가 화면 아래로 내려가 있어 보이지 않고, 찰 때만 발끝이 화면 아래쪽으로 올라옵니다.

const MODEL: PackedScene = preload("res://assets/models/character.glb")
# 카메라 기준 엉덩이 관절 위치입니다. 오른쪽(+X), 아래(-Y), 앞(-Z).
const HIP_OFFSET := Vector3(7.0, -10.0, -19.0)
# 카메라 코앞이라 실제 크기면 화면을 너무 많이 가리므로 조금 줄여 그립니다.
const LEG_SCALE := 0.75
const KICK_DURATION := 0.32
# 다리를 뒤로 살짝 당겼다가 이 각도까지 앞으로 차올립니다.
const WINDUP_ANGLE := deg_to_rad(-15)
const STRIKE_ANGLE := deg_to_rad(105)
const STRIKE_AT := 0.35

var _leg: Node3D
# 차기 시작한 뒤 지난 시간입니다. 음수면 차고 있지 않습니다.
var _time := -1.0

func _ready() -> void:
    position = HIP_OFFSET
    scale = Vector3.ONE * LEG_SCALE
    var model: Node3D = MODEL.instantiate()
    _leg = model.find_child("LegR", true, false)
    _leg.get_parent().remove_child(_leg)
    model.free()
    _leg.transform = Transform3D.IDENTITY
    add_child(_leg)
    for mesh_instance in _leg.find_children("*", "MeshInstance3D", true, false):
        mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        for surface in mesh_instance.mesh.get_surface_count():
            var original := mesh_instance.mesh.surface_get_material(surface) as BaseMaterial3D
            if original:
                mesh_instance.set_surface_override_material(surface, Shapes.toon_material(original.albedo_color))
    visible = false

func kick() -> void:
    _time = 0.0
    visible = true

func _process(delta: float) -> void:
    if _time < 0.0:
        return
    _time += delta
    var t := _time / KICK_DURATION
    if t >= 1.0:
        _time = -1.0
        visible = false
        return
    # 빠르게 차올리고(STRIKE_AT 까지) 천천히 내립니다.
    var angle: float
    if t < STRIKE_AT:
        angle = lerpf(WINDUP_ANGLE, STRIKE_ANGLE, ease(t / STRIKE_AT, 0.35))
    else:
        angle = lerpf(STRIKE_ANGLE, WINDUP_ANGLE, ease((t - STRIKE_AT) / (1.0 - STRIKE_AT), 1.8))
    _leg.rotation.x = angle
