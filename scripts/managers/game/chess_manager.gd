extends "res://scripts/managers/core/base_manager.gd"
class_name ChessManager
## 棋子管理器
## 负责管理棋子实例的创建、获取和缓存

# 信号
signal chess_created(chess_piece)
signal chess_released(chess_piece)
signal chess_merged(pieces, upgraded_piece)
signal chess_config_loaded(config_id)

# 棋子实例缓存 {棋子ID: 棋子实例}
var _chess_cache: Dictionary = {}

# 商店库存 (存储棋子实例的ID)
var _shop_inventory: Array = []

# 棋子场景路径
const CHESS_PIECE_ENTITY_SCENE = "res://scenes/game/chess/chess_piece_entity.tscn"

# 棋子配置缓存
var _chess_configs: Dictionary = {}

# 棋子工厂
var chess_factory: ChessPieceFactory = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ChessManager"

	# 添加依赖
	add_dependency("ConfigManager")

	# 连接事件
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 创建棋子工厂
	chess_factory = ChessPieceFactory.new()
	add_child(chess_factory)

	# 加载棋子配置
	_load_chess_configs()

	# 预热对象池
	chess_factory.warm_pool(10)

	_log_info("棋子管理器初始化完成")

## 加载棋子配置
func _load_chess_configs() -> void:
	# 从配置管理器获取棋子配置
	var chess_configs = ConfigManager.get_all_chess_pieces()

	# 清空现有配置
	_chess_configs.clear()

	# 加载所有棋子配置
	for chess_id in chess_configs:
		var chess_model = chess_configs[chess_id] as ChessPieceConfig
		_chess_configs[chess_id] = chess_model.get_data()

		# 发送配置加载信号
		chess_config_loaded.emit(chess_id)

# 获取棋子实例
func get_chess(chess_id: String) -> ChessPieceEntity:
	# 先从缓存查找
	if _chess_cache.has(chess_id):
		return _chess_cache[chess_id]

	# 从配置创建新实例
	var chess_piece = create_chess_piece(chess_id)
	if chess_piece:
		_chess_cache[chess_id] = chess_piece
		chess_created.emit(chess_piece)

	return chess_piece

## 创建棋子
func create_chess_piece(chess_id: String, star_level: int = 1, is_player_piece: bool = true) -> ChessPieceEntity:
	# 检查棋子配置是否存在
	if not _chess_configs.has(chess_id):
		_log_warning("未知的棋子配置: " + chess_id)
		return null

	# 获取棋子数据
	var chess_data = _chess_configs[chess_id].duplicate()

	# 设置星级和所属
	chess_data["level"] = star_level
	chess_data["is_player_piece"] = is_player_piece

	# 使用棋子工厂创建棋子
	var chess_piece = chess_factory.create_from_config(chess_id, is_player_piece)

	# 设置棋子等级
	if chess_piece:
		chess_piece.set_level(star_level)

		# 发送创建信号
		chess_created.emit(chess_piece)

	return chess_piece

# 释放棋子实例
func release_chess(chess_piece: ChessPieceEntity) -> void:
	if chess_piece:
		# 获取棋子ID
		var chess_id = chess_piece.id

		# 从缓存中移除
		if not chess_id.is_empty() and _chess_cache.has(chess_id):
			_chess_cache.erase(chess_id)

		# 释放棋子
		release_chess_piece(chess_piece)

		# 发送释放信号
		chess_released.emit(chess_piece)

## 释放棋子
func release_chess_piece(chess_piece: ChessPieceEntity) -> void:
	if not chess_piece:
		return

	# 使用棋子工厂回收棋子
	chess_factory.recycle_chess_piece(chess_piece)

## 合并棋子升级
func merge_chess_pieces(pieces: Array) -> ChessPieceEntity:
	if pieces.size() < 3:
		_log_warning("合并棋子需要至少3个相同棋子")
		return null

	# 检查棋子是否相同
	var first_piece = pieces[0] as ChessPieceEntity
	if not first_piece:
		_log_warning("无法识别的棋子类型")
		return null

	var chess_id = first_piece.id
	var star_level = first_piece.get_level()
	var is_player = first_piece.is_player_piece

	# 检查所有棋子是否相同
	for piece in pieces:
		var chess_piece = piece as ChessPieceEntity
		if not chess_piece:
			continue

		if chess_piece.id != chess_id or chess_piece.get_level() != star_level:
			_log_warning("合并棋子必须是相同类型和星级")
			return null

	# 如果已经是3星，无法再升级
	if star_level >= 3:
		_log_warning("3星棋子无法再升级")
		return null

	# 获取棋子的位置
	var position = first_piece.global_position

	# 创建升级后的棋子
	var upgraded_piece = create_chess_piece(chess_id, star_level + 1, is_player)

	# 设置升级后棋子的位置
	upgraded_piece.global_position = position

	# 释放原棋子
	for piece in pieces:
		release_chess(piece as ChessPieceEntity)

	# 发送合并完成信号
	chess_merged.emit(pieces, upgraded_piece)

	return upgraded_piece

# 刷新商店库存
func refresh_shop_inventory(count: int = 5, player_level: int = 1) -> void:
	_shop_inventory.clear()

	# 获取棋子池
	var chess_pool = _get_chess_pool_by_level(player_level)

	# 随机选择棋子
	for i in range(count):
		if chess_pool.size() > 0:
			var random_index = randi() % chess_pool.size()
			var chess_id = chess_pool[random_index].get_id()

			# 存储棋子ID
			_shop_inventory.append(chess_id)

	# 发送商店刷新信号
	EventBus.economy.emit_event("chess_shop_inventory_updated", [_shop_inventory])

# 获取商店库存
func get_shop_inventory() -> Array:
	return _shop_inventory

# 根据玩家等级获取棋子池
func _get_chess_pool_by_level(player_level: int) -> Array:
	var all_chess = ConfigManager.get_all_chess_pieces()
	var chess_pool = []

	# 根据等级设置不同费用棋子的出现概率
	var probabilities = _get_chess_probabilities(player_level)

	# 根据概率填充棋子池
	for chess_id in all_chess:
		var chess_config = all_chess[chess_id]
		var cost = chess_config.get_cost()

		# 检查该费用的棋子是否可以出现
		if probabilities.has(cost) and probabilities[cost] > 0:
			# 根据概率添加到池中
			var count = int(100 * probabilities[cost] / _get_chess_pool_size(cost))
			for i in range(count):
				chess_pool.append(chess_config)

	return chess_pool

# 获取棋子概率表
func _get_chess_probabilities(player_level: int) -> Dictionary:
	# 根据玩家等级返回不同费用棋子的出现概率
	match player_level:
		1: return {1: 1.00, 2: 0.00, 3: 0.00, 4: 0.00, 5: 0.00}
		2: return {1: 0.60, 2: 0.30, 3: 0.10, 4: 0.00, 5: 0.00}
		3: return {1: 0.50, 2: 0.35, 3: 0.15, 4: 0.00, 5: 0.00}
		4: return {1: 0.35, 2: 0.35, 3: 0.25, 4: 0.05, 5: 0.00}
		5: return {1: 0.20, 2: 0.30, 3: 0.30, 4: 0.15, 5: 0.05}
		6: return {1: 0.15, 2: 0.20, 3: 0.30, 4: 0.25, 5: 0.10}
		7, 8, 9: return {1: 0.10, 2: 0.15, 3: 0.25, 4: 0.30, 5: 0.20}
		_: return {1: 1.00, 2: 0.00, 3: 0.00, 4: 0.00, 5: 0.00}

# 获取棋子池大小
func _get_chess_pool_size(cost: int) -> int:
	# 不同费用的棋子池大小
	match cost:
		1: return 39  # 1费棋子：每类39个
		2: return 26  # 2费棋子：每类26个
		3: return 18  # 3费棋子：每类18个
		4: return 12  # 4费棋子：每类12个
		5: return 10  # 5费棋子：每类10个
		_: return 39

# 获取棋子品质
func get_tier_from_chess_id(chess_id: String) -> int:
	var chess_config = ConfigManager.get_chess_piece_config(chess_id)
	if chess_config:
		return chess_config.get_cost()
	return 1

# 回合开始事件处理
func _on_battle_round_started(_round_number: int) -> void:
	# 刷新商店库存
	var player = GameManager.player_manager.get_current_player()
	if player:
		refresh_shop_inventory(5, player.level)

# 游戏状态变化事件处理
func _on_game_state_changed(_old_state: int, new_state: int) -> void:
	# 如果进入商店状态，刷新商店库存
	if new_state == GameManager.GameState.SHOP:
		var player = GameManager.player_manager.get_current_player()
		if player:
			refresh_shop_inventory(5, player.level)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 重写重置方法
func _do_reset() -> void:
	# 清空缓存
	_chess_cache.clear()
	_shop_inventory.clear()
	_chess_configs.clear()

	# 重新加载棋子配置
	_load_chess_configs()

	# 重置棋子工厂
	if chess_factory:
		chess_factory.clear_pool()
		chess_factory.warm_pool(10)

	_log_info("棋子管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 清理棋子缓存
	for chess_id in _chess_cache:
		var chess_piece = _chess_cache[chess_id]
		if chess_piece:
			release_chess_piece(chess_piece)

	_chess_cache.clear()
	_shop_inventory.clear()

	# 清理棋子工厂
	if chess_factory:
		chess_factory.clear_pool()
		chess_factory.queue_free()
		chess_factory = null

	# 断开事件连接
	EventBus.battle.disconnect_event("battle_round_started", _on_battle_round_started)
	EventBus.game.disconnect_event("game_state_changed", _on_game_state_changed)

	_log_info("棋子管理器清理完成")

# 获取棋子配置
func get_chess_config(chess_id: String) -> Dictionary:
	if _chess_configs.has(chess_id):
		return _chess_configs[chess_id].duplicate()
	return {}

# 获取所有棋子配置
func get_all_chess_configs() -> Dictionary:
	return _chess_configs.duplicate()

# 获取指定等级的棋子配置
func get_chess_configs_by_tier(tier: int) -> Array:
	var result = []

	for chess_id in _chess_configs:
		var config = _chess_configs[chess_id]
		if config.get("tier", 1) == tier:
			result.append(chess_id)

	return result


