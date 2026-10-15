extends GdUnitTestSuite

func test_캐릭터는_공을_튀길_수_있다() -> void:
    var character := Character.new()
    assert_bool(character.bounce()).is_true()
