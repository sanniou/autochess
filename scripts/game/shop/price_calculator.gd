extends Node
class_name PriceCalculator
## 价格计算器接口
## 定义价格计算的通用接口

# 计算基础价格
func calculate_base_price(item_data: Dictionary) -> int:
	# 子类实现
	return 0

# 计算折扣价格
func calculate_discounted_price(item_data: Dictionary, discount_rate: float) -> int:
	var base_price = calculate_base_price(item_data)
	return int(base_price * discount_rate)

# 计算出售价格
func calculate_sell_price(item_data: Dictionary) -> int:
	var base_price = calculate_base_price(item_data)
	return int(base_price * 0.5) # 默认出售价格为基础价格的50%
