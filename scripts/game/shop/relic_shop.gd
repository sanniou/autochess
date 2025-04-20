extends BaseShop
class_name RelicShop
## 遗物商店
## 管理遗物商店的特定功能

# 遗物商店特有属性
var rarity_weights: Dictionary = {
	0: 0.5,  # 普通
	1: 0.3,  # 稀有
	2: 0.15, # 史诗
	3: 0.05  # 传说
}

# 初始化
func _init(generator, calculator):
	super(generator, calculator)
	shop_name = "RelicShop"
	shop_type = ShopConstants.ShopType.RELIC
	max_items = 3 # 默认3个遗物

# 生成遗物物品
func _generate_items(player_level: int) -> Array:
	# 使用生成器生成物品
	var options = {
		"rarity_weights": _adjust_rarity_weights(player_level),
		"exclude_ids": _get_owned_relics() # 排除已有遗物
	}
	return item_generator.generate_items(max_items, player_level, options)

# 创建遗物实例
func _create_item_instance(item: ShopItem) -> Relic:
	# 获取遗物管理器
	var relic_manager = GameManager.get_manager("RelicManager")
	if relic_manager == null:
		return null
		
	# 创建遗物实例
	return relic_manager.acquire_relic(item.get_id())

# 计算遗物出售价格
func _calculate_sell_price(relic: Relic) -> int:
	# 获取遗物数据
	var relic_data = {
		"id": relic.id,
		"rarity": relic.rarity
	}
	
	# 计算基础价格
	var base_price = price_calculator.calculate_base_price(relic_data)
	
	# 遗物出售价格为基础价格的70%
	return int(base_price * 0.7)

# 获取物品类型
func _get_item_type(item) -> String:
	return "relic"

# 获取已拥有的遗物ID
func _get_owned_relics() -> Array:
	var relic_manager = GameManager.get_manager("RelicManager")
	if relic_manager == null:
		return []
		
	var owned_relics = []
	for relic in relic_manager.get_player_relics():
		owned_relics.append(relic.id)
		
	return owned_relics

# 调整遗物稀有度权重
func _adjust_rarity_weights(player_level: int) -> Dictionary:
	var adjusted_weights = rarity_weights.duplicate()
	
	# 根据玩家等级调整权重
	var level_factor = min(player_level / 10.0, 1.0)
	
	# 降低普通遗物权重，提高高级遗物权重
	adjusted_weights[0] -= 0.2 * level_factor
	adjusted_weights[1] += 0.05 * level_factor
	adjusted_weights[2] += 0.1 * level_factor
	adjusted_weights[3] += 0.05 * level_factor
	
	# 确保权重在合理范围内
	for rarity in adjusted_weights:
		adjusted_weights[rarity] = max(0.0, min(adjusted_weights[rarity], 1.0))
	
	return adjusted_weights

# 同步经济参数
func sync_economy_params() -> void:
	# 根据难度调整遗物稀有度权重
	var difficulty = GameManager.get_difficulty()
	
	# 难度越高，高级遗物出现概率越高
	rarity_weights[0] = 0.5 - difficulty * 0.05
	rarity_weights[1] = 0.3 - difficulty * 0.01
	rarity_weights[2] = 0.15 + difficulty * 0.03
	rarity_weights[3] = 0.05 + difficulty * 0.03
	
	# 确保权重在合理范围内
	for rarity in rarity_weights:
		rarity_weights[rarity] = max(0.0, min(rarity_weights[rarity], 1.0))
