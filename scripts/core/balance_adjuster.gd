extends Node
class_name BalanceAdjuster
## 游戏平衡性调整器
## 用于动态调整游戏难度和平衡性

# 信号
signal difficulty_adjusted(old_level, new_level, reason)
signal balance_parameters_adjusted(parameters)
signal player_performance_updated(performance_data)

# 难度级别
enum DifficultyLevel {
	VERY_EASY,
	EASY,
	NORMAL,
	HARD,
	VERY_HARD,
	CUSTOM
}

# 当前难度级别
var current_difficulty = DifficultyLevel.NORMAL

# 难度参数
var difficulty_parameters = {
	DifficultyLevel.VERY_EASY: {
		"enemy_health_multiplier": 0.6,
		"enemy_damage_multiplier": 0.6,
		"gold_gain_multiplier": 1.5,
		"shop_cost_multiplier": 0.8,
		"chess_piece_upgrade_chance": 1.3,
		"enemy_ai_level": 0
	},
	DifficultyLevel.EASY: {
		"enemy_health_multiplier": 0.8,
		"enemy_damage_multiplier": 0.8,
		"gold_gain_multiplier": 1.2,
		"shop_cost_multiplier": 0.9,
		"chess_piece_upgrade_chance": 1.1,
		"enemy_ai_level": 1
	},
	DifficultyLevel.NORMAL: {
		"enemy_health_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"gold_gain_multiplier": 1.0,
		"shop_cost_multiplier": 1.0,
		"chess_piece_upgrade_chance": 1.0,
		"enemy_ai_level": 2
	},
	DifficultyLevel.HARD: {
		"enemy_health_multiplier": 1.2,
		"enemy_damage_multiplier": 1.2,
		"gold_gain_multiplier": 0.9,
		"shop_cost_multiplier": 1.1,
		"chess_piece_upgrade_chance": 0.9,
		"enemy_ai_level": 3
	},
	DifficultyLevel.VERY_HARD: {
		"enemy_health_multiplier": 1.5,
		"enemy_damage_multiplier": 1.3,
		"gold_gain_multiplier": 0.8,
		"shop_cost_multiplier": 1.2,
		"chess_piece_upgrade_chance": 0.8,
		"enemy_ai_level": 4
	},
	DifficultyLevel.CUSTOM: {
		"enemy_health_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"gold_gain_multiplier": 1.0,
		"shop_cost_multiplier": 1.0,
		"chess_piece_upgrade_chance": 1.0,
		"enemy_ai_level": 2
	}
}

# 动态难度调整设置
var dynamic_difficulty_settings = {
	"enabled": true,
	"check_interval": 60.0,  # 检查间隔（秒）
	"adjustment_threshold": 0.2,  # 调整阈值
	"max_adjustment_per_check": 1,  # 每次检查最大调整级别
	"performance_history_size": 5,  # 性能历史大小
	"performance_weights": {
		"win_rate": 0.4,
		"health_remaining": 0.2,
		"gold_efficiency": 0.2,
		"time_per_decision": 0.1,
		"chess_piece_synergy": 0.1
	}
}

# 玩家性能数据
var player_performance = {
	"battles_won": 0,
	"battles_total": 0,
	"win_rate": 0.0,
	"average_health_remaining": 0.0,
	"gold_spent": 0,
	"value_gained": 0,
	"gold_efficiency": 0.0,
	"decision_times": [],
	"average_decision_time": 0.0,
	"synergy_score": 0.0,
	"performance_score": 0.0
}

# 性能历史
var _performance_history = []

# 计时器
var _difficulty_check_timer = 0.0

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS

# 进程
func _process(delta: float) -> void:
	if not dynamic_difficulty_settings.enabled:
		return
	
	# 更新难度检查计时器
	_difficulty_check_timer += delta
	
	# 检查是否需要调整难度
	if _difficulty_check_timer >= dynamic_difficulty_settings.check_interval:
		_difficulty_check_timer = 0.0
		_check_difficulty_adjustment()

## 设置难度级别
func set_difficulty(level: int) -> void:
	if level < DifficultyLevel.VERY_EASY or level > DifficultyLevel.CUSTOM:
		push_error("无效的难度级别: " + str(level))
		return
	
	var old_level = current_difficulty
	current_difficulty = level
	
	# 发送难度调整信号
	difficulty_adjusted.emit(old_level, current_difficulty, "手动设置")
	
	EventBus.debug_message.emit("难度级别已设置为: " + _get_difficulty_name(level), 0)

## 获取当前难度参数
func get_difficulty_parameters() -> Dictionary:
	return difficulty_parameters[current_difficulty]

## 设置自定义难度参数
func set_custom_difficulty_parameters(parameters: Dictionary) -> void:
	# 更新自定义难度参数
	for key in parameters:
		if difficulty_parameters[DifficultyLevel.CUSTOM].has(key):
			difficulty_parameters[DifficultyLevel.CUSTOM][key] = parameters[key]
	
	# 如果当前是自定义难度，发送参数调整信号
	if current_difficulty == DifficultyLevel.CUSTOM:
		balance_parameters_adjusted.emit(difficulty_parameters[DifficultyLevel.CUSTOM])
	
	EventBus.debug_message.emit("自定义难度参数已更新", 0)

## 启用动态难度调整
func enable_dynamic_difficulty() -> void:
	dynamic_difficulty_settings.enabled = true
	EventBus.debug_message.emit("动态难度调整已启用", 0)

## 禁用动态难度调整
func disable_dynamic_difficulty() -> void:
	dynamic_difficulty_settings.enabled = false
	EventBus.debug_message.emit("动态难度调整已禁用", 0)

## 设置动态难度调整设置
func set_dynamic_difficulty_settings(settings: Dictionary) -> void:
	# 更新设置
	for key in settings:
		if dynamic_difficulty_settings.has(key):
			if key == "performance_weights" and settings[key] is Dictionary:
				for weight_key in settings[key]:
					if dynamic_difficulty_settings.performance_weights.has(weight_key):
						dynamic_difficulty_settings.performance_weights[weight_key] = settings[key][weight_key]
			else:
				dynamic_difficulty_settings[key] = settings[key]
	
	EventBus.debug_message.emit("动态难度调整设置已更新", 0)

## 更新玩家性能数据
func update_player_performance(performance_data: Dictionary) -> void:
	# 更新性能数据
	for key in performance_data:
		if player_performance.has(key):
			player_performance[key] = performance_data[key]
	
	# 计算性能得分
	_calculate_performance_score()
	
	# 添加到历史
	_add_performance_to_history()
	
	# 发送性能更新信号
	player_performance_updated.emit(player_performance)

## 记录战斗结果
func record_battle_result(won: bool, health_remaining: float) -> void:
	# 更新战斗统计
	player_performance.battles_total += 1
	if won:
		player_performance.battles_won += 1
	
	# 更新胜率
	player_performance.win_rate = float(player_performance.battles_won) / player_performance.battles_total
	
	# 更新平均剩余生命值
	player_performance.average_health_remaining = (player_performance.average_health_remaining * (player_performance.battles_total - 1) + health_remaining) / player_performance.battles_total
	
	# 计算性能得分
	_calculate_performance_score()
	
	# 添加到历史
	_add_performance_to_history()
	
	# 发送性能更新信号
	player_performance_updated.emit(player_performance)

## 记录金币使用
func record_gold_usage(gold_spent: int, value_gained: int) -> void:
	# 更新金币统计
	player_performance.gold_spent += gold_spent
	player_performance.value_gained += value_gained
	
	# 更新金币效率
	if player_performance.gold_spent > 0:
		player_performance.gold_efficiency = float(player_performance.value_gained) / player_performance.gold_spent
	
	# 计算性能得分
	_calculate_performance_score()
	
	# 添加到历史
	_add_performance_to_history()
	
	# 发送性能更新信号
	player_performance_updated.emit(player_performance)

## 记录决策时间
func record_decision_time(time: float) -> void:
	# 添加决策时间
	player_performance.decision_times.append(time)
	
	# 限制决策时间历史大小
	while player_performance.decision_times.size() > 20:
		player_performance.decision_times.pop_front()
	
	# 计算平均决策时间
	var total_time = 0.0
	for t in player_performance.decision_times:
		total_time += t
	
	player_performance.average_decision_time = total_time / player_performance.decision_times.size()
	
	# 计算性能得分
	_calculate_performance_score()
	
	# 添加到历史
	_add_performance_to_history()
	
	# 发送性能更新信号
	player_performance_updated.emit(player_performance)

## 更新协同得分
func update_synergy_score(score: float) -> void:
	player_performance.synergy_score = score
	
	# 计算性能得分
	_calculate_performance_score()
	
	# 添加到历史
	_add_performance_to_history()
	
	# 发送性能更新信号
	player_performance_updated.emit(player_performance)

## 计算性能得分
func _calculate_performance_score() -> void:
	var weights = dynamic_difficulty_settings.performance_weights
	var score = 0.0
	
	# 胜率（越高越好）
	score += player_performance.win_rate * weights.win_rate
	
	# 平均剩余生命值（越高越好）
	score += (player_performance.average_health_remaining / 100.0) * weights.health_remaining
	
	# 金币效率（越高越好）
	score += min(player_performance.gold_efficiency, 2.0) / 2.0 * weights.gold_efficiency
	
	# 决策时间（越低越好，转换为0-1范围）
	var decision_time_score = 0.0
	if player_performance.average_decision_time > 0:
		decision_time_score = max(0.0, 1.0 - player_performance.average_decision_time / 10.0)
	score += decision_time_score * weights.time_per_decision
	
	# 协同得分（越高越好，假设范围是0-1）
	score += player_performance.synergy_score * weights.chess_piece_synergy
	
	# 保存性能得分
	player_performance.performance_score = score

## 添加性能到历史
func _add_performance_to_history() -> void:
	_performance_history.append(player_performance.duplicate(true))
	
	# 限制历史大小
	while _performance_history.size() > dynamic_difficulty_settings.performance_history_size:
		_performance_history.pop_front()

## 检查难度调整
func _check_difficulty_adjustment() -> void:
	# 如果没有足够的性能历史，跳过
	if _performance_history.size() < 2:
		return
	
	# 计算平均性能得分
	var avg_score = 0.0
	for perf in _performance_history:
		avg_score += perf.performance_score
	avg_score /= _performance_history.size()
	
	# 确定是否需要调整难度
	var target_score = 0.5  # 目标性能得分（中等难度）
	var score_diff = avg_score - target_score
	
	# 如果差异超过阈值，调整难度
	if abs(score_diff) > dynamic_difficulty_settings.adjustment_threshold:
		var adjustment = 0
		
		if score_diff > 0:
			# 玩家表现好，增加难度
			adjustment = min(ceil(score_diff / dynamic_difficulty_settings.adjustment_threshold), dynamic_difficulty_settings.max_adjustment_per_check)
		else:
			# 玩家表现差，降低难度
			adjustment = max(floor(score_diff / dynamic_difficulty_settings.adjustment_threshold), -dynamic_difficulty_settings.max_adjustment_per_check)
		
		# 计算新难度
		var new_difficulty = clamp(current_difficulty + adjustment, DifficultyLevel.VERY_EASY, DifficultyLevel.VERY_HARD)
		
		# 如果难度变化，应用新难度
		if new_difficulty != current_difficulty:
			var old_difficulty = current_difficulty
			current_difficulty = new_difficulty
			
			# 发送难度调整信号
			difficulty_adjusted.emit(old_difficulty, current_difficulty, "动态调整")
			
			EventBus.debug_message.emit("难度已动态调整为: " + _get_difficulty_name(current_difficulty) + "，性能得分: " + str(avg_score), 0)

## 获取难度名称
func _get_difficulty_name(level: int) -> String:
	match level:
		DifficultyLevel.VERY_EASY:
			return "非常简单"
		DifficultyLevel.EASY:
			return "简单"
		DifficultyLevel.NORMAL:
			return "普通"
		DifficultyLevel.HARD:
			return "困难"
		DifficultyLevel.VERY_HARD:
			return "非常困难"
		DifficultyLevel.CUSTOM:
			return "自定义"
		_:
			return "未知"

## 获取玩家性能数据
func get_player_performance() -> Dictionary:
	return player_performance

## 重置玩家性能数据
func reset_player_performance() -> void:
	player_performance = {
		"battles_won": 0,
		"battles_total": 0,
		"win_rate": 0.0,
		"average_health_remaining": 0.0,
		"gold_spent": 0,
		"value_gained": 0,
		"gold_efficiency": 0.0,
		"decision_times": [],
		"average_decision_time": 0.0,
		"synergy_score": 0.0,
		"performance_score": 0.0
	}
	
	_performance_history.clear()
	
	EventBus.debug_message.emit("玩家性能数据已重置", 0)
