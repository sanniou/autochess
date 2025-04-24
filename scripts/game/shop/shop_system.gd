extends Node
class_name ShopSystem
## 商店系统
## 统一管理所有商店相关功能

# 引入常量
const SC = preload("res://scripts/constants/shop_constants.gd")

# 信号
signal shop_refreshed(shop_type)
signal item_purchased(item_data)
signal item_sold(item_data)
signal discount_applied(discount_rate)

# 商店状态
var is_locked: bool = false

# 商店组件
var _item_generators: Dictionary = {}
var _price_calculators: Dictionary = {}
var _shops: Dictionary = {}
var _event_handler: ShopEventHandler

# 初始化
func _init():
	# 创建事件处理器
	_event_handler = ShopEventHandler.new()
	add_child(_event_handler)

	# 初始化商店组件
	_initialize_components()

	# 连接事件处理器信号
	_event_handler.shop_refresh_requested.connect(_on_shop_refresh_requested)
	_event_handler.battle_round_started.connect(_on_battle_round_started)
	_event_handler.map_node_selected.connect(_on_map_node_selected)
	_event_handler.difficulty_changed.connect(_on_difficulty_changed)

# 初始化商店组件
func _initialize_components():
	# 创建物品生成器
	_item_generators[SC.ShopType.CHESS] = ChessItemGenerator.new()
	_item_generators[SC.ShopType.EQUIPMENT] = EquipmentItemGenerator.new()
	_item_generators[SC.ShopType.RELIC] = RelicItemGenerator.new()

	# 创建价格计算器
	_price_calculators[SC.ShopType.CHESS] = ChessPriceCalculator.new()
	_price_calculators[SC.ShopType.EQUIPMENT] = EquipmentPriceCalculator.new()
	_price_calculators[SC.ShopType.RELIC] = RelicPriceCalculator.new()

	# 创建商店
	_shops[SC.ShopType.CHESS] = ChessShop.new(_item_generators[SC.ShopType.CHESS], _price_calculators[SC.ShopType.CHESS])
	_shops[SC.ShopType.EQUIPMENT] = EquipmentShop.new(_item_generators[SC.ShopType.EQUIPMENT], _price_calculators[SC.ShopType.EQUIPMENT])
	_shops[SC.ShopType.RELIC] = RelicShop.new(_item_generators[SC.ShopType.RELIC], _price_calculators[SC.ShopType.RELIC])
	_shops[SC.ShopType.EXP] = ExpShop.new(_price_calculators[SC.ShopType.CHESS])  # 使用棋子价格计算器作为占位
	_shops[SC.ShopType.BLACK_MARKET] = BlackMarketShop.new(_item_generators, _price_calculators)
	_shops[SC.ShopType.MYSTERY_SHOP] = MysteryShop.new(_item_generators, _price_calculators)

	# 添加商店为子节点
	for shop in _shops.values():
		add_child(shop)

		# 连接商店信号
		shop.item_purchased.connect(_on_item_purchased)
		shop.item_sold.connect(_on_item_sold)

# 刷新商店
func refresh_shop(shop_type: SC.ShopType, force: bool = false) -> bool:
	# 检查是否锁定
	if is_locked and not force:
		return false

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 刷新指定商店
	var shop = _shops[shop_type]
	var result = shop.refresh(player.level)

	if result:
		# 发送商店刷新信号
		shop_refreshed.emit(shop_type)
		GlobalEventBus.economy.dispatch_event(EconomyEvents.ShopRefreshedEvent.new(str(shop_type),result))

	return result

# 刷新所有商店
func refresh_all_shops(force: bool = false) -> bool:
	# 检查是否锁定
	if is_locked and not force:
		return false

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 刷新所有商店
	var result = true
	for shop_type in _shops:
		result = result and _shops[shop_type].refresh(player.level)

	if result:
		# 发送商店刷新信号
		shop_refreshed.emit(-1) # -1 表示所有商店
		GlobalEventBus.economy.dispatch_event(EconomyEvents.ShopRefreshedEvent.new("-1",result))

	return result

# 手动刷新商店（需要花费金币）
func manual_refresh_shop(shop_type: SC.ShopType = -1) -> bool:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 获取当前刷新费用
	var refresh_cost = GameManager.economy_manager.get_refresh_cost()

	# 检查金币是否足够
	if player.gold < refresh_cost:
		return false

	# 扣除金币
	if player.spend_gold(refresh_cost):
		# 刷新商店
		var result = false
		if shop_type == -1:
			result = refresh_all_shops()
		else:
			result = refresh_shop(shop_type)

		# 发送刷新事件
		if result:
			GlobalEventBus.economy.dispatch_event(EconomyEvents.ShopManuallyRefreshedEvent.new(str(shop_type),refresh_cost))

		return result

	return false

# 锁定/解锁商店
func toggle_shop_lock() -> bool:
	is_locked = !is_locked
	return is_locked

# 购买商店物品
func purchase_item(shop_type: SC.ShopType, item_index: int) -> Variant:
	# 获取商店
	var shop = _shops[shop_type]

	# 购买物品
	return shop.purchase_item(item_index)

# 出售物品
func sell_item(item_type: SC.ShopType, item) -> bool:
	match item_type:
		SC.ShopType.CHESS:
			return _shops[SC.ShopType.CHESS].sell_item(item)
		SC.ShopType.EQUIPMENT:
			return _shops[SC.ShopType.EQUIPMENT].sell_item(item)
		SC.ShopType.RELIC:
			return _shops[SC.ShopType.RELIC].sell_item(item)
	return false

# 应用折扣
func apply_discount(discount_rate: float, shop_type: SC.ShopType = -1) -> void:
	# 确保折扣率在合理范围内
	discount_rate = clamp(discount_rate, 0.1, 2.0)

	# 应用折扣
	if shop_type == -1:
		# 应用到所有商店
		for shop in _shops.values():
			shop.apply_discount(discount_rate)
	else:
		# 应用到指定商店
		_shops[shop_type].apply_discount(discount_rate)

	# 发送折扣应用信号
	discount_applied.emit(discount_rate)
	GlobalEventBus.economy.dispatch_event(EconomyEvents.ShopDiscountAppliedEvent.new(str(shop_type),discount_rate))

# 获取商店物品
func get_shop_items(shop_type) -> Array:
	return _shops[shop_type].get_items()

# 获取商店参数
func get_shop_params() -> Dictionary:
	# 收集各个商店的参数
	var params = {
		"is_locked": is_locked,
		"is_black_market": (_shops[SC.ShopType.BLACK_MARKET] as BlackMarketShop).is_active,
		"is_mystery_shop": (_shops[SC.ShopType.MYSTERY_SHOP] as MysteryShop).is_active,
		"is_equipment_shop": (_shops[SC.ShopType.EQUIPMENT] as EquipmentShop).max_items == SC.SPECIAL_EQUIPMENT_ITEMS,
		"is_relic_shop": (_shops[SC.ShopType.RELIC] as RelicShop).max_items == SC.SPECIAL_RELIC_ITEMS,
		"max_chess_items": (_shops[SC.ShopType.CHESS] as ChessShop).max_items,
		"max_equipment_items": (_shops[SC.ShopType.EQUIPMENT] as EquipmentShop).max_items,
		"max_relic_items": (_shops[SC.ShopType.RELIC] as RelicShop).max_items,
		"target_chess_id": (_shops[SC.ShopType.CHESS] as ChessShop).target_chess,
		"consecutive_refresh_count": (_shops[SC.ShopType.CHESS] as ChessShop).pity_counter
	}

	return params

# 获取所有商店物品
func get_all_shop_items() -> Dictionary:
	var result = {}
	for shop_type in _shops:
		result[shop_type] = _shops[shop_type].get_items()
	return result

# 触发黑市商店
func trigger_black_market() -> void:
	# 获取黑市商店
	var black_market = _shops[SC.ShopType.BLACK_MARKET]

	# 激活黑市
	black_market.activate()

	# 应用折扣，随机60-80%折扣
	var discount_rate = SC.BLACK_MARKET_MIN_DISCOUNT + randf() * (SC.BLACK_MARKET_MAX_DISCOUNT - SC.BLACK_MARKET_MIN_DISCOUNT)
	black_market.apply_discount(discount_rate)

	# 刷新黑市
	var player = GameManager.player_manager.get_current_player()
	if player:
		black_market.refresh(player.level)

	# 发送黑市商人触发信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("黑市商人出现了！", 0))
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo", tr("ui.shop.black_market_appeared")))

# 触发神秘商店
func trigger_mystery_shop() -> void:
	# 获取神秘商店
	var mystery_shop = _shops[SC.ShopType.MYSTERY_SHOP]

	# 激活神秘商店
	mystery_shop.activate()

	# 刷新神秘商店
	var player = GameManager.player_manager.get_current_player()
	if player:
		mystery_shop.refresh(player.level)

	# 发送神秘商店触发信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("神秘商店出现了！", 0))
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo",tr("ui.shop.mystery_shop_appeared")))

# 设置目标棋子（用于保底机制）
func set_target_chess(chess_id: String) -> void:
	var chess_shop = _shops[SC.ShopType.CHESS] as ChessShop
	chess_shop.set_target_chess(chess_id)

# 商店刷新请求事件处理
func _on_shop_refresh_requested(player_level: int) -> void:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return

	# 刷新所有商店
	refresh_all_shops(true)

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 重置特殊商店状态
	(_shops[SC.ShopType.BLACK_MARKET] as BlackMarketShop).deactivate()
	(_shops[SC.ShopType.MYSTERY_SHOP] as MysteryShop).deactivate()

	# 检查黑市商人触发
	if round_number % 3 == 0 and randf() < SC.BLACK_MARKET_CHANCE:
		trigger_black_market()

	# 检查装备商店触发
	if SC.EQUIPMENT_SHOP_ROUNDS.has(round_number):
		(_shops[SC.ShopType.EQUIPMENT] as EquipmentShop).set_max_items(SC.SPECIAL_EQUIPMENT_ITEMS)

	# 检查遗物商店触发
	if SC.RELIC_SHOP_ROUNDS.has(round_number):
		(_shops[SC.ShopType.RELIC] as RelicShop).set_max_items(SC.SPECIAL_RELIC_ITEMS)

	# 刷新商店
	refresh_all_shops(true)

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 检查是否是商店节点
	if node_data.type == "shop":
		# 重置特殊商店状态
		(_shops[SC.ShopType.BLACK_MARKET] as BlackMarketShop).deactivate()
		(_shops[SC.ShopType.MYSTERY_SHOP] as MysteryShop).deactivate()

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
					(_shops[SC.ShopType.EQUIPMENT] as EquipmentShop).set_max_items(SC.SPECIAL_EQUIPMENT_ITEMS)

		# 刷新商店
		refresh_all_shops(true)

	# 检查是否是精英战斗节点
	elif node_data.type == "elite_battle" and node_data.has("result") and node_data.result == "victory":
		# 检查神秘商店触发
		if randf() < SC.MYSTERY_SHOP_CHANCE:
			trigger_mystery_shop()
			refresh_all_shops(true)

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int) -> void:
	# 同步经济参数
	for shop in _shops.values():
		shop.sync_economy_params()

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 转发物品购买信号
	item_purchased.emit(item_data)

# 物品出售事件处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 转发物品出售信号
	item_sold.emit(item_data)

# 清理
func cleanup() -> void:
	# 断开事件处理器信号
	_event_handler.shop_refresh_requested.disconnect(_on_shop_refresh_requested)
	_event_handler.battle_round_started.disconnect(_on_battle_round_started)
	_event_handler.map_node_selected.disconnect(_on_map_node_selected)
	_event_handler.difficulty_changed.disconnect(_on_difficulty_changed)

	# 清理事件处理器
	_event_handler.cleanup()

	# 清理商店
	for shop in _shops.values():
		shop.cleanup()
		shop.queue_free()

	# 清理物品生成器和价格计算器
	for generator in _item_generators.values():
		generator.queue_free()

	for calculator in _price_calculators.values():
		calculator.queue_free()

	# 清空字典
	_shops.clear()
	_item_generators.clear()
	_price_calculators.clear()

# 触发装备商店
func trigger_equipment_shop() -> void:
	# 设置装备商店最大物品数量
	(_shops[SC.ShopType.EQUIPMENT] as EquipmentShop).set_max_items(SC.SPECIAL_EQUIPMENT_ITEMS)

	# 刷新装备商店
	var player = GameManager.player_manager.get_current_player()
	if player:
		_shops[SC.ShopType.EQUIPMENT].refresh(player.level)

	# 发送装备商店触发信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("装备商店出现了！", 0))
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo",tr("ui.shop.equipment_shop_appeared")))

# 触发遗物商店
func trigger_relic_shop() -> void:
	# 设置遗物商店最大物品数量
	(_shops[SC.ShopType.RELIC] as RelicShop).set_max_items(SC.SPECIAL_RELIC_ITEMS)

	# 刷新遗物商店
	var player = GameManager.player_manager.get_current_player()
	if player:
		_shops[SC.ShopType.RELIC].refresh(player.level)

	# 发送遗物商店触发信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("遗物商店出现了！", 0))
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo",tr("ui.shop.relic_shop_appeared")))

# 添加特殊道具
func add_special_items(count: int = 1) -> void:
	# 随机选择特殊道具
	var selected_items = []
	var available_items = SC.SPECIAL_ITEMS.duplicate()

	# 选择指定数量的特殊道具
	for i in range(min(count, available_items.size())):
		var index = randi() % available_items.size()
		selected_items.append(available_items[index])
		available_items.remove_at(index)

	# 添加到黑市
	for item_id in selected_items:
		# 这里可以根据项目需求实现添加特殊道具的逻辑
		# 例如，可以调用相应的管理器来创建道具
		pass

# 重置
func reset() -> void:
	# 重置商店锁定状态
	is_locked = false

	# 重置所有商店
	for shop in _shops.values():
		shop.reset()
