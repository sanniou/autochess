extends RefCounted
class_name EconomyEvents
## 经济事件类型
## 定义与经济系统相关的事件

## 金币变化事件 (Renamed to PlayerGoldChangedEvent, parameters updated)
class PlayerGoldChangedEvent extends BusEvent: # Renamed from GoldChangedEvent
	var player # Player instance or ID
	var old_gold: int
	var new_gold: int
	var amount_changed: int
	var reason: String

	## 初始化
	func _init(p_player, p_old_gold: int, p_new_gold: int, p_amount_changed: int, p_reason: String = ""):
		player = p_player
		old_gold = p_old_gold
		new_gold = p_new_gold
		amount_changed = p_amount_changed
		reason = p_reason

	## 获取事件类型
	static func get_type() -> String:
		return "economy.player_gold_changed" # Updated type string

	## 获取事件的字符串表示
	func _to_string() -> String:
		var player_id_str = str(player.id if player and player.has_method("get_id") else player) # Basic player string representation
		return "PlayerGoldChangedEvent[player=%s, old_gold=%d, new_gold=%d, amount_changed=%d, reason=%s]" % [
			player_id_str, old_gold, new_gold, amount_changed, reason
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = PlayerGoldChangedEvent.new(player, old_gold, new_gold, amount_changed, reason)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 商店刷新事件
class ShopRefreshedEvent extends BusEvent:
	## 商店ID
	var shop_id: String

	## 商品列表
	var items: Array

	## 是否手动刷新
	var is_manual: bool

	## 初始化
	func _init(p_shop_id: String, p_items: Array, p_is_manual: bool = false):
		shop_id = p_shop_id
		items = p_items
		is_manual = p_is_manual

	## 获取事件类型
	static func get_type() -> String:
		return "economy.shop_refreshed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShopRefreshedEvent[shop_id=%s, items=%d, is_manual=%s]" % [
			shop_id, items.size(), is_manual
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = ShopRefreshedEvent.new(shop_id, items.duplicate(), is_manual)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 商店手动刷新事件
class ShopRefreshRequestedEvent extends BusEvent:
	var player_level: int

	func _init(p_player_level: int):
		player_level = p_player_level

	## 获取事件类型
	static func get_type() -> String:
		return "economy.shop_refresh_requested"

## 商店手动刷新事件
class ShopManuallyRefreshedEvent extends BusEvent:
	## 商店ID
	var shop_id: String

	## 刷新成本
	var refresh_cost: int

	## 初始化
	func _init(p_shop_id: String, p_refresh_cost: int):
		shop_id = p_shop_id
		refresh_cost = p_refresh_cost

	## 获取事件类型
	static func get_type() -> String:
		return "economy.shop_manually_refreshed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShopManuallyRefreshedEvent[shop_id=%s, refresh_cost=%d]" % [
			shop_id, refresh_cost
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = ShopManuallyRefreshedEvent.new(shop_id, refresh_cost)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 物品购买事件
class ItemPurchasedEvent extends BusEvent:
	## 商店ID
	var shop_id: String

	## 物品ID
	var item_id: String

	## 物品数据
	var item_data: Dictionary

	## 购买价格
	var price: int

	## 初始化
	func _init(p_shop_id: String, p_item_id: String, p_item_data: Dictionary, p_price: int):
		shop_id = p_shop_id
		item_id = p_item_id
		item_data = p_item_data
		price = p_price

	## 获取事件类型
	static func get_type() -> String:
		return "economy.item_purchased"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ItemPurchasedEvent[shop_id=%s, item_id=%s, price=%d]" % [
			shop_id, item_id, price
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = ItemPurchasedEvent.new(shop_id, item_id, item_data.duplicate(), price)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 物品出售事件
class ItemSoldEvent extends BusEvent:
	## 物品ID
	var item_id: String

	## 物品数据
	var item_data: Dictionary

	## 出售价格
	var price: int

	## 初始化
	func _init(p_item_id: String, p_item_data: Dictionary, p_price: int):
		item_id = p_item_id
		item_data = p_item_data
		price = p_price

	## 获取事件类型
	static func get_type() -> String:
		return "economy.item_sold"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ItemSoldEvent[item_id=%s, price=%d]" % [
			item_id, price
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = ItemSoldEvent.new(item_id, item_data.duplicate(), price)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 商店折扣应用事件
class ShopDiscountAppliedEvent extends BusEvent:
	## 商店ID
	var shop_id: String

	## 折扣百分比
	var discount_percent: float

	## 折扣原因
	var reason: String

	## 初始化
	func _init(p_shop_id: String, p_discount_percent: float, p_reason: String = ""):
		shop_id = p_shop_id
		discount_percent = p_discount_percent
		reason = p_reason

	## 获取事件类型
	static func get_type() -> String:
		return "economy.shop_discount_applied"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShopDiscountAppliedEvent[shop_id=%s, discount_percent=%.1f, reason=%s]" % [
			shop_id, discount_percent, reason
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = ShopDiscountAppliedEvent.new(shop_id, discount_percent, reason)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 棋子商店库存更新事件
class ChessShopInventoryUpdatedEvent extends BusEvent:
	## 商店ID
	#var shop_id: String

	## 棋子列表
	var chess_pieces: Array

	## 初始化
	func _init(p_chess_pieces: Array):
		chess_pieces = p_chess_pieces

	## 获取事件类型
	static func get_type() -> String:
		return "economy.chess_shop_inventory_updated"

class IncomeGrantedEvent extends BusEvent:

	## 棋子列表
	var income: int

	## 初始化
	func _init(p_income: int):
		income = p_income

	## 获取事件类型
	static func get_type() -> String:
		return "economy.income_granted"

class ShopClosedEvent extends BusEvent:

	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "economy.shop_closed"
