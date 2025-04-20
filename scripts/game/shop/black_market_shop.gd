extends BaseShop
class_name BlackMarketShop
## 黑市商店
## 管理黑市商店的特定功能

# 黑市商店特有属性
var item_type_weights: Dictionary = {
	ShopItem.ItemType.CHESS: 0.3,
	ShopItem.ItemType.EQUIPMENT: 0.4,
	ShopItem.ItemType.RELIC: 0.2,
	ShopItem.ItemType.CONSUMABLE: 0.1
}

# 所有物品生成器
var _all_generators: Dictionary

# 所有价格计算器
var _all_calculators: Dictionary

# 初始化
func _init(generators, calculators):
	super(null, null)
	shop_name = "BlackMarketShop"
	shop_type = ShopConstants.ShopType.BLACK_MARKET
	max_items = 6 # 黑市默认6个物品

	# 保存所有生成器和计算器
	_all_generators = generators
	_all_calculators = calculators

	# 默认停用
	is_active = false

# 生成黑市物品
func _generate_items(player_level: int) -> Array:
	var items = []

	# 决定每种类型的物品数量
	var type_counts = _decide_item_type_counts()

	# 生成每种类型的物品
	for item_type in type_counts:
		var count = type_counts[item_type]
		if count <= 0:
			continue

		# 获取对应的生成器和计算器
		var generator = _get_generator_for_type(item_type)
		var calculator = _get_calculator_for_type(item_type)

		if generator and calculator:
			# 生成物品
			var options = {
				"is_black_market": true,
				"quality_boost": 0.2 # 黑市物品品质提升
			}
			var type_items = generator.generate_items(count, player_level, options)

			# 设置价格（黑市价格有折扣）
			for item in type_items:
				var base_price = calculator.calculate_base_price(item.get_data())
				item.set_cost(int(base_price * discount_rate))

			# 添加到结果
			items.append_array(type_items)

	return items

# 创建物品实例
func _create_item_instance(item: ShopItem) -> Variant:
	match item.get_type():
		ShopItem.ItemType.CHESS:
			return _create_chess_instance(item)
		ShopItem.ItemType.EQUIPMENT:
			return _create_equipment_instance(item)
		ShopItem.ItemType.RELIC:
			return _create_relic_instance(item)
		ShopItem.ItemType.CONSUMABLE:
			return _create_consumable_instance(item)
	return null

# 创建棋子实例
func _create_chess_instance(item: ShopItem):
	var chess_manager = GameManager.get_manager("ChessManager")
	if chess_manager == null:
		return null
	return chess_manager.create_chess_piece(item.get_id())

# 创建装备实例
func _create_equipment_instance(item: ShopItem) -> Equipment:
	var equipment_manager = GameManager.get_manager("EquipmentManager")
	if equipment_manager == null:
		return null
	return equipment_manager.get_equipment(item.get_id())

# 创建遗物实例
func _create_relic_instance(item: ShopItem) -> Relic:
	var relic_manager = GameManager.get_manager("RelicManager")
	if relic_manager == null:
		return null
	return relic_manager.acquire_relic(item.get_id())

# 创建消耗品实例
func _create_consumable_instance(item: ShopItem) -> Variant:
	var consumable_manager = GameManager.get_manager("ConsumableManager")
	if consumable_manager == null:
		return null
	return consumable_manager.get_consumable(item.get_id())

# 计算出售价格
func _calculate_sell_price(item) -> int:
	# 根据物品类型获取对应的计算器
	var item_type = _get_item_type(item)
	var calculator = _get_calculator_for_type(_get_shop_item_type(item_type))

	if calculator:
		var item_data = {}
		match item_type:
			"chess":
				item_data = {
					"id": item.id,
					"rarity": item.rarity,
					"level": item.level
				}
			"equipment":
				item_data = item.get_data()
			"relic":
				item_data = {
					"id": item.id,
					"rarity": item.rarity
				}
			"consumable":
				item_data = {
					"id": item.id,
					"rarity": item.rarity
				}

		# 计算基础价格
		var base_price = calculator.calculate_base_price(item_data)

		# 黑市出售价格为基础价格的65%
		return int(base_price * 0.65)

	return 0

# 获取物品类型
func _get_item_type(item) -> String:
	if item is ChessPieceEntity:
		return "chess"
	elif item is Equipment:
		return "equipment"
	elif item is Relic:
		return "relic"
	elif item.has_method("get_type") and item.get_type() == "consumable":
		return "consumable"
	return ""

# 获取ShopItem类型
func _get_shop_item_type(item_type: String) -> int:
	match item_type:
		"chess":
			return ShopItem.ItemType.CHESS
		"equipment":
			return ShopItem.ItemType.EQUIPMENT
		"relic":
			return ShopItem.ItemType.RELIC
		"consumable":
			return ShopItem.ItemType.CONSUMABLE
	return ShopItem.ItemType.CHESS

# 决定每种类型的物品数量
func _decide_item_type_counts() -> Dictionary:
	var counts = {}
	var remaining = max_items

	# 按权重分配物品数量
	for item_type in item_type_weights:
		var weight = item_type_weights[item_type]
		var count = int(max_items * weight)
		counts[item_type] = count
		remaining -= count

	# 分配剩余物品
	while remaining > 0:
		var random_type = _weighted_random_type()
		counts[random_type] += 1
		remaining -= 1

	return counts

# 加权随机选择物品类型
func _weighted_random_type() -> int:
	var total_weight = 0.0
	for item_type in item_type_weights:
		total_weight += item_type_weights[item_type]

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for item_type in item_type_weights:
		current_weight += item_type_weights[item_type]
		if random_value <= current_weight:
			return item_type

	return ShopItem.ItemType.EQUIPMENT # 默认返回装备类型

# 获取指定类型的生成器
func _get_generator_for_type(item_type: int) -> ItemGenerator:
	match item_type:
		ShopItem.ItemType.CHESS:
			return _all_generators[ShopConstants.ShopType.CHESS]
		ShopItem.ItemType.EQUIPMENT:
			return _all_generators[ShopConstants.ShopType.EQUIPMENT]
		ShopItem.ItemType.RELIC:
			return _all_generators[ShopConstants.ShopType.RELIC]
		ShopItem.ItemType.CONSUMABLE:
			# 消耗品生成器可能不存在
			if _all_generators.has(ShopConstants.ShopType.CONSUMABLE):
				return _all_generators[ShopConstants.ShopType.CONSUMABLE]
	return null

# 获取指定类型的计算器
func _get_calculator_for_type(item_type: int) -> PriceCalculator:
	match item_type:
		ShopItem.ItemType.CHESS:
			return _all_calculators[ShopConstants.ShopType.CHESS]
		ShopItem.ItemType.EQUIPMENT:
			return _all_calculators[ShopConstants.ShopType.EQUIPMENT]
		ShopItem.ItemType.RELIC:
			return _all_calculators[ShopConstants.ShopType.RELIC]
		ShopItem.ItemType.CONSUMABLE:
			# 消耗品计算器可能不存在
			if _all_calculators.has(ShopConstants.ShopType.CONSUMABLE):
				return _all_calculators[ShopConstants.ShopType.CONSUMABLE]
	return null

# 同步经济参数
func sync_economy_params() -> void:
	# 根据难度调整物品类型权重
	var difficulty = GameManager.get_difficulty()

	# 难度越高，高级物品（装备和遗物）出现概率越高
	item_type_weights[ShopItem.ItemType.CHESS] = 0.3 - difficulty * 0.02
	item_type_weights[ShopItem.ItemType.EQUIPMENT] = 0.4 + difficulty * 0.01
	item_type_weights[ShopItem.ItemType.RELIC] = 0.2 + difficulty * 0.01
	item_type_weights[ShopItem.ItemType.CONSUMABLE] = 0.1

	# 确保权重在合理范围内
	for item_type in item_type_weights:
		item_type_weights[item_type] = max(0.0, min(item_type_weights[item_type], 1.0))
