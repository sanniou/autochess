extends Node
class_name ShopManager
## 商店管理器
## 管理商店物品的生成、购买和刷新

# 常量
const MAX_CHESS_ITEMS = 5  # 最大棋子商品数
const MAX_EQUIPMENT_ITEMS = 3  # 最大装备商品数
const DEFAULT_REFRESH_COST = 2  # 默认刷新费用
const DEFAULT_EQUIPMENT_COST = 3  # 默认装备价格

# 商店参数
var shop_params = {
	"refresh_cost": DEFAULT_REFRESH_COST,  # 刷新费用
	"equipment_cost": DEFAULT_EQUIPMENT_COST,  # 装备固定价格
	"discount_rate": 1.0,  # 折扣率，1.0表示无折扣
	"max_chess_items": MAX_CHESS_ITEMS,  # 最大棋子商品数
	"max_equipment_items": MAX_EQUIPMENT_ITEMS,  # 最大装备商品数
	"special_offer": false  # 是否有特价商品
}

# 商店状态
var is_locked = false

# 商店物品
var shop_items = {
	"chess": [],
	"equipment": []
}

# 获取商店物品
func get_shop_items() -> Dictionary:
	return shop_items

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var economy_manager = get_node("/root/GameManager/EconomyManager")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var config_manager = get_node("/root/ConfigManager")

# 初始化
func _ready() -> void:
	# 连接信号
	EventBus.battle_round_started.connect(_on_battle_round_started)
	EventBus.shop_refreshed.connect(_on_shop_refreshed)
	EventBus.map_node_selected.connect(_on_map_node_selected)
	EventBus.difficulty_changed.connect(_on_difficulty_changed)

	# 从经济管理器同步参数
	_sync_with_economy_manager()

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

	# 获取当前刷新费用
	var refresh_cost = get_current_refresh_cost()

	# 检查金币是否足够
	if player.gold < refresh_cost:
		return false

	# 扣除金币
	if player.spend_gold(refresh_cost):
		# 刷新商店
		var result = refresh_shop()

		# 发送刷新事件
		if result:
			EventBus.shop_manually_refreshed.emit(refresh_cost)

		return result

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

	# 获取当前棋子价格
	var chess_cost = get_current_chess_cost(chess_data)

	# 检查金币是否足够
	if player.gold < chess_cost:
		return null

	# 扣除金币
	if player.spend_gold(chess_cost):
		# 创建棋子实例
		var chess_factory = get_node("/root/GameManager/ChessFactory")
		if chess_factory == null:
			# 退还金币
			player.add_gold(chess_cost)
			return null

		var chess_piece = chess_factory.create_chess_piece(chess_data.id)
		if chess_piece == null:
			# 退还金币
			player.add_gold(chess_cost)
			return null

		# 添加到玩家棋子列表
		if player.add_chess_piece(chess_piece):
			# 从商店移除
			shop_items.chess.remove_at(chess_index)

			# 添加购买类型信息
			var purchase_data = chess_data.duplicate()
			purchase_data["type"] = "chess_piece"
			purchase_data["cost"] = chess_cost

			# 发送物品购买信号
			EventBus.item_purchased.emit(purchase_data)

			return chess_piece
		else:
			# 添加失败，退还金币
			player.add_gold(chess_cost)

	return null

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

	# 获取当前装备价格
	var equipment_cost = get_current_equipment_cost(equipment_data)

	# 检查金币是否足够
	if player.gold < equipment_cost:
		return null

	# 扣除金币
	if player.spend_gold(equipment_cost):
		# 获取装备实例
		var equipment = equipment_manager.get_equipment(equipment_id)
		if equipment == null:
			# 退还金币
			player.add_gold(equipment_cost)
			return null

		# 添加到玩家装备列表
		if player.add_equipment(equipment):
			# 从商店移除
			shop_items.equipment.remove_at(equipment_index)

			# 添加购买类型信息
			var purchase_data = equipment_data.duplicate()
			purchase_data["type"] = "equipment"
			purchase_data["cost"] = equipment_cost

			# 发送物品购买信号
			EventBus.item_purchased.emit(purchase_data)

			return equipment
		else:
			# 添加失败，退还金币
			player.add_gold(equipment_cost)

	return null

# 购买经验
func purchase_exp() -> bool:
	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return false

	# 获取当前经验价格和数量
	var exp_cost = get_current_exp_cost()
	var exp_amount = economy_manager.get_exp_purchase_amount()

	# 检查金币是否足够
	if player.gold < exp_cost:
		return false

	# 扣除金币
	if player.spend_gold(exp_cost):
		# 添加经验
		player.add_exp(exp_amount)

		# 添加购买类型信息
		var purchase_data = {
			"type": "exp",
			"cost": exp_cost,
			"amount": exp_amount
		}

		# 发送物品购买信号
		EventBus.item_purchased.emit(purchase_data)

		return true

	return false

# 出售棋子
func sell_chess(chess_piece: ChessPiece) -> bool:
	# 检查棋子是否有效
	if chess_piece == null:
		return false

	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return false

	# 获取棋子数据
	var chess_id = chess_piece.id
	var chess_data = config_manager.get_chess_piece(chess_id)
	if chess_data == null:
		return false

	# 计算出售价格（通常是原价格的一半）
	var sell_price = int(chess_data.cost * 0.5)

	# 从玩家棋子列表中移除
	if player.remove_chess_piece(chess_piece):
		# 添加金币
		player.add_gold(sell_price)

		# 添加出售类型信息
		var sell_data = chess_data.duplicate()
		sell_data["type"] = "chess_piece"
		sell_data["price"] = sell_price

		# 发送物品出售信号
		EventBus.item_sold.emit(sell_data)

		return true

	return false

# 出售装备
func sell_equipment(equipment: Equipment) -> bool:
	# 检查装备是否有效
	if equipment == null:
		return false

	# 获取当前玩家
	var player = player_manager.get_current_player()
	if player == null:
		return false

	# 获取装备数据
	var equipment_id = equipment.id
	var equipment_data = config_manager.get_equipment(equipment_id)
	if equipment_data == null:
		return false

	# 计算出售价格（通常是原价格的一半）
	var sell_price = int(shop_params.equipment_cost * 0.5)

	# 从玩家装备列表中移除
	if player.remove_equipment(equipment):
		# 添加金币
		player.add_gold(sell_price)

		# 添加出售类型信息
		var sell_data = equipment_data.duplicate()
		sell_data["type"] = "equipment"
		sell_data["price"] = sell_price

		# 发送物品出售信号
		EventBus.item_sold.emit(sell_data)

		return true

	return false

# 获取当前刷新费用
func get_current_refresh_cost() -> int:
	if economy_manager:
		return int(economy_manager.get_refresh_cost() * shop_params.discount_rate)
	else:
		return int(shop_params.refresh_cost * shop_params.discount_rate)

# 获取当前棋子价格
func get_current_chess_cost(chess_data: Dictionary) -> int:
	var base_cost = chess_data.cost
	return int(base_cost * shop_params.discount_rate)

# 获取当前装备价格
func get_current_equipment_cost(equipment_data: Dictionary) -> int:
	return int(shop_params.equipment_cost * shop_params.discount_rate)

# 获取当前经验价格
func get_current_exp_cost() -> int:
	if economy_manager:
		return int(economy_manager.get_exp_purchase_cost() * shop_params.discount_rate)
	else:
		return int(DEFAULT_REFRESH_COST * shop_params.discount_rate)

# 应用折扣
func apply_discount(discount_rate: float) -> void:
	# 确保折扣率在合理范围内
	discount_rate = clamp(discount_rate, 0.1, 2.0)

	# 设置折扣率
	shop_params.discount_rate = discount_rate

	# 发送折扣应用信号
	EventBus.shop_discount_applied.emit(discount_rate)

# 添加特定物品
func add_specific_item(item_id: String) -> bool:
	# 检查是否是棋子
	var chess_data = config_manager.get_chess_piece(item_id)
	if chess_data != null:
		shop_items.chess.append(chess_data)
		return true

	# 检查是否是装备
	if config_manager.get_equipment(item_id) != null:
		shop_items.equipment.append(item_id)
		return true

	return false

# 获取商店物品
func get_shop_items() -> Dictionary:
	return shop_items.duplicate(true)

# 获取商店参数
func get_shop_params() -> Dictionary:
	return shop_params.duplicate(true)

# 设置商店参数
func set_shop_params(params: Dictionary) -> void:
	# 更新商店参数
	for key in params:
		if shop_params.has(key):
			shop_params[key] = params[key]

# 生成棋子商品
func _generate_chess_items(player_level: int) -> void:
	shop_items.chess.clear()

	# 获取棋子池
	var chess_pool = _get_chess_pool_by_level(player_level)

	# 随机选择棋子
	var selected_chess = []
	for i in range(shop_params.max_chess_items):
		if chess_pool.size() > 0:
			var index = randi() % chess_pool.size()
			selected_chess.append(chess_pool[index])
			chess_pool.remove_at(index)

	shop_items.chess = selected_chess

# 生成装备商品
func _generate_equipment_items(player_level: int) -> void:
	shop_items.equipment.clear()

	# 使用装备管理器刷新商店库存
	if equipment_manager:
		equipment_manager.refresh_shop_inventory(shop_params.max_equipment_items, player_level)
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

# 从经济管理器同步参数
func _sync_with_economy_manager() -> void:
	if economy_manager:
		shop_params.refresh_cost = economy_manager.get_refresh_cost()
		shop_params.equipment_cost = economy_manager.get_economy_params().get("equipment_cost", DEFAULT_EQUIPMENT_COST)

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 刷新商店
	refresh_shop(true)

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	# 记录刷新次数统计
	var stats_manager = get_node("/root/GameManager/StatsManager")
	if stats_manager:
		stats_manager.increment_stat("shop_refreshes")

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 检查是否是商店节点
	if node_data.type == "shop":
		# 应用商店节点特性
		if node_data.has("discount") and node_data.discount:
			# 应用折扣
			apply_discount(0.8)  # 80%折扣
		else:
			# 重置折扣
			apply_discount(1.0)

		# 刷新商店
		refresh_shop(true)

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int) -> void:
	# 重新同步经济参数
	_sync_with_economy_manager()

# 重置管理器
func reset() -> void:
	# 重置商店状态
	is_locked = false
	shop_items = {
		"chess": [],
		"equipment": []
	}

	# 重置商店参数
	shop_params = {
		"refresh_cost": DEFAULT_REFRESH_COST,
		"equipment_cost": DEFAULT_EQUIPMENT_COST,
		"discount_rate": 1.0,
		"max_chess_items": MAX_CHESS_ITEMS,
		"max_equipment_items": MAX_EQUIPMENT_ITEMS,
		"special_offer": false
	}

	# 从经济管理器同步参数
	_sync_with_economy_manager()
