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

func test_게임이_시작하면_공_위치와_속도가_초기화된다() -> void:
    var game := Game.new()
    game.ball.position = Vector3.FORWARD
    game.ball.velocity = Vector3.FORWARD
    game.start()
    assert_vector(game.ball.position).is_equal(Vector3.ZERO)
    assert_vector(game.ball.velocity).is_equal(Vector3.ZERO)

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
    game.tick(Game.GOAL_PAUSE)
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
    game.tick(Game.GOAL_PAUSE)
    game.ball.position = back_goal.position
    game.tick(0.1)
    assert_int(back_goal.score).is_equal(2)

func test_골을_넣으면_골_상태가_된다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    assert_str(game.status).is_equal(GameStatus.GOAL)

func test_골_상태에서는_점수가_더_오르지_않는다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    game.tick(0.1)
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)

func test_골_상태에서도_공과_캐릭터는_움직인다() -> void:
    var player := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    var ball_position := game.ball.position
    var player_position := player.position
    game.ball.velocity = Vector3.FORWARD * 100
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_vector(game.ball.position).is_not_equal(ball_position)
    assert_vector(player.position).is_not_equal(player_position)

func test_공은_골망_뒤로_빠져나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(0, 0, -(Game.FIELD_LENGTH / 2 + Goal.DEPTH - Ball.RADIUS - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.position.z).is_greater_equal(-(Game.FIELD_LENGTH / 2 + Goal.DEPTH - Ball.RADIUS))
    assert_float(game.ball.velocity.z).is_greater(0)

func test_공은_골망_옆으로_빠져나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(Goal.WIDTH / 2 - Ball.RADIUS - 1, 0, -(Game.FIELD_LENGTH / 2 + 10))
    game.ball.velocity = Vector3.RIGHT * 100
    game.tick(0.1)
    assert_float(game.ball.position.x).is_less_equal(Goal.WIDTH / 2 - Ball.RADIUS)
    assert_float(game.ball.position.z).is_less(-Game.FIELD_LENGTH / 2)

func test_골_상태가_끝나기_전에는_리셋되지_않는다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE / 2)
    assert_str(game.status).is_equal(GameStatus.GOAL)
    assert_vector(game.ball.position).is_equal(forward_goal.position)

func test_골을_넣으면_잠시_뒤에_공과_캐릭터가_처음_위치로_돌아간다() -> void:
    var player := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    var start_position := player.position
    var start_facing := player.facing
    player.position = Vector3(100, 0, 100)
    player.facing = Vector3.RIGHT
    game.ball.position = game.goals[0].position
    game.ball.velocity = Vector3.FORWARD
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE)
    assert_vector(game.ball.position).is_equal(Ball.POSITION)
    assert_vector(game.ball.velocity).is_equal(Vector3.ZERO)
    assert_vector(player.position).is_equal(start_position)
    assert_vector(player.facing).is_equal(start_facing)

func test_골_상태가_끝나면_다시_플레이_중이_된다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = game.goals[0].position
    game.tick(0.1)
    game.tick(Game.GOAL_PAUSE)
    assert_str(game.status).is_equal(GameStatus.PLAYING)

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
    assert_vector(Vector3(game.ball.velocity.x, 0, game.ball.velocity.z).normalized()).is_equal_approx(player.facing, EPSILON)

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
    game.start()
    var initial_position := player.position
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_vector(player.position).is_equal_approx(initial_position + player.world_move_direction() * Character.SPEED * 0.1, EPSILON)

func test_시간이_흐르면_공이_움직인다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.FORWARD
    game.ball.velocity = Vector3.FORWARD * 10
    var initial_position := game.ball.position
    game.tick(0.1)
    assert_vector(game.ball.position).is_equal_approx(initial_position + game.ball.velocity * 0.1, EPSILON)

func test_공이_옆_벽에_닿으면_x_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - Ball.RADIUS - 1)
    game.ball.velocity = Vector3(100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.x).is_less(0)
    assert_float(game.ball.velocity.z).is_less(0)

func test_공이_반대쪽_옆_벽에_닿아도_x_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.LEFT * (Game.FIELD_WIDTH / 2 - Ball.RADIUS - 1)
    game.ball.velocity = Vector3(-100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.x).is_greater(0)
    assert_float(game.ball.velocity.z).is_less(0)

func test_공은_옆_벽_밖으로_나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - Ball.RADIUS - 1)
    game.ball.velocity = Vector3.RIGHT * 100
    game.tick(0.1)
    assert_float(game.ball.position.x).is_less_equal(Game.FIELD_WIDTH / 2 - Ball.RADIUS)

func test_공이_앞_벽에_닿으면_z_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - Ball.RADIUS - 1))
    game.ball.velocity = Vector3(100, 0, -100)
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_greater(0)
    assert_float(game.ball.velocity.x).is_greater(0)

func test_공이_뒤_벽에_닿아도_z_속도가_반대로_바뀐다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, Game.FIELD_LENGTH / 2 - Ball.RADIUS - 1)
    game.ball.velocity = Vector3(100, 0, 100)
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_less(0)
    assert_float(game.ball.velocity.x).is_greater(0)

func test_공은_앞뒤_벽_밖으로_나가지_않는다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - Ball.RADIUS - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.position.z).is_greater_equal(-(Game.FIELD_LENGTH / 2 - Ball.RADIUS))

func test_공이_골대_입구로_가면_벽에_튕기지_않고_골이_된다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    game.ball.position = Vector3(0, 0, -(Game.FIELD_LENGTH / 2 - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_less(0)
    game.tick(0.1)
    assert_int(forward_goal.score).is_equal(1)

func test_캐릭터는_옆_벽_밖으로_나가지_않는다() -> void:
    var right_player := Character.new()
    var left_player := Character.new()
    var characters: Array[Character] = [right_player, left_player]
    var game := Game.new(characters)
    game.start()
    right_player.place(Vector3.RIGHT * (Game.FIELD_WIDTH / 2 - 1), Vector3.FORWARD)
    left_player.place(Vector3.LEFT * (Game.FIELD_WIDTH / 2 - 1), Vector3.FORWARD)
    right_player.move_input = Vector3.RIGHT
    left_player.move_input = Vector3.LEFT
    game.tick(0.1)
    assert_float(right_player.position.x).is_equal(Game.FIELD_WIDTH / 2)
    assert_float(left_player.position.x).is_equal(-Game.FIELD_WIDTH / 2)

func test_캐릭터는_앞뒤_벽_밖으로_나가지_않는다() -> void:
    var forward_player := Character.new()
    var back_player := Character.new()
    var characters: Array[Character] = [forward_player, back_player]
    var game := Game.new(characters)
    game.start()
    forward_player.place(Vector3(200, 0, -(Game.FIELD_LENGTH / 2 - 1)), Vector3.FORWARD)
    back_player.place(Vector3(200, 0, Game.FIELD_LENGTH / 2 - 1), Vector3.BACK)
    forward_player.move_input = Vector3.FORWARD
    back_player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_float(forward_player.position.z).is_equal(-Game.FIELD_LENGTH / 2)
    assert_float(back_player.position.z).is_equal(Game.FIELD_LENGTH / 2)

func test_게임을_다시_시작하면_점수가_초기화된다() -> void:
    var game := Game.new()
    game.start()
    var forward_goal := game.goals[0]
    var back_goal := game.goals[1]
    forward_goal.score = 1
    back_goal.score = 2
    game.start()
    assert_int(forward_goal.score).is_equal(0)
    assert_int(back_goal.score).is_equal(0)

func test_게임을_다시_시작하면_남은_시간이_초기화된다() -> void:
    var game := Game.new()
    game.start()
    game.tick(Game.DURATION * 2)
    game.start()
    assert_float(game.remaining_time()).is_equal(Game.DURATION)

func test_게임을_다시_시작하면_캐릭터가_처음_위치로_돌아간다() -> void:
    var player := Character.new(Vector3(0, 0, 300), Vector3.FORWARD)
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    var start_position := player.position
    var start_facing := player.facing
    player.position = Vector3(100, 0, 100)
    player.facing = Vector3.RIGHT
    game.start()
    assert_vector(player.position).is_equal(start_position)
    assert_vector(player.facing).is_equal(start_facing)

func test_게임이_시작되면_모든_캐릭터가_팀을_가진다() -> void:
    var game := Game.new(_characters(4))
    game.start()
    for character in game.characters:
        assert_int(character.team).is_not_equal(Character.NO_TEAM)

func test_팀은_인원이_같게_나뉜다() -> void:
    var game := Game.new(_characters(4))
    game.start()
    var team_0 := game.characters.filter(func(c): return c.team == 0)
    var team_1 := game.characters.filter(func(c): return c.team == 1)
    assert_int(team_0.size()).is_equal(2)
    assert_int(team_1.size()).is_equal(2)

func test_같은_시드면_같은_팀이_구성된다() -> void:
    assert_array(_teams_with_seed(7)).is_equal(_teams_with_seed(7))

func test_시드가_다르면_다른_팀이_구성될_수_있다() -> void:
    var first := _teams_with_seed(0)
    var has_different := false
    for _seed in range(1, 20):
        if _teams_with_seed(_seed) != first:
            has_different = true
    assert_bool(has_different).is_true()

func test_골대는_각_팀에_하나씩_할당된다() -> void:
    var game := Game.new()
    assert_int(game.goals[0].team).is_equal(0)
    assert_int(game.goals[1].team).is_equal(1)

func test_캐릭터는_자기_팀_골대_쪽_진영에서_시작한다() -> void:
    var game := Game.new(_characters(4))
    game.start()
    for character in game.characters:
        var own_goal := game.goal_of(character.team)
        assert_float(signf(character.position.z)).is_equal(signf(own_goal.position.z))

func test_캐릭터는_상대_골대를_바라보고_시작한다() -> void:
    var game := Game.new(_characters(4))
    game.start()
    for character in game.characters:
        var to_opponent_goal := game.opponent_goal_of(character.team).position - character.position
        assert_float(character.facing.dot(to_opponent_goal)).is_greater(0)

func test_같은_팀_캐릭터는_서로_다른_위치에서_시작한다() -> void:
    var game := Game.new(_characters(4))
    game.start()
    var positions := game.characters.map(func(c): return c.position)
    for i in positions.size():
        for j in range(i + 1, positions.size()):
            assert_vector(positions[i]).is_not_equal(positions[j])

func test_캐릭터가_공격할_골대는_상대_팀_골대다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    for character in game.characters:
        assert_int(game.opponent_goal_of(character.team).team).is_not_equal(character.team)

func _characters(count: int) -> Array[Character]:
    var characters: Array[Character] = []
    for i in count:
        characters.append(Character.new())
    return characters

func _teams_with_seed(_seed: int) -> Array:
    var game := Game.new(_characters(6))
    game.rng.seed = _seed
    game.start()
    return game.characters.map(func(c): return c.team)

func test_팀_점수는_상대_골대에_넣은_골_수다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    game.goal_of(0).score = 1
    game.goal_of(1).score = 2
    assert_int(game.score_of(0)).is_equal(2)
    assert_int(game.score_of(1)).is_equal(1)

func test_경기가_끝나지_않으면_승자는_없다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    game.goal_of(0).score = 1
    game.goal_of(1).score = 2
    assert_int(game.winner()).is_equal(Character.NO_TEAM)

func test_경기가_끝나면_점수가_높은_팀이_이긴다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    game.goal_of(0).score = 1
    game.goal_of(1).score = 2
    game.tick(Game.DURATION * 2)
    assert_int(game.winner()).is_equal(0)

func test_경기가_끝났을_때_동점이면_무승부다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    game.goal_of(0).score = 1
    game.goal_of(1).score = 1
    game.tick(Game.DURATION * 2)
    assert_int(game.winner()).is_equal(Character.NO_TEAM)

func test_경기_중에는_승자가_없다() -> void:
    var game := Game.new(_characters(2))
    game.start()
    game.goal_of(0).score = 1
    game.goal_of(1).score = 2
    assert_int(game.winner()).is_equal(Character.NO_TEAM)
    game.tick(Game.DURATION / 2)
    assert_int(game.winner()).is_equal(Character.NO_TEAM)

func test_캐릭터는_골대_입구로_골망_안에_들어갈_수_있다() -> void:
    var player := Character.new()
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    player.place(Vector3(0, 0, -(Game.FIELD_LENGTH / 2 - 1)), Vector3.FORWARD)
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_float(player.position.z).is_less(-Game.FIELD_LENGTH / 2)

func test_캐릭터는_골망_뒤로_나가지_않는다() -> void:
    var player := Character.new()
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    player.place(Vector3(0, 0, -(Game.FIELD_LENGTH / 2 + Goal.DEPTH - 1)), Vector3.FORWARD)
    player.move_input = Vector3.FORWARD
    game.tick(0.1)
    assert_float(player.position.z).is_equal(-(Game.FIELD_LENGTH / 2 + Goal.DEPTH))

func test_캐릭터는_골망_옆으로_나가지_않는다() -> void:
    var player := Character.new()
    var characters: Array[Character] = [player]
    var game := Game.new(characters)
    game.start()
    player.place(Vector3(Goal.WIDTH / 2 - 1, 0, -(Game.FIELD_LENGTH / 2 + 10)), Vector3.FORWARD)
    player.move_input = Vector3.RIGHT
    game.tick(0.1)
    assert_float(player.position.x).is_equal(Goal.WIDTH / 2)
    assert_float(player.position.z).is_less(-Game.FIELD_LENGTH / 2)

func test_공이_크로스바_아래라면_떠_있어도_골이다() -> void:
    var game := Game.new()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.UP * (Goal.HEIGHT - Ball.RADIUS * 2)
    assert_bool(game.is_goal()).is_true()

func test_공이_크로스바에_걸치거나_그보다_높으면_골이_아니다() -> void:
    var game := Game.new()
    var forward_goal := game.goals[0]
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.UP * (Goal.HEIGHT - Ball.RADIUS)
    assert_bool(game.is_goal()).is_false()
    game.ball.position = forward_goal.position + Vector3.FORWARD * 10 + Vector3.UP * (Goal.HEIGHT + 10)
    assert_bool(game.is_goal()).is_false()

func test_공이_크로스바_위로_날아오면_골망에_들어가지_않고_앞_벽에_튕긴다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(0, Goal.HEIGHT + 50, -(Game.FIELD_LENGTH / 2 - Ball.RADIUS - 1))
    game.ball.velocity = Vector3.FORWARD * 100
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_greater(0)
    assert_float(game.ball.position.z).is_greater_equal(-(Game.FIELD_LENGTH / 2 - Ball.RADIUS))

func test_공이_크로스바_위로_날아오면_뒤_벽에도_튕긴다() -> void:
    var game := Game.new()
    game.start()
    game.ball.position = Vector3(0, Goal.HEIGHT + 50, Game.FIELD_LENGTH / 2 - Ball.RADIUS - 1)
    game.ball.velocity = Vector3.BACK * 100
    game.tick(0.1)
    assert_float(game.ball.velocity.z).is_less(0)
    assert_float(game.ball.position.z).is_less_equal(Game.FIELD_LENGTH / 2 - Ball.RADIUS)

func test_게임_스냅샷에_모든_캐릭터가_들어간다() -> void:
    var characters: Array[Character] = [Character.new(Vector3.ZERO, Vector3.FORWARD, 5), Character.new(Vector3.ZERO, Vector3.FORWARD, 6)]
    var game := Game.new(characters)
    game.start()
    var peer_ids: Array = game.snapshot(5).characters.map(func(c: Dictionary): return c.peer_id)
    assert_array(peer_ids).contains_exactly([5, 6])
