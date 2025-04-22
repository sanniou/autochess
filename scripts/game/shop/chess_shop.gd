extends BaseShop
class_name ChessShop
## 棋子商店
## 管理棋子商店的特定功能

# 棋子商店特有属性
var target_chess: String = "" # 保底机制目标棋子
var pity_counter: int = 0 # 保底计数器
var pity_threshold: int = 5 # 保底阈值

# 初始化
func _init(generator, calculator):
	super(generator, calculator)
	shop_name = "ChessShop"
	shop_type = ShopConstants.ShopType.CHESS

# 设置目标棋子（用于保底机制）
func set_target_chess(chess_id: String) -> void:
	target_chess = chess_id
	pity_counter = 0

# 重写刷新方法，添加保底机制
func refresh(player_level: int) -> bool:
	if not is_active:
		return false

	# 清空当前物品
	current_items.clear()

	# 生成新物品
	var new_items = _generate_items(player_level)

	# 检查保底机制
	if not target_chess.is_empty():
		var has_target = false
		for item in new_items:
			if item.get_id() == target_chess:
				has_target = true
				break

		# 如果没有目标棋子，增加保底计数
		if not has_target:
			pity_counter += 1

			# 如果达到保底阈值，强制添加目标棋子
			if pity_counter >= pity_threshold:
				# 获取目标棋子数据
				var target_data = GameManager.config_manager.get_chess_config(target_chess)
				if target_data:
					# 创建目标棋子物品
					var target_item_data = target_data.get_data()
					target_item_data["cost"] = price_calculator.calculate_base_price(target_item_data)
					var target_item = ShopItem.new(target_item_data)

					# 替换一个随机物品
					if not new_items.is_empty():
						var replace_index = randi() % new_items.size()
						new_items[replace_index] = target_item
					else:
						new_items.append(target_item)

					# 重置保底计数
					pity_counter = 0
		else:
			# 如果有目标棋子，重置保底计数
			pity_counter = 0

	# 添加到当前物品列表
	for item in new_items:
		current_items.append(item)

	# 发送商店刷新信号
	shop_refreshed.emit()

	return true

# 生成棋子物品
func _generate_items(player_level: int) -> Array:
	# 使用生成器生成物品
	return item_generator.generate_items(max_items, player_level)

# 创建棋子实例
func _create_item_instance(item: ShopItem):
	# 获取棋子管理器
	var chess_manager = GameManager.get_manager("ChessManager")
	if chess_manager == null:
		return null

	# 创建棋子实例
	return chess_manager.create_chess_piece(item.get_id())

# 计算棋子出售价格
func _calculate_sell_price(chess) -> int:
	# 获取棋子数据
	var chess_id = ""
	var chess_rarity = 0
	var chess_level = 1

	# 检查棋子类型
	if chess is ChessPieceEntity:
		chess_id = chess.id
		chess_rarity = chess.rarity
		chess_level = chess.level
	# elif chess is ChessPieceAdapter:
	# 	chess_id = chess.id
	# 	chess_rarity = chess.get_property("rarity", 0)
	# 	chess_level = chess.level
	# elif chess is ChessPieceEntity:
	# 	chess_id = chess.id
	# 	chess_rarity = chess.get_property("rarity", 0)
	# 	chess_level = chess.level

	var chess_data = {
		"id": chess_id,
		"rarity": chess_rarity,
		"level": chess_level
	}

	# 计算基础价格
	var base_price = price_calculator.calculate_base_price(chess_data)

	# 根据棋子等级调整价格
	var level_factor = 0.5 + (chess_level - 1) * 0.25 # 1级50%，2级75%，3级100%

	return int(base_price * level_factor)

# 获取物品类型
func _get_item_type(item) -> String:
	return "chess"

# 同步经济参数
func sync_economy_params() -> void:
	# 更新保底阈值
	var difficulty = GameManager.get_difficulty()
	pity_threshold = 5 - difficulty # 难度越高，保底阈值越低
