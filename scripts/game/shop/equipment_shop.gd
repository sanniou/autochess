extends BaseShop
class_name EquipmentShop
## 装备商店
## 管理装备商店的特定功能

# 装备商店特有属性
var tier_weights: Dictionary = {
	0: 0.5,  # 普通
	1: 0.3,  # 魔法
	2: 0.15, # 稀有
	3: 0.04, # 史诗
	4: 0.01  # 传说
}

# 初始化
func _init(generator, calculator):
	super(generator, calculator)
	shop_name = "EquipmentShop"
	shop_type = ShopConstants.ShopType.EQUIPMENT

# 生成装备物品
func _generate_items(player_level: int) -> Array:
	# 使用生成器生成物品
	var options = {
		"tier_weights": _adjust_tier_weights(player_level),
		"exclude_ids": [] # 可以排除已有装备
	}
	return item_generator.generate_items(max_items, player_level, options)

# 创建装备实例
func _create_item_instance(item: ShopItem) -> Equipment:
	# 获取装备管理器
	var equipment_manager = GameManager.get_manager("EquipmentManager")
	if equipment_manager == null:
		return null
		
	# 创建装备实例
	return equipment_manager.get_equipment(item.get_id())

# 计算装备出售价格
func _calculate_sell_price(equipment: Equipment) -> int:
	# 获取装备数据
	var equipment_data = equipment.get_data()
	
	# 计算基础价格
	var base_price = price_calculator.calculate_base_price(equipment_data)
	
	# 装备出售价格为基础价格的60%
	return int(base_price * 0.6)

# 获取物品类型
func _get_item_type(item) -> String:
	return "equipment"

# 调整装备品质权重
func _adjust_tier_weights(player_level: int) -> Dictionary:
	var adjusted_weights = tier_weights.duplicate()
	
	# 根据玩家等级调整权重
	var level_factor = min(player_level / 10.0, 1.0)
	
	# 降低普通装备权重，提高高级装备权重
	adjusted_weights[0] -= 0.3 * level_factor
	adjusted_weights[1] += 0.1 * level_factor
	adjusted_weights[2] += 0.1 * level_factor
	adjusted_weights[3] += 0.07 * level_factor
	adjusted_weights[4] += 0.03 * level_factor
	
	# 确保权重在合理范围内
	for tier in adjusted_weights:
		adjusted_weights[tier] = max(0.0, min(adjusted_weights[tier], 1.0))
	
	return adjusted_weights

# 同步经济参数
func sync_economy_params() -> void:
	# 根据难度调整装备品质权重
	var difficulty = GameManager.get_difficulty()
	
	# 难度越高，高级装备出现概率越高
	tier_weights[0] = 0.5 - difficulty * 0.05
	tier_weights[1] = 0.3 - difficulty * 0.02
	tier_weights[2] = 0.15 + difficulty * 0.02
	tier_weights[3] = 0.04 + difficulty * 0.03
	tier_weights[4] = 0.01 + difficulty * 0.02
	
	# 确保权重在合理范围内
	for tier in tier_weights:
		tier_weights[tier] = max(0.0, min(tier_weights[tier], 1.0))
