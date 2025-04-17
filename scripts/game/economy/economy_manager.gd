extends "res://scripts/core/base_manager.gd"
class_name EconomyManager
## 经济管理器
## 管理游戏经济系统，包括金币收入、商店和物品价格

# 基础收入
const BASE_INCOME = 5

# 利息上限
const MAX_INTEREST = 5

# 连胜/连败奖励表
const STREAK_BONUS = {
	2: 1,  # 2连胜/败：+1金币
	3: 2,  # 3连胜/败：+2金币
	5: 3   # 5连胜/败：+3金币
}

# 商店刷新费用
const SHOP_REFRESH_COST = 2

# 经验购买费用
const EXP_PURCHASE_COST = 4

# 经验购买数量
const EXP_PURCHASE_AMOUNT = 4

# 经济系统参数
var economy_params = {
	"base_income": BASE_INCOME,
	"max_interest": MAX_INTEREST,
	"streak_bonus": STREAK_BONUS.duplicate(),
	"shop_refresh_cost": SHOP_REFRESH_COST,
	"exp_purchase_cost": EXP_PURCHASE_COST,
	"exp_purchase_amount": EXP_PURCHASE_AMOUNT,
	"difficulty_modifier": 1.0,  # 难度对经济的影响
	"bankruptcy_protection": true  # 破产保护开关
}

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var config_manager = get_node("/root/ConfigManager")

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EconomyManager"
	# 添加依赖
	add_dependency("ConfigManager")
	# 添加依赖
	add_dependency("GameManager")
	
	# 原 _ready 函数的内容
	# 连接信号
		EventBus.battle.battle_round_started.connect(_on_battle_round_started)
		EventBus.economy.shop_refreshed.connect(_on_shop_refreshed)
		EventBus.economy.item_purchased.connect(_on_item_purchased)
		EventBus.economy.item_sold.connect(_on_item_sold)
		EventBus.difficulty_changed.connect(_on_difficulty_changed)
	
		# 加载难度设置
		_load_difficulty_settings()
	
	# 计算回合收入
func calculate_round_income(player: Player) -> int:
	var income = economy_params.base_income

	# 计算利息 (每10金币1金币，最多取决于经济参数)
	var interest = min(economy_params.max_interest, player.gold / 10)
	income += interest

	# 计算连胜/连败奖励
	var streak_bonus = 0
	var streak_bonuses = economy_params.streak_bonus

	if player.win_streak >= 5 and streak_bonuses.has(5):
		streak_bonus = streak_bonuses[5]
	elif player.win_streak >= 3 and streak_bonuses.has(3):
		streak_bonus = streak_bonuses[3]
	elif player.win_streak >= 2 and streak_bonuses.has(2):
		streak_bonus = streak_bonuses[2]
	elif player.lose_streak >= 5 and streak_bonuses.has(5):
		streak_bonus = streak_bonuses[5]
	elif player.lose_streak >= 3 and streak_bonuses.has(3):
		streak_bonus = streak_bonuses[3]
	elif player.lose_streak >= 2 and streak_bonuses.has(2):
		streak_bonus = streak_bonuses[2]

	income += streak_bonus

	# 应用难度修正
	income = int(income * economy_params.difficulty_modifier)

	# 破产保护
	if economy_params.bankruptcy_protection and player.current_health < 20 and player.gold == 0:
		income = max(income, 5)  # 至少获得5金币

	# 保底收入
	income = max(income, 2)  # 每回合至少获得2金币

	# 检查遗物效果
	income = _apply_relic_effects_to_income(player, income)

	return income

# 获取经济参数
func get_economy_params() -> Dictionary:
	return economy_params

# 设置经济参数
func set_economy_params(params: Dictionary) -> void:
	for key in params:
		if economy_params.has(key):
			economy_params[key] = params[key]

# 获取当前刷新费用
func get_refresh_cost() -> int:
	return economy_params.shop_refresh_cost

# 获取当前经验购买费用
func get_exp_purchase_cost() -> int:
	return economy_params.exp_purchase_cost

# 获取当前经验购买数量
func get_exp_purchase_amount() -> int:
	return economy_params.exp_purchase_amount

# 保存经济状态
func save_economy_state() -> Dictionary:
	return economy_params.duplicate(true)

# 加载经济状态
func load_economy_state(state: Dictionary) -> void:
	set_economy_params(state)

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 计算并发放回合收入
	var player = player_manager.get_current_player()
	if player:
		# 计算回合收入
		var income = calculate_round_income(player)

		# 发放收入
		player.add_gold(income)

		# 发送收入发放信号
		EventBus.economy.income_granted.emit(income)

		# 添加自动经验
		player.add_exp(2)

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	# 记录刷新次数统计
	var stats_manager = get_node("/root/GameManager/StatsManager")
	if stats_manager:
		stats_manager.increment_stat("shop_refreshes")

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 记录购买统计
	var stats_manager = get_node("/root/GameManager/StatsManager")
	if stats_manager:
		stats_manager.increment_stat("items_purchased")

		# 根据物品类型记录不同的统计
		if item_data.has("type"):
			match item_data.type:
				"chess_piece":
					stats_manager.increment_stat("chess_pieces_purchased")
				"equipment":
					stats_manager.increment_stat("equipments_purchased")
				"exp":
					stats_manager.increment_stat("exp_purchased")

# 物品出售事件处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 记录出售统计
	var stats_manager = get_node("/root/GameManager/StatsManager")
	if stats_manager:
		stats_manager.increment_stat("items_sold")

		# 根据物品类型记录不同的统计
		if item_data.has("type"):
			match item_data.type:
				"chess_piece":
					stats_manager.increment_stat("chess_pieces_sold")
				"equipment":
					stats_manager.increment_stat("equipments_sold")

# 应用遗物效果到收入
func _apply_relic_effects_to_income(player: Player, base_income: int) -> int:
	var modified_income = base_income

	# 获取玩家遗物
	var relic_manager = get_node("/root/GameManager/RelicManager")
	if relic_manager == null or player == null:
		return modified_income

	# 遍历玩家遗物，检查收入相关效果
	var player_relics = relic_manager.get_player_relics()
	for relic in player_relics:
		# 检查遗物效果
		for effect in relic.effects:
			if effect.has("type") and effect.type == "income_boost":
				# 收入提升效果
				if effect.has("value"):
					if effect.has("is_percentage") and effect.is_percentage:
						# 百分比提升
						modified_income += int(base_income * effect.value)
					else:
						# 固定值提升
						modified_income += effect.value

	return modified_income

# 加载难度设置
func _load_difficulty_settings() -> void:
	# 获取当前难度级别
	var game_manager = get_node("/root/GameManager")
	if game_manager == null:
		return

	var difficulty_level = game_manager.difficulty_level

	# 加载难度配置
	var difficulty_config = config_manager.difficulty_config
	if difficulty_config == null or not difficulty_config.has("economy"):
		return

	var economy_config = difficulty_config.economy

	# 根据难度级别调整经济参数
	match difficulty_level:
		1: # 简单
			economy_params.difficulty_modifier = economy_config.get("easy_modifier", 1.2)
			economy_params.bankruptcy_protection = true
		2: # 正常
			economy_params.difficulty_modifier = economy_config.get("normal_modifier", 1.0)
			economy_params.bankruptcy_protection = true
		3: # 困难
			economy_params.difficulty_modifier = economy_config.get("hard_modifier", 0.8)
			economy_params.bankruptcy_protection = false
		_: # 默认
			economy_params.difficulty_modifier = 1.0
			economy_params.bankruptcy_protection = true

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int) -> void:
	# 重新加载难度设置
	_load_difficulty_settings()

# 重置管理器
func reset() -> void:
	# 重置经济参数
	economy_params = {
		"base_income": BASE_INCOME,
		"max_interest": MAX_INTEREST,
		"streak_bonus": STREAK_BONUS.duplicate(),
		"shop_refresh_cost": SHOP_REFRESH_COST,
		"exp_purchase_cost": EXP_PURCHASE_COST,
		"exp_purchase_amount": EXP_PURCHASE_AMOUNT,
		"difficulty_modifier": 1.0,
		"bankruptcy_protection": true
	}

	# 重新加载难度设置
	_load_difficulty_settings()

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
