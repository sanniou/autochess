extends "res://scripts/managers/core/base_manager.gd"
class_name PlayerManager
## 玩家管理器
## 管理玩家实例和相关操作

# 玩家状态
enum PlayerState {
	IDLE,       # 空闲状态
	PREPARING,  # 准备阶段
	BATTLING,   # 战斗阶段
	SHOPPING,   # 商店阶段
	MAP,        # 地图阶段
	EVENT       # 事件阶段
}

# 当前玩家
var current_player: Player = null

# AI对手列表
var ai_opponents: Array[Player] = []

# 当前对手
var current_opponent: Player = null

# 当前玩家状态
var current_state: PlayerState = PlayerState.IDLE

## 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "PlayerManager"

	# 添加依赖
	add_dependency("ConfigManager")

	# 连接信号
	_connect_event_signals()

	_log_info("玩家管理器初始化完成")

## 连接事件信号
func _connect_event_signals() -> void:
	# 游戏事件
	GlobalEventBus.game.add_listener("game_started", _on_game_started)
	GlobalEventBus.game.add_listener("game_state_changed", _on_game_state_changed)

	# 战斗事件
	GlobalEventBus.battle.add_listener("battle_ended", _on_battle_ended)

	# 棋子事件
	GlobalEventBus.chess.add_listener("chess_piece_created", _on_chess_piece_created)

	# 经济事件
	EventBus.economy.connect_event("item_purchased", _on_item_purchased)

	# 装备事件
	EventBus.equipment.connect_event("equipment_created", _on_equipment_created)

	# 遗物事件
	EventBus.relic.connect_event("relic_acquired", _on_relic_acquired)

	# 地图事件
	EventBus.map.connect_event("map_node_selected", _on_map_node_selected)
	EventBus.map.connect_event("rest_completed", _on_rest_completed)

	## 初始化玩家
## @param player_name 玩家名称
## @return void
func initialize_player(player_name: String = "玩家") -> void:
	current_player = Player.new(player_name)
	_log_info("玩家 '%s' 初始化完成" % player_name)
	EventBus.game.emit_event("player_initialized", [current_player])

## 初始化AI对手
## @param count 创建AI对手的数量
## @return void
func initialize_ai_opponents(count: int = 7) -> void:
	ai_opponents.clear()

	# 创建AI对手
	for i in range(count):
		var ai_name = "AI对手 %d" % (i + 1)
		var ai_player = Player.new(ai_name)
		ai_opponents.append(ai_player)

	_log_info("AI对手初始化完成，共 %d 个" % count)
	EventBus.game.emit_event("ai_opponents_initialized", [ai_opponents])

## 选择当前对手
## @return 选中的对手，如果没有对手则返回 null
func select_opponent() -> Player:
	if ai_opponents.is_empty():
		_log_warning("没有可用的AI对手")
		return null

	# 随机选择一个对手
	var index = randi() % ai_opponents.size()
	current_opponent = ai_opponents[index]

	_log_info("选择对手: %s" % current_opponent.player_name)
	EventBus.battle.emit_event("opponent_selected", [current_opponent])
	return current_opponent

## 获取当前玩家
## @return 当前玩家实例
func get_current_player() -> Player:
	if current_player == null:
		_log_warning("当前玩家未初始化")
	return current_player

## 获取当前对手
## @return 当前对手实例
func get_current_opponent() -> Player:
	if current_opponent == null:
		_log_warning("当前对手未选择")
	return current_opponent

## 添加经验值给玩家
## @param amount 要添加的经验值数量
## @return bool 是否添加成功
func add_exp(amount: int) -> bool:
	if current_player == null:
		_log_warning("无法添加经验：当前玩家未初始化")
		return false

	if amount <= 0:
		_log_warning("无法添加经验：数量必须大于0")
		return false

	# 调用玩家的add_exp方法
	current_player.add_exp(amount)
	_log_info("玩家获得经验: %d" % amount)
	return true

## 购买棋子
## @param piece_id 棋子ID
## @return 购买的棋子实例，如果购买失败则返回 null
func purchase_chess_piece(piece_id: String) -> ChessPieceEntity:
	if current_player == null:
		_log_warning("无法购买棋子：当前玩家未初始化")
		return null

	# 获取棋子配置
	var piece_config = GameManager.config_manager.get_chess_piece_config(piece_id)
	if piece_config == null:
		_log_warning("无法购买棋子：未找到棋子配置 %s" % piece_id)
		return null

	# 检查金币是否足够
	if current_player.gold < piece_config.cost:
		_log_warning("无法购买棋子：金币不足 (需要 %d, 当前 %d)" % [piece_config.cost, current_player.gold])
		return null

	# 创建棋子实例
	var piece = GameManager.chess_factory.create_chess_piece(piece_id)
	if piece == null:
		_log_warning("无法购买棋子：创建棋子实例失败 %s" % piece_id)
		return null

	# 扣除金币
	if current_player.spend_gold(piece_config.cost):
		# 添加到玩家棋子列表
		if current_player.add_chess_piece(piece):
			_log_info("玩家购买棋子: %s, 花费: %d 金币" % [piece_id, piece_config.cost])
			# 发送棋子购买信号
			EventBus.chess.emit_event("chess_piece_purchased", [piece, piece_config.cost])
			return piece
		else:
			_log_warning("无法购买棋子：添加棋子到玩家失败")
			# 退还金币
			current_player.add_gold(piece_config.cost)

	return null

## 出售棋子
## @param piece 要出售的棋子
## @return 是否出售成功
func sell_chess_piece(piece: ChessPieceEntity) -> bool:
	if current_player == null:
		_log_warning("无法出售棋子：当前玩家未初始化")
		return false

	if piece == null:
		_log_warning("无法出售棋子：棋子为空")
		return false

	var result = current_player.sell_chess_piece(piece)
	if result:
		_log_info("玩家出售棋子: %s, 获得: %d 金币" % [piece.id, piece.cost * piece.star_level])

	return result

## 回合开始处理
## @return void
func on_round_start() -> void:
	if current_player == null:
		_log_warning("无法处理回合开始：当前玩家未初始化")
		return

	# 处理玩家回合开始逻辑
	current_player.on_round_start()
	_log_info("玩家回合开始，自动获得基础收入和经验")

	# 自动刷新商店
	EventBus.economy.emit_event("shop_refresh_requested", [current_player.level])
	_log_info("商店自动刷新，玩家等级: %d" % current_player.level)

	# 更新玩家状态
	current_state = PlayerState.PREPARING
	EventBus.game.emit_event("player_state_changed", [PlayerState.PREPARING])

## 战斗结束处理
## @param result 战斗结果字典
## @return void
func _on_battle_ended(result: Dictionary) -> void:
	if current_player == null:
		_log_warning("无法处理战斗结束：当前玩家未初始化")
		return

	# 处理战斗结果
	var is_victory = result.get("is_victory", false)
	if is_victory:
		# 玩家胜利
		current_player.on_battle_win()
		_log_info("玩家战斗胜利，连胜数: %d" % current_player.win_streak)
	else:
		# 玩家失败
		var player_impact = result.get("player_impact", {})
		var damage = player_impact.get("health_change", -10) * -1  # 转换为正数
		current_player.on_battle_loss(damage)
		_log_info("玩家战斗失败，损失生命值: %d, 当前生命值: %d" % [damage, current_player.current_health])

## 游戏开始事件处理
## @return void
func _on_game_started() -> void:
	_log_info("游戏开始，初始化玩家和AI对手")

	# 初始化玩家
	initialize_player()

	# 初始化AI对手
	initialize_ai_opponents()

## 棋子创建事件处理
## @param piece 创建的棋子
## @return void
func _on_chess_piece_created(piece: ChessPieceEntity) -> void:
	if piece == null:
		return

	_log_info("棋子创建: %s, 类型: %s, 星级: %d" % [piece.id, piece.type, piece.star_level])

	# 检查棋子是否属于当前玩家
	if current_player != null:
		if current_player.chess_pieces.has(piece) or current_player.bench_pieces.has(piece):
			# 更新玩家棋子统计
			EventBus.game.emit_event("player_chess_updated", [current_player.chess_pieces.size(), current_player.bench_pieces.size()])

## 物品购买事件处理
## @param item_data 购买的物品数据
## @return void
func _on_item_purchased(item_data: Dictionary) -> void:
	if item_data.is_empty():
		return

	_log_info("物品购买: %s, 花费: %d 金币" % [item_data.get("id", "unknown"), item_data.get("cost", 0)])

	# 更新玩家物品统计
	if current_player != null:
		EventBus.game.emit_event("player_inventory_updated", [current_player.gold])

## 装备创建事件处理
## @param equipment 创建的装备
## @return void
func _on_equipment_created(equipment: Equipment) -> void:
	if equipment == null:
		return

	_log_info("装备创建: %s, 类型: %s" % [equipment.id, equipment.type])

	# 更新玩家装备统计
	if current_player != null:
		EventBus.game.emit_event("player_equipment_updated", [current_player.equipments.size()])

## 遗物获取事件处理
## @param relic 获取的遗物
## @return void
func _on_relic_acquired(relic) -> void:
	if relic == null:
		return

	_log_info("遗物获取: %s" % relic.id)

	# 更新玩家遗物统计
	if current_player != null:
		EventBus.game.emit_event("player_relic_updated", [current_player.relics.size()])

## 获取玩家存档数据
## @return 玩家存档数据字典
func get_save_data() -> Dictionary:
	if current_player == null:
		_log_warning("无法获取存档数据：当前玩家未初始化")
		return {}

	var save_data = current_player.get_save_data()
	_log_info("玩家存档数据生成完成")
	return save_data

## 从存档数据加载
## @param data 存档数据字典
## @return void
func load_from_save_data(data: Dictionary) -> void:
	if data.is_empty():
		_log_warning("无法加载存档数据：数据为空")
		return

	if current_player == null:
		_log_info("初始化玩家以加载存档数据")
		initialize_player()

	current_player.load_from_save_data(data)
	_log_info("玩家存档数据加载完成")

## 重置管理器
## @return 是否重置成功
func reset() -> bool:
	_log_info("重置玩家管理器")

	if current_player != null:
		current_player.reset()
		_log_info("玩家数据已重置")

	ai_opponents.clear()
	current_opponent = null
	current_state = PlayerState.IDLE

	_log_info("玩家管理器重置完成")
	return true

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			# 游戏事件
			GlobalEventBus.game.remove_listener("game_started", _on_game_started)
			GlobalEventBus.game.remove_listener("game_state_changed", _on_game_state_changed)

			# 战斗事件
			GlobalEventBus.battle.remove_listener("battle_ended", _on_battle_ended)

			# 棋子事件
			GlobalEventBus.chess.remove_listener("chess_piece_created", _on_chess_piece_created)

			# 经济事件
			EventBus.economy.disconnect_event("item_purchased", _on_item_purchased)

			# 装备事件
			EventBus.equipment.disconnect_event("equipment_created", _on_equipment_created)

			# 遗物事件
			EventBus.relic.disconnect_event("relic_acquired", _on_relic_acquired)

			# 地图事件
			EventBus.map.disconnect_event("map_node_selected", _on_map_node_selected)
			EventBus.map.disconnect_event("rest_completed", _on_rest_completed)

	# 清理玩家数据
	if current_player != null:
		current_player.free()
		current_player = null

	# 清理AI对手
	for opponent in ai_opponents:
		opponent.free()
	ai_opponents.clear()
	current_opponent = null

	# 重置状态
	current_state = PlayerState.IDLE

	_log_info("玩家管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 重置玩家数据
	if current_player != null:
		current_player.reset()

	# 清理AI对手
	ai_opponents.clear()
	current_opponent = null

	# 重置状态
	current_state = PlayerState.IDLE

	_log_info("玩家管理器重置完成")

## 游戏状态变化处理
## @param old_state 旧游戏状态
## @param new_state 新游戏状态
## @return void
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	var old_player_state = current_state

	# 根据游戏状态更新玩家状态
	match new_state:
		GameManager.GameState.MAIN_MENU:
			current_state = PlayerState.IDLE
		GameManager.GameState.MAP:
			current_state = PlayerState.MAP
		GameManager.GameState.BATTLE:
			current_state = PlayerState.BATTLING
		GameManager.GameState.SHOP:
			current_state = PlayerState.SHOPPING
		GameManager.GameState.EVENT:
			current_state = PlayerState.EVENT

	# 如果状态发生变化，发送信号
	if old_player_state != current_state:
		_log_info("玩家状态变化: %s -> %s" % [_get_state_name(old_player_state), _get_state_name(current_state)])
		EventBus.game.emit_event("player_state_changed", [old_player_state, current_state])

## 地图节点选择处理
## @param node_data 选择的地图节点数据
## @return void
func _on_map_node_selected(node_data: Dictionary) -> void:
	if node_data.is_empty():
		_log_warning("无法处理地图节点选择：节点数据为空")
		return

	_log_info("选择地图节点: %s" % node_data.get("type", "unknown"))

	# 处理地图节点选择后的玩家状态变化
	if node_data.get("type", "") == "rest":
		# 如果是休息节点，恢复生命值
		if node_data.has("heal_amount") and current_player != null:
			var heal_amount = node_data.get("heal_amount", 0)
			current_player.heal(heal_amount)
			_log_info("休息节点恢复生命值: %d, 当前生命值: %d" % [heal_amount, current_player.current_health])

## 休息完成处理
## @param heal_amount 恢复的生命值数量
## @return void
func _on_rest_completed(heal_amount: int) -> void:
	if current_player == null:
		_log_warning("无法处理休息完成：当前玩家未初始化")
		return

	# 恢复玩家生命值
	var old_health = current_player.current_health
	current_player.heal(heal_amount)
	_log_info("休息完成，恢复生命值: %d, 生命值变化: %d -> %d" % [heal_amount, old_health, current_player.current_health])

## 添加金币
## @param amount 要添加的金币数量
## @return void
func add_gold(amount: int) -> bool:
	if current_player == null:
		_log_warning("无法添加金币：当前玩家未初始化")
		return false

	if amount <= 0:
		_log_warning("无法添加金币：数量必须大于0")
		return false

	var old_gold = current_player.gold
	current_player.add_gold(amount)
	_log_info("玩家获得金币: %d, 金币变化: %d -> %d" % [amount, old_gold, current_player.gold])
	return true

## 恢复玩家生命值
## @param amount 要恢复的生命值数量
## @return void
func heal_player(amount: int) -> bool:
	if current_player == null:
		_log_warning("无法恢复生命值：当前玩家未初始化")
		return false

	if amount <= 0:
		_log_warning("无法恢复生命值：数量必须大于0")
		return false

	var old_health = current_player.current_health
	current_player.heal(amount)
	_log_info("玩家恢复生命值: %d, 生命值变化: %d -> %d" % [amount, old_health, current_player.current_health])
	return true

## 获取玩家状态
## @return 当前玩家状态
func get_player_state() -> PlayerState:
	return current_state

## 获取状态名称
## @param state 状态枚举值
## @return 状态名称字符串
func _get_state_name(state: PlayerState) -> String:
	match state:
		PlayerState.IDLE:
			return "IDLE"
		PlayerState.PREPARING:
			return "PREPARING"
		PlayerState.BATTLING:
			return "BATTLING"
		PlayerState.SHOPPING:
			return "SHOPPING"
		PlayerState.MAP:
			return "MAP"
		PlayerState.EVENT:
			return "EVENT"
		_:
			return "UNKNOWN"
