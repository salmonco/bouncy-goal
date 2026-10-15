extends GdUnitTestSuite

func test_골대는_위치를_가진다() -> void:
    var goal = Goal.new(Vector3(0, 0, -999))
    assert_vector(goal.position).is_equal(Vector3(0, 0, -999))
