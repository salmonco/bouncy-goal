class_name CharacterView
extends Node3D

const RADIUS := 12.0
const HEIGHT := 50.0

var character: Character

# 팀은 game.start() 때마다 다시 정해지므로, 바뀌면 다시 칠합니다.
var _painted_team: int = Character.NO_TEAM
var _body_material: StandardMaterial3D
var _range_material: StandardMaterial3D

func _init(_character: Character) -> void:
    character = _character

func _ready() -> void:
    var capsule := CapsuleMesh.new()
    capsule.radius = RADIUS
    capsule.height = HEIGHT
    var body := Shapes.mesh(capsule, TeamColors.NO_TEAM_COLOR)
    _body_material = capsule.material
    body.position.y = HEIGHT / 2
    add_child(body)

    # 바라보는 방향(-Z)을 알 수 있게 코를 붙입니다.
    var nose := Shapes.box(Vector3(6, 6, 14), Color.BLACK)
    nose.position = Vector3(0, HEIGHT * 0.7, -RADIUS)
    add_child(nose)

    # 공을 튀길 수 있는 범위(BOUNCE_RANGE)를 바닥에 표시합니다.
    var disc := CylinderMesh.new()
    disc.top_radius = Character.BOUNCE_RANGE
    disc.bottom_radius = Character.BOUNCE_RANGE
    disc.height = 0.5
    var range_marker := Shapes.mesh(disc, Color(TeamColors.NO_TEAM_COLOR, 0.3))
    _range_material = disc.material
    range_marker.position.y = 0.5
    add_child(range_marker)
    _paint()

func _process(_delta: float) -> void:
    if character.team != _painted_team:
        _paint()
    position = character.position
    if character.facing != Vector3.ZERO:
        basis = Basis.looking_at(character.facing)

func _paint() -> void:
    var color := TeamColors.of(character.team)
    _body_material.albedo_color = color
    _range_material.albedo_color = Color(color, 0.3)
    _painted_team = character.team
