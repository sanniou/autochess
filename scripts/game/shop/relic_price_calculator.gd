extends PriceCalculator
class_name RelicPriceCalculator
## 遗物价格计算器
## 计算遗物的价格

# 基础价格表
var base_prices = {
	0: 5,   # 普通
	1: 10,  # 稀有
	2: 15,  # 史诗
	3: 25   # 传说
}

# 计算基础价格
func calculate_base_price(item_data: Dictionary) -> int:
	# 获取遗物稀有度
	var rarity = item_data.get("rarity", 0)
	
	# 计算基础价格
	var base_price = base_prices.get(rarity, 5)
	
	# 考虑遗物效果
	var effect_bonus = 0
	if item_data.has("effects") and item_data.effects is Array:
		effect_bonus = item_data.effects.size() * 2
	
	# 考虑遗物是否是被动
	var passive_bonus = 0
	if item_data.get("is_passive", false):
		passive_bonus = 5
	
	# 考虑遗物充能次数
	var charges_bonus = 0
	if item_data.has("max_charges") and item_data.max_charges > 0:
		charges_bonus = item_data.max_charges
	
	return base_price + effect_bonus + passive_bonus + charges_bonus

# 计算出售价格
func calculate_sell_price(item_data: Dictionary) -> int:
	var base_price = calculate_base_price(item_data)
	
	# 获取遗物稀有度
	var rarity = item_data.get("rarity", 0)
	
	# 根据稀有度调整出售价格比例
	var sell_ratio = 0.7 # 默认出售价格为基础价格的70%
	if rarity > 0:
		sell_ratio = 0.7 + rarity * 0.05 # 普通70%，稀有75%，史诗80%，传说85%
	
	return int(base_price * sell_ratio)
