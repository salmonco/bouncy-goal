extends GdUnitTestSuite

const EPSILON := Vector3(0.0001, 0.0001, 0.0001)

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

func test_캐릭터는_이동_방향을_가진다() -> void:
    var character := Character.new()
    assert_vector(character.move_input).is_equal(Vector3.ZERO)
    character.move_input = Vector3.FORWARD
    assert_vector(character.move_input).is_equal(Vector3.FORWARD)

func test_캐릭터는_얼굴_방향_기준으로_월드에서의_이동_방향이_결정된다() -> void:
    var character := Character.new()
    character.facing = Vector3.FORWARD
    character.move_input = Vector3.FORWARD
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.FORWARD, EPSILON)
    character.move_input = Vector3.BACK
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.BACK, EPSILON)
    character.move_input = Vector3.LEFT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.LEFT, EPSILON)
    character.move_input = Vector3.RIGHT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.RIGHT, EPSILON)
    character.facing = Vector3.BACK
    character.move_input = Vector3.FORWARD
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.BACK, EPSILON)
    character.move_input = Vector3.BACK
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.FORWARD, EPSILON)
    character.move_input = Vector3.LEFT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.RIGHT, EPSILON)
    character.move_input = Vector3.RIGHT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.LEFT, EPSILON)
    character.facing = Vector3.LEFT
    character.move_input = Vector3.FORWARD
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.LEFT, EPSILON)
    character.move_input = Vector3.BACK
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.RIGHT, EPSILON)
    character.move_input = Vector3.LEFT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.BACK, EPSILON)
    character.move_input = Vector3.RIGHT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.FORWARD, EPSILON)
    character.facing = Vector3.RIGHT
    character.move_input = Vector3.FORWARD
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.RIGHT, EPSILON)
    character.move_input = Vector3.BACK
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.LEFT, EPSILON)
    character.move_input = Vector3.LEFT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.FORWARD, EPSILON)
    character.move_input = Vector3.RIGHT
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.BACK, EPSILON)
