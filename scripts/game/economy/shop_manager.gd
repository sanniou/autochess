extends Node
class_name ShopManager
## 商店管理器
## 管理商店物品的生成、购买和刷新

# 商店刷新费用
const REFRESH_COST = 2

# 装备固定价格
const EQUIPMENT_COST = 3

# 商店状态
var is_locked = false

# 商店物品
var shop_items = {
	"chess": [],
	"equipment": []
}

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var economy_manager = get_node("/root/GameManager/EconomyManager")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var config_manager = get_node("/root/ConfigManager")

func _ready():
	# 连接信号
	EventBus.battle_round_started.connect(_on_battle_round_started)
	EventBus.shop_refreshed.connect(_on_shop_refreshed)

# 刷新商店
func refresh_shop(force: bool = false) -> bool:
	# 检查是否锁定
	if is_locked and not force:
		return false
	
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return false
	
	# 生成新的棋子
	_generate_chess_items(player.level)
	
	# 生成新的装备
	_generate_equipment_items(player.level)
	
	# 发送商店刷新信号
	EventBus.shop_refreshed.emit()
	
	return true

# 手动刷新商店（需要花费金币）
func manual_refresh_shop() -> bool:
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return false
	
	# 检查金币是否足够
	if player.gold < REFRESH_COST:
		return false
	
	# 扣除金币
	if player.spend_gold(REFRESH_COST):
		# 刷新商店
		return refresh_shop()
	
	return false

# 锁定/解锁商店
func toggle_shop_lock() -> bool:
	is_locked = !is_locked
	return is_locked

# 购买棋子
func purchase_chess(chess_index: int) -> ChessPiece:
	# 检查索引是否有效
	if chess_index < 0 or chess_index >= shop_items.chess.size():
		return null
	
	# 获取棋子数据
	var chess_data = shop_items.chess[chess_index]
	
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return null
	
	# 检查金币是否足够
	if player.gold < chess_data.cost:
		return null
	
	# 购买棋子
	var chess_piece = player_manager.purchase_chess_piece(chess_data.id)
	if chess_piece != null:
		# 从商店移除
		shop_items.chess.remove_at(chess_index)
		
		# 发送物品购买信号
		EventBus.item_purchased.emit(chess_data)
	
	return chess_piece

# 购买装备
func purchase_equipment(equipment_index: int) -> Equipment:
	# 检查索引是否有效
	if equipment_index < 0 or equipment_index >= shop_items.equipment.size():
		return null
	
	# 获取装备ID
	var equipment_id = shop_items.equipment[equipment_index]
	
	# 获取装备数据
	var equipment_data = config_manager.get_equipment(equipment_id)
	if equipment_data == null:
		return null
	
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return null
	
	# 检查金币是否足够
	if player.gold < EQUIPMENT_COST:
		return null
	
	# 购买装备
	var equipment = player_manager.purchase_equipment(equipment_id)
	if equipment != null:
		# 从商店移除
		shop_items.equipment.remove_at(equipment_index)
		
		# 发送物品购买信号
		EventBus.item_purchased.emit(equipment_data)
	
	return equipment

# 生成棋子商品
func _generate_chess_items(player_level: int) -> void:
	shop_items.chess.clear()
	
	# 获取棋子池
	var chess_pool = _get_chess_pool_by_level(player_level)
	
	# 随机选择5个棋子
	var selected_chess = []
	for i in range(5):
		if chess_pool.size() > 0:
			var index = randi() % chess_pool.size()
			selected_chess.append(chess_pool[index])
			chess_pool.remove_at(index)
	
	shop_items.chess = selected_chess

# 生成装备商品
func _generate_equipment_items(player_level: int) -> void:
	# 使用装备管理器刷新商店库存
	if equipment_manager:
		equipment_manager.refresh_shop_inventory(3, player_level)
		shop_items.equipment = equipment_manager.get_shop_inventory()

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

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	# 这里可以处理商店刷新后的逻辑
	pass

# 重置管理器
func reset() -> void:
	is_locked = false
	shop_items = {
		"chess": [],
		"equipment": []
	}
