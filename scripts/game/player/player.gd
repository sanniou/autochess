extends Node
class_name Player
## 玩家类
## 管理玩家的属性、棋子和装备

# 信号
signal health_changed(old_value, new_value)
signal gold_changed(old_value, new_value)
signal exp_changed(old_value, new_value)
signal level_changed(old_level, new_level)
signal win_streak_changed(old_streak, new_streak)
signal lose_streak_changed(old_streak, new_streak)

# 基本属性
var player_name: String = "玩家"
var max_health: int = 100
var current_health: int = 100
var gold: int = 0
var level: int = 1
var exp: int = 0
var win_streak: int = 0
var lose_streak: int = 0
var total_wins: int = 0
var total_losses: int = 0

# 棋子和装备
var chess_pieces: Array = []
var bench_pieces: Array = []
var equipments: Array = []
var relics: Array = []

# 等级经验需求表
const LEVEL_EXP_REQUIRED = {
	1: 0,
	2: 2,
	3: 6,
	4: 10,
	5: 20,
	6: 36,
	7: 56,
	8: 80,
	9: 100
}

# 人口上限表
const LEVEL_POPULATION_LIMIT = {
	1: 1,
	2: 2,
	3: 3,
	4: 4,
	5: 5,
	6: 6,
	7: 7,
	8: 8,
	9: 9
}

# 初始化
func _init(p_name: String = "玩家"):
	player_name = p_name
	reset()

# 重置玩家状态
func reset() -> void:
	current_health = max_health
	gold = 10  # 初始金币
	level = 1
	exp = 0
	win_streak = 0
	lose_streak = 0
	total_wins = 0
	total_losses = 0

	# 清空棋子和装备
	chess_pieces.clear()
	bench_pieces.clear()
	equipments.clear()
	relics.clear()

# 受到伤害
func take_damage(amount: int) -> void:
	var old_health = current_health
	current_health = max(0, current_health - amount)

	# 发送生命值变化信号
	health_changed.emit(old_health, current_health)
	EventBus.game.emit_event("player_health_changed", [old_health, current_health])

	# 检查是否死亡
	if current_health <= 0:
		EventBus.game.emit_event("player_died", [])

# 恢复生命值
func heal(amount: int) -> void:
	var old_health = current_health
	current_health = min(max_health, current_health + amount)

	# 发送生命值变化信号
	health_changed.emit(old_health, current_health)
	EventBus.game.emit_event("player_health_changed", [old_health, current_health])

# 增加金币
func add_gold(amount: int) -> void:
	var old_gold = gold
	gold = max(0, gold + amount)

	# 发送金币变化信号
	gold_changed.emit(old_gold, gold)
	EventBus.economy.emit_event("gold_changed", [old_gold, gold])

# 扣除金币
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false

	var old_gold = gold
	gold -= amount

	# 发送金币变化信号
	gold_changed.emit(old_gold, gold)
	EventBus.economy.emit_event("gold_changed", [old_gold, gold])

	return true

# 增加经验
func add_exp(amount: int) -> void:
	var old_exp = exp
	var old_level = level

	exp += amount

	# 检查是否升级
	while level < 9 and exp >= get_exp_required_for_next_level():
		level += 1
		# 升级时重置经验
		exp -= get_exp_required_for_next_level()

		# 升级时增加最大生命值
		max_health += 10
		current_health += 10

		# 发送生命值变化信号
		health_changed.emit(current_health - 10, current_health)
		EventBus.game.emit_event("player_health_changed", [current_health - 10, current_health])

	# 发送经验变化信号
	exp_changed.emit(old_exp, exp)
	EventBus.game.emit_event("player_exp_changed", [old_exp, exp])

	# 如果等级变化，发送等级变化信号
	if level != old_level:
		level_changed.emit(old_level, level)
		EventBus.game.emit_event("player_level_changed", [old_level, level])

# 购买经验
func buy_exp(amount: int = 4, cost: int = 4) -> bool:
	if gold < cost:
		return false

	# 扣除金币
	if spend_gold(cost):
		# 增加经验
		add_exp(amount)
		return true

	return false

# 获取下一级所需经验
func get_exp_required_for_next_level() -> int:
	if level >= 9:
		return 999  # 最高等级

	# 如果是当前等级到下一级的经验需求
	if level + 1 in LEVEL_EXP_REQUIRED:
		return LEVEL_EXP_REQUIRED[level + 1] - LEVEL_EXP_REQUIRED[level]

	return 999  # 默认返回大值

# 获取当前人口上限
func get_population_limit() -> int:
	return LEVEL_POPULATION_LIMIT[level]

# 获取当前人口数量
func get_current_population() -> int:
	return chess_pieces.size()

# 战斗胜利处理
func on_battle_win() -> void:
	# 增加连胜计数
	var old_streak = win_streak
	win_streak += 1
	lose_streak = 0
	total_wins += 1

	# 发送连胜信号
	win_streak_changed.emit(old_streak, win_streak)

	# 计算连胜奖励
	var streak_bonus = 0
	if win_streak >= 5:
		streak_bonus = 3
	elif win_streak >= 3:
		streak_bonus = 2
	elif win_streak >= 2:
		streak_bonus = 1

	# 添加基础金币和连胜奖励
	add_gold(5 + streak_bonus)

# 战斗失败处理
func on_battle_loss(damage: int) -> void:
	# 增加连败计数
	var old_streak = lose_streak
	lose_streak += 1
	win_streak = 0
	total_losses += 1

	# 发送连败信号
	lose_streak_changed.emit(old_streak, lose_streak)

	# 计算连败奖励
	var streak_bonus = 0
	if lose_streak >= 5:
		streak_bonus = 3
	elif lose_streak >= 3:
		streak_bonus = 2
	elif lose_streak >= 2:
		streak_bonus = 1

	# 添加基础金币和连败奖励
	add_gold(2 + streak_bonus)

	# 受到伤害
	take_damage(damage)

	# 破产保护
	if current_health < 20 and gold == 0:
		add_gold(5)  # 破产补助

# 添加棋子
func add_chess_piece(piece: ChessPiece) -> bool:
	# 检查是否已达到人口上限
	if get_current_population() >= get_population_limit() and bench_pieces.size() >= 9:
		return false

	# 优先添加到场上，如果满了则添加到备战区
	if get_current_population() < get_population_limit():
		chess_pieces.append(piece)
	else:
		bench_pieces.append(piece)

	return true

# 移除棋子
func remove_chess_piece(piece: ChessPiece) -> bool:
	if chess_pieces.has(piece):
		chess_pieces.erase(piece)
		return true

	if bench_pieces.has(piece):
		bench_pieces.erase(piece)
		return true

	return false

# 出售棋子
func sell_chess_piece(piece: ChessPiece) -> bool:
	if remove_chess_piece(piece):
		# 返还金币
		add_gold(piece.cost * piece.star_level)

		# 发送棋子出售信号
		EventBus.chess.emit_event("chess_piece_sold", [piece])

		return true

	return false

# 添加装备
func add_equipment(equipment: Equipment) -> bool:
	equipments.append(equipment)

	# 发送装备获取信号
	EventBus.equipment.emit_event("equipment_created", [equipment])

	return true

# 移除装备
func remove_equipment(equipment: Equipment) -> bool:
	if equipments.has(equipment):
		equipments.erase(equipment)
		return true

	return false

# 添加遗物
func add_relic(relic) -> bool:
	relics.append(relic)

	# 发送遗物获取信号
	EventBus.relic.emit_event("relic_acquired", [relic])

	return true

# 移除遗物
func remove_relic(relic) -> bool:
	if relics.has(relic):
		relics.erase(relic)
		return true

	return false

# 回合开始处理
func on_round_start() -> void:
	# 添加基础收入
	add_gold(5)

	# 添加利息收入 (每10金币1金币，最多5金币)
	var interest = min(5, gold / 10)
	if interest > 0:
		add_gold(interest)

	# 添加自动经验
	add_exp(2)

# 获取玩家数据（用于存档）
func get_save_data() -> Dictionary:
	var data = {
		"name": player_name,
		"health": current_health,
		"max_health": max_health,
		"gold": gold,
		"level": level,
		"exp": exp,
		"win_streak": win_streak,
		"lose_streak": lose_streak,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"chess_pieces": [],
		"bench_pieces": [],
		"equipments": [],
		"relics": []
	}

	# 保存棋子数据
	for piece in chess_pieces:
		data.chess_pieces.append({
			"id": piece.id,
			"star_level": piece.star_level,
			"position": {"x": piece.board_position.x, "y": piece.board_position.y},
			"equipments": []
		})

	# 保存备战区棋子数据
	for piece in bench_pieces:
		data.bench_pieces.append({
			"id": piece.id,
			"star_level": piece.star_level,
			"equipments": []
		})

	# 保存装备数据
	for equipment in equipments:
		data.equipments.append({
			"id": equipment.id
		})

	# 保存遗物数据
	for relic in relics:
		data.relics.append({
			"id": relic.id
		})

	return data

# 从存档数据加载
func load_from_save_data(data: Dictionary) -> void:
	player_name = data.name
	current_health = data.health
	max_health = data.max_health
	gold = data.gold
	level = data.level
	exp = data.exp
	win_streak = data.win_streak
	lose_streak = data.lose_streak
	total_wins = data.total_wins
	total_losses = data.total_losses

	# 清空现有数据
	chess_pieces.clear()
	bench_pieces.clear()
	equipments.clear()
	relics.clear()

	# 获取必要的管理器
	var chess_factory = get_node("/root/GameManager/ChessFactory")
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")
	var relic_manager = get_node("/root/GameManager/RelicManager")
	var board_manager = get_node("/root/GameManager/BoardManager")

	# 加载棋子数据
	if data.has("chess_pieces") and chess_factory:
		for piece_data in data.chess_pieces:
			# 创建棋子
			var piece = chess_factory.create_chess_piece(piece_data.id)
			if piece:
				# 设置星级
				piece.star_level = piece_data.star_level

				# 设置位置
				if piece_data.has("position") and board_manager:
					var pos = Vector2i(piece_data.position.x, piece_data.position.y)
					board_manager.place_piece(piece, pos)

				# 添加到棋子列表
				chess_pieces.append(piece)

	# 加载备战区棋子数据
	if data.has("bench_pieces") and chess_factory:
		for piece_data in data.bench_pieces:
			# 创建棋子
			var piece = chess_factory.create_chess_piece(piece_data.id)
			if piece:
				# 设置星级
				piece.star_level = piece_data.star_level

				# 添加到备战区棋子列表
				bench_pieces.append(piece)

	# 加载装备数据
	if data.has("equipments") and equipment_manager:
		for equip_data in data.equipments:
			# 获取装备
			var equipment = equipment_manager.get_equipment(equip_data.id)
			if equipment:
				# 添加到装备列表
				equipments.append(equipment)

				# 如果装备已经装备到棋子上
				if equip_data.has("equipped_to"):
					# 查找棋子
					var piece = _find_chess_piece_by_id(equip_data.equipped_to)
					if piece:
						# 装备到棋子上
						piece.equip_item(equipment)

	# 加载遗物数据
	if data.has("relics") and relic_manager:
		for relic_data in data.relics:
			# 获取遗物
			var relic = relic_manager.acquire_relic(relic_data.id, self)
			if relic:
				# 添加到遗物列表
				relics.append(relic)

# 根据ID查找棋子
func _find_chess_piece_by_id(piece_id: String) -> ChessPiece:
	# 在场上棋子中查找
	for piece in chess_pieces:
		if piece.id == piece_id:
			return piece

	# 在备战区棋子中查找
	for piece in bench_pieces:
		if piece.id == piece_id:
			return piece

	return null
