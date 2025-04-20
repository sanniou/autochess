extends "res://scripts/managers/core/base_manager.gd"
class_name ChessManager
## 棋子管理器
## 负责管理棋子实例的创建、获取和缓存

# 信号
signal chess_created(chess_piece)
signal chess_released(chess_piece)
signal chess_merged(pieces, upgraded_piece)

# 棋子实例缓存 {棋子ID: 棋子实例}
var _chess_cache: Dictionary = {}

# 商店库存 (存储棋子实例的ID)
var _shop_inventory: Array = []

# 棋子场景路径
const CHESS_PIECE_SCENE = "res://scenes/chess/chess_piece.tscn"

# 棋子类型映射
var _chess_piece_types = {}

# 对象池
var _chess_pool = null

# 初始化
func _ready() -> void:
	# 连接事件
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
			EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 注册棋子类型
	_register_chess_types()

	# 初始化对象池
	_initialize_pool()

## 注册棋子类型
func _register_chess_types() -> void:
	# 从配置中加载棋子类型
	var chess_configs = ConfigManager.get_all_chess_pieces()

	for chess_id in chess_configs:
		var chess_model = chess_configs[chess_id] as ChessPieceConfig
		_chess_piece_types[chess_id] = chess_model.get_data()

## 初始化对象池
func _initialize_pool() -> void:
	# 获取对象池引用
	_chess_pool = ObjectPool

	# 创建棋子对象池
	var chess_scene = load(CHESS_PIECE_SCENE)
	_chess_pool.create_pool("chess_pieces", chess_scene, 10, 5, 50)

# 获取棋子实例
func get_chess(chess_id: String) -> ChessPiece:
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
func create_chess_piece(chess_id: String, star_level: int = 1, is_player_piece: bool = true) -> ChessPiece:
	# 检查棋子类型是否存在
	if not _chess_piece_types.has(chess_id):
		_log_warning("未知的棋子类型: " + chess_id)
		return null

	# 获取棋子数据
	var chess_data = _chess_piece_types[chess_id].duplicate()

	# 设置星级和所属
	chess_data["star_level"] = star_level
	chess_data["is_player_piece"] = is_player_piece

	# 从对象池获取棋子实例
	var chess_piece = null
	if _chess_pool:
		chess_piece = _chess_pool.get_object("chess_pieces")

	# 如果对象池无法提供实例，直接实例化
	if not chess_piece:
		var chess_scene = load(CHESS_PIECE_SCENE)
		if chess_scene:
			chess_piece = chess_scene.instantiate()
		else:
			_log_warning("无法加载棋子场景: " + CHESS_PIECE_SCENE)
			return null

	# 初始化棋子
	chess_piece.initialize(chess_data)

	# 发送创建信号
	chess_created.emit(chess_piece)

	return chess_piece

# 释放棋子实例
func release_chess(chess_piece: ChessPiece) -> void:
	if chess_piece:
		var chess_id = chess_piece.id
		if _chess_cache.has(chess_id):
			_chess_cache.erase(chess_id)

		release_chess_piece(chess_piece)
		chess_released.emit(chess_piece)

## 释放棋子回对象池
func release_chess_piece(chess_piece: ChessPiece) -> void:
	if _chess_pool and chess_piece:
		_chess_pool.release_object("chess_pieces", chess_piece)

## 合并棋子升级
func merge_chess_pieces(pieces: Array) -> ChessPiece:
	if pieces.size() < 3:
		_log_warning("合并棋子需要至少3个相同棋子")
		return null

	# 检查棋子是否相同
	var first_piece = pieces[0]
	var chess_id = first_piece.get_id()
	var star_level = first_piece.get_property("star_level")

	for piece in pieces:
		if piece.get_id() != chess_id or piece.get_property("star_level") != star_level:
			_log_warning("合并棋子必须是相同类型和星级")
			return null

	# 如果已经是3星，无法再升级
	if star_level >= 3:
		_log_warning("3星棋子无法再升级")
		return null

	# 获取棋子的位置
	var position = first_piece.global_position

	# 创建升级后的棋子
	var upgraded_piece = create_chess_piece(chess_id, star_level + 1, first_piece.get_property("is_player_piece"))

	# 设置升级后棋子的位置
	upgraded_piece.global_position = position

	# 释放原棋子
	for piece in pieces:
		release_chess(piece)

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

# 重写清理方法
func _do_cleanup() -> void:
	# 清理棋子缓存
	for chess_id in _chess_cache:
		var chess_piece = _chess_cache[chess_id]
		if chess_piece:
			GameManager.chess_factory.release_chess_piece(chess_piece)

	_chess_cache.clear()
	_shop_inventory.clear()

	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.battle.disconnect_event("battle_round_started", _on_battle_round_started)
			EventBus.game.disconnect_event("game_state_changed", _on_game_state_changed)
