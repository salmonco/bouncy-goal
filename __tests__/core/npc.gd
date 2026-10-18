extends GdUnitTestSuite

const EPSILON := Vector3.ONE * 0.0001

func test_NPC는_캐릭터다() -> void:
    var npc := Npc.new()
    assert_object(npc).is_instanceof(Character)

func test_NPC는_공을_바라본다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * 100)
    npc.think(ball, Goal.new(Vector3.RIGHT * 1000))
    assert_vector(npc.facing).is_equal_approx(Vector3.RIGHT, EPSILON)

func test_NPC는_공_쪽으로_이동한다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3(100, 0, 100))
    npc.think(ball, Goal.new(Vector3(1000, 0, 1000)))
    assert_vector(npc.world_move_direction()).is_equal_approx(Vector3(1, 0, 1).normalized(), EPSILON)

func test_NPC는_공이_가까우면_찬다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * 10)
    npc.think(ball, Goal.new(Vector3.RIGHT * 1000))
    assert_vector(Vector3(ball.velocity.x, 0, ball.velocity.z).normalized()).is_equal_approx(Vector3.RIGHT, EPSILON)

func test_NPC는_공이_떠_있어도_땅에서만_움직인다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3(0, 100, -300))
    npc.think(ball, Goal.new(Vector3.FORWARD * 1000))
    npc.move(0.1)
    assert_float(npc.position.y).is_equal(0.0)

func test_NPC는_공이_멀면_차지_않는다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * 100)
    npc.think(ball, Goal.new(Vector3.RIGHT * 1000))
    assert_vector(ball.velocity).is_equal(Vector3.ZERO)

func test_NPC는_공과_같은_위치에_있어도_바라보는_방향을_잃지_않는다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.ZERO)
    npc.think(ball, Goal.new(Vector3.RIGHT * 1000))
    assert_float(npc.facing.length()).is_equal_approx(1.0, 0.0001)

func test_NPC는_공을_찰_수_있는_거리에_있으면_멈춘다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * Character.BOUNCE_RANGE)
    npc.think(ball, Goal.new(Vector3.RIGHT * 1000))
    assert_vector(npc.move_input).is_equal(Vector3.ZERO)

func test_NPC는_공을_자기_골대_쪽으로_차지_않는다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * 10)
    npc.think(ball, Goal.new(Vector3.LEFT * 1000))
    assert_vector(ball.velocity).is_equal(Vector3.ZERO)

func test_NPC는_공_뒤편으로_돌아_들어간다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    var ball := Ball.new(Vector3.RIGHT * 100)
    npc.think(ball, Goal.new(Vector3(100, 0, -1000)))
    var behind_ball := Vector3(100, 0, Character.BOUNCE_RANGE / 2)
    assert_vector(npc.world_move_direction()).is_equal_approx(behind_ball.normalized(), EPSILON)

func test_NPC는_찬_공보다_느리게_움직인다() -> void:
    var npc := Npc.new(Vector3.ZERO, Vector3.FORWARD)
    npc.move_input = Vector3.FORWARD
    npc.move(1.0)
    assert_float(npc.position.length()).is_less(Character.POWER)

func test_NPC는_구석의_공을_벽이_아닌_상대_골대_쪽으로_찬다() -> void:
    var npc := Npc.new(Vector3(370, 0, -897), Vector3.FORWARD)
    var ball := Ball.new(Vector3(375, 0, -975))
    var goal := Goal.new(Vector3(0, 0, -1000))
    npc.think(ball, goal)
    var to_goal := (goal.position - ball.position).normalized()
    assert_vector(Vector3(ball.velocity.x, 0, ball.velocity.z).normalized()).is_equal_approx(to_goal, EPSILON)
