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

func test_게임이_시작하면_공_위치가_초기화된다() -> void:
    var game := Game.new()
    game.ball.position = Vector3.FORWARD
    game.start()
    assert_vector(game.ball.position).is_equal(Vector3.ZERO)

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
    game.ball.position = back_goal.position
    game.tick(0.1)
    assert_int(back_goal.score).is_equal(2)

func test_골을_넣으면_공의_위치가_리셋된다() -> void:
    var game := Game.new()
    game.start()
    var target := game.goals[0]
    game.ball.position = target.position
    game.tick(0.1)
    assert_vector(game.ball.position).is_equal(Ball.POSITION)

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
