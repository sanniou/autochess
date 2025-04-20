extends ItemGenerator
class_name ChessItemGenerator
## 棋子物品生成器
## 生成棋子商店物品

# 生成棋子物品
func generate_items(count: int, player_level: int, options: Dictionary = {}) -> Array:
	var items = []
	
	# 获取可用棋子池
	var available_chess = get_available_items(player_level, options)
	
	# 如果没有可用棋子，返回空数组
	if available_chess.is_empty():
		return items
	
	# 随机选择棋子
	var selected_chess = random_select(available_chess, count)
	
	# 创建棋子物品
	for chess_data in selected_chess:
		# 计算棋子价格
		var price_calculator = GameManager.get_manager("ShopSystem")._price_calculators[ShopConstants.ShopType.CHESS]
		var cost = price_calculator.calculate_base_price(chess_data)
		
		# 应用折扣
		if options.has("discount_rate"):
			cost = int(cost * options.discount_rate)
		
		# 创建物品数据
		var item_data = chess_data.duplicate()
		item_data["cost"] = cost
		
		# 创建物品
		var item = ShopItem.new(item_data)
		items.append(item)
	
	return items

# 生成单个棋子物品
func generate_item(player_level: int, options: Dictionary = {}) -> ShopItem:
	var items = generate_items(1, player_level, options)
	if items.is_empty():
		return null
	return items[0]

# 获取可用棋子池
func get_available_items(player_level: int, options: Dictionary = {}) -> Array:
	# 获取配置管理器
	var config_manager = GameManager.get_manager("ConfigManager")
	if config_manager == null:
		return []
	
	# 获取游戏常量
	var game_consts = load("res://scripts/constants/game_constants.gd")
	
	# 获取可用稀有度
	var available_rarities = game_consts.get_rarities_by_level(player_level)
	
	# 获取所有棋子配置
	var all_chess = config_manager.get_chess_by_rarity(available_rarities)
	
	# 转换为数据数组
	var chess_data_array = []
	for chess_config in all_chess:
		chess_data_array.append(chess_config.get_data())
	
	# 应用过滤条件
	if options.has("exclude_ids"):
		var exclude_ids = options.exclude_ids
		for i in range(chess_data_array.size() - 1, -1, -1):
			if exclude_ids.has(chess_data_array[i].id):
				chess_data_array.remove_at(i)
	
	# 应用稀有度过滤
	if options.has("rarity_filter"):
		chess_data_array = filter_by_rarity(chess_data_array, options.rarity_filter)
	
	# 应用类型过滤
	if options.has("type_filter"):
		chess_data_array = filter_by_type(chess_data_array, options.type_filter)
	
	# 应用品质提升
	if options.has("quality_boost") or options.has("is_mystery_shop") or options.has("is_black_market"):
		# 提高高稀有度棋子的权重
		var boost_factor = options.get("quality_boost", 0.2)
		if options.get("is_mystery_shop", false):
			boost_factor = 0.3
		elif options.get("is_black_market", false):
			boost_factor = 0.2
		
		# 根据稀有度进行加权选择
		var weighted_array = []
		for chess_data in chess_data_array:
			var weight = 1.0
			match chess_data.rarity:
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
				weighted_array.append(chess_data)
		
		# 使用加权数组替换原数组
		if not weighted_array.is_empty():
			chess_data_array = weighted_array
	
	return chess_data_array
