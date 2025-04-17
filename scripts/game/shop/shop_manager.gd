extends "res://scripts/core/base_manager.gd"
class_name ShopManager
## 商店管理器
## 负责商店物品的生成、刷新和购买

# 商店相关常量
const MAX_SHOP_TIER = 3  # 最大商店等级
const REFRESH_COST = 2  # 刷新商店的金币消耗

# 商店数据
var current_shop_items = []  # 当前商店物品
var shop_tier = 1  # 商店等级
var shop_discount = 0.0  # 商店折扣
var refresh_count = 0  # 刷新次数

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var chess_factory = get_node("/root/GameManager/ChessFactory")

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ShopManager"
	
	# 原 _ready 函数的内容
	# 连接信号
		EventBus.map.map_node_selected.connect(_on_map_node_selected)
	
	# 生成商店物品
func generate_shop_items(tier: int = 1, has_discount: bool = false) -> Array:
	# 设置商店等级
	shop_tier = clamp(tier, 1, MAX_SHOP_TIER)
	
	# 设置商店折扣
	shop_discount = 0.2 if has_discount else 0.0
	
	# 清空当前商店物品
	current_shop_items.clear()
	
	# 生成装备物品
	var equipment_count = 3
	for i in range(equipment_count):
		var equipment = _generate_equipment_item()
		if equipment:
			current_shop_items.append(equipment)
	
	# 生成棋子物品
	var chess_count = 3
	for i in range(chess_count):
		var chess = _generate_chess_item()
		if chess:
			current_shop_items.append(chess)
	
	# 生成消耗品
	var consumable_count = 1
	for i in range(consumable_count):
		var consumable = _generate_consumable_item()
		if consumable:
			current_shop_items.append(consumable)
	
	# 应用折扣
	if has_discount:
		_apply_discount()
	
	return current_shop_items

# 生成装备物品
func _generate_equipment_item() -> Dictionary:
	# 获取随机装备
	var equipment = equipment_manager.generate_random_equipment("", shop_tier)
	if not equipment:
		return {}
	
	# 计算价格
	var base_price = 20 + shop_tier * 10
	var rarity_multiplier = 1.0
	match equipment.rarity:
		"common": rarity_multiplier = 1.0
		"uncommon": rarity_multiplier = 1.5
		"rare": rarity_multiplier = 2.0
		"epic": rarity_multiplier = 3.0
		"legendary": rarity_multiplier = 5.0
	
	var price = int(base_price * rarity_multiplier)
	
	# 创建商店物品
	return {
		"id": equipment.id,
		"name": equipment.display_name,
		"type": "equipment",
		"description": equipment.description,
		"price": price,
		"rarity": equipment.rarity,
		"tier": shop_tier
	}

# 生成棋子物品
func _generate_chess_item() -> Dictionary:
	# 获取所有棋子配置
	var chess_configs = config_manager.get_all_chess_pieces()
	
	# 筛选符合等级的棋子
	var eligible_chess = []
	for id in chess_configs:
		var config = chess_configs[id]
		if config.cost <= shop_tier + 1:
			eligible_chess.append(id)
	
	# 如果没有符合条件的棋子，返回空
	if eligible_chess.is_empty():
		return {}
	
	# 随机选择一个棋子
	var chess_id = eligible_chess[randi() % eligible_chess.size()]
	var chess_config = chess_configs[chess_id]
	
	# 计算价格
	var price = chess_config.cost * 3
	
	# 创建商店物品
	return {
		"id": chess_id,
		"name": chess_config.name,
		"type": "chess_piece",
		"description": "一个可用的棋子",
		"price": price,
		"cost": chess_config.cost,
		"synergies": chess_config.synergies
	}

# 生成消耗品物品
func _generate_consumable_item() -> Dictionary:
	# 消耗品类型
	var consumable_types = [
		{
			"id": "health_potion",
			"name": "生命药水",
			"description": "恢复20点生命值",
			"price": 15,
			"effect": {"type": "heal", "amount": 20}
		},
		{
			"id": "strength_potion",
			"name": "力量药水",
			"description": "临时提升所有棋子10%攻击力",
			"price": 25,
			"effect": {"type": "buff", "stat": "attack", "amount": 0.1, "duration": 3}
		},
		{
			"id": "refresh_scroll",
			"name": "刷新卷轴",
			"description": "免费刷新商店一次",
			"price": 10,
			"effect": {"type": "refresh", "free": true}
		}
	]
	
	# 随机选择一个消耗品
	var consumable = consumable_types[randi() % consumable_types.size()]
	
	# 根据商店等级调整价格
	consumable.price += (shop_tier - 1) * 5
	
	# 创建商店物品
	return {
		"id": consumable.id,
		"name": consumable.name,
		"type": "consumable",
		"description": consumable.description,
		"price": consumable.price,
		"effect": consumable.effect
	}

# 应用折扣
func _apply_discount() -> void:
	for item in current_shop_items:
		item.price = int(item.price * (1.0 - shop_discount))

# 刷新商店
func refresh_shop(player_gold: int, free_refresh: bool = false) -> bool:
	# 检查金币是否足够
	if not free_refresh and player_gold < REFRESH_COST:
		return false
	
	# 增加刷新次数
	refresh_count += 1
	
	# 生成新的商店物品
	generate_shop_items(shop_tier, shop_discount > 0)
	
	# 发送商店刷新信号
	EventBus.economy.shop_refreshed.emit(current_shop_items)
	
	return true

# 购买物品
func purchase_item(item_index: int, player_gold: int) -> Dictionary:
	# 检查索引是否有效
	if item_index < 0 or item_index >= current_shop_items.size():
		return {}
	
	# 获取物品
	var item = current_shop_items[item_index]
	
	# 检查金币是否足够
	if player_gold < item.price:
		return {}
	
	# 从商店中移除物品
	var purchased_item = current_shop_items[item_index]
	current_shop_items.remove_at(item_index)
	
	# 发送物品购买信号
	EventBus.economy.shop_item_purchased.emit(purchased_item)
	
	return purchased_item

# 设置商店等级
func set_shop_tier(tier: int) -> void:
	shop_tier = clamp(tier, 1, MAX_SHOP_TIER)

# 设置商店折扣
func set_shop_discount(discount: float) -> void:
	shop_discount = clamp(discount, 0.0, 0.5)  # 最大折扣50%
	
	# 如果有商店物品，应用折扣
	if not current_shop_items.is_empty():
		_apply_discount()

# 获取商店等级
func get_shop_tier() -> int:
	return shop_tier

# 获取商店折扣
func get_shop_discount() -> float:
	return shop_discount

# 获取当前商店物品
func get_current_shop_items() -> Array:
	return current_shop_items.duplicate()

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 如果是商店节点，生成商店物品
	if node_data.type == "shop":
		_handle_shop_node(node_data)

# 处理商店节点
func _handle_shop_node(node_data: Dictionary) -> void:
	# 获取商店等级
	var tier = node_data.get("tier", 1)
	
	# 获取是否有折扣
	var has_discount = node_data.get("discount", false)
	
	# 生成商店物品
	generate_shop_items(tier, has_discount)
	
	# 发送商店打开信号
	EventBus.economy.shop_opened.emit(current_shop_items)

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
