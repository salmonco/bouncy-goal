extends GdUnitTestSuite

func test_게임이_초기화되면_공이_생긴다() -> void:
   var game := Game.new()
   assert_that(game.ball).is_not_null()

func test_게임이_시작하면_공_위치가_초기화된다() -> void:
    var game := Game.new()
    game.ball.position = Vector3.FORWARD
    game.start()
    assert_vector(game.ball.position).is_equal(Vector3.ZERO)
