extends GdUnitTestSuite

func test_공은_처음_위치가_고정되어_있다() -> void:
    var ball := Ball.new()
    assert_vector(ball.position).is_equal(Ball.POSITION)
