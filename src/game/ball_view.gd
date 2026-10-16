class_name BallView
extends Node3D

var ball: Ball

func _init(_ball: Ball) -> void:
    ball = _ball

func _ready() -> void:
    var sphere := SphereMesh.new()
    sphere.radius = Ball.RADIUS
    sphere.height = Ball.RADIUS * 2
    var body := Shapes.mesh(sphere, Color.WHITE)
    # 코어의 position 은 공의 바닥 기준이라, 땅에 묻히지 않게 반지름만큼 띄웁니다.
    body.position.y = Ball.RADIUS
    add_child(body)

func _process(_delta: float) -> void:
    position = ball.position
