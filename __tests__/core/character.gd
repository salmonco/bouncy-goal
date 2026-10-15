extends GdUnitTestSuite

func test_캐릭터는_자신의_위치를_가진다() -> void:
    var character := Character.new(Vector3(-10, 0, -10))
    assert_vector(character.position).is_equal(Vector3(-10, 0, -10))

func test_캐릭터는_자신의_얼굴_방향을_가진다() -> void:
    var character := Character.new(Vector3(-10, 0, -10), Vector3.FORWARD)
    assert_vector(character.facing).is_equal(Vector3.FORWARD)

func test_캐릭터의_근처에_공이_있어야_공을_튀길_수_있다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3(-999, -999, -999)
    assert_bool(character.bounce(ball)).is_false()

func test_공이_영역_안에_들어와도_캐릭터가_바라보는_방향이랑_같아야_공을_튀길_수_있다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    character.facing = Vector3.FORWARD
    ball.position = Vector3.FORWARD * 10
    assert_bool(character.bounce(ball)).is_true()
    character.facing = Vector3.BACK
    assert_bool(character.bounce(ball)).is_false()
