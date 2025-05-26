extends "res://scripts/managers/core/base_manager.gd"
class_name StatsManager
## 统计管理器
## 负责记录和管理游戏统计数据

# 信号
signal stat_updated(stat_name: String, value)
signal stats_reset()

# 统计数据
var stats: Dictionary = {}

# 会话统计（不保存）
var session_stats: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "StatsManager"

	# 添加依赖
	add_dependency("StateManager")

	# 初始化统计数据
	_initialize_stats()

	# 连接事件
	_connect_events()

	_log_info("统计管理器初始化完成")

# 初始化统计数据
func _initialize_stats() -> void:
	# 从 GameState 获取默认统计结构
	var game_state_class = load("res://scripts/state/game_state.gd")
	stats = game_state_class.create_default_stats()

	# 初始化会话统计
	session_stats = game_state_class.create_default_stats()

# 连接事件
func _connect_events() -> void:
	# 游戏事件
	GlobalEventBus.game.add_listener("game_started", _on_game_started)
	GlobalEventBus.game.add_listener("game_ended", _on_game_ended)

	# 战斗事件
	GlobalEventBus.battle.add_listener("battle_ended", _on_battle_ended)
	GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)
	GlobalEventBus.battle.add_listener("healing_done", _on_healing_done)

	# 经济事件
	GlobalEventBus.economy.add_class_listener(EconomyEvents.PlayerGoldChangedEvent, _on_player_gold_changed) # Updated listener
	GlobalEventBus.economy.add_class_listener(EconomyEvents.ItemPurchasedEvent, _on_item_purchased)
	GlobalEventBus.economy.add_class_listener(EconomyEvents.ItemSoldEvent, _on_item_sold)
	GlobalEventBus.economy.add_class_listener(EconomyEvents.ShopRefreshedEvent, _on_stats_shop_refreshed)

	# 棋子事件
	GlobalEventBus.chess.add_listener("chess_piece_bought", _on_chess_piece_bought)
	GlobalEventBus.chess.add_listener("chess_piece_upgraded", _on_chess_piece_upgraded)

	# 羁绊事件
	GlobalEventBus.chess.add_listener("synergy_activated", _on_synergy_activated)

# 获取统计数据
func get_stats() -> Dictionary:
	return stats.duplicate(true)

# 获取特定统计数据
func get_stat(stat_name: String, default_value = 0):
	return _get_nested_stat(stats, stat_name, default_value)

# 获取会话统计数据
func get_session_stats() -> Dictionary:
	return session_stats.duplicate(true)

# 增加统计数值
func increment_stat(stat_name: String, amount: int = 1) -> void:
	var current_value = get_stat(stat_name, 0)
	set_stat(stat_name, current_value + amount)

	# 同时更新会话统计
	var session_value = _get_nested_stat(session_stats, stat_name, 0)
	_set_nested_stat(session_stats, stat_name, session_value + amount)

# 设置统计数值
func set_stat(stat_name: String, value) -> void:
	_set_nested_stat(stats, stat_name, value)

	# 发送统计更新信号
	stat_updated.emit(stat_name, value)

	# 检查成就
	_check_achievements(stat_name, value)

# 重置统计数据
func reset_stats() -> void:
	# 从 GameState 获取默认统计结构
	var game_state_class = load("res://scripts/state/game_state.gd")
	stats = game_state_class.create_default_stats()

	# 发送统计重置信号
	stats_reset.emit()

	_log_info("统计数据已重置")

# 重置会话统计
func reset_session_stats() -> void:
	# 从 GameState 获取默认统计结构
	var game_state_class = load("res://scripts/state/game_state.gd")
	session_stats = game_state_class.create_default_stats()

	_log_info("会话统计已重置")

# 保存统计数据
func save_stats() -> Dictionary:
	return stats.duplicate(true)

# 加载统计数据
func load_stats(saved_stats: Dictionary) -> void:
	if saved_stats.is_empty():
		return

	# 合并保存的统计数据
	_merge_stats(stats, saved_stats)

	_log_info("统计数据已加载")

# 合并统计数据
func _merge_stats(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key):
			if source[key] is Dictionary and target[key] is Dictionary:
				_merge_stats(target[key], source[key])
			else:
				target[key] = source[key]
		else:
			target[key] = source[key]

# 获取嵌套统计数据
func _get_nested_stat(data: Dictionary, path: String, default_value = 0):
	var parts = path.split(".")
	var current = data

	for i in range(parts.size() - 1):
		var part = parts[i]
		if not current.has(part) or not current[part] is Dictionary:
			return default_value
		current = current[part]

	var last_part = parts[parts.size() - 1]
	if not current.has(last_part):
		return default_value

	return current[last_part]

# 设置嵌套统计数据
func _set_nested_stat(data: Dictionary, path: String, value) -> void:
	var parts = path.split(".")
	var current = data

	for i in range(parts.size() - 1):
		var part = parts[i]
		if not current.has(part) or not current[part] is Dictionary:
			current[part] = {}
		current = current[part]

	var last_part = parts[parts.size() - 1]
	current[last_part] = value

# 检查成就
func _check_achievements(stat_name: String, value) -> void:
	var achievement_manager = GameManager.achievement_manager
	if achievement_manager:
		achievement_manager.check_stat_achievement(stat_name, value)

# 游戏开始事件处理
func _on_game_started() -> void:
	# 重置会话统计
	reset_session_stats()

	# 记录游戏开始时间
	session_stats.start_time = Time.get_unix_time_from_system()

	_log_info("游戏开始，会话统计已重置")

# 游戏结束事件处理
func _on_game_ended(win: bool) -> void:
	# 记录游戏结果
	increment_stat("games_played")
	if win:
		increment_stat("games_won")
	else:
		increment_stat("games_lost")

	# 计算胜率
	var games_played = get_stat("games_played")
	var games_won = get_stat("games_won")
	if games_played > 0:
		set_stat("win_rate", float(games_won) / games_played)

	# 记录游戏时长
	var end_time = Time.get_unix_time_from_system()
	var start_time = session_stats.start_time
	var play_time = end_time - start_time
	increment_stat("total_play_time", int(play_time))

	_log_info("游戏结束，统计数据已更新")

# 战斗结束事件处理
func _on_battle_ended(result) -> void:
	# 更新战斗统计
	increment_stat("battles_played")
	if result.is_victory:
		increment_stat("battles_won")
	else:
		increment_stat("battles_lost")

	# 更新伤害统计
	if result.has("player_damage_dealt"):
		increment_stat("total_damage_dealt", result.player_damage_dealt)

	# 更新治疗统计
	if result.has("player_healing"):
		increment_stat("total_healing", result.player_healing)

# 伤害事件处理
func _on_damage_dealt(source, target, amount: float) -> void:
	if source and source.is_player_piece:
		increment_stat("total_damage_dealt", int(amount))
	elif target and target.is_player_piece:
		increment_stat("total_damage_taken", int(amount))

# 治疗事件处理
func _on_healing_done(target, amount: float) -> void:
	if target and target.is_player_piece:
		increment_stat("total_healing", int(amount))

# 金币变化事件处理 (Now PlayerGoldChangedEvent)
func _on_player_gold_changed(event: EconomyEvents.PlayerGoldChangedEvent) -> void:
	if event.amount_changed > 0: # Gold was granted
		increment_stat("total_gold_earned", event.amount_changed)
	# If spending needs to be tracked as a stat (e.g., "total_gold_spent"), it could be done here:
	# elif event.amount_changed < 0:
	#	increment_stat("total_gold_spent", -event.amount_changed)

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	increment_stat("items_purchased")

	# 根据物品类型记录不同的统计
	if item_data.has("type"):
		match item_data.type:
			"chess_piece":
				increment_stat("chess_pieces_purchased")
			"equipment":
				increment_stat("equipments_purchased")
			"exp":
				increment_stat("exp_purchased")

# 物品出售事件处理
func _on_item_sold(item_data: Dictionary) -> void:
	increment_stat("items_sold")

	# 根据物品类型记录不同的统计
	if item_data.has("type"):
		match item_data.type:
			"chess_piece":
				increment_stat("chess_pieces_sold")
			"equipment":
				increment_stat("equipments_sold")

# 棋子购买事件处理
func _on_chess_piece_bought(piece_data: Dictionary) -> void:
	var piece_id = piece_data.id

	# 更新棋子购买统计
	if not stats.chess_pieces_bought.has(piece_id):
		stats.chess_pieces_bought[piece_id] = 0
	stats.chess_pieces_bought[piece_id] += 1

	# 发送统计更新信号
	stat_updated.emit("chess_pieces_bought." + piece_id, stats.chess_pieces_bought[piece_id])

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece) -> void:
	if piece.star_level == 3:
		var piece_id = piece.id

		# 更新3星棋子统计
		if not stats.chess_pieces_3star.has(piece_id):
			stats.chess_pieces_3star[piece_id] = 0
		stats.chess_pieces_3star[piece_id] += 1

		# 发送统计更新信号
		stat_updated.emit("chess_pieces_3star." + piece_id, stats.chess_pieces_3star[piece_id])

# 羁绊激活事件处理
func _on_synergy_activated(synergy_id: String, level: int) -> void:
	# 更新羁绊激活统计
	if not stats.synergies_activated.has(synergy_id):
		stats.synergies_activated[synergy_id] = 0
	stats.synergies_activated[synergy_id] += 1

	# 发送统计更新信号
	stat_updated.emit("synergies_activated." + synergy_id, stats.synergies_activated[synergy_id])

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	# 断开游戏事件
	GlobalEventBus.game.remove_listener("game_started", _on_game_started)
	GlobalEventBus.game.remove_listener("game_ended", _on_game_ended)

	# 断开战斗事件
	GlobalEventBus.battle.remove_listener("battle_ended", _on_battle_ended)
	GlobalEventBus.battle.remove_listener("damage_dealt", _on_damage_dealt)
	GlobalEventBus.battle.remove_listener("healing_done", _on_healing_done)

	# 断开经济事件
	GlobalEventBus.economy.remove_class_listener(EconomyEvents.PlayerGoldChangedEvent, _on_player_gold_changed) # Updated listener removal
	GlobalEventBus.economy.remove_class_listener(EconomyEvents.ItemPurchasedEvent, _on_item_purchased)
	GlobalEventBus.economy.remove_class_listener(EconomyEvents.ItemSoldEvent, _on_item_sold)
	GlobalEventBus.economy.remove_class_listener(EconomyEvents.ShopRefreshedEvent, _on_stats_shop_refreshed)

	# 断开棋子事件
	GlobalEventBus.chess.remove_listener("chess_piece_bought", _on_chess_piece_bought)
	GlobalEventBus.chess.remove_listener("chess_piece_upgraded", _on_chess_piece_upgraded)

	# 断开羁绊事件
	GlobalEventBus.chess.remove_listener("synergy_activated", _on_synergy_activated)

	_log_info("统计管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 重置会话统计
	reset_session_stats()

	_log_info("统计管理器重置完成")

# 检查统计成就
func check_stat_achievement(stat_name: String, value) -> void:
	var achievement_manager = GameManager.achievement_manager
	if not achievement_manager:
		return

	# 根据统计名称检查不同的成就
	match stat_name:
		"games_played":
			if value >= 10:
				achievement_manager.unlock_achievement("play_10_games")
			if value >= 50:
				achievement_manager.unlock_achievement("play_50_games")
			if value >= 100:
				achievement_manager.unlock_achievement("play_100_games")

		"games_won":
			if value >= 5:
				achievement_manager.unlock_achievement("win_5_games")
			if value >= 20:
				achievement_manager.unlock_achievement("win_20_games")
			if value >= 50:
				achievement_manager.unlock_achievement("win_50_games")

		"total_damage_dealt":
			if value >= 10000:
				achievement_manager.unlock_achievement("deal_10000_damage")
			if value >= 50000:
				achievement_manager.unlock_achievement("deal_50000_damage")

		"total_gold_earned":
			if value >= 5000:
				achievement_manager.unlock_achievement("earn_5000_gold")
			if value >= 20000:
				achievement_manager.unlock_achievement("earn_20000_gold")

# Handler for ShopRefreshedEvent
func _on_stats_shop_refreshed(_event: EconomyEvents.ShopRefreshedEvent) -> void:
	increment_stat("shop_refreshes")

# Removed redundant public check_stat_achievement method.
# The internal _check_achievements method correctly delegates to AchievementManager.
