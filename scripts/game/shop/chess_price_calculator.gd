extends PriceCalculator
class_name ChessPriceCalculator
## 棋子价格计算器
## 计算棋子的价格

# 基础价格表
var base_prices = {
	0: 1,  # 普通
	1: 2,  # 稀有
	2: 3,  # 史诗
	3: 5   # 传说
}

# 计算基础价格
func calculate_base_price(item_data: Dictionary) -> int:
	# 获取棋子稀有度
	var rarity = item_data.get("rarity", 0)
	
	# 获取棋子等级
	var level = item_data.get("level", 1)
	
	# 计算基础价格
	var base_price = base_prices.get(rarity, 1)
	
	# 根据等级调整价格
	var level_multiplier = 1.0
	if level > 1:
		level_multiplier = pow(3, level - 1) # 1级1倍，2级3倍，3级9倍
	
	return int(base_price * level_multiplier)

# 计算出售价格
func calculate_sell_price(item_data: Dictionary) -> int:
	var base_price = calculate_base_price(item_data)
	
	# 获取棋子等级
	var level = item_data.get("level", 1)
	
	# 根据等级调整出售价格比例
	var sell_ratio = 0.5 # 默认出售价格为基础价格的50%
	if level > 1:
		sell_ratio = 0.5 + (level - 1) * 0.1 # 1级50%，2级60%，3级70%
	
	return int(base_price * sell_ratio)
