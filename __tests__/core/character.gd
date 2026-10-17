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
    assert_vector(Vector3(ball.velocity.x, 0, ball.velocity.z).normalized()).is_equal_approx(character.facing, EPSILON)

func test_캐릭터는_처음에는_정면을_본다() -> void:
    var character := Character.new()
    assert_float(character.pitch).is_equal(0.0)
    assert_vector(character.aim()).is_equal_approx(character.facing, EPSILON)

func test_캐릭터가_고개를_들면_조준_방향이_위로_기운다() -> void:
    var character := Character.new()
    character.tilt(deg_to_rad(30))
    assert_float(character.aim().y).is_equal_approx(sin(deg_to_rad(30)), 0.0001)
    assert_vector(Vector3(character.aim().x, 0, character.aim().z).normalized()).is_equal_approx(character.facing, EPSILON)

func test_캐릭터가_고개를_숙이면_조준_방향이_아래로_기운다() -> void:
    var character := Character.new()
    character.tilt(deg_to_rad(-20))
    assert_float(character.aim().y).is_less(0.0)

func test_캐릭터는_고개를_한계_이상_젖히거나_숙이지_못한다() -> void:
    var character := Character.new()
    character.tilt(deg_to_rad(180))
    assert_float(character.pitch).is_equal(Character.MAX_PITCH)
    character.tilt(deg_to_rad(-360))
    assert_float(character.pitch).is_equal(Character.MIN_PITCH)

func test_캐릭터가_몸을_돌리면_조준_방향도_같이_돈다() -> void:
    var character := Character.new()
    character.tilt(deg_to_rad(30))
    character.turn(deg_to_rad(90))
    var aim := character.aim()
    assert_vector(Vector3(aim.x, 0, aim.z).normalized()).is_equal_approx(Vector3.LEFT, EPSILON)
    assert_float(aim.y).is_equal_approx(sin(deg_to_rad(30)), 0.0001)

func test_캐릭터는_고개를_들어도_땅_위로만_이동한다() -> void:
    var character := Character.new()
    character.tilt(deg_to_rad(45))
    character.move_input = Vector3.FORWARD
    character.move(0.1)
    assert_float(character.position.y).is_equal(0.0)

func test_캐릭터가_고개를_들고_공을_튀겨도_공은_몸이_향한_쪽으로_나아간다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.tilt(deg_to_rad(30))
    character.bounce(ball)
    assert_vector(Vector3(ball.velocity.x, 0, ball.velocity.z).normalized()).is_equal_approx(character.facing, EPSILON)

func test_캐릭터가_고개를_들고_공을_튀기면_공은_수평보다_세게_위로_튄다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.tilt(deg_to_rad(30))
    character.bounce(ball)
    var aim := character.aim()
    assert_vector(Vector3(ball.velocity.x, 0, ball.velocity.z)).is_equal_approx(Vector3(aim.x, 0, aim.z) * Character.POWER, EPSILON)
    assert_float(ball.velocity.y).is_greater(aim.y * Character.POWER)

func test_캐릭터가_정면을_보고_공을_튀기면_공은_뜨지_않고_굴러간다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.bounce(ball)
    assert_float(ball.velocity.y).is_equal_approx(0.0, 0.0001)

func test_캐릭터가_고개를_살짝만_들고_공을_튀겨도_공은_위로_뜬다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.tilt(deg_to_rad(10))
    character.bounce(ball)
    assert_float(ball.velocity.y).is_greater(0.0)

func test_캐릭터가_고개를_들수록_공은_더_세게_위로_튄다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.bounce(ball)
    var straight_lift := ball.velocity.y
    character.tilt(deg_to_rad(30))
    character.bounce(ball)
    assert_float(ball.velocity.y).is_greater(straight_lift)

func test_캐릭터가_고개를_끝까지_숙이고_공을_튀기면_공은_땅으로_내리꽂힌다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    character.tilt(Character.MIN_PITCH)
    character.bounce(ball)
    assert_float(ball.velocity.y).is_less(0.0)

func test_캐릭터는_리셋하면_처음_위치와_방향으로_돌아간다() -> void:
    var character := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    character.position = Vector3(100, 0, 100)
    character.facing = Vector3.RIGHT
    character.move_input = Vector3.FORWARD
    character.tilt(deg_to_rad(30))
    character.reset()
    assert_vector(character.position).is_equal(Vector3(0, 0, 300))
    assert_vector(character.facing).is_equal(Vector3.FORWARD)
    assert_vector(character.move_input).is_equal(Vector3.ZERO)
    assert_float(character.pitch).is_equal(0.0)

func test_캐릭터는_처음에는_팀이_없다() -> void:
    var character := Character.new()
    assert_int(character.team).is_equal(Character.NO_TEAM)

func test_캐릭터를_배치하면_그_위치가_시작_위치가_된다() -> void:
    var character := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    character.place(Vector3(0, 0, -300), Vector3.BACK)
    assert_vector(character.position).is_equal(Vector3(0, 0, -300))
    assert_vector(character.facing).is_equal(Vector3.BACK)
    character.position = Vector3(100, 0, 100)
    character.reset()
    assert_vector(character.position).is_equal(Vector3(0, 0, -300))
    assert_vector(character.facing).is_equal(Vector3.BACK)

func test_캐릭터가_공을_튀기면_튀겼다는_신호를_보낸다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.FORWARD * 10
    var emitted := [false]
    character.bounced.connect(func(): emitted[0] = true)
    character.bounce(ball)
    assert_bool(emitted[0]).is_true()

func test_캐릭터가_공을_튀기지_못하면_신호를_보내지_않는다() -> void:
    var character := Character.new()
    var ball := Ball.new()
    ball.position = Vector3.BACK * 10
    var emitted := [false]
    character.bounced.connect(func(): emitted[0] = true)
    character.bounce(ball)
    assert_bool(emitted[0]).is_false()
