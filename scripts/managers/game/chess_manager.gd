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
# 注意：我们不再维护自己的配置缓存，而是直接使用 ConfigManager

# 棋子工厂
var chess_factory: ChessPieceFactory = null

# 连接事件
func _connect_events() -> void:
	# 战斗事件
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)

	# 游戏状态事件
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 棋子事件
	EventBus.chess.connect_event("chess_piece_moved", _on_chess_piece_moved)
	EventBus.chess.connect_event("chess_piece_placed", _on_chess_piece_placed)
	EventBus.chess.connect_event("chess_piece_removed", _on_chess_piece_removed)

	# 存档事件
	EventBus.save.connect_event("save_game_requested", _on_save_game_requested)
	EventBus.save.connect_event("load_game_requested", _on_load_game_requested)

	_log_info("ChessManager 事件连接完成")

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ChessManager"

	# 添加依赖
	add_dependency("ConfigManager")

	# 连接事件
	_connect_events()

	# 创建棋子工厂
	chess_factory = ChessPieceFactory.new()
	add_child(chess_factory)

	# 加载棋子配置
	_load_chess_configs()

	# 预热对象池
	chess_factory.warm_pool(20)  # 增加预热数量

	# 添加对象池监控
	_setup_pool_monitoring()

	_log_info("棋子管理器初始化完成")

## 加载棋子配置
func _load_chess_configs() -> void:
	# 从配置管理器获取棋子配置
	var chess_configs = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

	# 连接配置变更信号
	if not GameManager.config_manager.config_changed.is_connected(_on_config_changed):
		GameManager.config_manager.config_changed.connect(_on_config_changed)

	# 发送所有棋子的配置加载信号
	for chess_id in chess_configs:
		chess_config_loaded.emit(chess_id)

	_log_info("棋子配置加载完成，共 " + str(chess_configs.size()) + " 个棋子")

## 配置变更回调
func _on_config_changed(config_type: String, config_id: String) -> void:
	# 检查是否是棋子配置
	if config_type == ConfigTypes.int_to_string(ConfigTypes.Type.CHESS_PIECES):
		# 发送配置加载信号
		chess_config_loaded.emit(config_id)
		_log_info("棋子配置已更新: " + config_id)

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
	# 获取棋子配置
	var chess_config = get_chess_config(chess_id)

	# 检查棋子配置是否存在
	if chess_config.is_empty():
		_log_warning("未知的棋子配置: " + chess_id)
		return null

	# 设置星级和所属
	chess_config["level"] = star_level
	chess_config["is_player_piece"] = is_player_piece

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
	var all_chess = GameManager.config_manager.get_all_chess_pieces()
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
	var chess_config = GameManager.config_manager.get_chess_piece_config(chess_id)
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
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# 如果进入商店状态，刷新商店库存
	if new_state == GameManager.GameState.SHOP:
		var player = GameManager.player_manager.get_current_player()
		if player:
			refresh_shop_inventory(5, player.level)
			_log_info("进入商店状态，刷新商店库存")

	# 如果进入战斗状态，准备棋子
	elif new_state == GameManager.GameState.BATTLE:
		_log_info("进入战斗状态，准备棋子")
		# 可以在这里添加战斗准备逻辑
		_prepare_chess_for_battle()

	# 如果退出战斗状态，清理战斗相关的棋子状态
	if old_state == GameManager.GameState.BATTLE:
		_log_info("退出战斗状态，清理战斗相关的棋子状态")
		# 可以在这里添加战斗后清理逻辑
		_cleanup_chess_after_battle()

# 棋子移动事件处理
func _on_chess_piece_moved(piece: ChessPieceEntity, from_pos: Vector2i, to_pos: Vector2i) -> void:
	# 棋子移动时更新其位置信息
	if piece == null:
		_log_warning("棋子移动事件处理失败：棋子为空")
		return

	_log_info("棋子移动: " + piece.id + ", 从 " + str(from_pos) + " 到 " + str(to_pos))

	# 更新棋子位置
	piece.board_position = to_pos

	# 更新棋子缓存
	if _chess_cache.has(piece.id):
		_chess_cache[piece.id] = piece

# 棋子放置事件处理
func _on_chess_piece_placed(piece: ChessPieceEntity, position: Vector2i) -> void:
	# 棋子放置在棋盘上时的处理
	if piece == null:
		_log_warning("棋子放置事件处理失败：棋子为空")
		return

	_log_info("棋子放置: " + piece.id + ", 位置: " + str(position))

	# 更新棋子位置
	piece.board_position = position

	# 更新棋子缓存
	if not _chess_cache.has(piece.id):
		_chess_cache[piece.id] = piece
	else:
		_chess_cache[piece.id] = piece

# 棋子移除事件处理
func _on_chess_piece_removed(piece: ChessPieceEntity, position: Vector2i) -> void:
	# 棋子从棋盘上移除时的处理
	if piece == null:
		_log_warning("棋子移除事件处理失败：棋子为空")
		return

	_log_info("棋子移除: " + piece.id + ", 位置: " + str(position))

	# 重置棋子位置
	piece.board_position = Vector2i(-1, -1)

	# 更新棋子缓存
	if _chess_cache.has(piece.id):
		_chess_cache[piece.id] = piece

# 为战斗准备棋子
func _prepare_chess_for_battle() -> void:
	# 获取玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		_log_warning("无法为战斗准备棋子：玩家不存在")
		return

	# 准备棋盘上的棋子
	for piece in player.chess_pieces:
		if piece:
			# 重置棋子状态
			piece.reset_for_battle()

			# 更新棋子缓存
			if not _chess_cache.has(piece.id):
				_chess_cache[piece.id] = piece
			else:
				_chess_cache[piece.id] = piece

	_log_info("棋子已准备就绪进入战斗，总数: " + str(player.chess_pieces.size()))

# 战斗后清理棋子
func _cleanup_chess_after_battle() -> void:
	# 获取玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		_log_warning("无法清理战斗后的棋子：玩家不存在")
		return

	# 清理棋盘上的棋子
	for piece in player.chess_pieces:
		if piece:
			# 重置棋子战斗状态
			piece.reset_after_battle()

			# 更新棋子缓存
			if _chess_cache.has(piece.id):
				_chess_cache[piece.id] = piece

	_log_info("战斗后棋子清理完成，总数: " + str(player.chess_pieces.size()))

# 存档事件处理
func _on_save_game_requested(save_slot: String) -> void:
	# 保存棋子状态
	var chess_state = save_chess_state()

	# 将棋子状态添加到存档数据中
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.add_save_data("chess", chess_state)
		_log_info("棋子状态已保存到存档: " + save_slot)
	else:
		_log_warning("无法保存棋子状态：存档管理器不可用")

# 加载事件处理
func _on_load_game_requested(save_slot: String) -> void:
	# 从存档中加载棋子状态
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		var chess_state = save_manager.get_save_data("chess")
		if chess_state:
			load_chess_state(chess_state)
			_log_info("棋子状态已从存档加载: " + save_slot)
		else:
			_log_warning("无法加载棋子状态：存档中没有棋子数据")
	else:
		_log_warning("无法加载棋子状态：存档管理器不可用")

# 保存棋子状态
func save_chess_state() -> Dictionary:
	var state = {}

	# 保存商店库存
	state["shop_inventory"] = []
	for chess_id in _shop_inventory:
		state["shop_inventory"].append(chess_id)

	# 保存玩家棋子
	state["player_pieces"] = []
	var player = GameManager.player_manager.get_current_player()
	if player:
		# 棋盘上的棋子
		for piece in player.chess_pieces:
			if piece:
				var piece_data = {
					"id": piece.id,
					"config_id": piece.config_id,
					"star_level": piece.star_level,
					"position": {"x": piece.board_position.x, "y": piece.board_position.y},
					"health": piece.current_health,
					"max_health": piece.max_health,
					"items": [],  # 装备列表
					"abilities": [],  # 技能列表
					"synergies": piece.synergies,  # 羊结列表
					"stats": {}  # 属性字典
				}

				# 保存装备
				for item in piece.items:
					piece_data["items"].append(item.id)

				# 保存技能
				for ability in piece.abilities:
					piece_data["abilities"].append(ability.id)

				# 保存属性
				for stat_name in piece.stats:
					piece_data["stats"][stat_name] = piece.stats[stat_name]

				state["player_pieces"].append(piece_data)

		# 备用区的棋子
		state["bench_pieces"] = []
		for piece in player.bench_pieces:
			if piece:
				var piece_data = {
					"id": piece.id,
					"config_id": piece.config_id,
					"star_level": piece.star_level,
					"position": {"x": -1, "y": -1},  # 备用区棋子没有棋盘位置
					"health": piece.current_health,
					"max_health": piece.max_health,
					"items": [],
					"abilities": [],
					"synergies": piece.synergies,
					"stats": {}
				}

				# 保存装备
				for item in piece.items:
					piece_data["items"].append(item.id)

				# 保存技能
				for ability in piece.abilities:
					piece_data["abilities"].append(ability.id)

				# 保存属性
				for stat_name in piece.stats:
					piece_data["stats"][stat_name] = piece.stats[stat_name]

				state["bench_pieces"].append(piece_data)

	_log_info("棋子状态已保存，棋盘棋子: " + str(state["player_pieces"].size()) + ", 备用区棋子: " + str(state.get("bench_pieces", []).size()))
	return state

# 加载棋子状态
func load_chess_state(state: Dictionary) -> void:
	if state.is_empty():
		_log_warning("无法加载棋子状态：状态数据为空")
		return

	# 清理当前状态
	_chess_cache.clear()
	_shop_inventory.clear()

	# 加载商店库存
	if state.has("shop_inventory"):
		for chess_id in state["shop_inventory"]:
			_shop_inventory.append(chess_id)

	# 获取玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		_log_warning("无法加载棋子状态：玩家不存在")
		return

	# 清理玩家棋子
	for piece in player.chess_pieces:
		if piece:
			release_chess(piece)
	player.chess_pieces.clear()

	for piece in player.bench_pieces:
		if piece:
			release_chess(piece)
	player.bench_pieces.clear()

	# 加载棋盘上的棋子
	if state.has("player_pieces"):
		for piece_data in state["player_pieces"]:
			# 创建棋子
			var piece = create_chess_piece(
				piece_data["config_id"],
				piece_data["star_level"],
				true  # 玩家棋子
			)

			if piece:
				# 设置棋子ID
				piece.id = piece_data["id"]

				# 设置棋子位置
				var pos_data = piece_data["position"]
				piece.board_position = Vector2i(pos_data["x"], pos_data["y"])

				# 设置生命值
				piece.max_health = piece_data["max_health"]
				piece.current_health = piece_data["health"]

				# 设置属性
				if piece_data.has("stats"):
					for stat_name in piece_data["stats"]:
						piece.stats[stat_name] = piece_data["stats"][stat_name]

				# 添加装备
				if piece_data.has("items"):
					for item_id in piece_data["items"]:
						# 这里需要调用装备管理器来创建装备
						var item = GameManager.item_manager.create_item(item_id)
						if item:
							piece.add_item(item)

				# 添加到玩家棋子列表
				player.chess_pieces.append(piece)

				# 更新棋子缓存
				_chess_cache[piece.id] = piece

	# 加载备用区的棋子
	if state.has("bench_pieces"):
		for piece_data in state["bench_pieces"]:
			# 创建棋子
			var piece = create_chess_piece(
				piece_data["config_id"],
				piece_data["star_level"],
				true  # 玩家棋子
			)

			if piece:
				# 设置棋子ID
				piece.id = piece_data["id"]

				# 设置生命值
				piece.max_health = piece_data["max_health"]
				piece.current_health = piece_data["health"]

				# 设置属性
				if piece_data.has("stats"):
					for stat_name in piece_data["stats"]:
						piece.stats[stat_name] = piece_data["stats"][stat_name]

				# 添加装备
				if piece_data.has("items"):
					for item_id in piece_data["items"]:
						# 这里需要调用装备管理器来创建装备
						var item = GameManager.item_manager.create_item(item_id)
						if item:
							piece.add_item(item)

				# 添加到玩家备用区列表
				player.bench_pieces.append(piece)

				# 更新棋子缓存
				_chess_cache[piece.id] = piece

	_log_info("棋子状态已加载，棋盘棋子: " + str(player.chess_pieces.size()) + ", 备用区棋子: " + str(player.bench_pieces.size()))

# 重写重置方法
func _do_reset() -> void:
	# 清空缓存
	_chess_cache.clear()
	_shop_inventory.clear()

	# 重新加载棋子配置
	_load_chess_configs()

	# 重置棋子工厂
	if chess_factory:
		chess_factory.clear_pool()
		chess_factory.warm_pool(20)  # 增加预热数量

	_log_info("棋子管理器重置完成")

# 断开事件
func _disconnect_events() -> void:
	# 战斗事件
	EventBus.battle.disconnect_event("battle_round_started", _on_battle_round_started)

	# 游戏状态事件
	EventBus.game.disconnect_event("game_state_changed", _on_game_state_changed)

	# 棋子事件
	EventBus.chess.disconnect_event("chess_piece_moved", _on_chess_piece_moved)
	EventBus.chess.disconnect_event("chess_piece_placed", _on_chess_piece_placed)
	EventBus.chess.disconnect_event("chess_piece_removed", _on_chess_piece_removed)

	# 存档事件
	EventBus.save.disconnect_event("save_game_requested", _on_save_game_requested)
	EventBus.save.disconnect_event("load_game_requested", _on_load_game_requested)

	_log_info("ChessManager 事件断开完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 清理棋子缓存
	for chess_id in _chess_cache:
		var chess_piece = _chess_cache[chess_id]
		if chess_piece:
			release_chess_piece(chess_piece)

	_chess_cache.clear()
	_shop_inventory.clear()

	# 停止对象池监控
	var timer = get_node_or_null("PoolMonitorTimer")
	if timer:
		timer.stop()
		timer.queue_free()

	# 清理棋子工厂
	if chess_factory:
		chess_factory.clear_pool()
		chess_factory.queue_free()
		chess_factory = null

	# 断开事件连接
	_disconnect_events()

	# 断开配置变更信号连接
	if GameManager and GameManager.config_manager:
		if GameManager.config_manager.config_changed.is_connected(_on_config_changed):
			GameManager.config_manager.config_changed.disconnect(_on_config_changed)

	_log_info("棋子管理器清理完成")

# 获取棋子配置
func get_chess_config(chess_id: String) -> Dictionary:
	# 直接使用 ConfigManager 获取棋子配置
	var chess_model = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.CHESS_PIECES, chess_id)
	if chess_model:
		return chess_model.get_data()
	return {}

# 获取棋子预览数据
func get_chess_preview_data(chess_id: String) -> Dictionary:
	# 获取并返回棋子的详细信息
	var preview_data = {}

	# 获取基本配置
	var chess_config = get_chess_config(chess_id)
	if chess_config.is_empty():
		_log_warning("无法获取棋子预览数据：找不到棋子 " + chess_id)
		return {}

	# 填充预览数据
	preview_data["id"] = chess_id
	preview_data["name"] = chess_config.get("name", "未知棋子")
	preview_data["description"] = chess_config.get("description", "")
	preview_data["cost"] = chess_config.get("cost", 1)
	preview_data["tier"] = chess_config.get("tier", 1)
	preview_data["synergies"] = chess_config.get("synergies", [])
	preview_data["stats"] = chess_config.get("stats", {})
	preview_data["abilities"] = chess_config.get("abilities", [])
	preview_data["icon"] = chess_config.get("icon", "")
	preview_data["model"] = chess_config.get("model", "")

	# 添加额外的游戏相关数据
	preview_data["available_count"] = get_available_count(chess_id)
	preview_data["owned_count"] = get_owned_count(chess_id)

	# 添加升级信息
	preview_data["upgrade_info"] = get_upgrade_info(chess_id)

	# 添加推荐装备
	preview_data["recommended_items"] = get_recommended_items(chess_id)

	return preview_data

# 获取棋子在池中的可用数量
func get_available_count(chess_id: String) -> int:
	# 获取棋子配置
	var chess_config = get_chess_config(chess_id)
	if chess_config.is_empty():
		return 0

	# 获取棋子费用
	var cost = chess_config.get("cost", 1)

	# 根据费用确定棋子在池中的总数量
	var total_count = _get_chess_pool_size(cost)

	# 计算已经被购买的棋子数量
	var purchased_count = 0
	var player = GameManager.player_manager.get_current_player()
	if player:
		# 棋盘上的棋子
		for piece in player.chess_pieces:
			if piece.config_id == chess_id:
				purchased_count += 1

		# 备用区的棋子
		for piece in player.bench_pieces:
			if piece.config_id == chess_id:
				purchased_count += 1

	# 返回可用数量
	return total_count - purchased_count

# 获取玩家拥有的棋子数量
func get_owned_count(chess_id: String) -> int:
	var owned_count = 0
	var player = GameManager.player_manager.get_current_player()

	if player:
		# 棋盘上的棋子
		for piece in player.chess_pieces:
			if piece.config_id == chess_id:
				owned_count += 1

		# 备用区的棋子
		for piece in player.bench_pieces:
			if piece.config_id == chess_id:
				owned_count += 1

	return owned_count

# 获取棋子升级信息
func get_upgrade_info(chess_id: String) -> Dictionary:
	var upgrade_info = {}

	# 获取棋子配置
	var chess_config = get_chess_config(chess_id)
	if chess_config.is_empty():
		return upgrade_info

	# 获取当前拥有的数量
	var owned_count = get_owned_count(chess_id)

	# 计算升级所需的数量
	upgrade_info["current_count"] = owned_count
	upgrade_info["needed_for_2_star"] = 3
	upgrade_info["needed_for_3_star"] = 9
	upgrade_info["can_upgrade_to_2_star"] = owned_count >= 3
	upgrade_info["can_upgrade_to_3_star"] = owned_count >= 9

	# 计算升级后的属性提升
	var base_stats = chess_config.get("stats", {})
	var stats_2_star = {}
	var stats_3_star = {}

	for stat_name in base_stats:
		var base_value = base_stats[stat_name]
		stats_2_star[stat_name] = base_value * 1.8  # 2星棋子属性提升系数
		stats_3_star[stat_name] = base_value * 3.2  # 3星棋子属性提升系数

	upgrade_info["stats_1_star"] = base_stats
	upgrade_info["stats_2_star"] = stats_2_star
	upgrade_info["stats_3_star"] = stats_3_star

	return upgrade_info

# 获取棋子推荐装备
func get_recommended_items(chess_id: String) -> Array:
	var recommended_items = []

	# 获取棋子配置
	var chess_config = get_chess_config(chess_id)
	if chess_config.is_empty():
		return recommended_items

	# 获取棋子类型和羊结
	var synergies = chess_config.get("synergies", [])

	# 根据羊结和棋子类型推荐装备
	# 这里只是示例，实际实现可能需要更复杂的逻辑
	if "warrior" in synergies:
		recommended_items.append("sword")
		recommended_items.append("armor")
	elif "mage" in synergies:
		recommended_items.append("staff")
		recommended_items.append("robe")
	elif "assassin" in synergies:
		recommended_items.append("dagger")
		recommended_items.append("cloak")
	elif "ranger" in synergies:
		recommended_items.append("bow")
		recommended_items.append("quiver")

	return recommended_items

# 获取所有棋子配置
func get_all_chess_configs() -> Dictionary:
	# 使用 ConfigManager 获取所有棋子配置
	var chess_models = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

	# 转换为数据字典
	var result = {}
	for chess_id in chess_models:
		var chess_model = chess_models[chess_id]
		result[chess_id] = chess_model.get_data()

	return result

# 获取指定等级的棋子配置
func get_chess_configs_by_tier(tier: int) -> Array:
	# 使用配置查询功能
	var chess_models = GameManager.config_manager.query_array(ConfigTypes.Type.CHESS_PIECES, {"tier": tier})

	# 提取棋子ID
	var result = []
	for chess_model in chess_models:
		result.append(chess_model.get_id())

	return result

# 根据羊结类型搜索棋子
func get_chess_by_synergy(synergy_type: String) -> Array:
	# 使用配置查询功能
	var chess_models = GameManager.config_manager.query_array(ConfigTypes.Type.CHESS_PIECES, {"synergies": [synergy_type]})

	# 提取棋子ID
	var result = []
	for chess_model in chess_models:
		result.append(chess_model.get_id())

	return result

# 根据费用范围搜索棋子
func get_chess_by_cost_range(min_cost: int, max_cost: int) -> Array:
	# 获取所有棋子配置
	var chess_models = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

	# 根据费用范围过滤
	var result = []
	for chess_id in chess_models:
		var chess_model = chess_models[chess_id]
		var cost = chess_model.get_cost()

		if cost >= min_cost and cost <= max_cost:
			result.append(chess_id)

	return result

# 根据多个条件过滤棋子
func filter_chess(filters: Dictionary) -> Array:
	var result = []
	# 获取所有棋子配置
	var chess_configs = get_all_chess_configs()
	var all_chess_ids = chess_configs.keys()

	# 如果没有过滤条件，返回所有棋子
	if filters.is_empty():
		return all_chess_ids

	# 开始过滤
	for chess_id in all_chess_ids:
		var config = chess_configs[chess_id]
		var match_all = true

		# 棋子费用过滤
		if filters.has("min_cost") and filters.has("max_cost"):
			var cost = config.get("cost", 1)
			if cost < filters["min_cost"] or cost > filters["max_cost"]:
				match_all = false

		# 羊结类型过滤
		if filters.has("synergy") and match_all:
			var synergies = config.get("synergies", [])
			if not filters["synergy"] in synergies:
				match_all = false

		# 等级过滤
		if filters.has("tier") and match_all:
			var tier = config.get("tier", 1)
			if tier != filters["tier"]:
				match_all = false

		# 名称搜索
		if filters.has("name_search") and match_all:
			var name = config.get("name", "")
			if not filters["name_search"].to_lower() in name.to_lower():
				match_all = false

		# 技能类型过滤
		if filters.has("ability_type") and match_all:
			var abilities = config.get("abilities", [])
			var has_ability_type = false

			for ability in abilities:
				if ability.get("type", "") == filters["ability_type"]:
					has_ability_type = true
					break

			if not has_ability_type:
				match_all = false

		# 如果所有条件都匹配，添加到结果中
		if match_all:
			result.append(chess_id)

	return result

# 设置对象池监控
func _setup_pool_monitoring() -> void:
	# 创建定时器
	var timer = Timer.new()
	timer.name = "PoolMonitorTimer"
	timer.wait_time = 10.0  # 10秒检查一次
	timer.autostart = true
	timer.timeout.connect(_on_pool_monitor_timeout)
	add_child(timer)

# 对象池监控定时器回调
func _on_pool_monitor_timeout() -> void:
	# 检查对象池是否存在
	if not ObjectPool._pools.has(chess_factory.CHESS_POOL_NAME):
		return

	# 获取对象池统计信息
	var stats = ObjectPool.get_pool_stats(chess_factory.CHESS_POOL_NAME)

	# 记录对象池状态
	var usage_rate = stats.usage_rate * 100
	var active_count = stats.active
	var total_count = ObjectPool._pools[chess_factory.CHESS_POOL_NAME].size()

	# 发送调试信息
	if usage_rate > 80:
		_log_warning("棋子对象池使用率过高: " + str(usage_rate) + "% (" + str(active_count) + "/" + str(total_count) + ")")
	else:
		_log_info("棋子对象池状态: " + str(usage_rate) + "% (" + str(active_count) + "/" + str(total_count) + ")")

	# 如果使用率过高，增加池大小
	if usage_rate > 90:
		var new_size = total_count + 10
		ObjectPool.set_pool_size(chess_factory.CHESS_POOL_NAME, new_size)
		_log_warning("自动增加棋子对象池大小至: " + str(new_size))
