extends GdUnitTestSuite

func test_공은_처음_위치가_고정되어_있다() -> void:
    var ball := Ball.new()
    assert_vector(ball.position).is_equal(Ball.POSITION)

func test_공은_속도를_가진다() -> void:
    var ball := Ball.new()
    assert_vector(ball.velocity).is_equal(Vector3.ZERO)

func test_공은_시간에_따라_이동한다() -> void:
    var ball := Ball.new()
    ball.position = Vector3.FORWARD
    ball.velocity = Vector3.FORWARD * 10
    var initial_position := ball.position
    ball.move(0.1)
    assert_vector(ball.position).is_equal(initial_position + ball.velocity * 0.1)
