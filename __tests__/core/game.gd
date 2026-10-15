extends GdUnitTestSuite

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

func test_게임이_시작하면_공_위치가_초기화된다() -> void:
    var game := Game.new()
    game.ball.position = Vector3.FORWARD
    game.start()
    assert_vector(game.ball.position).is_equal(Vector3.ZERO)

func test_공이_골대_영역에_있으면_골이다() -> void:
    var game := Game.new()
    var target := game.goals[0]
    game.ball.position = target.position
    assert_bool(game.is_goal()).is_true()
    game.ball.position = target.position + Vector3.FORWARD * 10
    assert_bool(game.is_goal()).is_true()
    game.ball.position = target.position + Vector3.FORWARD * 10 + Vector3.LEFT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()
    game.ball.position = target.position + Vector3.FORWARD * 10 + Vector3.RIGHT * Goal.WIDTH / 3
    assert_bool(game.is_goal()).is_true()

func test_공이_골대_영역_밖에_있으면_골이_아니다() -> void:
    var game := Game.new()
    var target := game.goals[0]
    game.ball.position = target.position + Vector3.LEFT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.RIGHT * Goal.WIDTH / 2
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.BACK * 10
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.BACK * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.BACK * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.FORWARD * 10 + Vector3.LEFT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()
    game.ball.position = target.position + Vector3.FORWARD * 10 + Vector3.RIGHT * Goal.WIDTH
    assert_bool(game.is_goal()).is_false()

func test_골대에_공이_들어가면_점수가_오른다() -> void:
    var game := Game.new()
    var target := game.goals[0]
    game.ball.position = target.position
    game.tick(0.1)
    assert_int(target.score).is_equal(1)
    game.tick(0.1)
    assert_int(target.score).is_equal(2)
