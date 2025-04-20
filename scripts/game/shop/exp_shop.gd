extends BaseShop
class_name ExpShop
## 经验商店
## 管理经验购买功能

# 初始化
func _init(calculator):
	super(null, calculator)
	shop_name = "ExpShop"
	shop_type = ShopConstants.ShopType.EXP

# 刷新商店
func refresh(player_level: int) -> bool:
	# 经验商店不需要刷新，始终可用
	return true

# 购买经验
func purchase_item(item_index: int = 0) -> bool:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false
	
	# 获取当前经验价格和数量
	var exp_cost = GameManager.economy_manager.get_exp_purchase_cost()
	var exp_amount = GameManager.economy_manager.get_exp_purchase_amount()
	
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
		item_purchased.emit(purchase_data)
		
		return true
	
	return false

# 出售物品（经验不能出售）
func sell_item(item) -> bool:
	return false

# 获取商店物品
func get_items() -> Array:
	# 经验商店没有物品列表
	return []

# 应用折扣
func apply_discount(discount_rate: float) -> void:
	# 经验商店不应用折扣
	pass

# 同步经济参数
func sync_economy_params() -> void:
	# 经验商店不需要同步经济参数
	pass
