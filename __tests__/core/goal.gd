extends GdUnitTestSuite

func test_골대는_위치를_가진다() -> void:
    var goal = Goal.new(Vector3(0, 0, -999))
    assert_vector(goal.position).is_equal(Vector3(0, 0, -999))

func test_골대가_리셋되면_점수가_초기화된다() -> void:
    var goal = Goal.new(Vector3(0, 0, -999))
    goal.score = 1
    goal.reset()
    assert_int(goal.score).is_equal(0)

func test_골대는_지키는_팀을_가진다() -> void:
    var goal = Goal.new(Vector3(0, 0, -999), 1)
    assert_int(goal.team).is_equal(1)
