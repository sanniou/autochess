extends Control
## 棋盘测试场景
## 用于测试棋盘系统的功能

# 棋盘引用
@onready var board = $ChessBoard

# 棋子场景
var chess_piece_scene = preload("res://scenes/chess/chess_piece.tscn")

# 棋子数据
var test_pieces = [
	{
		"id": "warrior",
		"name": "战士",
		"description": "近战物理攻击单位",
		"cost": 1,
		"health": 100,
		"attack_damage": 10,
		"attack_speed": 1.0,
		"attack_range": 1,
		"armor": 5,
		"magic_resist": 0,
		"move_speed": 300,
		"synergies": ["fighter", "human"]
	},
	{
		"id": "archer",
		"name": "弓箭手",
		"description": "远程物理攻击单位",
		"cost": 2,
		"health": 80,
		"attack_damage": 15,
		"attack_speed": 0.8,
		"attack_range": 3,
		"armor": 0,
		"magic_resist": 0,
		"move_speed": 280,
		"synergies": ["ranger", "elf"]
	},
	{
		"id": "mage",
		"name": "法师",
		"description": "远程魔法攻击单位",
		"cost": 3,
		"health": 70,
		"attack_damage": 8,
		"attack_speed": 0.7,
		"attack_range": 4,
		"armor": 0,
		"magic_resist": 10,
		"move_speed": 270,
		"synergies": ["mage", "human"]
	}
]

func _ready():
	# 初始化测试
	_initialize_test()

# 初始化测试
func _initialize_test():
	# 连接信号
	EventBus.connect("board_initialized", _on_board_initialized)
	EventBus.connect("chess_piece_moved", _on_chess_piece_moved)
	EventBus.connect("chess_piece_upgraded", _on_chess_piece_upgraded)

# 添加棋子按钮处理
func _on_add_piece_button_pressed():
	# 随机选择一个棋子类型
	var piece_data = test_pieces[randi() % test_pieces.size()]

	# 创建棋子
	var piece = chess_piece_scene.instantiate()
	piece.initialize(piece_data)

	# 随机选择一个空格子
	var empty_cells = _get_empty_cells()
	if empty_cells.size() > 0:
		var cell = empty_cells[randi() % empty_cells.size()]
		cell.place_piece(piece)
		print("添加棋子: %s 到位置 %s" % [piece_data.name, cell.grid_position])
	else:
		print("没有空格子可放置棋子")
		piece.queue_free()

# 移除棋子按钮处理
func _on_remove_piece_button_pressed():
	# 随机选择一个有棋子的格子
	var occupied_cells = _get_occupied_cells()
	if occupied_cells.size() > 0:
		var cell = occupied_cells[randi() % occupied_cells.size()]
		var piece = cell.remove_piece()
		if piece:
			print("移除棋子: %s 从位置 %s" % [piece.display_name, cell.grid_position])
			piece.queue_free()
	else:
		print("没有棋子可移除")

# 重置棋盘按钮处理
func _on_reset_board_button_pressed():
	board.reset_board()
	print("棋盘已重置")

# 开始战斗按钮处理
func _on_start_battle_button_pressed():
	EventBus.battle.emit_event("battle_started", [])
	print("战斗开始")

# 结束战斗按钮处理
func _on_end_battle_button_pressed():
	EventBus.battle.emit_event("battle_ended", [true])  # 假设玩家获胜
	print("战斗结束")

# 棋盘初始化事件处理
func _on_board_initialized():
	print("棋盘已初始化")

# 棋子移动事件处理
func _on_chess_piece_moved(piece, from_pos, to_pos):
	var display_name = piece.get_property("display_name") if piece.has_method("get_property") else piece.data.display_name
	print("棋子移动: %s 从 %s 到 %s" % [display_name, from_pos, to_pos])

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece):
	var display_name = piece.get_property("display_name") if piece.has_method("get_property") else piece.data.display_name
	var star_level = piece.get_property("star_level") if piece.has_method("get_property") else piece.data.star_level
	print("棋子升级: %s 到 %d 星" % [display_name, star_level])

# 获取所有空格子
func _get_empty_cells() -> Array:
	var empty_cells = []

	# 检查棋盘格子
	for row in board.cells:
		for cell in row:
			if cell.is_playable and not cell.current_piece:
				empty_cells.append(cell)

	# 检查备战区格子
	for cell in board.bench_cells:
		if cell.is_playable and not cell.current_piece:
			empty_cells.append(cell)

	return empty_cells

# 获取所有有棋子的格子
func _get_occupied_cells() -> Array:
	var occupied_cells = []

	# 检查棋盘格子
	for row in board.cells:
		for cell in row:
			if cell.current_piece:
				occupied_cells.append(cell)

	# 检查备战区格子
	for cell in board.bench_cells:
		if cell.current_piece:
			occupied_cells.append(cell)

	return occupied_cells
