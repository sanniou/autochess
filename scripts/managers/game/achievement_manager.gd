extends "res://scripts/managers/core/base_manager.gd"
class_name AchievementManager
## 成就管理器
## 负责管理游戏成就的解锁和显示

# 引入成就常量
const AC = preload("res://scripts/constants/achievement_constants.gd")

# 信号
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: float, max_progress: float)

# 成就配置
var achievement_configs = {}

# 已解锁的成就
var unlocked_achievements = {}

# 成就进度
var achievement_progress = {}

# 成就条件处理器
var condition_handler: AchievementConditionHandler

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "AchievementManager"
	
	# 添加依赖
	add_dependency("ConfigManager")
	add_dependency("GameManager")
	add_dependency("SaveManager")

	# 加载成就配置
	_load_achievement_configs()
	
	# 创建条件处理器
	condition_handler = AchievementConditionHandler.new(self)

	# 连接信号
	_connect_signals()

# 加载成就配置
func _load_achievement_configs() -> void:
	achievement_configs = GameManager.config_manager.get_all_achievements()

	# 初始化成就进度
	for id in achievement_configs:
		if not achievement_progress.has(id):
			achievement_progress[id] = 0.0

# 连接信号
func _connect_signals() -> void:
	# 连接游戏事件信号
	GlobalEventBus.chess.add_class_listener(ChessEvents.ChessPieceCreatedEvent, _on_chess_piece_created)
	GlobalEventBus.chess.add_class_listener(ChessEvents.ChessPieceLevelChangedEvent,_on_chess_piece_upgraded)
	GlobalEventBus.battle.add_class_listener(BattleEvents.BattleEndedEvent,_on_battle_ended)
	GlobalEventBus.event.add_class_listener(EventEvents.EventCompletedEvent,_on_event_completed)
	GlobalEventBus.relic.add_class_listener(RelicEvents.RelicAcquiredEvent,_on_relic_acquired)
	GlobalEventBus.economy.add_class_listener(EconomyEvents.GoldChangedEvent,_on_gold_changed)
	GlobalEventBus.chess.add_class_listener(ChessEvents.SynergyTypeAddedEvent,_on_synergy_activated)
	GlobalEventBus.game.add_class_listener(GameEvents.GameEndedEvent,_on_game_completed)

# 获取成就
func get_achievement(achievement_id: String) -> AchievementConfig:
	if not achievement_configs.has(achievement_id):
		return null
	
	return achievement_configs[achievement_id]

# 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("成就不存在: " + achievement_id, 1))
		return false

	# 检查成就是否已解锁
	if unlocked_achievements.has(achievement_id):
		return false

	# 获取成就数据
	var achievement_data = achievement_configs[achievement_id]

	# 解锁成就
	unlocked_achievements[achievement_id] = {
		"id": achievement_id,
		"unlock_time": Time.get_unix_time_from_system(),
		"rewards_claimed": false
	}

	# 发送成就解锁信号
	achievement_unlocked.emit(achievement_id, achievement_data)

	# 显示成就解锁通知
	_show_achievement_notification(achievement_id)

	# 检查是否解锁了"完美主义者"成就
	condition_handler.check_completionist_achievement()

	# 保存成就数据
	_save_achievement_data()

	return true
# 更新成就进度
func update_achievement_progress(achievement_id: String, progress: float) -> void:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		return

	# 检查成就是否已解锁
	if unlocked_achievements.has(achievement_id):
		return

	# 获取成就数据
	var achievement = achievement_configs[achievement_id]

	# 获取当前进度
	var current_progress = achievement_progress.get(achievement_id, 0.0)

	# 更新进度
	achievement_progress[achievement_id] = progress

	# 获取最大进度
	var max_progress = achievement.get_requirement_count()

	# 发送进度更新信号
	achievement_progress_updated.emit(achievement_id, progress, max_progress)

	# 检查是否达成成就
	if achievement.is_achieved(progress):
		unlock_achievement(achievement_id)

	# 保存成就数据
	_save_achievement_data()

# 增加成就进度
func increment_achievement_progress(achievement_id: String, amount: float = 1.0) -> void:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		return

	# 检查成就是否已解锁
	if unlocked_achievements.has(achievement_id):
		return

	# 获取当前进度
	var current_progress = achievement_progress.get(achievement_id, 0.0)

	# 更新进度
	update_achievement_progress(achievement_id, current_progress + amount)

# 获取成就进度
func get_achievement_progress(achievement_id: String) -> float:
	return achievement_progress.get(achievement_id, 0.0)

# 获取成就最大进度
func get_achievement_max_progress(achievement_id: String) -> float:
	# 获取成就数据
	var achievement = achievement_configs.get(achievement_id)
	if achievement == null:
		return 1.0
	
	return achievement.get_requirement_count()

# 检查成就是否已解锁
func is_achievement_unlocked(achievement_id: String) -> bool:
	return unlocked_achievements.has(achievement_id)

# 获取所有成就
func get_all_achievements() -> Dictionary:
	return achievement_configs.duplicate()

# 获取已解锁的成就
func get_unlocked_achievements() -> Dictionary:
	return unlocked_achievements.duplicate()

# 获取成就奖励
func get_achievement_rewards(achievement_id: String) -> Dictionary:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		return {}

	# 获取成就数据
	var achievement = achievement_configs[achievement_id]

	# 返回奖励
	return achievement.get_rewards()

# 领取成就奖励
func claim_achievement_rewards(achievement_id: String) -> bool:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		return false

	# 检查成就是否已解锁
	if not unlocked_achievements.has(achievement_id):
		return false

	# 检查奖励是否已领取
	if unlocked_achievements[achievement_id].rewards_claimed:
		return false

	# 获取成就奖励
	var rewards = get_achievement_rewards(achievement_id)

	# 应用奖励
	_apply_achievement_rewards(rewards)

	# 标记奖励已领取
	unlocked_achievements[achievement_id].rewards_claimed = true

	# 保存成就数据
	_save_achievement_data()

	return true

# 应用成就奖励
func _apply_achievement_rewards(rewards: Dictionary) -> void:
	# 获取玩家管理器
	var player_manager = GameManager.player_manager
	if player_manager == null:
		return

	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return

	# 应用金币奖励
	if rewards.has("gold") and rewards.gold > 0:
		player.add_gold(int(rewards.gold))

	# 应用经验奖励
	if rewards.has("exp") and rewards.exp > 0:
		player.add_exp(int(rewards.exp))

	# 应用解锁物品奖励
	if rewards.has("unlock_item") and rewards.unlock_item != "":
		# 根据物品类型解锁不同的物品
		var item_id = rewards.unlock_item

		if item_id.begins_with("chess_"):
			# 解锁棋子
			var chess_id = item_id.substr(6)
			player_manager.unlock_chess_piece(chess_id)

		elif item_id.begins_with("equipment_"):
			# 解锁装备
			var equipment_id = item_id.substr(10)
			var equipment_manager = GameManager.equipment_manager
			if equipment_manager:
				equipment_manager.unlock_equipment(equipment_id)

		elif item_id.begins_with("relic_"):
			# 解锁遗物
			var relic_id = item_id.substr(6)
			var relic_manager = GameManager.relic_manager
			if relic_manager:
				relic_manager.unlock_relic(relic_id)

		elif item_id.begins_with("skin_"):
			# 解锁皮肤
			var skin_id = item_id.substr(5)
			var skin_manager = GameManager.skin_manager
			if skin_manager and rewards.has("skin_type"):
				skin_manager.unlock_skin(skin_id, rewards.skin_type)

# 保存成就数据
func _save_achievement_data() -> void:
	# 获取存档管理器
	var save_manager = SaveManager
	if save_manager == null:
		return

	# 创建成就存档数据
	var achievement_save_data = {
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"achievement_progress": achievement_progress.duplicate()
	}

	# 保存成就数据
	save_manager.save_achievement_data(achievement_save_data)

# 加载成就数据
func load_achievement_data(data: Dictionary) -> void:
	# 加载已解锁的成就
	if data.has("unlocked_achievements"):
		unlocked_achievements = data.unlocked_achievements.duplicate()

	# 加载成就进度
	if data.has("achievement_progress"):
		achievement_progress = data.achievement_progress.duplicate()

	# 检查是否有新的成就配置
	for id in achievement_configs:
		if not achievement_progress.has(id):
			achievement_progress[id] = 0.0

# 显示成就解锁通知
func _show_achievement_notification(achievement_id: String) -> void:
	# 获取成就数据
	var achievement_data = achievement_configs[achievement_id]

	# 获取UI管理器
	var ui_manager = GameManager.ui_manager
	if ui_manager == null:
		return

	# 显示成就解锁通知
	ui_manager.show_achievement_notification(achievement_id, achievement_data)

# 检查统计相关成就
func check_stat_achievement(stat_name: String, value) -> void:
	condition_handler.handle_stat_achievement(stat_name, value)

# 棋子创建事件处理
func _on_chess_piece_created(event:ChessEvents.ChessPieceCreatedEvent) -> void:
	condition_handler.handle_chess_piece_created(event.piece)

# 棋子升级事件处理
func _on_chess_piece_upgraded(evnet:ChessEvents.ChessPieceLevelChangedEvent) -> void:
	condition_handler.handle_chess_piece_upgraded(evnet.piece, evnet.old_level, evnet.new_level)

# 战斗结束事件处理
func _on_battle_ended(event:BattleEvents.BattleEndedEvent) -> void:
	# 处理不同格式的结果
	var battle_result = {}

	# 处理不同类型的结果
	if typeof(event.result) == TYPE_DICTIONARY:
		# 如果是字典，直接使用
		battle_result = event.result
	elif typeof(event.result) == TYPE_BOOL:
		# 如果是布尔值，创建简单的结果字典
		battle_result = BattleResult.create_simple(event.result).to_dict()
	elif event.result is BattleResult:
		# 如果是 BattleResult 对象，转换为字典
		battle_result = event.result.to_dict()
	else:
		# 无法处理的类型，返回
		_log_warning("_on_battle_ended 收到了无法处理的结果类型: " + str(typeof(event.result)))
		return

	condition_handler.handle_battle_ended(battle_result)

# 事件完成事件处理
func _on_event_completed(event:EventEvents.EventCompletedEvent) -> void:
	condition_handler.handle_event_completed(event.event, event.result)

# 遗物获取事件处理
func _on_relic_acquired(event:RelicEvents.RelicAcquiredEvent) -> void:
	condition_handler.handle_relic_acquired(event.relic)

# 金币变化事件处理
func _on_gold_changed(event:EconomyEvents.GoldChangedEvent) -> void:
	condition_handler.handle_gold_changed(event.player, event.old_amount, event.new_amount)

# 羁绊激活事件处理
func _on_synergy_activated(event:ChessEvents.SynergyTypeAddedEvent) -> void:
	condition_handler.handle_synergy_activated(event.synergy_id, event.level)

# 游戏完成事件处理
func _on_game_completed(event:GameEvents.GameEndedEvent) -> void:
	condition_handler.handle_game_completed(event.is_victory)

# 重写重置方法
func _do_reset() -> void:
	# 清空成就进度
	achievement_progress.clear()

	# 清空已解锁的成就
	unlocked_achievements.clear()

	# 重新加载成就配置
	_load_achievement_configs()

	_log_info("成就管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接	
	GlobalEventBus.chess.remoe_class_listener(ChessEvents.ChessPieceCreatedEvent, _on_chess_piece_created)
	GlobalEventBus.chess.remoe_class_listener(ChessEvents.ChessPieceLevelChangedEvent,_on_chess_piece_upgraded)
	GlobalEventBus.battle.remoe_class_listener(BattleEvents.BattleEndedEvent,_on_battle_ended)
	GlobalEventBus.event.remoe_class_listener(EventEvents.EventCompletedEvent,_on_event_completed)
	GlobalEventBus.relic.remoe_class_listener(RelicEvents.RelicAcquiredEvent,_on_relic_acquired)
	GlobalEventBus.economy.remoe_class_listener(EconomyEvents.GoldChangedEvent,_on_gold_changed)
	GlobalEventBus.chess.remoe_class_listener(ChessEvents.SynergyTypeAddedEvent,_on_synergy_activated)
	GlobalEventBus.game.remoe_class_listener(GameEvents.GameEndedEvent,_on_game_completed)

	# 清空成就数据
	achievement_configs.clear()
	achievement_progress.clear()
	unlocked_achievements.clear()
	
	# 清理条件处理器
	condition_handler = null

	_log_info("成就管理器清理完成")
