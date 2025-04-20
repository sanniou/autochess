extends PriceCalculator
class_name EquipmentPriceCalculator
## 装备价格计算器
## 计算装备的价格

# 基础价格表（按稀有度）
var rarity_prices = {
	0: 2,  # 普通
	1: 4,  # 稀有
	2: 6,  # 史诗
	3: 10  # 传说
}

# 品质价格倍率
var tier_multipliers = {
	0: 1.0,  # 普通
	1: 1.2,  # 魔法
	2: 1.5,  # 稀有
	3: 2.0,  # 史诗
	4: 3.0   # 传说
}

# 计算基础价格
func calculate_base_price(item_data: Dictionary) -> int:
	# 获取装备稀有度
	var rarity = item_data.get("rarity", 0)
	
	# 获取装备品质
	var tier = item_data.get("tier", 0)
	
	# 计算基础价格
	var base_price = rarity_prices.get(rarity, 2)
	
	# 应用品质倍率
	var tier_multiplier = tier_multipliers.get(tier, 1.0)
	
	# 考虑装备效果
	var effect_bonus = 0
	if item_data.has("effects") and item_data.effects is Array:
		effect_bonus = item_data.effects.size()
	
	# 考虑装备属性
	var stats_bonus = 0
	if item_data.has("stats") and item_data.stats is Dictionary:
		stats_bonus = item_data.stats.size()
	
	return int(base_price * tier_multiplier + effect_bonus + stats_bonus)

# 计算出售价格
func calculate_sell_price(item_data: Dictionary) -> int:
	var base_price = calculate_base_price(item_data)
	
	# 获取装备品质
	var tier = item_data.get("tier", 0)
	
	# 根据品质调整出售价格比例
	var sell_ratio = 0.6 # 默认出售价格为基础价格的60%
	if tier > 0:
		sell_ratio = 0.6 + tier * 0.05 # 普通60%，魔法65%，稀有70%，史诗75%，传说80%
	
	return int(base_price * sell_ratio)
