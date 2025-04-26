extends RefCounted
class_name AchievementConditionHandler
## 成就条件处理器
## 负责处理不同类型的成就条件

# 引入成就常量
const AC = preload("res://scripts/constants/achievement_constants.gd")

# 成就管理器引用
var achievement_manager: AchievementManager

# 初始化
func _init(manager: AchievementManager):
	achievement_manager = manager

# 处理棋子创建事件
func handle_chess_piece_created(piece: ChessPieceEntity) -> void:
	# 获取所有棋子类型的成就
	var chess_achievements = _get_achievements_by_type(AC.Type.CHESS)
	
	# 检查是否需要收集所有棋子
	for id in chess_achievements:
		var achievement = chess_achievements[id]
		var requirements = achievement.get_requirements()
		
		if requirements.get("all", false):
			_check_all_chess_collected(id, piece)

# 处理棋子升级事件
func handle_chess_piece_upgraded(piece: ChessPieceEntity, old_star: int, new_star: int) -> void:
	# 获取所有棋子星级类型的成就
	var star_achievements = _get_achievements_by_type(AC.Type.CHESS_STAR)
	
	# 检查星级要求
	for id in star_achievements:
		var achievement = star_achievements[id]
		var star_requirement = achievement.get_requirement_star()
		
		if star_requirement > 0 and star_requirement == new_star:
			achievement_manager.increment_achievement_progress(id)

# 处理战斗结束事件
func handle_battle_ended(battle_result: Dictionary) -> void:
	# 获取所有战斗类型的成就
	var battle_achievements = _get_achievements_by_type(AC.Type.BATTLE)
	
	# 检查战斗要求
	for id in battle_achievements:
		var achievement = battle_achievements[id]
		
		# 检查是否要求不损失棋子
		if achievement.is_requirement_no_loss() and battle_result.get("is_victory", false):
			var player_pieces = battle_result.get("player_pieces", {})
			var remaining = player_pieces.get("remaining", 0)
			var initial = player_pieces.get("initial", 0)
			
			if remaining == initial and initial > 0:
				achievement_manager.unlock_achievement(id)
	
	# 检查连胜类型的成就
	var streak_achievements = _get_achievements_by_type(AC.Type.STREAK)
	
	# 获取当前连胜次数
	var streak = GameManager.get_win_streak() if battle_result.get("is_victory", false) else 0
	
	# 检查连胜要求
	for id in streak_achievements:
		var achievement = streak_achievements[id]
		var count_requirement = achievement.get_requirement_count()
		
		if achievement.is_requirement_win() and streak >= count_requirement:
			achievement_manager.unlock_achievement(id)
	
	# 检查其他战斗相关成就
	if battle_result.get("is_victory", false):
		# 检查低血量胜利成就
		if GameManager.player_manager and GameManager.player_manager.get_current_player():
			var player = GameManager.player_manager.get_current_player()
			var health_achievements = _get_achievements_by_type(AC.Type.VICTORY)
			
			for id in health_achievements:
				var achievement = health_achievements[id]
				var health_max = achievement.get_requirement_health_max()
				
				if health_max > 0 and player.health <= health_max:
					achievement_manager.unlock_achievement(id)
		
		# 检查高伤害成就
		var stats = battle_result.get("stats", {})
		var damage_dealt = stats.get("damage_dealt", 0)
		
		if damage_dealt > 1000:
			# 查找高伤害成就
			var damage_achievements = _get_achievements_by_type(AC.Type.BATTLE)
			
			for id in damage_achievements:
				var achievement = damage_achievements[id]
				if achievement.get_requirements().has("damage_min") and damage_dealt >= achievement.get_requirements().damage_min:
					achievement_manager.unlock_achievement(id)
		
		# 检查全灭敌人成就
		var enemy_pieces = battle_result.get("enemy_pieces", {})
		if enemy_pieces.get("remaining", 0) == 0 and enemy_pieces.get("initial", 0) >= 5:
			# 查找全灭敌人成就
			var annihilation_achievements = _get_achievements_by_type(AC.Type.BATTLE)
			
			for id in annihilation_achievements:
				var achievement = annihilation_achievements[id]
				if achievement.get_requirements().has("annihilation") and achievement.get_requirements().annihilation:
					achievement_manager.unlock_achievement(id)

# 处理事件完成事件
func handle_event_completed(event: Dictionary, result: Dictionary) -> void:
	# 获取所有事件类型的成就
	var event_achievements = _get_achievements_by_type(AC.Type.EVENT)
	
	# 增加事件完成进度
	for id in event_achievements:
		achievement_manager.increment_achievement_progress(id)

# 处理遗物获取事件
func handle_relic_acquired(relic: Dictionary) -> void:
	# 获取所有遗物类型的成就
	var relic_achievements = _get_achievements_by_type(AC.Type.RELIC)
	
	# 检查单局游戏中获得的遗物数量
	var relic_count = GameManager.relic_manager.get_player_relics().size()
	
	for id in relic_achievements:
		var achievement = relic_achievements[id]
		var count_requirement = achievement.get_requirement_count()
		var in_single_game = achievement.is_requirement_in_single_game()
		
		if in_single_game and relic_count >= count_requirement:
			achievement_manager.unlock_achievement(id)
		else:
			achievement_manager.increment_achievement_progress(id)

# 处理金币变化事件
func handle_gold_changed(player, old_amount: int, new_amount: int) -> void:
	# 获取所有金币类型的成就
	var gold_achievements = _get_achievements_by_type(AC.Type.GOLD)
	
	for id in gold_achievements:
		var achievement = gold_achievements[id]
		var amount_requirement = achievement.get_requirement_amount()
		var in_single_game = achievement.is_requirement_in_single_game()
		
		if in_single_game and new_amount >= amount_requirement:
			achievement_manager.unlock_achievement(id)

# 处理羁绊激活事件
func handle_synergy_activated(synergy_id: String, level: int) -> void:
	# 获取所有羁绊类型的成就
	var synergy_achievements = _get_achievements_by_type(AC.Type.SYNERGY)
	
	# 检查羁绊大师成就
	for id in synergy_achievements:
		_check_synergy_master_achievement(id)

# 处理游戏完成事件
func handle_game_completed(victory: bool) -> void:
	if not victory:
		return
	
	# 获取所有胜利类型的成就
	var victory_achievements = _get_achievements_by_type(AC.Type.VICTORY)
	
	for id in victory_achievements:
		var achievement = victory_achievements[id]
		
		# 检查是否是首次胜利成就
		if not achievement.get_requirements().has("difficulty_min") and not achievement.get_requirements().has("time_max"):
			achievement_manager.unlock_achievement(id)
		
		# 检查困难胜利成就
		var difficulty_min = achievement.get_requirement_difficulty_min()
		if difficulty_min > 0:
			var difficulty = GameManager.difficulty_level
			if difficulty >= difficulty_min:
				achievement_manager.unlock_achievement(id)
		
		# 检查速通成就
		var time_max = achievement.get_requirement_time_max()
		if time_max > 0:
			var game_time = _get_game_time()
			if game_time <= time_max:
				achievement_manager.unlock_achievement(id)

# 处理统计数据成就
func handle_stat_achievement(stat_name: String, value) -> void:
	# 获取所有统计数据类型的成就
	var stat_achievements = _get_achievements_by_type(AC.Type.STAT)
	
	for id in stat_achievements:
		var achievement = stat_achievements[id]
		var requirements = achievement.get_requirements()
		
		if requirements.has("stat_name") and requirements.stat_name == stat_name:
			var threshold = requirements.get("threshold", 0.0)
			if value >= threshold:
				achievement_manager.unlock_achievement(id)

# 检查棋盘是否已满
func check_full_board_achievement() -> void:
	# 获取所有棋盘类型的成就
	var board_achievements = _get_achievements_by_type(AC.Type.BOARD)
	
	# 检查棋盘是否已满
	var board_manager = GameManager.board_manager
	if board_manager == null:
		return
	
	if board_manager.is_board_full():
		for id in board_achievements:
			var achievement = board_achievements[id]
			if achievement.is_requirement_full():
				achievement_manager.unlock_achievement(id)

# 检查装备收藏家成就
func check_equipment_collector_achievement() -> void:
	# 获取所有装备类型的成就
	var equipment_achievements = _get_achievements_by_type(AC.Type.EQUIPMENT)
	
	# 获取装备管理器
	var equipment_manager = GameManager.equipment_manager
	if equipment_manager == null:
		return
	
	for id in equipment_achievements:
		var achievement = equipment_achievements[id]
		var rarity_requirement = achievement.get_requirement_rarity()
		var all_required = achievement.is_requirement_all()
		
		if rarity_requirement > 0 and all_required:
			_check_all_equipment_collected(id, rarity_requirement)

# 检查完美主义者成就
func check_completionist_achievement() -> void:
	# 获取所有成就类型的成就
	var achievement_achievements = _get_achievements_by_type(AC.Type.ACHIEVEMENT)
	
	for id in achievement_achievements:
		var achievement = achievement_achievements[id]
		var all_required = achievement.is_requirement_all()
		var exclude = achievement.get_requirement_exclude()
		
		if all_required:
			_check_all_achievements_unlocked(id, exclude)

# 获取指定类型的所有成就
func _get_achievements_by_type(type_enum: int) -> Dictionary:
	var result = {}
	var all_achievements = achievement_manager.get_all_achievements()
	
	for id in all_achievements:
		var achievement = all_achievements[id]
		if achievement.get_requirement_type_enum() == type_enum:
			result[id] = achievement
	
	return result

# 检查是否收集了所有棋子
func _check_all_chess_collected(achievement_id: String, new_piece: ChessPieceEntity = null) -> void:
	# 获取棋子管理器
	var chess_manager = GameManager.chess_manager
	if chess_manager == null:
		return
	
	# 获取所有棋子配置
	var all_chess_configs = GameManager.config_manager.get_all_chess_pieces()
	
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
	
	# 如果拥有所有棋子，解锁成就
	if all_owned:
		achievement_manager.unlock_achievement(achievement_id)

# 检查是否激活了足够数量的最高级别羁绊
func _check_synergy_master_achievement(achievement_id: String) -> void:
	# 获取羁绊管理器
	var synergy_manager = GameManager.synergy_manager
	if synergy_manager == null:
		return
	
	# 获取成就配置
	var achievement = achievement_manager.get_achievement(achievement_id)
	if achievement == null:
		return
	
	# 获取要求数量
	var count_requirement = achievement.get_requirement_count()
	
	# 获取激活的羁绊
	var active_synergies = synergy_manager.get_active_synergies()
	
	# 计算最高级别的羁绊数量
	var max_level_count = 0
	for synergy_id in active_synergies:
		var synergy_data = active_synergies[synergy_id]
		var max_level = synergy_manager.get_max_synergy_level(synergy_id)
		
		if synergy_data.level == max_level:
			max_level_count += 1
	
	# 如果达到要求数量，解锁成就
	if max_level_count >= count_requirement:
		achievement_manager.unlock_achievement(achievement_id)

# 检查是否收集了所有指定稀有度的装备
func _check_all_equipment_collected(achievement_id: String, rarity: int) -> void:
	# 获取装备管理器
	var equipment_manager = GameManager.equipment_manager
	if equipment_manager == null:
		return
	
	# 获取所有指定稀有度的装备配置
	var all_equipment_configs = GameManager.config_manager.get_all_equipment()
	var rare_equipment_ids = []
	
	for id in all_equipment_configs:
		var config = all_equipment_configs[id]
		if config.has("rarity") and config.rarity == rarity:
			rare_equipment_ids.append(id)
	
	# 获取玩家拥有的装备
	var player_equipment = equipment_manager.get_all_player_equipment()
	
	# 创建已拥有装备ID集合
	var owned_equipment_ids = {}
	for equipment in player_equipment:
		owned_equipment_ids[equipment.id] = true
	
	# 检查是否拥有所有指定稀有度的装备
	var all_owned = true
	for id in rare_equipment_ids:
		if not owned_equipment_ids.has(id):
			all_owned = false
			break
	
	# 如果拥有所有指定稀有度的装备，解锁成就
	if all_owned:
		achievement_manager.unlock_achievement(achievement_id)

# 检查是否解锁了所有其他成就
func _check_all_achievements_unlocked(achievement_id: String, exclude: Array) -> void:
	# 检查是否已解锁该成就
	if achievement_manager.is_achievement_unlocked(achievement_id):
		return
	
	# 获取所有成就
	var all_achievements = achievement_manager.get_all_achievements()
	
	# 获取已解锁的成就
	var unlocked_achievements = achievement_manager.get_unlocked_achievements()
	
	# 检查是否解锁了所有其他成就
	var all_unlocked = true
	for id in all_achievements:
		if id == achievement_id or exclude.has(id):
			continue
		
		if not unlocked_achievements.has(id):
			all_unlocked = false
			break
	
	# 如果解锁了所有其他成就，解锁该成就
	if all_unlocked:
		achievement_manager.unlock_achievement(achievement_id)

# 获取游戏时间
func _get_game_time() -> float:
	# 从存档数据中获取游戏开始时间，然后计算持续时间
	var save_manager = SaveManager
	if save_manager != null:
		var save_data = save_manager.get_save_data()
		if save_data.has("game_start_time"):
			var start_time = save_data.game_start_time
			var current_time = Time.get_unix_time_from_system()
			return current_time - start_time
	
	return 0.0
