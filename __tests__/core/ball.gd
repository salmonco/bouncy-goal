extends GdUnitTestSuite

const EPSILON := Vector3.ONE * 0.0001

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

func test_공은_시간이_흐르면_속도가_줄어든다() -> void:
    var ball := Ball.new()
    ball.velocity = Vector3.FORWARD * 10
    ball.move(0.1)
    assert_float(ball.velocity.length()).is_less(10.0)
    assert_vector(ball.velocity.normalized()).is_equal_approx(Vector3.FORWARD, EPSILON)

func test_공은_속도가_줄어들다가_멈춘다() -> void:
    var ball := Ball.new()
    ball.velocity = Vector3.FORWARD * 10
    ball.move(100.0)
    assert_vector(ball.velocity).is_equal(Vector3.ZERO)

func test_공은_반지름을_가진다() -> void:
    assert_float(Ball.RADIUS).is_greater(0)

func test_공은_떠_있으면_중력_때문에_점점_빠르게_떨어진다() -> void:
    var ball := Ball.new()
    ball.position = Vector3.UP * 1000
    ball.velocity = Vector3.DOWN * 100
    ball.move(0.1)
    assert_float(ball.velocity.y).is_less(-100.0)

func test_공은_땅_아래로_떨어지지_않는다() -> void:
    var ball := Ball.new()
    ball.position = Vector3.UP * 10
    ball.velocity = Vector3.DOWN * 100
    ball.move(1.0)
    assert_float(ball.position.y).is_greater_equal(0.0)

func test_공은_떨어지다_땅에_닿으면_위로_튀어오른다() -> void:
    var ball := Ball.new()
    ball.position = Vector3.UP * 1
    ball.velocity = Vector3.DOWN * 100
    ball.move(0.1)
    assert_float(ball.velocity.y).is_greater(0.0)
