extends Node2D
class_name ChessBoard
## 棋盘场景控制器
## 负责棋盘的视觉表现和用户交互，不直接管理棋盘数据
## 主要职责：
## 1. 创建和管理棋盘的视觉组件
## 2. 处理用户交互（点击、拖拽等）
## 3. 提供视觉反馈（高亮、动画等）
## 4. 将用户操作转发给BoardManager处理
## 5. 响应BoardManager的状态变化

# 棋盘配置
@export var board_width: int = 8
@export var board_height: int = 4
@export var bench_size: int = 9
@export var cell_size: Vector2 = Vector2(64, 64)
@export var cell_scene: PackedScene
@export var board_theme: String = "default"  # 棋盘主题(default/forest/desert/snow等)
@export var use_special_cells: bool = true   # 是否使用特殊效果格子

# 拖拽相关
var dragging_piece = null
var drag_start_cell: BoardCell = null
var drag_offset: Vector2 = Vector2.ZERO
var is_combining: bool = false  # 是否正在合成棋子

@onready var background = $Background
@onready var bench_background = $BenchBackground

# 初始化
func _ready():

	# 设置棋盘配置
	GameManager.board_manager.set_board_config(board_width, board_height, bench_size, use_special_cells)

	# 创建棋盘视觉组件
	_create_board_visuals()

	# 连接信号
	_connect_signals()

# 处理输入
func _process(_delta):
	# 处理拖拽逻辑
	if dragging_piece:
		dragging_piece.global_position = get_viewport().get_mouse_position() - drag_offset

# 创建棋盘视觉组件
func _create_board_visuals():
	# 调整背景大小
	background.size = Vector2(board_width * cell_size.x, board_height * cell_size.y)
	bench_background.size = Vector2(bench_size * cell_size.x, cell_size.y)
	bench_background.position.y = board_height * cell_size.y + 20

	# 创建棋盘格子
	for y in range(board_height):
		for x in range(board_width):
			var cell = cell_scene.instantiate() as BoardCell
			cell.grid_position = Vector2i(x, y)
			cell.position = Vector2(x * cell_size.x, y * cell_size.y)

			# 设置格子类型
			if y == 0:  # 第一行为玩家出生区
				cell.set_cell_type("spawn")
			elif y == board_height - 1:  # 最后一行为敌人出生区
				cell.set_cell_type("blocked")
			else:
				cell.set_cell_type("normal")

			add_child(cell)

			# 连接信号
			cell.cell_clicked.connect(_on_cell_clicked)
			cell.cell_hovered.connect(_on_cell_hovered)
			cell.cell_exited.connect(_on_cell_exited)
			cell.piece_placed.connect(_on_piece_placed)
			cell.piece_removed.connect(_on_piece_removed)

			# 注册到 BoardManager
			GameManager.board_manager.register_cell(cell, false)

	# 创建备战区格子
	var bench_y = board_height * cell_size.y + 20  # 备战区位置
	for i in range(bench_size):
		var cell = cell_scene.instantiate() as BoardCell
		cell.grid_position = Vector2i(i, -1)  # 使用特殊坐标表示备战区
		cell.position = Vector2(i * cell_size.x, bench_y)
		cell.set_cell_type("bench")

		add_child(cell)

		# 连接信号
		cell.cell_clicked.connect(_on_cell_clicked)
		cell.cell_hovered.connect(_on_cell_hovered)
		cell.cell_exited.connect(_on_cell_exited)
		cell.piece_placed.connect(_on_bench_piece_placed)
		cell.piece_removed.connect(_on_bench_piece_removed)

		# 注册到 BoardManager
		GameManager.board_manager.register_cell(cell, true)

	# 生成特殊格子
	if use_special_cells:
		GameManager.board_manager.generate_special_cells()

# 连接信号
func _connect_signals():
	# 连接 BoardManager 信号
	GameManager.board_manager.board_reset.connect(_on_board_reset)

	# 连接战斗信号
	GlobalEventBus.battle.add_listener("battle_started", _on_battle_started)
	GlobalEventBus.battle.add_listener("battle_ended", _on_battle_ended)

# 格子点击处理
func _on_cell_clicked(cell: BoardCell):
	if cell.current_piece and not dragging_piece:
		# 开始拖拽
		start_drag_piece(cell)

		# 尝试合成棋子
		if not is_combining and cell.current_piece.star_level < 3:
			GameManager.board_manager.try_combine_pieces(cell.current_piece)
	elif dragging_piece:
		# 结束拖拽
		end_drag_piece(cell)

	GlobalEventBus.board.dispatch_event(BoardEvents.CellClickedEvent.new(cell))

# 格子悬停处理
func _on_cell_hovered(cell: BoardCell):
	# 如果正在拖拽棋子，高亮可放置的格子
	if dragging_piece and cell.is_playable and not cell.current_piece:
		# 获取棋子属性
		var is_player_piece = dragging_piece.is_player_piece

		# 如果是玩家棋子且格子是出生区
		if is_player_piece and cell.cell_type == "spawn":
			cell.highlight(true, Color(0.2, 0.8, 0.2, 0.4), "valid")  # 绿色，有效放置
		# 如果是玩家棋子且格子不是出生区
		elif is_player_piece and cell.cell_type != "spawn":
			cell.highlight(true, Color(0.8, 0.8, 0.2, 0.4), "warning")  # 黄色，警告放置
		# 如果是敌方棋子且格子不是出生区
		elif not is_player_piece and cell.cell_type != "blocked":
			cell.highlight(true, Color(0.2, 0.8, 0.2, 0.4), "valid")  # 绿色，有效放置

	# 如果格子有棋子且不在拖拽状态，显示棋子信息
	if cell.current_piece and not dragging_piece:
		GlobalEventBus.chess.dispatch_event(ChessEvents.ShowChessInfoEvent.new(cell.current_piece))

	# 发送格子悬停信号
	GlobalEventBus.board.dispatch_event(BoardEvents.CellHoveredEvent.new(cell))

# 格子离开处理
func _on_cell_exited(cell: BoardCell):
	# 取消高亮
	if cell.is_highlighted and not is_combining:
		cell.highlight(false)

	# 如果格子有棋子，隐藏棋子信息
	if cell.current_piece:
		GlobalEventBus.chess.dispatch_event(ChessEvents.HideChessInfoEvent.new(cell.current_piece))

	# 发送格子离开信号
	GlobalEventBus.board.dispatch_event(BoardEvents.CellExitedEvent.new(cell))

# 棋子放置处理
func _on_piece_placed(piece: ChessPieceEntity):
	GameManager.board_manager.add_piece(piece, false)
	GlobalEventBus.board.dispatch_event(BoardEvents.PiecePlacedOnBoardEvent.new(piece))

# 棋子移除处理
func _on_piece_removed(piece: ChessPieceEntity):
	GameManager.board_manager.remove_piece(piece, false)
	GlobalEventBus.board.dispatch_event(BoardEvents.PieceRemovedFromBoardEvent.new(piece))

# 备战区棋子放置处理
func _on_bench_piece_placed(piece: ChessPieceEntity):
	GameManager.board_manager.add_piece(piece, true)
	GlobalEventBus.board.dispatch_event(BoardEvents.PiecePlacedOnBenchEvent.new(piece))

# 备战区棋子移除处理
func _on_bench_piece_removed(piece: ChessPieceEntity):
	GameManager.board_manager.remove_piece(piece, true)
	GlobalEventBus.board.dispatch_event(BoardEvents.PieceRemovedFromBenchEvent.new(piece))

# 开始拖拽棋子
func start_drag_piece(cell: BoardCell) -> void:
	if not cell.current_piece:
		return

	dragging_piece = cell.remove_piece()
	drag_start_cell = cell
	drag_offset = get_viewport().get_mouse_position() - dragging_piece.global_position

	# 将棋子移到顶层显示
	call_deferred("_reparent_piece", dragging_piece)

	# 添加视觉反馈
	# 创建拖拽动画
	var tween = create_tween()
	tween.tween_property(dragging_piece, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(dragging_piece, "modulate:a", 0.8, 0.1)

	# 添加拖拽阴影
	var shadow = ColorRect.new()
	shadow.name = "DragShadow"
	shadow.color = Color(0.2, 0.2, 0.2, 0.3)
	shadow.size = Vector2(cell_size.x * 0.8, cell_size.y * 0.8)
	shadow.position = Vector2(-cell_size.x * 0.4, -cell_size.y * 0.4)
	dragging_piece.add_child(shadow)

	# 播放拖拽音效
	GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("drag_start"))

	# 高亮可放置的格子
	_highlight_valid_cells()

# 结束拖拽棋子
func end_drag_piece(target_cell: BoardCell = null) -> void:
	if not dragging_piece:
		return

	# 移除拖拽阴影
	if dragging_piece.has_node("DragShadow"):
		dragging_piece.get_node("DragShadow").queue_free()

	# 取消所有格子的高亮
	_clear_all_highlights()

	# 如果没有指定目标格子，查找鼠标下方的格子
	if not target_cell:
		var mouse_pos = get_viewport().get_mouse_position()
		target_cell = _find_cell_at_position(mouse_pos)

	if target_cell and not target_cell.current_piece and target_cell.is_playable:
		# 创建放置动画
		var tween = create_tween()
		tween.tween_property(dragging_piece, "scale", Vector2(1.0, 1.0), 0.15)
		tween.parallel().tween_property(dragging_piece, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(dragging_piece, "position", target_cell.position, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# 放置到新格子
		target_cell.place_piece(dragging_piece)

		# 创建放置效果
		var effect = ColorRect.new()
		effect.color = Color(0.2, 0.8, 0.2, 0.3)
		effect.size = Vector2(cell_size.x, cell_size.y)
		effect.position = Vector2(-cell_size.x/2, -cell_size.y/2)
		target_cell.add_child(effect)

		# 创建消失动画
		var effect_tween = create_tween()
		effect_tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
		effect_tween.tween_callback(effect.queue_free)

		# 播放放置音效
		GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("piece_placed"))

		# 发送移动信号
		GlobalEventBus.chess.dispatch_event(ChessEvents.ChessPieceMovedEvent.new(dragging_piece, drag_start_cell.grid_position, target_cell.grid_position))
	else:
		# 创建返回动画
		var tween = create_tween()
		tween.tween_property(dragging_piece, "scale", Vector2(1.0, 1.0), 0.15)
		tween.parallel().tween_property(dragging_piece, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(dragging_piece, "position", drag_start_cell.position, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# 放回原格子
		drag_start_cell.place_piece(dragging_piece)

		# 播放取消音效
		GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("piece_return"))

	dragging_piece = null
	drag_start_cell = null

# 查找指定位置的格子
func _find_cell_at_position(global_pos: Vector2) -> BoardCell:
	# 检查主棋盘格子
	var all_cells = GameManager.board_manager.get_all_cells()
	for cell in all_cells:
		var rect = Rect2(cell.global_position, cell_size)
		if rect.has_point(global_pos):
			return cell

	# 检查备战区格子
	var bench_cells = GameManager.board_manager.get_bench_cells()
	for cell in bench_cells:
		var rect = Rect2(cell.global_position, cell_size)
		if rect.has_point(global_pos):
			return cell

	return null

# 高亮可放置的格子
func _highlight_valid_cells() -> void:
	if not dragging_piece:
		return

	# 获取所有格子
	var all_cells = GameManager.board_manager.get_all_cells()
	var bench_cells = GameManager.board_manager.get_bench_cells()

	# 获取棋子属性
	var is_player_piece = dragging_piece.is_player_piece

	# 高亮棋盘上的可放置格子
	for cell in all_cells:
		if cell.is_playable and not cell.current_piece:
			# 如果是玩家棋子且格子是出生区
			if is_player_piece and cell.cell_type == "spawn":
				cell.highlight(true, Color(0.2, 0.8, 0.2, 0.4), "valid")  # 绿色，有效放置
			# 如果是玩家棋子且格子不是出生区
			elif is_player_piece and cell.cell_type != "spawn":
				cell.highlight(true, Color(0.8, 0.8, 0.2, 0.4), "warning")  # 黄色，警告放置
			# 如果是敌方棋子且格子不是出生区
			elif not is_player_piece and cell.cell_type != "blocked":
				cell.highlight(true, Color(0.2, 0.8, 0.2, 0.4), "valid")  # 绿色，有效放置

	# 高亮备战区的可放置格子
	for cell in bench_cells:
		if cell.is_playable and not cell.current_piece:
			cell.highlight(true, Color(0.2, 0.8, 0.2, 0.4), "valid")  # 绿色，有效放置

# 清除所有高亮
func _clear_all_highlights() -> void:
	# 获取所有格子
	var all_cells = GameManager.board_manager.get_all_cells()
	var bench_cells = GameManager.board_manager.get_bench_cells()

	# 清除棋盘上的高亮
	for cell in all_cells:
		if cell.is_highlighted:
			cell.highlight(false)

	# 清除备战区的高亮
	for cell in bench_cells:
		if cell.is_highlighted:
			cell.highlight(false)

# 重新父级化棋子（安全地移动到顶层）
func _reparent_piece(piece: Node) -> void:
	if piece.is_inside_tree() and piece.get_parent() == self:
		remove_child(piece)
	add_child(piece)

# 棋盘重置处理
func _on_board_reset():
	# 更新视觉效果
	pass

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 禁用拖拽功能
	set_process(false)

	# 锁定所有格子
	var all_cells = GameManager.board_manager.get_all_cells()
	var bench_cells = GameManager.board_manager.get_bench_cells()

	for cell in all_cells:
		cell.is_playable = false

	for cell in bench_cells:
		cell.is_playable = false

# 战斗结束事件处理
func _on_battle_ended(_result) -> void:
	# 重新启用拖拽功能
	set_process(true)

	# 解锁格子
	var all_cells = GameManager.board_manager.get_all_cells()
	var bench_cells = GameManager.board_manager.get_bench_cells()

	for cell in all_cells:
		if cell.cell_type != "blocked":
			cell.is_playable = true

	for cell in bench_cells:
		cell.is_playable = true
