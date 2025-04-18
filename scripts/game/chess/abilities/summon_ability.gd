extends Ability
class_name SummonAbility
## 召唤技能
## 召唤临时棋子协助战斗

# 召唤相关属性
var summon_id: String = ""        # 召唤物ID
var summon_count: int = 1         # 召唤数量
var summon_duration: float = 10.0 # 召唤持续时间
var summon_health_percent: float = 0.5  # 召唤物生命值百分比
var summon_damage_percent: float = 0.5  # 召唤物伤害百分比
var summoned_pieces: Array = []   # 已召唤的棋子

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置召唤属性
	summon_id = ability_data.get("summon_id", "")
	summon_count = ability_data.get("summon_count", 1)
	summon_duration = ability_data.get("summon_duration", 10.0)
	summon_health_percent = ability_data.get("summon_health_percent", 0.5)
	summon_damage_percent = ability_data.get("summon_damage_percent", 0.5)

	# 设置目标类型
	target_type = "self"

	# 连接信号
	owner.died.connect(_on_owner_died)

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 获取棋盘管理器和棋子工厂
	var game_manager = owner.get_node("/root/GameManager")
	var board_manager = game_manager.board_manager
	var chess_factory = game_manager.chess_factory

	if not board_manager or not chess_factory:
		return

	# 清除之前的召唤物
	_clear_summons()

	# 获取可用的空格子
	var empty_cells = _get_empty_cells_around(owner.board_position, board_manager)

	# 如果没有可用格子，返回
	if empty_cells.size() == 0:
		return

	# 召唤棋子
	for i in range(min(summon_count, empty_cells.size())):
		# 创建召唤物
		var summon = chess_factory.create_chess_piece(summon_id)
		if not summon:
			# 如果没有指定ID或创建失败，使用默认召唤物
			summon = _create_default_summon()

		# 设置召唤物属性
		summon.is_player_piece = owner.is_player_piece
		summon.max_health *= summon_health_percent
		summon.current_health = summon.max_health
		summon.attack_damage *= summon_damage_percent

		# 标记为召唤物
		summon.set_meta("is_summon", true)
		summon.set_meta("summoner", owner)

		# 放置到空格子
		var cell = empty_cells[i]
		board_manager.place_piece(summon, cell.grid_position)

		# 添加到召唤物列表
		summoned_pieces.append(summon)

		# 播放召唤特效
		_play_summon_effect(summon)

		# 设置召唤物消失定时器
		if summon_duration > 0:
			var timer = Timer.new()
			timer.wait_time = summon_duration
			timer.one_shot = true
			summon.add_child(timer)
			timer.timeout.connect(func():
				_remove_summon(summon)
				timer.queue_free()
			)
			timer.start()

	# 播放技能特效
	_play_effect(owner)

# 获取周围的空格子
func _get_empty_cells_around(position: Vector2i, board_manager) -> Array:
	var empty_cells = []
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]

	for dir in directions:
		var check_pos = position + dir
		if board_manager.is_valid_cell(check_pos):
			var cell = board_manager.get_cell(check_pos)
			if cell and not cell.current_piece:
				empty_cells.append(cell)

	return empty_cells

# 创建默认召唤物
func _create_default_summon() -> ChessPiece:
	# 创建一个基础棋子作为召唤物
	var summon = ChessPiece.new()

	# 设置基本属性
	summon.id = "summon_" + str(randi())
	summon.display_name = "召唤物"
	summon.description = "由" + owner.display_name + "召唤的临时棋子"
	summon.cost = 1
	summon.star_level = 1

	# 设置战斗属性
	summon.max_health = 200
	summon.current_health = 200
	summon.attack_damage = 30
	summon.attack_speed = 0.8
	summon.attack_range = 1
	summon.armor = 10
	summon.magic_resist = 10
	summon.move_speed = 300

	return summon

# 移除召唤物
func _remove_summon(summon: ChessPiece) -> void:
	if is_instance_valid(summon) and summon.current_state != ChessPiece.ChessState.DEAD:
		# 播放消失特效
		_play_despawn_effect(summon)

		# 移除召唤物
		summoned_pieces.erase(summon)
		summon.die()

# 清除所有召唤物
func _clear_summons() -> void:
	for summon in summoned_pieces:
		if is_instance_valid(summon):
			_remove_summon(summon)

	summoned_pieces.clear()

# 所有者死亡处理
func _on_owner_died() -> void:
	# 清除所有召唤物
	_clear_summons()

# 播放召唤特效
func _play_summon_effect(summon: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = owner.get_node("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建召唤特效
	var params = {
		"summon_type": "summon"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.SUMMON, summon, params)

# 播放消失特效
func _play_despawn_effect(summon: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = owner.get_node("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建消失特效
	var params = {
		"teleport_type": "disappear"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(game_manager.effect_manager.VisualEffectType.TELEPORT_DISAPPEAR, summon, params)

# 播放技能特效
func _play_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = owner.get_node("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建增益特效
	var params = {
		"buff_type": "buff"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_effect(game_manager.effect_manager.EffectType.BUFF, target, params)
