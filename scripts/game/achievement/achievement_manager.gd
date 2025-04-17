extends "res://scripts/core/base_manager.gd"
class_name AchievementManager
## 成就管理器
## 负责管理游戏成就的解锁和显示

# 信号
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: float, max_progress: float)

# 成就配置
var achievement_configs = {}

# 已解锁的成就
var unlocked_achievements = {}

# 成就进度
var achievement_progress = {}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var game_manager = get_node("/root/GameManager")

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "AchievementManager"
	# 添加依赖
	add_dependency("ConfigManager")
	# 添加依赖
	add_dependency("GameManager")
	# 添加依赖
	add_dependency("SaveManager")
	
	# 原 _ready 函数的内容
	# 加载成就配置
		_load_achievement_configs()
		
		# 连接信号
		_connect_signals()
	
	# 加载成就配置
func _load_achievement_configs() -> void:
	achievement_configs = config_manager.get_all_achievements()
	
	# 初始化成就进度
	for id in achievement_configs:
		if not achievement_progress.has(id):
			achievement_progress[id] = 0.0

# 连接信号
func _connect_signals() -> void:
	# 连接游戏事件信号
	EventBus.chess.chess_piece_created.connect(_on_chess_piece_created)
	EventBus.chess.chess_piece_upgraded.connect(_on_chess_piece_upgraded)
	EventBus.battle.battle_ended.connect(_on_battle_ended)
	EventBus.event.event_completed.connect(_on_event_completed)
	EventBus.relic.relic_acquired.connect(_on_relic_acquired)
	EventBus.economy.gold_changed.connect(_on_gold_changed)
	EventBus.chess.synergy_activated.connect(_on_synergy_activated)
	EventBus.game_completed.connect(_on_game_completed)

# 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	# 检查成就是否存在
	if not achievement_configs.has(achievement_id):
		EventBus.debug.debug_message.emit("成就不存在: " + achievement_id, 1)
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
	_check_completionist_achievement()
	
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
	var achievement_data = achievement_configs[achievement_id]
	
	# 获取当前进度
	var current_progress = achievement_progress.get(achievement_id, 0.0)
	
	# 更新进度
	achievement_progress[achievement_id] = progress
	
	# 获取最大进度
	var max_progress = 1.0
	if achievement_data.has("requirements") and achievement_data.requirements.has("count"):
		max_progress = float(achievement_data.requirements.count)
	
	# 发送进度更新信号
	achievement_progress_updated.emit(achievement_id, progress, max_progress)
	
	# 检查是否达成成就
	if progress >= max_progress:
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
	var achievement_data = achievement_configs.get(achievement_id, {})
	
	# 获取最大进度
	if achievement_data.has("requirements") and achievement_data.requirements.has("count"):
		return float(achievement_data.requirements.count)
	
	return 1.0

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
	var achievement_data = achievement_configs[achievement_id]
	
	# 返回奖励
	if achievement_data.has("rewards"):
		return achievement_data.rewards.duplicate()
	
	return {}

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
	var player_manager = game_manager.player_manager
	if player_manager == null:
		return
	
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return
	
	# 应用金币奖励
	if rewards.has("gold") and rewards.gold > 0:
		player.add_gold(rewards.gold)
	
	# 应用经验奖励
	if rewards.has("exp") and rewards.exp > 0:
		player.add_exp(rewards.exp)
	
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
			var equipment_manager = game_manager.equipment_manager
			if equipment_manager:
				equipment_manager.unlock_equipment(equipment_id)
		
		elif item_id.begins_with("relic_"):
			# 解锁遗物
			var relic_id = item_id.substr(6)
			var relic_manager = game_manager.relic_manager
			if relic_manager:
				relic_manager.unlock_relic(relic_id)
		
		elif item_id.begins_with("skin_"):
			# 解锁皮肤
			var skin_id = item_id.substr(5)
			var skin_manager = game_manager.skin_manager
			if skin_manager:
				skin_manager.unlock_skin(skin_id)

# 保存成就数据
func _save_achievement_data() -> void:
	# 获取存档管理器
	var save_manager = get_node("/root/SaveManager")
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
	var ui_manager = game_manager.ui_manager
	if ui_manager == null:
		return
	
	# 显示成就解锁通知
	ui_manager.show_achievement_notification(achievement_id, achievement_data)

# 检查"完美主义者"成就
func _check_completionist_achievement() -> void:
	# 检查是否已解锁"完美主义者"成就
	if unlocked_achievements.has("completionist"):
		return
	
	# 获取"完美主义者"成就数据
	var completionist_data = achievement_configs.get("completionist", {})
	if completionist_data.is_empty():
		return
	
	# 获取需要排除的成就
	var exclude_achievements = []
	if completionist_data.has("requirements") and completionist_data.requirements.has("exclude"):
		exclude_achievements = completionist_data.requirements.exclude
	
	# 检查是否解锁了所有其他成就
	var all_unlocked = true
	for id in achievement_configs:
		if id == "completionist" or exclude_achievements.has(id):
			continue
		
		if not unlocked_achievements.has(id):
			all_unlocked = false
			break
	
	# 如果解锁了所有其他成就，解锁"完美主义者"成就
	if all_unlocked:
		unlock_achievement("completionist")

# 棋子创建事件处理
func _on_chess_piece_created(piece: ChessPiece) -> void:
	# 检查"棋子大师"成就
	_check_chess_master_achievement(piece)

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece: ChessPiece, old_star: int, new_star: int) -> void:
	# 检查"三星收藏家"成就
	if new_star == 3:
		increment_achievement_progress("three_star_collector")

# 战斗结束事件处理
func _on_battle_ended(result: Dictionary) -> void:
	# 检查"完美战斗"成就
	if result.is_victory and result.player_pieces_left == result.initial_player_pieces:
		unlock_achievement("perfect_battle")
	
	# 检查"连胜"成就
	if result.is_victory:
		var streak = game_manager.get_win_streak()
		if streak >= 5:
			unlock_achievement("win_streak")
	
	# 检查"低血量胜利"成就
	if result.is_victory and game_manager.player_manager.get_current_player().health <= 10:
		unlock_achievement("low_health_victory")

# 事件完成事件处理
func _on_event_completed(event: Dictionary, result: Dictionary) -> void:
	# 增加"事件大师"成就进度
	increment_achievement_progress("event_master")

# 遗物获取事件处理
func _on_relic_acquired(relic: Dictionary) -> void:
	# 增加"遗物猎人"成就进度
	increment_achievement_progress("relic_hunter")
	
	# 检查单局游戏中获得的遗物数量
	var relic_count = game_manager.relic_manager.get_player_relics().size()
	if relic_count >= 5:
		unlock_achievement("relic_hunter")

# 金币变化事件处理
func _on_gold_changed(player, old_amount: int, new_amount: int) -> void:
	# 检查"富豪"成就
	if new_amount >= 50:
		unlock_achievement("rich_player")

# 羁绊激活事件处理
func _on_synergy_activated(synergy_id: String, level: int) -> void:
	# 检查"羁绊大师"成就
	_check_synergy_master_achievement()

# 游戏完成事件处理
func _on_game_completed(victory: bool, stats: Dictionary) -> void:
	if not victory:
		return
	
	# 解锁"初次胜利"成就
	unlock_achievement("first_victory")
	
	# 检查"困难胜利"成就
	var difficulty = game_manager.difficulty_level
	if difficulty >= 3:
		unlock_achievement("hard_victory")
	
	# 检查"速通"成就
	var game_time = stats.get("game_time", 0)
	if game_time <= 1200:  # 20分钟
		unlock_achievement("speed_run")

# 检查"棋子大师"成就
func _check_chess_master_achievement(new_piece: ChessPiece = null) -> void:
	# 获取棋子管理器
	var chess_manager = game_manager.chess_manager
	if chess_manager == null:
		return
	
	# 获取所有棋子配置
	var all_chess_configs = config_manager.get_all_chess_pieces()
	
	# 获取玩家拥有的棋子
	var player_chess_pieces = chess_manager.get_all_player_chess_pieces()
	
	# 创建已拥有棋子ID集合
	var owned_chess_ids = {}
	for piece in player_chess_pieces:
		owned_chess_ids[piece.id] = true
	
	# 如果有新棋子，添加到集合
	if new_piece != null:
		owned_chess_ids[new_piece.id] = true
	
	# 检查是否拥有所有棋子
	var all_owned = true
	for id in all_chess_configs:
		if not owned_chess_ids.has(id):
			all_owned = false
			break
	
	# 如果拥有所有棋子，解锁"棋子大师"成就
	if all_owned:
		unlock_achievement("chess_master")

# 检查"羁绊大师"成就
func _check_synergy_master_achievement() -> void:
	# 获取羁绊管理器
	var synergy_manager = game_manager.synergy_manager
	if synergy_manager == null:
		return
	
	# 获取激活的羁绊
	var active_synergies = synergy_manager.get_active_synergies()
	
	# 计算最高级别的羁绊数量
	var max_level_count = 0
	for synergy_id in active_synergies:
		var synergy_data = active_synergies[synergy_id]
		var max_level = synergy_manager.get_max_synergy_level(synergy_id)
		
		if synergy_data.level == max_level:
			max_level_count += 1
	
	# 如果有3个最高级别的羁绊，解锁"羁绊大师"成就
	if max_level_count >= 3:
		unlock_achievement("synergy_master")

# 检查"满员"成就
func _check_full_board_achievement() -> void:
	# 获取棋盘管理器
	var board_manager = game_manager.board_manager
	if board_manager == null:
		return
	
	# 检查棋盘是否已满
	if board_manager.is_board_full():
		unlock_achievement("full_board")

# 检查"装备收藏家"成就
func _check_equipment_collector_achievement() -> void:
	# 获取装备管理器
	var equipment_manager = game_manager.equipment_manager
	if equipment_manager == null:
		return
	
	# 获取所有稀有装备配置
	var all_equipment_configs = config_manager.get_all_equipment()
	var rare_equipment_ids = []
	
	for id in all_equipment_configs:
		var config = all_equipment_configs[id]
		if config.has("rarity") and config.rarity == "rare":
			rare_equipment_ids.append(id)
	
	# 获取玩家拥有的装备
	var player_equipment = equipment_manager.get_all_player_equipment()
	
	# 创建已拥有装备ID集合
	var owned_equipment_ids = {}
	for equipment in player_equipment:
		owned_equipment_ids[equipment.id] = true
	
	# 检查是否拥有所有稀有装备
	var all_owned = true
	for id in rare_equipment_ids:
		if not owned_equipment_ids.has(id):
			all_owned = false
			break
	
	# 如果拥有所有稀有装备，解锁"装备收藏家"成就
	if all_owned:
		unlock_achievement("equipment_collector")

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.debug_message.emit(error_message, 2)
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.debug_message.emit(info_message, 0)
