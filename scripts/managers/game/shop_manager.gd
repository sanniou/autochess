extends "res://scripts/managers/core/base_manager.gd"
class_name ShopManager
## 商店管理器
## 管理商店物品的生成、购买和刷新

# 常量
const MAX_CHESS_ITEMS = 5  # 最大棋子商品数
const MAX_EQUIPMENT_ITEMS = 3  # 最大装备商品数
const MAX_RELIC_ITEMS = 3  # 最大遗物商品数
const DEFAULT_REFRESH_COST = 2  # 默认刷新费用
const DEFAULT_EQUIPMENT_COST = 3  # 默认装备价格
const DEFAULT_RELIC_COST = 5  # 默认遗物价格

# 特殊商店常量
const BLACK_MARKET_CHANCE = 0.35  # 黑市商人出现概率(每3回合检查)
const MYSTERY_SHOP_CHANCE = 0.40  # 神秘商店出现概率(精英战斗胜利后)
const EQUIPMENT_SHOP_ROUNDS = [3, 6, 9]  # 装备商店出现的回合
const RELIC_SHOP_ROUNDS = [5, 10]  # 遗物商店出现的回合

# 商店参数
var shop_params = {
	"refresh_cost": DEFAULT_REFRESH_COST,  # 刷新费用
	"equipment_cost": DEFAULT_EQUIPMENT_COST,  # 装备固定价格
	"relic_cost": DEFAULT_RELIC_COST,  # 遗物固定价格
	"discount_rate": 1.0,  # 折扣率，1.0表示无折扣
	"max_chess_items": MAX_CHESS_ITEMS,  # 最大棋子商品数
	"max_equipment_items": MAX_EQUIPMENT_ITEMS,  # 最大装备商品数
	"max_relic_items": MAX_RELIC_ITEMS,  # 最大遗物商品数
	"special_offer": false,  # 是否有特价商品
	"is_black_market": false,  # 是否为黑市商人
	"is_mystery_shop": false,  # 是否为神秘商店
	"is_equipment_shop": false,  # 是否为装备商店
	"is_relic_shop": false,  # 是否为遗物商店
	"consecutive_refresh_count": 0,  # 连续刷新次数（用于保底机制）
	"target_chess_id": ""  # 目标棋子ID（用于保底机制）
}

# 商店状态
var is_locked = false

# 商店物品
var shop_items = {
	"chess": [],
	"equipment": [],
	"relic": []
}

# 获取商店物品
func get_shop_items() -> Dictionary:
	return shop_items

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ShopManager"

	# 添加依赖
	add_dependency("ConfigManager")
	add_dependency("PlayerManager")
	add_dependency("EconomyManager")
	add_dependency("EquipmentManager")
	add_dependency("SynergyManager")
	add_dependency("StatsManager")
	add_dependency("RelicManager")

	# 原 _ready 函数的内容
	# 加载事件定义
	var event_definitions = load("res://scripts/events/event_definitions.gd")

	# 连接信号 - 使用规范的事件连接方式
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
	EventBus.economy.connect_event("shop_refreshed", _on_shop_refreshed)
	EventBus.map.connect_event("map_node_selected", _on_map_node_selected)
	EventBus.game.connect_event(event_definitions.GameEvents.DIFFICULTY_CHANGED, _on_difficulty_changed)

	# 从经济管理器同步参数
	_sync_with_economy_manager()

	_log_info("商店管理器初始化完成")

# 刷新商店
func refresh_shop(force: bool = false) -> bool:
	# 检查是否锁定
	if is_locked and not force:
		return false

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 如果不是强制刷新，增加连续刷新计数
	if not force and shop_params.target_chess_id != "":
		shop_params.consecutive_refresh_count += 1

	# 生成新的棋子
	_generate_chess_items(player.level)

	# 生成新的装备
	_generate_equipment_items(player.level)

	# 生成新的遗物
	_generate_relic_items(player.level)

	# 应用保底机制
	_apply_pity_system(player.level)

	# 发送商店刷新信号
	EventBus.economy.emit_event("shop_refreshed", [])

	return true

# 手动刷新商店（需要花费金币）
func manual_refresh_shop() -> bool:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 获取当前刷新费用
	var refresh_cost = get_current_refresh_cost()

	# 检查金币是否足够
	if player.gold < refresh_cost:
		return false

	# 扣除金币
	if player.spend_gold(refresh_cost):
		# 刷新商店
		var result = refresh_shop()

		# 发送刷新事件
		if result:
			EventBus.economy.emit_event("shop_manually_refreshed", [refresh_cost])

		return result

	return false

# 锁定/解锁商店
func toggle_shop_lock() -> bool:
	is_locked = !is_locked
	return is_locked

# 购买棋子
func purchase_chess(chess_index: int) -> ChessPiece:
	# 检查索引是否有效
	if chess_index < 0 or chess_index >= shop_items.chess.size():
		return null

	# 获取棋子ID
	var chess_id = shop_items.chess[chess_index]

	# 从 ChessManager 获取棋子实例
	var chess_piece = GameManager.chess_manager.get_chess(chess_id)
	if chess_piece == null:
		return null

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return null

	# 获取当前棋子价格
	var chess_cost = get_current_chess_cost(chess_piece)

	# 检查金币是否足够
	if player.gold < chess_cost:
		return null

	# 扣除金币
	if player.spend_gold(chess_cost):
		# 添加到玩家棋子列表
		if player.add_chess_piece(chess_piece):
			# 从商店移除
			shop_items.chess.remove_at(chess_index)

			# 获取棋子数据用于事件
			var chess_config = ConfigManager.get_chess_piece_config(chess_id)
			var purchase_data = chess_config.get_data()
			purchase_data["type"] = "chess_piece"
			purchase_data["cost"] = chess_cost

			# 发送物品购买信号
			EventBus.economy.emit_event("item_purchased", [purchase_data])

			return chess_piece
		else:
			# 添加失败，退还金币
			player.add_gold(chess_cost)

	return null

# 购买装备
func purchase_equipment(equipment_index: int) -> Equipment:
	# 检查索引是否有效
	if equipment_index < 0 or equipment_index >= shop_items.equipment.size():
		return null

	# 获取装备ID
	var equipment_id = shop_items.equipment[equipment_index]

	# 获取装备实例来获取装备数据
	var equipment_instance = GameManager.equipment_manager.get_equipment(equipment_id)
	if equipment_instance == null:
		return null

	# 获取装备数据
	var equipment_data = equipment_instance.get_data()

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return null

	# 获取当前装备价格
	var equipment_cost = get_current_equipment_cost(equipment_instance)

	# 检查金币是否足够
	if player.gold < equipment_cost:
		return null

	# 扣除金币
	if player.spend_gold(equipment_cost):
		# 获取装备实例
		var equipment = GameManager.equipment_manager.get_equipment(equipment_id)
		if equipment == null:
			# 退还金币
			player.add_gold(equipment_cost)
			return null

		# 添加到玩家装备列表
		if player.add_equipment(equipment):
			# 从商店移除
			shop_items.equipment.remove_at(equipment_index)

			# 添加购买类型信息
			var purchase_data = equipment_data.duplicate()
			purchase_data["type"] = "equipment"
			purchase_data["cost"] = equipment_cost

			# 发送物品购买信号
			EventBus.economy.emit_event("item_purchased", [purchase_data])

			return equipment
		else:
			# 添加失败，退还金币
			player.add_gold(equipment_cost)

	return null

# 购买经验
func purchase_exp() -> bool:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 获取当前经验价格和数量
	var exp_cost = get_current_exp_cost()
	var exp_amount = GameManager.economy_manager.get_exp_purchase_amount()

	# 检查金币是否足够
	if player.gold < exp_cost:
		return false

	# 扣除金币
	if player.spend_gold(exp_cost):
		# 添加经验
		player.add_exp(exp_amount)

		# 添加购买类型信息
		var purchase_data = {
			"type": "exp",
			"cost": exp_cost,
			"amount": exp_amount
		}

		# 发送物品购买信号
		EventBus.economy.emit_event("item_purchased", [purchase_data])

		return true

	return false

# 购买遗物
func purchase_relic(relic_index: int) -> Relic:
	# 检查索引是否有效
	if relic_index < 0 or not shop_items.has("relic") or relic_index >= shop_items.relic.size():
		return null

	# 获取遗物数据
	var relic_data = shop_items.relic[relic_index]

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return null

	# 获取当前遗物价格
	var relic_cost = get_current_relic_cost(relic_data)

	# 检查金币是否足够
	if player.gold < relic_cost:
		return null

	# 扣除金币
	if player.spend_gold(relic_cost):
		# 获取遗物实例
		var relic = GameManager.relic_manager.acquire_relic(relic_data.id, player)
		if relic == null:
			# 退还金币
			player.add_gold(relic_cost)
			return null

		# 从商店移除
		shop_items.relic.remove_at(relic_index)

		# 添加购买类型信息
		var purchase_data = relic_data.duplicate()
		purchase_data["type"] = "relic"
		purchase_data["cost"] = relic_cost

		# 发送物品购买信号
		EventBus.economy.emit_event("item_purchased", [purchase_data])

		return relic

	return null

# 出售棋子
func sell_chess(chess_piece) -> bool:
	# 检查棋子是否有效
	if chess_piece == null:
		return false

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 获取棋子数据
	var chess_id = chess_piece.id
	var chess_data = ConfigManager.get_chess_piece_config(chess_id)
	if chess_data == null:
		return false

	# 计算出售价格（通常是原价格的一半）
	var sell_price = int(chess_data.cost * 0.5)

	# 从玩家棋子列表中移除
	if player.remove_chess_piece(chess_piece):
		# 添加金币
		player.add_gold(sell_price)

		# 添加出售类型信息
		var sell_data = chess_data.duplicate()
		sell_data["type"] = "chess_piece"
		sell_data["price"] = sell_price

		# 发送物品出售信号
		EventBus.economy.emit_event("item_sold", [sell_data])

		return true

	return false

# 出售装备
func sell_equipment(equipment: Equipment) -> bool:
	# 检查装备是否有效
	if equipment == null:
		return false

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return false

	# 获取装备数据
	var equipment_data = equipment.get_data()
	if equipment_data.is_empty():
		return false

	# 计算出售价格（通常是原价格的一半）
	var sell_price = int(shop_params.equipment_cost * 0.5)

	# 从玩家装备列表中移除
	if player.remove_equipment(equipment):
		# 添加金币
		player.add_gold(sell_price)

		# 添加出售类型信息
		var sell_data = equipment_data.duplicate()
		sell_data["type"] = "equipment"
		sell_data["price"] = sell_price

		# 发送物品出售信号
		EventBus.economy.emit_event("item_sold", [sell_data])

		return true

	return false

# 获取当前刷新费用
func get_current_refresh_cost() -> int:
	return int(GameManager.economy_manager.get_refresh_cost() * shop_params.discount_rate)

# 获取当前棋子价格
func get_current_chess_cost(chess_piece: ChessPiece) -> int:
	# 获取棋子基础价格
	var base_cost = chess_piece.cost

	# 应用折扣
	return int(base_cost * shop_params.discount_rate)

# 获取当前装备价格
func get_current_equipment_cost(equipment) -> int:
	# 基础价格
	var base_cost = shop_params.equipment_cost

	# 根据装备品质调整价格
	var tier_multiplier = 1.0
	var tier = GameManager.equipment_manager.get_tier_from_equipment_id(equipment.id)

	match tier:
		EquipmentTierManager.EquipmentTier.MAGIC: tier_multiplier = 1.5
		EquipmentTierManager.EquipmentTier.RARE: tier_multiplier = 2.0
		EquipmentTierManager.EquipmentTier.EPIC: tier_multiplier = 3.0
		EquipmentTierManager.EquipmentTier.LEGENDARY: tier_multiplier = 5.0

	return int(base_cost * tier_multiplier * shop_params.discount_rate)

# 获取当前遗物价格
func get_current_relic_cost(relic_data: Dictionary) -> int:
	var base_cost = relic_data.get("cost", shop_params.relic_cost)
	return int(base_cost * shop_params.discount_rate)

# 获取当前经验价格
func get_current_exp_cost() -> int:
	return int(GameManager.economy_manager.get_exp_purchase_cost() * shop_params.discount_rate)

# 应用折扣
func apply_discount(discount_rate: float) -> void:
	# 确保折扣率在合理范围内
	discount_rate = clamp(discount_rate, 0.1, 2.0)

	# 设置折扣率
	shop_params.discount_rate = discount_rate

	# 发送折扣应用信号
	EventBus.economy.emit_event("shop_discount_applied", [discount_rate])

# 添加特定物品
func add_specific_item(item_id: String) -> bool:
	# 检查是否是棋子
	var chess_data = ConfigManager.get_chess_piece_config(item_id)
	if chess_data != null:
		# 存储棋子ID而不是配置
		shop_items.chess.append(item_id)
		return true

	# 检查是否是装备
	if ConfigManager.get_equipment_config(item_id) != null:
		shop_items.equipment.append(item_id)
		return true

	# 检查是否是遗物
	var relic_data = GameManager.relic_manager.get_relic_data(item_id)
	if not relic_data.is_empty():
		shop_items.relic.append(relic_data)
		return true

	return false



# 获取商店参数
func get_shop_params() -> Dictionary:
	return shop_params.duplicate(true)

# 设置商店参数
func set_shop_params(params: Dictionary) -> void:
	# 更新商店参数
	for key in params:
		if shop_params.has(key):
			shop_params[key] = params[key]

# 生成棋子商品
func _generate_chess_items(player_level: int) -> void:
	shop_items.chess.clear()

	# 使用ChessManager刷新商店库存
	GameManager.chess_manager.refresh_shop_inventory(shop_params.max_chess_items, player_level)

	# 获取商店库存
	shop_items.chess = GameManager.chess_manager.get_shop_inventory()

# 生成装备商品
func _generate_equipment_items(player_level: int) -> void:
	shop_items.equipment.clear()

	# 使用装备管理器刷新商店库存
	GameManager.equipment_manager.refresh_shop_inventory(shop_params.max_equipment_items, player_level)
	shop_items.equipment = GameManager.equipment_manager.get_shop_inventory()

# 生成遗物商品
func _generate_relic_items(player_level: int) -> void:
	shop_items.relic.clear()

	# 如果不是遗物商店，且不是黑市或神秘商店，则不生成遗物
	if not shop_params.is_relic_shop and not shop_params.is_black_market and not shop_params.is_mystery_shop:
		return

	# 获取随机遗物
	var relic_count = shop_params.max_relic_items
	var exclude_ids = []

	# 获取玩家已有的遗物ID
	var player_relics = GameManager.relic_manager.get_player_relics()
	for relic in player_relics:
		exclude_ids.append(relic.id)

	# 获取随机遗物ID
	var relic_ids = GameManager.relic_manager.get_random_relics(relic_count, -1, exclude_ids)

	# 添加遗物ID到商店
	for relic_id in relic_ids:
		# 直接存储遗物ID而不是配置
		shop_items.relic.append(relic_id)

# 获取棋子品质
func get_tier_from_chess_id(chess_id: String) -> int:
	return GameManager.chess_manager.get_tier_from_chess_id(chess_id)

# 从经济管理器同步参数
func _sync_with_economy_manager() -> void:
	shop_params.refresh_cost = GameManager.economy_manager.get_refresh_cost()
	shop_params.equipment_cost = GameManager.economy_manager.get_economy_params().get("equipment_cost", DEFAULT_EQUIPMENT_COST)

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 重置特殊商店状态
	shop_params.is_black_market = false
	shop_params.is_mystery_shop = false
	shop_params.is_equipment_shop = false
	shop_params.is_relic_shop = false

	# 检查黑市商人触发
	if round_number % 3 == 0 and Utils.randf_bool(BLACK_MARKET_CHANCE):
		_trigger_black_market()

	# 检查装备商店触发
	if EQUIPMENT_SHOP_ROUNDS.has(round_number):
		_trigger_equipment_shop()

	# 检查遗物商店触发
	if RELIC_SHOP_ROUNDS.has(round_number):
		_trigger_relic_shop()

	# 刷新商店
	refresh_shop(true)

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	# 记录刷新次数统计
	var stats_manager = GameManager.stats_manager
	if stats_manager:
		stats_manager.increment_stat("shop_refreshes")

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 检查是否是商店节点
	if node_data.type == "shop":
		# 重置特殊商店状态
		shop_params.is_black_market = false
		shop_params.is_mystery_shop = false
		shop_params.is_equipment_shop = false

		# 应用商店节点特性
		if node_data.has("discount") and node_data.discount:
			# 应用折扣
			apply_discount(0.8)  # 80%折扣
		else:
			# 重置折扣
			apply_discount(1.0)

		# 检查是否是特殊商店
		if node_data.has("shop_type"):
			match node_data.shop_type:
				"black_market":
					_trigger_black_market()
				"mystery_shop":
					_trigger_mystery_shop()
				"equipment_shop":
					_trigger_equipment_shop()

		# 刷新商店
		refresh_shop(true)

	# 检查是否是精英战斗节点
	else:
		if node_data.type == "elite_battle" and node_data.has("result") and node_data.result == "victory":
			# 检查神秘商店触发
			if Utils.randf_bool(MYSTERY_SHOP_CHANCE):
				_trigger_mystery_shop()
				refresh_shop(true)

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int) -> void:
	# 重新同步经济参数
	_sync_with_economy_manager()

# 触发黑市商人
func _trigger_black_market() -> void:
	# 设置黑市商人状态
	shop_params.is_black_market = true

	# 应用折扣，随机60-80%折扣
	var discount_rate = randf_range(0.6, 0.8)
	apply_discount(discount_rate)

	# 增加特殊道具
	_add_special_black_market_items()

	# 发送黑市商人触发信号
	EventBus.debug.emit_event("debug_message", ["黑市商人出现了！", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.shop.black_market_appeared")])

# 触发神秘商店
func _trigger_mystery_shop() -> void:
	# 设置神秘商店状态
	shop_params.is_mystery_shop = true

	# 添加高级棋子
	_add_high_tier_chess_pieces()

	# 添加高级遗物
	_add_high_tier_relics()

	# 发送神秘商店触发信号
	EventBus.debug.emit_event("debug_message", ["神秘商店出现了！", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.shop.mystery_shop_appeared")])

# 触发装备商店
func _trigger_equipment_shop() -> void:
	# 设置装备商店状态
	shop_params.is_equipment_shop = true

	# 增加装备数量
	shop_params.max_equipment_items = 6

	# 发送装备商店触发信号
	EventBus.debug.emit_event("debug_message", ["装备商店出现了！", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.shop.equipment_shop_appeared")])

# 触发遗物商店
func _trigger_relic_shop() -> void:
	# 设置遗物商店状态
	shop_params.is_relic_shop = true

	# 增加遗物数量
	shop_params.max_relic_items = 4

	# 发送遗物商店触发信号
	EventBus.debug.emit_event("debug_message", ["遗物商店出现了！", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.shop.relic_shop_appeared")])

# 添加黑市特殊道具
func _add_special_black_market_items() -> void:
	# 获取当前玩家等级
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return

	# 随机添加特殊道具
	var special_items = [
		"equipment_disassembler",  # 装备分解券
		"chess_transformer",       # 棋子改造卷轴
		"refresh_token",          # 免费刷新令牌
		"exp_potion"              # 经验药水
	]

	# 随机选择1-2个特殊道具添加到商店
	var num_items = 1 + int(Utils.randf_bool(0.5))

	# 使用 Utils 的 choose_multiple 方法随机选择多个元素
	var selected_items = Utils.choose_multiple(special_items, num_items)
	for item_id in selected_items:
		add_specific_item(item_id)

	# 添加随机遗物
	var exclude_ids = []

	# 获取玩家已有的遗物ID
	var player_relics = GameManager.relic_manager.get_player_relics()
	for relic in player_relics:
		exclude_ids.append(relic.id)

	# 获取随机遗物ID
	var relic_id = GameManager.relic_manager.get_random_relic(-1, exclude_ids)
	if relic_id != "":
		var relic_data = GameManager.relic_manager.get_relic_data(relic_id)
		if not relic_data.is_empty():
			shop_items.relic.append(relic_data)

# 添加高级棋子
func _add_high_tier_chess_pieces() -> void:
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if player == null:
		return

	# 获取玩家阵容相关的棋子
	var player_synergies = []
	player_synergies = GameManager.synergy_manager.get_active_synergies()
	var related_chess_pieces = []

	# 根据玩家的羁绊找出相关棋子
	for synergy in player_synergies:
		var synergy_chess = ConfigManager.get_chess_pieces_by_synergy(synergy.id)
		related_chess_pieces.append_array(synergy_chess)

	# 如果没有相关棋子，使用高费用棋子
	if related_chess_pieces.is_empty():
		var high_cost_chess = ConfigManager.get_chess_pieces_by_cost([4, 5])
		related_chess_pieces.append_array(high_cost_chess)

	# 清空当前棋子库
	shop_items.chess.clear()

	# 添加相关棋子到商店
	var max_items = min(shop_params.max_chess_items, related_chess_pieces.size())
	for i in range(max_items):
		if related_chess_pieces.size() > 0:
			var index = randi() % related_chess_pieces.size()
			var chess_config = related_chess_pieces[index]
			# 存储棋子ID而不是配置
			var chess_id = chess_config.get_id()
			shop_items.chess.append(chess_id)
			related_chess_pieces.remove_at(index)

# 应用保底机制
func _apply_pity_system(player_level: int) -> void:
	# 检查目标棋子保底机制
	if shop_params.target_chess_id != "" and shop_params.consecutive_refresh_count >= 3:
		# 第4次刷新必出目标棋子
		var chess_data = ConfigManager.get_chess_piece_config(shop_params.target_chess_id)
		if chess_data != null and not shop_items.chess.has(shop_params.target_chess_id):
			# 添加目标棋子ID
			shop_items.chess.append(shop_params.target_chess_id)

			# 如果超过最大棋子数量，移除一个
			if shop_items.chess.size() > shop_params.max_chess_items:
				shop_items.chess.remove_at(0)

			# 重置计数器
			shop_params.consecutive_refresh_count = 0
			shop_params.target_chess_id = ""

			# 发送保底触发信号
			EventBus.debug.emit_event("debug_message", ["保底机制触发，目标棋子出现", 0])

	# 检查高等级保底机制
	if player_level >= 8:
		# 检查是否有至少4费以上棋子
		var has_high_cost_chess = false
		for chess_id in shop_items.chess:
			var chess_config = ConfigManager.get_chess_piece_config(chess_id)
			if chess_config and chess_config.get_cost() >= 4:
				has_high_cost_chess = true
				break

		# 如果没有高费用棋子，添加一个
		if not has_high_cost_chess:
			var high_cost_chess = ConfigManager.get_chess_pieces_by_cost([4, 5])
			if not high_cost_chess.is_empty():
				var random_index = randi() % high_cost_chess.size()
				var chess_config = high_cost_chess[random_index]

				# 添加高费用棋子ID
				var chess_id = chess_config.get_id()
				shop_items.chess.append(chess_id)

				# 如果超过最大棋子数量，移除一个
				if shop_items.chess.size() > shop_params.max_chess_items:
					# 移除一个低费用棋子
					var lowest_cost_index = 0
					var lowest_cost = 5
					for i in range(shop_items.chess.size() - 1):  # 不检查刚添加的棋子
						var piece_config = ConfigManager.get_chess_piece_config(shop_items.chess[i])
						if piece_config and piece_config.cost < lowest_cost:
							lowest_cost = piece_config.cost
							lowest_cost_index = i
					shop_items.chess.remove_at(lowest_cost_index)

# 设置目标棋子（用于保底机制）
func set_target_chess(chess_id: String) -> void:
	shop_params.target_chess_id = chess_id
	shop_params.consecutive_refresh_count = 0

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.battle.disconnect_event("battle_round_started", _on_battle_round_started)
			EventBus.economy.disconnect_event("shop_refreshed", _on_shop_refreshed)
			EventBus.map.disconnect_event("map_node_selected", _on_map_node_selected)

			# 断开难度变化事件
			var event_definitions = load("res://scripts/events/event_definitions.gd")
			EventBus.game.disconnect_event(event_definitions.GameEvents.DIFFICULTY_CHANGED, _on_difficulty_changed)

	# 清理商店数据
	shop_items.chess.clear()
	shop_items.equipment.clear()
	shop_items.relic.clear()

	# 重置商店参数
	shop_params.refresh_cost = DEFAULT_REFRESH_COST
	shop_params.equipment_cost = DEFAULT_EQUIPMENT_COST
	shop_params.relic_cost = DEFAULT_RELIC_COST
	shop_params.discount_rate = 1.0
	shop_params.special_offer = false
	shop_params.is_black_market = false
	shop_params.is_mystery_shop = false
	shop_params.is_equipment_shop = false
	shop_params.is_relic_shop = false
	shop_params.consecutive_refresh_count = 0
	shop_params.target_chess_id = ""

	# 重置商店锁定状态
	is_locked = false

	_log_info("商店管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 清理商店数据
	shop_items.chess.clear()
	shop_items.equipment.clear()
	shop_items.relic.clear()

	# 重置商店参数
	shop_params.refresh_cost = DEFAULT_REFRESH_COST
	shop_params.equipment_cost = DEFAULT_EQUIPMENT_COST
	shop_params.relic_cost = DEFAULT_RELIC_COST
	shop_params.discount_rate = 1.0
	shop_params.special_offer = false
	shop_params.is_black_market = false
	shop_params.is_mystery_shop = false
	shop_params.is_equipment_shop = false
	shop_params.is_relic_shop = false
	shop_params.consecutive_refresh_count = 0
	shop_params.target_chess_id = ""

	# 重置商店锁定状态
	is_locked = false

	# 从经济管理器同步参数
	_sync_with_economy_manager()

	_log_info("商店管理器重置完成")

# 添加高级遗物
func _add_high_tier_relics() -> void:
	# 清空当前遗物库
	shop_items.relic.clear()

	# 获取玩家已有的遗物ID
	var exclude_ids = []
	var player_relics = GameManager.relic_manager.get_player_relics()
	for relic in player_relics:
		exclude_ids.append(relic.id)

	# 获取高级遗物（稀有度 2-3）
	var relic_ids = GameManager.relic_manager.get_random_relics(shop_params.max_relic_items, 2, exclude_ids)

	# 如果高级遗物不足，添加一些普通遗物
	if relic_ids.size() < shop_params.max_relic_items:
		var remaining = shop_params.max_relic_items - relic_ids.size()
		var common_relic_ids = GameManager.relic_manager.get_random_relics(remaining, 1, exclude_ids + relic_ids)
		relic_ids.append_array(common_relic_ids)

	# 添加遗物到商店
	for relic_id in relic_ids:
		var relic_data = GameManager.relic_manager.get_relic_data(relic_id)
		if not relic_data.is_empty():
			shop_items.relic.append(relic_data)
