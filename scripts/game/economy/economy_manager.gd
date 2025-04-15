extends Node
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

# 当前商店状态
var shop_state = {
	"chess_pieces": [],
	"equipments": [],
	"is_locked": false
}

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var config_manager = get_node("/root/ConfigManager")

func _ready():
	# 连接信号
	EventBus.battle_round_started.connect(_on_battle_round_started)
	EventBus.shop_refreshed.connect(_on_shop_refreshed)
	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.item_sold.connect(_on_item_sold)

# 计算回合收入
func calculate_round_income(player: Player) -> int:
	var income = BASE_INCOME
	
	# 计算利息 (每10金币1金币，最多5金币)
	var interest = min(MAX_INTEREST, player.gold / 10)
	income += interest
	
	# 计算连胜/连败奖励
	var streak_bonus = 0
	if player.win_streak >= 5:
		streak_bonus = STREAK_BONUS[5]
	elif player.win_streak >= 3:
		streak_bonus = STREAK_BONUS[3]
	elif player.win_streak >= 2:
		streak_bonus = STREAK_BONUS[2]
	elif player.lose_streak >= 5:
		streak_bonus = STREAK_BONUS[5]
	elif player.lose_streak >= 3:
		streak_bonus = STREAK_BONUS[3]
	elif player.lose_streak >= 2:
		streak_bonus = STREAK_BONUS[2]
	
	income += streak_bonus
	
	# 破产保护
	if player.current_health < 20 and player.gold == 0:
		income = max(income, 5)  # 至少获得5金币
	
	# 保底收入
	income = max(income, 2)  # 每回合至少获得2金币
	
	return income

# 刷新商店
func refresh_shop(force: bool = false) -> void:
	# 检查是否锁定
	if shop_state.is_locked and not force:
		return
	
	var player = player_manager.get_current_player()
	if player == null:
		return
	
	# 生成新的棋子
	_generate_chess_shop_items(player.level)
	
	# 生成新的装备
	_generate_equipment_shop_items(player.level)
	
	# 发送商店刷新信号
	EventBus.shop_refreshed.emit()

# 锁定/解锁商店
func toggle_shop_lock() -> bool:
	shop_state.is_locked = !shop_state.is_locked
	return shop_state.is_locked

# 获取商店状态
func get_shop_state() -> Dictionary:
	return shop_state

# 保存商店状态
func save_shop_state() -> void:
	# 这里可以保存商店状态到存档
	pass

# 加载商店状态
func load_shop_state(state: Dictionary) -> void:
	shop_state = state

# 生成棋子商店物品
func _generate_chess_shop_items(player_level: int) -> void:
	shop_state.chess_pieces.clear()
	
	# 获取棋子池
	var chess_pool = _get_chess_pool_by_level(player_level)
	
	# 随机选择5个棋子
	var selected_chess = []
	for i in range(5):
		if chess_pool.size() > 0:
			var index = randi() % chess_pool.size()
			selected_chess.append(chess_pool[index])
			chess_pool.remove_at(index)
	
	shop_state.chess_pieces = selected_chess

# 生成装备商店物品
func _generate_equipment_shop_items(player_level: int) -> void:
	# 使用装备管理器刷新商店库存
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")
	if equipment_manager:
		equipment_manager.refresh_shop_inventory(3, player_level)
		shop_state.equipments = equipment_manager.get_shop_inventory()

# 根据玩家等级获取棋子池
func _get_chess_pool_by_level(player_level: int) -> Array:
	var all_chess = config_manager.get_all_chess_pieces()
	var chess_pool = []
	
	# 根据等级设置不同费用棋子的出现概率
	var probabilities = _get_chess_probabilities(player_level)
	
	# 根据概率填充棋子池
	for chess_id in all_chess:
		var chess = all_chess[chess_id]
		var cost = chess.cost
		
		# 检查该费用的棋子是否可以出现
		if probabilities.has(cost) and probabilities[cost] > 0:
			# 根据概率添加到池中
			var count = int(100 * probabilities[cost] / _get_chess_pool_size(cost))
			for i in range(count):
				chess_pool.append(chess)
	
	return chess_pool

# 获取棋子概率表
func _get_chess_probabilities(player_level: int) -> Dictionary:
	# 根据玩家等级返回不同费用棋子的出现概率
	match player_level:
		1: return {1: 1.00, 2: 0.00, 3: 0.00, 4: 0.00, 5: 0.00}
		2: return {1: 0.60, 2: 0.30, 3: 0.10, 4: 0.00, 5: 0.00}
		3: return {1: 0.50, 2: 0.35, 3: 0.15, 4: 0.00, 5: 0.00}
		4: return {1: 0.35, 2: 0.35, 3: 0.25, 4: 0.05, 5: 0.00}
		5: return {1: 0.20, 2: 0.30, 3: 0.30, 4: 0.15, 5: 0.05}
		6: return {1: 0.15, 2: 0.20, 3: 0.30, 4: 0.25, 5: 0.10}
		7, 8, 9: return {1: 0.10, 2: 0.15, 3: 0.25, 4: 0.30, 5: 0.20}
		_: return {1: 1.00, 2: 0.00, 3: 0.00, 4: 0.00, 5: 0.00}

# 获取棋子池大小
func _get_chess_pool_size(cost: int) -> int:
	# 不同费用的棋子池大小
	match cost:
		1: return 39  # 1费棋子：每类39个
		2: return 26  # 2费棋子：每类26个
		3: return 18  # 3费棋子：每类18个
		4: return 12  # 4费棋子：每类12个
		5: return 10  # 5费棋子：每类10个
		_: return 39
	
# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 刷新商店
	refresh_shop(true)
	
	# 计算并发放回合收入
	var player = player_manager.get_current_player()
	if player:
		player.on_round_start()

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	# 这里可以处理商店刷新后的逻辑
	pass

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 这里可以处理物品购买后的逻辑
	pass

# 物品出售事件处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 这里可以处理物品出售后的逻辑
	pass

# 重置管理器
func reset() -> void:
	shop_state = {
		"chess_pieces": [],
		"equipments": [],
		"is_locked": false
	}
