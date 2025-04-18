extends "res://scripts/managers/core/base_manager.gd"
class_name BoardManager
## 棋盘管理器
## 管理棋盘状态和逻辑，不直接处理视觉表现

# 信号
signal board_reset()
signal special_cells_generated()
signal piece_combined(piece_id, star_level, position)

# 棋盘配置
var board_width: int = 8
var board_height: int = 4
var bench_size: int = 9
var use_special_cells: bool = true

# 棋盘数据
var cells: Array = []  # 二维数组存储所有格子
var bench_cells: Array = []  # 备战区格子
var pieces: Array = []  # 当前棋盘上的棋子
var bench_pieces: Array = []  # 备战区棋子

# 对象池
var piece_pool: ObjectPool

# 特殊格子概率
const SPECIAL_CELL_CHANCE = 0.15  # 特殊格子生成概率
const SPECIAL_EFFECTS = {
	"attack_buff": {"weight": 30, "min_value": 5, "max_value": 15},
	"health_buff": {"weight": 30, "min_value": 20, "max_value": 50},
	"armor_buff": {"weight": 20, "min_value": 5, "max_value": 15},
	"speed_buff": {"weight": 20, "min_value": 0.1, "max_value": 0.3}
}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "BoardManager"

	# 添加依赖
	add_dependency("ObjectPool")

	# 获取对象池引用
	piece_pool = get_manager("ObjectPool")
	if not piece_pool:
		_log_error("无法获取对象池引用")

	# 初始化数据结构
	_initialize_data_structures()

	# 连接信号
	EventBus.battle.connect_event("battle_started", _on_battle_started)
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)

	_log_info("棋盘管理器初始化完成")

# 初始化数据结构
func _initialize_data_structures() -> void:
	cells = []
	bench_cells = []
	pieces = []
	bench_pieces = []

	# 初始化棋盘数组
	for y in range(board_height):
		var row = []
		for x in range(board_width):
			row.append(null)
		cells.append(row)

# 设置棋盘配置
func set_board_config(width: int, height: int, bench: int, special_cells: bool) -> void:
	board_width = width
	board_height = height
	bench_size = bench
	use_special_cells = special_cells

	# 重新初始化数据结构
	_initialize_data_structures()

# 注册格子
func register_cell(cell: BoardCell, is_bench: bool) -> void:
	if is_bench:
		bench_cells.append(cell)
	else:
		var x = cell.grid_position.x
		var y = cell.grid_position.y
		if x >= 0 and x < board_width and y >= 0 and y < board_height:
			cells[y][x] = cell

# 添加棋子
func add_piece(piece: ChessPiece, is_bench: bool) -> void:
	if is_bench:
		if not bench_pieces.has(piece):
			bench_pieces.append(piece)
	else:
		if not pieces.has(piece):
			pieces.append(piece)

# 移除棋子
func remove_piece(piece: ChessPiece, is_bench: bool) -> void:
	if is_bench:
		bench_pieces.erase(piece)
	else:
		pieces.erase(piece)

# 放置棋子
func place_piece(piece: ChessPiece, cell_pos: Vector2i) -> bool:
	if not is_valid_cell(cell_pos):
		return false

	var cell = get_cell(cell_pos)
	if cell.place_piece(piece):
		pieces.append(piece)
		return true
	return false

# 移动棋子
func move_piece(piece: ChessPiece, target_pos: Vector2i) -> bool:
	if not is_valid_cell(target_pos):
		return false

	var from_cell = get_cell(piece.board_position)
	var to_cell = get_cell(target_pos)

	if from_cell and to_cell and from_cell.remove_piece():
		return to_cell.place_piece(piece)
	return false

# 获取棋子
func get_piece_at(pos: Vector2i) -> ChessPiece:
	if is_valid_cell(pos):
		return get_cell(pos).current_piece
	return null

# 获取格子
func get_cell(pos: Vector2i) -> BoardCell:
	if is_valid_cell(pos):
		return cells[pos.y][pos.x]
	return null

# 检查格子是否有效
func is_valid_cell(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height

# 获取所有格子
func get_all_cells() -> Array:
	var all_cells = []
	for row in cells:
		for cell in row:
			if cell != null:
				all_cells.append(cell)
	return all_cells

# 获取备战区格子
func get_bench_cells() -> Array:
	return bench_cells.duplicate()

# 获取所有敌方棋子
func get_enemy_pieces(is_player: bool) -> Array:
	var enemies = []
	for piece in pieces:
		if piece.is_player_piece != is_player:
			enemies.append(piece)
	return enemies

# 获取所有友方棋子
func get_ally_pieces(is_player: bool) -> Array:
	var allies = []
	for piece in pieces:
		if piece.is_player_piece == is_player:
			allies.append(piece)
	return allies

# 从对象池获取棋子
func get_piece_from_pool(piece_id: String) -> ChessPiece:
	# 使用棋子工厂创建棋子
	var chess_factory = get_manager("ChessFactory")
	if not chess_factory:
		_log_error("无法获取棋子工厂")
		return null

	var piece = chess_factory.create_chess_piece(piece_id)
	if piece:
		piece.show()
	return piece

# 回收棋子到对象池
func return_piece_to_pool(piece: ChessPiece):
	var chess_factory = get_manager("ChessFactory")
	if not chess_factory:
		_log_error("无法获取棋子工厂")
		return

	chess_factory.release_chess_piece(piece)

# 获取移动范围
func get_movement_range(start_pos: Vector2i, move_range: int) -> Array:
	var reachable = []
	var visited = {}
	var queue = [{ "pos": start_pos, "distance": 0 }]

	while not queue.is_empty():
		var current = queue.pop_front()
		var pos = current.pos
		var distance = current.distance

		if visited.has(pos) or distance > move_range:
			continue

		visited[pos] = true
		reachable.append(pos)

		# 检查相邻格子
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var new_pos = pos + dir
			if is_valid_cell(new_pos) and not get_cell(new_pos).current_piece:
				queue.append({ "pos": new_pos, "distance": distance + 1 })

	return reachable

# 获取攻击目标
func find_attack_target(piece: ChessPiece) -> ChessPiece:
	var cell = get_cell(piece.board_position)
	var range_cells = cell.get_attack_range_cells(self, piece.attack_range)

	for target_cell in range_cells:
		if target_cell.has_enemy_piece(piece.is_player_piece):
			return target_cell.current_piece

	return null

# 重置棋盘
func reset_board():
	for row in cells:
		for cell in row:
			if cell and cell.current_piece:
				cell.remove_piece()
	pieces.clear()

	# 重新生成特殊格子
	if use_special_cells:
		generate_special_cells()

	# 发送棋盘重置信号
	board_reset.emit()
	EventBus.board.emit_event("board_reset", [])

# 生成特殊格子
func generate_special_cells() -> void:
	# 清除现有特殊格子
	for row in cells:
		for cell in row:
			if cell and cell.special_effect != "":
				cell.clear_special_effect()

	# 只在玩家区域生成特殊格子
	for y in range(1, board_height - 1):  # 跳过出生区和敌人区
		for x in range(board_width):
			# 根据概率决定是否生成特殊格子
			if RandomNumberGenerator.new().randf() < SPECIAL_CELL_CHANCE:
				var cell = cells[y][x]
				if not cell:
					continue

				# 随机选择一种特殊效果
				var effect = _weighted_random_effect()
				var effect_data = SPECIAL_EFFECTS[effect]

				# 随机生成效果值
				var min_value = effect_data.min_value
				var max_value = effect_data.max_value
				var rng = RandomNumberGenerator.new()
				var value = min_value + (max_value - min_value) * rng.randf()

				# 设置特殊效果
				cell.set_special_effect(effect, value)

	# 发送特殊格子生成信号
	special_cells_generated.emit()

# 查找棋子所在的格子
func find_cell_at_position(global_pos: Vector2, cell_size: Vector2) -> BoardCell:
	# 检查主棋盘格子
	for row in cells:
		for cell in row:
			if cell:
				var rect = Rect2(cell.global_position, cell_size)
				if rect.has_point(global_pos):
					return cell

	# 检查备战区格子
	for cell in bench_cells:
		var rect = Rect2(cell.global_position, cell_size)
		if rect.has_point(global_pos):
			return cell

	return null



# 获取所有备战区棋子
func get_bench_pieces() -> Array:
	return bench_pieces.duplicate()

# 获取备战区格子
func get_bench_cell(index: int) -> BoardCell:
	if index >= 0 and index < bench_cells.size():
		return bench_cells[index]
	return null

# 加权随机选择特殊效果
func _weighted_random_effect() -> String:
	var total_weight = 0
	for effect in SPECIAL_EFFECTS:
		total_weight += SPECIAL_EFFECTS[effect].weight

	var rng = RandomNumberGenerator.new()
	var random_value = rng.randi() % total_weight
	var current_weight = 0

	for effect in SPECIAL_EFFECTS:
		current_weight += SPECIAL_EFFECTS[effect].weight
		if random_value < current_weight:
			return effect

	# 默认返回第一个效果
	return SPECIAL_EFFECTS.keys()[0]

# 升级棋子
func upgrade_piece(piece_id: String) -> ChessPiece:
	# 查找相同类型和星级的棋子
	var same_pieces = []

	# 检查棋盘上的棋子
	for p in pieces:
		if p.id == piece_id and (same_pieces.is_empty() or p.star_level == same_pieces[0].star_level):
			same_pieces.append(p)
			if same_pieces.size() >= 3:
				break

	# 检查备战区的棋子
	if same_pieces.size() < 3:
		for p in bench_pieces:
			if p.id == piece_id and (same_pieces.is_empty() or p.star_level == same_pieces[0].star_level):
				same_pieces.append(p)
				if same_pieces.size() >= 3:
					break

	# 如果没有足够的棋子，返回空
	if same_pieces.size() < 3:
		return null

	# 获取第一个棋子的位置
	var first_piece = same_pieces[0]
	var first_cell = _find_cell_with_piece(first_piece)

	# 移除所有相同的棋子
	for p in same_pieces:
		var cell = _find_cell_with_piece(p)
		if cell:
			cell.remove_piece()

	# 创建升级后的棋子
	var upgraded_piece = get_piece_from_pool(piece_id)
	upgraded_piece.star_level = same_pieces[0].star_level + 1

	# 如果有原始位置，放回原位置
	if first_cell:
		first_cell.place_piece(upgraded_piece)

	# 发送升级信号
	piece_combined.emit(piece_id, upgraded_piece.star_level, first_cell.grid_position if first_cell else Vector2i(-1, -1))
	EventBus.chess.emit_event("chess_piece_upgraded", [upgraded_piece])

	return upgraded_piece

# 查找棋子所在的格子
func _find_cell_with_piece(piece: ChessPiece) -> BoardCell:
	# 检查棋盘格子
	for row in cells:
		for cell in row:
			if cell and cell.current_piece == piece:
				return cell

	# 检查备战区格子
	for cell in bench_cells:
		if cell.current_piece == piece:
			return cell

	return null

# 尝试合成棋子
func try_combine_pieces(piece: ChessPiece) -> bool:
	# 如果棋子已经是最高星级，不能合成
	if piece.star_level >= 3:
		return false

	# 查找相同类型和星级的棋子
	var same_pieces = [piece]

	# 检查棋盘上的棋子
	for p in pieces:
		if p != piece and p.id == piece.id and p.star_level == piece.star_level:
			same_pieces.append(p)
			if same_pieces.size() >= 3:
				break

	# 检查备战区的棋子
	if same_pieces.size() < 3:
		for p in bench_pieces:
			if p != piece and p.id == piece.id and p.star_level == piece.star_level:
				same_pieces.append(p)
				if same_pieces.size() >= 3:
					break

	# 如果有足够的棋子，进行合成
	if same_pieces.size() >= 3:
		# 播放合成音效
		EventBus.audio.emit_event("play_sound", ["combine_start"])

		# 合成棋子
		var upgraded_piece = upgrade_piece(piece.id)

		# 播放合成完成音效
		if upgraded_piece:
			EventBus.audio.emit_event("play_sound", ["combine_complete"])

			# 发送合成信号
			piece_combined.emit(piece.id, upgraded_piece.star_level, upgraded_piece.board_position)
			return true

	return false

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 发送战斗开始信号
	EventBus.board.emit_event("board_battle_started", [])

# 战斗结束事件处理
func _on_battle_ended(_result) -> void:
	# 发送战斗结束信号
	EventBus.board.emit_event("board_battle_ended", [_result])

# 记录错误信息
func _log_error(error_message: String) -> void:
	push_error(error_message)
	EventBus.debug.emit_event("debug_message", [error_message, 2])

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	push_warning(warning_message)
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	print(info_message)
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.battle.disconnect_event("battle_started", _on_battle_started)
			EventBus.battle.disconnect_event("battle_ended", _on_battle_ended)

	# 清理数据结构
	_initialize_data_structures()

	_log_info("棋盘管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 重置棋盘
	reset_board()

	_log_info("棋盘管理器重置完成")
