extends ItemGenerator
class_name EquipmentItemGenerator
## 装备物品生成器
## 生成装备商店物品

# 生成装备物品
func generate_items(count: int, player_level: int, options: Dictionary = {}) -> Array:
	var items = []
	
	# 获取可用装备池
	var available_equipment = get_available_items(player_level, options)
	
	# 如果没有可用装备，返回空数组
	if available_equipment.is_empty():
		return items
	
	# 随机选择装备
	var selected_equipment = random_select(available_equipment, count)
	
	# 创建装备物品
	for equipment_data in selected_equipment:
		# 计算装备价格
		var price_calculator = GameManager.get_manager("ShopSystem")._price_calculators[ShopConstants.ShopType.EQUIPMENT]
		var cost = price_calculator.calculate_base_price(equipment_data)
		
		# 应用折扣
		if options.has("discount_rate"):
			cost = int(cost * options.discount_rate)
		
		# 创建物品数据
		var item_data = equipment_data.duplicate()
		item_data["cost"] = cost
		
		# 创建物品
		var item = ShopItem.new(item_data)
		items.append(item)
	
	return items

# 生成单个装备物品
func generate_item(player_level: int, options: Dictionary = {}) -> ShopItem:
	var items = generate_items(1, player_level, options)
	if items.is_empty():
		return null
	return items[0]

# 获取可用装备池
func get_available_items(player_level: int, options: Dictionary = {}) -> Array:
	# 获取配置管理器
	var config_manager = GameManager.get_manager("ConfigManager")
	if config_manager == null:
		return []
	
	# 获取游戏常量
	var game_consts = load("res://scripts/constants/game_constants.gd")
	
	# 获取可用稀有度
	var available_rarities = game_consts.get_rarities_by_level(player_level)
	
	# 获取所有装备配置
	var all_equipment = config_manager.get_equipments_by_rarity(available_rarities)
	
	# 转换为数据数组
	var equipment_data_array = []
	for equipment_config in all_equipment:
		equipment_data_array.append(equipment_config.get_data())
	
	# 应用过滤条件
	if options.has("exclude_ids"):
		var exclude_ids = options.exclude_ids
		for i in range(equipment_data_array.size() - 1, -1, -1):
			if exclude_ids.has(equipment_data_array[i].id):
				equipment_data_array.remove_at(i)
	
	# 应用稀有度过滤
	if options.has("rarity_filter"):
		equipment_data_array = filter_by_rarity(equipment_data_array, options.rarity_filter)
	
	# 应用类型过滤
	if options.has("type_filter"):
		equipment_data_array = filter_by_type(equipment_data_array, options.type_filter)
	
	# 应用装备品质权重
	if options.has("tier_weights"):
		var tier_weights = options.tier_weights
		
		# 根据品质进行加权选择
		var weighted_array = []
		for equipment_data in equipment_data_array:
			var tier = equipment_data.get("tier", 0)
			var weight = tier_weights.get(tier, 1.0)
			
			# 添加多次以增加权重
			for i in range(int(weight * 100)):
				weighted_array.append(equipment_data)
		
		# 使用加权数组替换原数组
		if not weighted_array.is_empty():
			equipment_data_array = weighted_array
	
	# 应用品质提升
	elif options.has("quality_boost") or options.has("is_mystery_shop") or options.has("is_black_market"):
		# 提高高品质装备的权重
		var boost_factor = options.get("quality_boost", 0.2)
		if options.get("is_mystery_shop", false):
			boost_factor = 0.3
		elif options.get("is_black_market", false):
			boost_factor = 0.2
		
		# 根据品质进行加权选择
		var weighted_array = []
		for equipment_data in equipment_data_array:
			var tier = equipment_data.get("tier", 0)
			var weight = 1.0
			match tier:
				0: # 普通
					weight = 1.0 - boost_factor
				1: # 魔法
					weight = 1.0
				2: # 稀有
					weight = 1.0 + boost_factor
				3: # 史诗
					weight = 1.0 + boost_factor * 1.5
				4: # 传说
					weight = 1.0 + boost_factor * 2
			
			# 添加多次以增加权重
			for i in range(int(weight * 10)):
				weighted_array.append(equipment_data)
		
		# 使用加权数组替换原数组
		if not weighted_array.is_empty():
			equipment_data_array = weighted_array
	
	return equipment_data_array
