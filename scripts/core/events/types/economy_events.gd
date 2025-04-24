extends RefCounted
class_name EconomyEvents
## 经济事件类型
## 定义与经济系统相关的事件

## 金币变化事件
class GoldChangedEvent extends BusEvent:
	## 旧金币数量
	var old_amount: int
	
	## 新金币数量
	var new_amount: int
	
	## 变化原因
	var reason: String
	
	## 初始化
	func _init(p_old_amount: int, p_new_amount: int, p_reason: String = ""):
		old_amount = p_old_amount
		new_amount = p_new_amount
		reason = p_reason
	
	## 获取事件类型
	func get_type() -> String:
		return "economy.gold_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GoldChangedEvent[old_amount=%d, new_amount=%d, reason=%s]" % [
			old_amount, new_amount, reason
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = GoldChangedEvent.new(old_amount, new_amount, reason)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
		return event

## 商店手动刷新事件
class ShopRefreshRequestedEvent extends BusEvent:
	var player_level: int
	
	func _init(player_level: int):
		self.player_level = player_level
	
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
	func get_type() -> String:
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
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
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

class IncomeGrantedEvent extends BusEvent:
	
	## 棋子列表
	var income: int
	
	## 初始化
	func _init(p_income: int):
		income = p_income
