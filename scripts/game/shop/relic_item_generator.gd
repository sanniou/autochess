extends ItemGenerator
class_name RelicItemGenerator
## 遗物物品生成器
## 生成遗物商店物品

# 生成遗物物品
func generate_items(count: int, player_level: int, options: Dictionary = {}) -> Array:
	var items = []
	
	# 获取可用遗物池
	var available_relics = get_available_items(player_level, options)
	
	# 如果没有可用遗物，返回空数组
	if available_relics.is_empty():
		return items
	
	# 随机选择遗物
	var selected_relics = random_select(available_relics, count)
	
	# 创建遗物物品
	for relic_data in selected_relics:
		# 计算遗物价格
		var price_calculator = GameManager.get_manager("ShopSystem")._price_calculators[ShopConstants.ShopType.RELIC]
		var cost = price_calculator.calculate_base_price(relic_data)
		
		# 应用折扣
		if options.has("discount_rate"):
			cost = int(cost * options.discount_rate)
		
		# 创建物品数据
		var item_data = relic_data.duplicate()
		item_data["cost"] = cost
		
		# 创建物品
		var item = ShopItem.new(item_data)
		items.append(item)
	
	return items

# 生成单个遗物物品
func generate_item(player_level: int, options: Dictionary = {}) -> ShopItem:
	var items = generate_items(1, player_level, options)
	if items.is_empty():
		return null
	return items[0]

# 获取可用遗物池
func get_available_items(player_level: int, options: Dictionary = {}) -> Array:
	# 获取配置管理器
	var config_manager = GameManager.get_manager("ConfigManager")
	if config_manager == null:
		return []
	
	# 获取游戏常量
	var game_consts = load("res://scripts/constants/game_constants.gd")
	
	# 获取可用稀有度
	var available_rarities = game_consts.get_rarities_by_level(player_level)
	
	# 获取所有遗物配置
	var all_relics = config_manager.get_relics_by_rarity(available_rarities)
	
	# 转换为数据数组
	var relic_data_array = []
	for relic_config in all_relics:
		relic_data_array.append(relic_config.get_data())
	
	# 应用过滤条件
	if options.has("exclude_ids"):
		var exclude_ids = options.exclude_ids
		for i in range(relic_data_array.size() - 1, -1, -1):
			if exclude_ids.has(relic_data_array[i].id):
				relic_data_array.remove_at(i)
	
	# 应用稀有度过滤
	if options.has("rarity_filter"):
		relic_data_array = filter_by_rarity(relic_data_array, options.rarity_filter)
	
	# 应用类型过滤
	if options.has("type_filter"):
		relic_data_array = filter_by_type(relic_data_array, options.type_filter)
	
	# 应用稀有度权重
	if options.has("rarity_weights"):
		var rarity_weights = options.rarity_weights
		
		# 根据稀有度进行加权选择
		var weighted_array = []
		for relic_data in relic_data_array:
			var rarity = relic_data.rarity
			var weight = rarity_weights.get(rarity, 1.0)
			
			# 添加多次以增加权重
			for i in range(int(weight * 100)):
				weighted_array.append(relic_data)
		
		# 使用加权数组替换原数组
		if not weighted_array.is_empty():
			relic_data_array = weighted_array
	
	# 应用稀有度提升
	elif options.has("rarity_boost") or options.has("is_mystery_shop"):
		# 提高高稀有度遗物的权重
		var boost_factor = options.get("rarity_boost", 0.3)
		if options.get("is_mystery_shop", false):
			boost_factor = 0.4
		
		# 根据稀有度进行加权选择
		var weighted_array = []
		for relic_data in relic_data_array:
			var rarity = relic_data.rarity
			var weight = 1.0
			match rarity:
				0: # 普通
					weight = 1.0 - boost_factor
				1: # 稀有
					weight = 1.0
				2: # 史诗
					weight = 1.0 + boost_factor
				3: # 传说
					weight = 1.0 + boost_factor * 2
			
			# 添加多次以增加权重
			for i in range(int(weight * 10)):
				weighted_array.append(relic_data)
		
		# 使用加权数组替换原数组
		if not weighted_array.is_empty():
			relic_data_array = weighted_array
	
	return relic_data_array
