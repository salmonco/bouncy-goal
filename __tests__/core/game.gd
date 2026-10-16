extends GdUnitTestSuite

const EPSILON := Vector3.ONE * 0.0001

func test_게임이_초기화되면_공이_생긴다() -> void:
   var game := Game.new()
   assert_that(game.ball).is_not_null()

func test_게임이_초기화되면_골대_두_개가_생긴다() -> void:
    var game := Game.new()
    assert_int(game.goals.size()).is_equal(2)

func test_게임이_초기화될_때_캐릭터가_들어간다() -> void:
    var characters: Array[Character] = [Character.new(), Character.new()]
    var game := Game.new(characters)
    assert_that(game.characters).is_equal(characters)

func test_게임이_초기화되면_상태가_대기_상태다() -> void:
    var game := Game.new()
    assert_str(game.status).is_equal(GameStatus.WAITING)

func test_게임이_시작하면_공_위치와_속도가_초기화된다() -> void:
    var game := Game.new()
    game.ball.position = Vector3.FORWARD
    game.ball.velocity = Vector3.FORWARD
    game.start()
    assert_vector(game.ball.position).is_equal(Vector3.ZERO)
    assert_vector(game.ball.velocity).is_equal(Vector3.ZERO)

func test_공이_윗_골대_영역에_있으면_골이다() -> void:
    var game := Game.new()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    assert_bool(game.is_goal()).is_true()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10
    assert_bool(game.is_goal()).is_true()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.LEFT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.RIGHT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()

func test_공이_아랫_골대_영역에_있으면_골이다() -> void:
    var game := Game.new()
    var back_goal := game.goals[1]
    game.ball.position = back_goal.position
    assert_bool(game.is_goal()).is_true()
    game.ball.position = back_goal.position + Vector3.BACK * 10
    assert_bool(game.is_goal()).is_true()
    game.ball.position = back_goal.position + Vector3.BACK * 10 + Vector3.LEFT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()
    game.ball.position = back_goal.position + Vector3.BACK * 10 + Vector3.RIGHT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()

func test_공이_윗_골대_영역_밖에_있으면_골이_아니다() -> void:
    var game := Game.new()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position + Vector3.LEFT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.RIGHT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.BACK * 10
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.BACK * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.BACK * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()

func test_공이_아랫_골대_영역_밖에_있으면_골이_아니다() -> void:
    var game := Game.new()
    var back_goal := game.goals[1]
    game.ball.position = back_goal.position + Vector3.LEFT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.RIGHT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.FORWARD * 10
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.FORWARD * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.FORWARD * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.BACK * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = back_goal.position + Vector3.BACK * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()

func test_윗_골대에_공이_들어가면_점수가_오른다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)
    game.tick(Game.GOAL_PAUSE)
    game.ball.position = forward_goal.position
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(2)

func test_아랫_골대에_공이_들어가면_점수가_오른다() -> void:
    var game := Game.new()
    game.start()
    var back_goal := game.goals[1]
    game.ball.position = back_goal.position
    game.tick(0.1)
    assert_int(back_goal.score).is_equal(1)
    game.tick(Game.GOAL_PAUSE)
    game.ball.position = back_goal.position
    game.tick(0.1)
    assert_int(back_goal.score).is_equal(2)

func test_골을_넣으면_골_상태가_된다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    assert_str(game.status).is_equal(GameStatus.GOAL)

func test_골_상태에서는_점수가_더_오르지_않는다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    game.tick(0.1)
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)

func test_골_상태에서도_공과_캐릭터는_움직인다() -> void:
    var player := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    var ball_position := game.ball.position
    var player_position := player.position
    game.ball.velocity = Vector3.FORWARD * 100
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_vector(game.ball.position).is_not_equal(ball_position)
    assert_vector(player.position).is_not_equal(player_position)

func test_공은_골망_뒤로_빠져나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(0, 0, -(Game.FIELD_LENGTH / 2 + Goal.DEPTH - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.position.z).is_greater_equal(-(Game.FIELD_LENGTH / 2 + Goal.DEPTH))
    assert_float(game.ball.velocity.z).is_greater(0)

func test_공은_골망_옆으로_빠져나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(Goal.WIDTH / 2 - 1, 0, -(Game.FIELD_LENGTH / 2 + 10))
    game.ball.velocity = Vector3.RIGHT * 100
    game.tick(0.1)
    assert_float(game.ball.position.x).is_less_equal(Goal.WIDTH / 2)
    assert_float(game.ball.position.z).is_less(-Game.FIELD_LENGTH / 2)

func test_골_상태가_끝나기_전에는_리셋되지_않는다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE / 2)
    assert_str(game.status).is_equal(GameStatus.GOAL)
    assert_vector(game.ball.position).is_equal(forward_goal.position)

func test_골을_넣으면_잠시_뒤에_공과_캐릭터가_처음_위치로_돌아간다() -> void:
    var player := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    player.position = Vector3(100, 0, 100)
    player.facing = Vector3.RIGHT
    game.ball.position = game.goals[0].position
    game.ball.velocity = Vector3.FORWARD
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE)
    assert_vector(game.ball.position).is_equal(Ball.POSITION)
    assert_vector(game.ball.velocity).is_equal(Vector3.ZERO)
    assert_vector(player.position).is_equal(Vector3(0, 0, 300))
    assert_vector(player.facing).is_equal(Vector3.FORWARD)

func test_골_상태가_끝나면_다시_플레이_중이_된다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE)
    assert_str(game.status).is_equal(GameStatus.PLAYING)

func test_게임이_시작되면_상태가_플레이_중으로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    assert_str(game.status).is_equal(GameStatus.PLAYING)

func test_제한_시간이_지나면_게임이_종료된다() -> void:
    var game := Game.new()
    game.start()
    game.tick(0.1)
    assert_str(game.status).is_not_equal(GameStatus.OVER)
    game.tick(0.1)
    assert_str(game.status).is_not_equal(GameStatus.OVER)
    game.tick(Game.DURATION * 2)
    assert_str(game.status).is_equal(GameStatus.OVER)

func test_게임_시작_전이면_시간이_흘러도_게임이_종료되지_않는다() -> void:
    var game := Game.new()
    game.tick(Game.DURATION * 2)
    assert_str(game.status).is_not_equal(GameStatus.OVER)

func test_게임이_종료되면_골을_넣어도_점수가_오르지_않는다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)
    game.tick(Game.DURATION * 2)
    game.ball.position = forward_goal.position
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)

func test_게임을_시작하면_남은_시간이_계산된다() -> void:
    var game := Game.new()
    assert_float(game.remaining_time()).is_equal(Game.DURATION)
    game.start()
    game.tick(0.1)
    assert_float(game.remaining_time()).is_equal(Game.DURATION - 0.1)
    game.tick(0.1)
    assert_float(game.remaining_time()).is_equal(Game.DURATION - 0.1 * 2)

func test_캐릭터가_공을_튀기면_공의_속도가_바뀐다() -> void:
    var characters: Array[Character] = [Character.new(), Character.new()]
    var game := Game.new(characters)
    var player := characters[0]
    player.facing = Vector3.FORWARD
    game.ball.position = Vector3.FORWARD * 10
    player.bounce(game.ball)
    assert_vector(game.ball.velocity).is_equal(player.facing * Character.POWER)

func test_캐릭터가_공을_튀기지_못하면_공의_속도는_그대로다() -> void:
    var characters: Array[Character] = [Character.new(), Character.new()]
    var game := Game.new(characters)
    var player := characters[0]
    player.facing = Vector3.BACK
    game.ball.position = Vector3.FORWARD * 10
    player.bounce(game.ball)
    assert_vector(game.ball.velocity).is_equal(Vector3.ZERO)

func test_시간이_흐르면_캐릭터가_이동_방향으로_움직인다() -> void:
    var characters: Array[Character] = [Character.new(), Character.new()]
    var game := Game.new(characters)
    var player := characters[0]
    var initial_position := player.position
    game.start()
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_vector(player.position).is_equal_approx(initial_position + player.world_move_direction() * Character.SPEED * 0.1, EPSILON)

func test_시간이_흐르면_공이_움직인다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.FORWARD
    game.ball.velocity = Vector3.FORWARD * 10
    var initial_position := game.ball.position
    game.tick(0.1)
    assert_vector(game.ball.position).is_equal_approx(initial_position + game.ball.velocity * 0.1, EPSILON)

func test_공이_옆_벽에_닿으면_x_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - 1)
    game.ball.velocity = Vector3(100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.x).is_less(0)
    assert_float(game.ball.velocity.z).is_less(0)

func test_공이_반대쪽_옆_벽에_닿아도_x_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.LEFT * (Game.FIELD_WIDTH / 2 - 1)
    game.ball.velocity = Vector3(-100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.x).is_greater(0)
    assert_float(game.ball.velocity.z).is_less(0)

func test_공은_옆_벽_밖으로_나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - 1)
    game.ball.velocity = Vector3.RIGHT * 100
    game.tick(0.1)
    assert_float(game.ball.position.x).is_less_equal(Game.FIELD_WIDTH / 2)

func test_공이_앞_벽에_닿으면_z_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - 1))
    game.ball.velocity = Vector3(100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_greater(0)
    assert_float(game.ball.velocity.x).is_greater(0)

func test_공이_뒤_벽에_닿아도_z_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, Game.FIELD_LENGTH / 2 - 1)
    game.ball.velocity = Vector3(100, 0, 100)
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_less(0)
    assert_float(game.ball.velocity.x).is_greater(0)

func test_공은_앞뒤_벽_밖으로_나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.position.z).is_greater_equal(-Game.FIELD_LENGTH / 2)

func test_공이_골대_입구로_가면_벽에_튕기지_않고_골이_된다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = Vector3(0, 0, -(Game.FIELD_LENGTH / 2 - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_less(0)
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)

func test_캐릭터는_옆_벽_밖으로_나가지_않는다() -> void:
    var right_player := Character.new(Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - 1), Vector3.FORWARD)
    var left_player := Character.new(Vector3.LEFT * (Game.FIELD_WIDTH / 2 - 1), Vector3.FORWARD)
    var characters: Array[Character] = [right_player, left_player]
    var game := Game.new(characters)
    game.start()
    right_player.move_input = Vector3.RIGHT
    left_player.move_input = Vector3.LEFT
    game.tick(0.1)
    assert_float(right_player.position.x).is_equal(Game.FIELD_WIDTH / 2)
    assert_float(left_player.position.x).is_equal(-Game.FIELD_WIDTH / 2)

func test_캐릭터는_앞뒤_벽_밖으로_나가지_않는다() -> void:
    var forward_player := Character.new(Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - 1)), Vector3.FORWARD)
    var back_player := Character.new(Vector3(200, 0, Game.FIELD_LENGTH / 2 - 1), Vector3.BACK)
    var characters: Array[Character] = [forward_player, back_player]
    var game := Game.new(characters)
    game.start()
    forward_player.move_input = Vector3.FORWARD
    back_player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_float(forward_player.position.z).is_equal(-Game.FIELD_LENGTH / 2)
    assert_float(back_player.position.z).is_equal(Game.FIELD_LENGTH / 2)
