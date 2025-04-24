extends "res://scripts/managers/core/base_manager.gd"
class_name ShopManager
## 商店管理器
## 管理商店系统

# 引入常量
const SC = preload("res://scripts/constants/shop_constants.gd")

# 商店系统
var shop_system: ShopSystem = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ShopManager"

	# 添加依赖
	add_dependency("ConfigManager")
	add_dependency("PlayerManager")
	add_dependency("EconomyManager")
	add_dependency("EquipmentManager")
	add_dependency("ChessManager")
	add_dependency("RelicManager")

	# 创建商店系统
	shop_system = ShopSystem.new()
	add_child(shop_system)

	# 连接商店系统信号
	shop_system.shop_refreshed.connect(_on_shop_refreshed)
	shop_system.item_purchased.connect(_on_item_purchased)
	shop_system.item_sold.connect(_on_item_sold)
	shop_system.discount_applied.connect(_on_discount_applied)
	
	# 连接游戏事件
	GlobalEventBus.battle.add_listener("battle_round_started", _on_battle_round_started)
	GlobalEventBus.map.add_listener("map_node_selected", _on_map_node_selected)
	GlobalEventBus.game.add_listener("difficulty_changed", _on_difficulty_changed)

	_log_info("商店管理器初始化完成")

# 刷新商店
func refresh_shop(force: bool = false) -> bool:
	return shop_system.refresh_all_shops(force)

# 手动刷新商店
func manual_refresh_shop() -> bool:
	return shop_system.manual_refresh_shop()

# 切换商店锁定状态
func toggle_shop_lock() -> bool:
	return shop_system.toggle_shop_lock()

# 应用折扣
func apply_discount(discount_rate: float) -> void:
	shop_system.apply_discount(discount_rate)

# 购买棋子
func purchase_chess(chess_index: int):
	return shop_system.purchase_item(SC.ShopType.CHESS, chess_index)

# 购买装备
func purchase_equipment(equipment_index: int) -> Equipment:
	return shop_system.purchase_item(SC.ShopType.EQUIPMENT, equipment_index)

# 购买经验
func purchase_exp() -> bool:
	return shop_system.purchase_item(SC.ShopType.EXP, 0)

# 获取当前棋子价格
func get_current_chess_cost(chess_piece) -> int:
	return shop_system._price_calculators[SC.ShopType.CHESS].calculate_price(chess_piece)

# 获取当前装备价格
func get_current_equipment_cost(equipment) -> int:
	return shop_system._price_calculators[SC.ShopType.EQUIPMENT].calculate_price(equipment)

# 获取当前遗物价格
func get_current_relic_cost(relic) -> int:
	return shop_system._price_calculators[SC.ShopType.RELIC].calculate_price(relic)

# 获取商店参数
func get_shop_params() -> Dictionary:
	return shop_system.get_shop_params()

# 购买遗物
func purchase_relic(relic_index: int) -> Relic:
	return shop_system.purchase_item(SC.ShopType.RELIC, relic_index)

# 出售棋子
func sell_chess(chess_id: String) -> bool:
	return shop_system.sell_item(SC.ShopType.CHESS, chess_id)

# 出售装备
func sell_equipment(equipment_id: String) -> bool:
	return shop_system.sell_item(SC.ShopType.EQUIPMENT, equipment_id)

# 获取商店物品
func get_shop_items() -> Dictionary:
	var result = {}
	result["chess"] = shop_system.get_shop_items(SC.ShopType.CHESS)
	result["equipment"] = shop_system.get_shop_items(SC.ShopType.EQUIPMENT)
	result["relic"] = shop_system.get_shop_items(SC.ShopType.RELIC)
	return result

# 商店刷新事件处理
func _on_shop_refreshed(shop_type) -> void:
	# 发送商店刷新事件
	GlobalEventBus.shop.dispatch_event(EconomyEvents.ShopRefreshedEvent.new("todo",shop_type))

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 发送物品购买事件
	GlobalEventBus.economy.dispatch_event(EconomyEvents.ItemPurchasedEvent.new("todo","todo",item_data,0))

# 物品出售事件处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 发送物品出售事件
	GlobalEventBus.economy.dispatch_event(EconomyEvents.ItemSoldEvent.new("todo",item_data,0))

# 折扣应用事件处理
func _on_discount_applied(discount_rate: float) -> void:
	# 发送折扣应用事件
	GlobalEventBus.shop.dispatch_event(EconomyEvents.ShopDiscountAppliedEvent.new("todo",discount_rate))

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 检查黑市商人触发
	if round_number % 3 == 0 and randf() < SC.BLACK_MARKET_CHANCE:
		trigger_black_market()

	# 检查装备商店触发
	if SC.EQUIPMENT_SHOP_ROUNDS.has(round_number):
		shop_system.trigger_equipment_shop()

	# 检查遗物商店触发
	if SC.RELIC_SHOP_ROUNDS.has(round_number):
		shop_system.trigger_relic_shop()

	# 刷新商店
	refresh_shop(true)

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 检查是否是商店节点
	if node_data.type == "shop":
		# 应用商店节点特性
		if node_data.has("discount") and node_data.discount:
			# 应用折扣
			apply_discount(SC.NODE_DISCOUNT)
		else:
			# 重置折扣
			apply_discount(SC.DEFAULT_DISCOUNT)

		# 检查是否是特殊商店
		if node_data.has("shop_type"):
			match node_data.shop_type:
				"black_market":
					trigger_black_market()
				"mystery_shop":
					trigger_mystery_shop()
				"equipment_shop":
					shop_system.trigger_equipment_shop()

		# 刷新商店
		refresh_shop(true)

	# 检查是否是精英战斗节点
	elif node_data.type == "elite_battle" and node_data.has("result") and node_data.result == "victory":
		# 检查神秘商店触发
		if randf() < SC.MYSTERY_SHOP_CHANCE:
			trigger_mystery_shop()
			refresh_shop(true)

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int) -> void:
	# 同步商店系统的经济参数
	# 让商店系统处理难度变化
	pass

# 触发黑市商店
func trigger_black_market() -> void:
	shop_system.trigger_black_market()

# 触发神秘商店
func trigger_mystery_shop() -> void:
	shop_system.trigger_mystery_shop()


# 重写清理方法
func _do_cleanup() -> void:
	# 断开商店系统信号
	if shop_system:
		shop_system.shop_refreshed.disconnect(_on_shop_refreshed)
		shop_system.item_purchased.disconnect(_on_item_purchased)
		shop_system.item_sold.disconnect(_on_item_sold)
		shop_system.discount_applied.disconnect(_on_discount_applied)

		# 清理商店系统
		shop_system.cleanup()
		shop_system.queue_free()
		shop_system = null

	_log_info("商店管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 重置商店系统
	if shop_system:
		shop_system.reset()

	_log_info("商店管理器重置完成")
