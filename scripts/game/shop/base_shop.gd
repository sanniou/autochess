extends Node
class_name BaseShop
## 商店基类
## 定义商店的通用接口和功能

# 信号
signal item_purchased(item_data)
signal item_sold(item_data)
signal shop_refreshed()
signal discount_applied(discount_rate)

# 商店属性
var shop_name: String = "BaseShop"
var shop_type: ShopConstants.ShopType
var max_items: int = 5
var current_items: Array = []
var discount_rate: float = 1.0
var is_active: bool = true

# 组件引用
var item_generator
var price_calculator

# 初始化
func _init(generator = null, calculator = null):
	item_generator = generator
	price_calculator = calculator

# 刷新商店
func refresh(player_level: int) -> bool:
	if not is_active:
		return false
		
	# 清空当前物品
	current_items.clear()
	
	# 生成新物品
	var new_items = _generate_items(player_level)
	
	# 添加到当前物品列表
	for item in new_items:
		current_items.append(item)
	
	# 发送商店刷新信号
	shop_refreshed.emit()
	
	return true

# 购买物品
func purchase_item(item_index: int) -> Variant:
	# 检查索引是否有效
	if item_index < 0 or item_index >= current_items.size():
		return null
		
	# 获取物品
	var item = current_items[item_index]
	
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return null
		
	# 检查金币是否足够
	if player.gold < item.get_cost():
		return null
		
	# 扣除金币
	if player.spend_gold(item.get_cost()):
		# 从商店移除物品
		current_items.remove_at(item_index)
		
		# 发送物品购买信号
		item_purchased.emit(item.get_data())
		
		# 返回物品实例
		return _create_item_instance(item)
		
	return null

# 出售物品
func sell_item(item) -> bool:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false
		
	# 计算出售价格
	var sell_price = _calculate_sell_price(item)
	
	# 增加金币
	player.add_gold(sell_price)
	
	# 发送物品出售信号
	var item_data = {
		"id": item.id if item.has_method("get_id") else item.id,
		"type": _get_item_type(item),
		"sell_price": sell_price
	}
	item_sold.emit(item_data)
	
	return true

# 应用折扣
func apply_discount(rate: float) -> void:
	# 确保折扣率在合理范围内
	discount_rate = clamp(rate, 0.1, 2.0)
	
	# 更新所有物品价格
	for item in current_items:
		var base_cost = price_calculator.calculate_base_price(item.get_data())
		var discounted_cost = int(base_cost * discount_rate)
		item.set_cost(discounted_cost)
	
	# 发送折扣应用信号
	discount_applied.emit(discount_rate)

# 获取商店物品
func get_items() -> Array:
	return current_items.duplicate()

# 设置最大物品数量
func set_max_items(count: int) -> void:
	max_items = count

# 激活商店
func activate() -> void:
	is_active = true

# 停用商店
func deactivate() -> void:
	is_active = false

# 同步经济参数
func sync_economy_params() -> void:
	# 子类实现
	pass

# 生成物品（由子类实现）
func _generate_items(player_level: int) -> Array:
	# 子类实现
	return []

# 创建物品实例（由子类实现）
func _create_item_instance(item: ShopItem) -> Variant:
	# 子类实现
	return null

# 计算出售价格（由子类实现）
func _calculate_sell_price(item) -> int:
	# 子类实现
	return 0

# 获取物品类型（由子类实现）
func _get_item_type(item) -> String:
	# 子类实现
	return ""

# 清理
func cleanup() -> void:
	# 清空当前物品
	current_items.clear()

# 重置
func reset() -> void:
	# 重置商店状态
	discount_rate = 1.0
	is_active = true
	current_items.clear()
