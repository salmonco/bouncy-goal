extends GdUnitTestSuite

const EPSILON := Vector3.ONE * 0.0001

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

func test_캐릭터는_대각선으로_이동할_수_있다() -> void:
    var character := Character.new()
    character.facing = Vector3.FORWARD
    character.move_input = (Vector3.FORWARD + Vector3.LEFT).normalized()
    assert_vector(character.world_move_direction()).is_equal_approx((Vector3.FORWARD + Vector3.LEFT).normalized(), EPSILON)
    character.move_input = (Vector3.BACK + Vector3.RIGHT).normalized()
    assert_vector(character.world_move_direction()).is_equal_approx((Vector3.BACK + Vector3.RIGHT).normalized(), EPSILON)
    character.facing = Vector3.RIGHT
    character.move_input = (Vector3.FORWARD + Vector3.LEFT).normalized()
    assert_vector(character.world_move_direction()).is_equal_approx((Vector3.RIGHT + Vector3.FORWARD).normalized(), EPSILON)
    character.move_input = (Vector3.BACK + Vector3.RIGHT).normalized()
    assert_vector(character.world_move_direction()).is_equal_approx((Vector3.LEFT + Vector3.BACK).normalized(), EPSILON)

func test_캐릭터는_이동_방향이_없으면_월드의_이동_방향_또한_없다() -> void:
    var character := Character.new()
    character.move_input = Vector3.ZERO
    assert_vector(character.world_move_direction()).is_equal_approx(Vector3.ZERO, EPSILON)

func test_캐릭터가_시간에_따라_이동하면_위치가_바뀐다() -> void:
    var character := Character.new()
    var initial_position := character.position
    character.move(0.1)
    assert_vector(character.position).is_equal(initial_position + character.world_move_direction() * Character.SPEED * 0.1)

func test_캐릭터는_회전해서_얼굴_방향을_바꿀_수_있다() -> void:
    var character := Character.new()
    character.facing = Vector3.FORWARD
    character.turn(deg_to_rad(90))
    assert_vector(character.facing).is_equal_approx(Vector3.LEFT, EPSILON)
    character.turn(deg_to_rad(90))
    assert_vector(character.facing).is_equal_approx(Vector3.BACK, EPSILON)
    character.turn(deg_to_rad(90))
    assert_vector(character.facing).is_equal_approx(Vector3.RIGHT, EPSILON)
    character.turn(deg_to_rad(90))
    assert_vector(character.facing).is_equal_approx(Vector3.FORWARD, EPSILON)
    character.turn(deg_to_rad(180))
    assert_vector(character.facing).is_equal_approx(Vector3.BACK, EPSILON)

func test_캐릭터가_공을_튀기면_공의_속도가_바뀐다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.bounce(ball)
    assert_vector(ball.velocity).is_equal(character.facing * Character.POWER)

func test_캐릭터는_리셋하면_처음_위치와_방향으로_돌아간다() -> void:
    var character := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    character.position = Vector3(100, 0, 100)
    character.facing = Vector3.RIGHT
    character.move_input = Vector3.FORWARD
    character.reset()
    assert_vector(character.position).is_equal(Vector3(0, 0, 300))
    assert_vector(character.facing).is_equal(Vector3.FORWARD)
    assert_vector(character.move_input).is_equal(Vector3.ZERO)
