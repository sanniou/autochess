extends Node
class_name ItemGenerator
## 物品生成器接口
## 定义物品生成的通用接口

# 生成物品
func generate_items(count: int, player_level: int, options: Dictionary = {}) -> Array:
	# 子类实现
	return []

# 生成单个物品
func generate_item(player_level: int, options: Dictionary = {}) -> ShopItem:
	# 子类实现
	return null

# 获取可用物品池
func get_available_items(player_level: int, options: Dictionary = {}) -> Array:
	# 子类实现
	return []

# 根据稀有度过滤物品
func filter_by_rarity(items: Array, rarity: int) -> Array:
	var filtered = []
	for item in items:
		if item.rarity == rarity:
			filtered.append(item)
	return filtered

# 根据类型过滤物品
func filter_by_type(items: Array, type: String) -> Array:
	var filtered = []
	for item in items:
		if item.type == type:
			filtered.append(item)
	return filtered

# 随机选择物品
func random_select(items: Array, count: int) -> Array:
	var result = []
	var available = items.duplicate()
	
	for i in range(count):
		if available.is_empty():
			break
			
		var index = randi() % available.size()
		result.append(available[index])
		available.remove_at(index)
		
	return result
