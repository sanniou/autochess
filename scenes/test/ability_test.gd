extends Node2D
## 技能测试场景
## 用于测试各种棋子技能效果

# 棋子类型选项
var piece_types = []
# 当前创建的棋子
var created_pieces = []
# 测试区域格子
var test_cells = []
# 格子大小
var cell_size = Vector2(64, 64)

# 引用
@onready var grid_container = $TestArea/GridContainer
@onready var piece_type_option = $TestControls/PieceTypeOption

func _ready():
	# 初始化测试区域
	_initialize_test_area()
	
	# 加载棋子类型
	_load_piece_types()
	
	# 连接信号
	EventBus.chess_piece_ability_activated.connect(_on_ability_activated)

## 初始化测试区域
func _initialize_test_area() -> void:
	# 创建测试区域格子
	for y in range(7):
		for x in range(8):
			var cell = ColorRect.new()
			cell.custom_minimum_size = cell_size
			cell.color = Color(0.2, 0.2, 0.2, 1.0) if (x + y) % 2 == 0 else Color(0.25, 0.25, 0.25, 1.0)
			cell.set_meta("grid_position", Vector2i(x, y))
			
			# 添加点击事件
			var button = Button.new()
			button.flat = true
			button.modulate = Color(1, 1, 1, 0)
			button.size_flags_horizontal = Control.SIZE_FILL
			button.size_flags_vertical = Control.SIZE_FILL
			button.pressed.connect(_on_cell_clicked.bind(Vector2i(x, y)))
			cell.add_child(button)
			
			grid_container.add_child(cell)
			test_cells.append(cell)

## 加载棋子类型
func _load_piece_types() -> void:
	# 获取配置管理器
	var config_manager = get_node("/root/ConfigManager")
	if not config_manager:
		return
	
	# 加载所有棋子配置
	var chess_configs = config_manager.get_all_chess_pieces()
	
	# 添加到选项菜单
	for chess_id in chess_configs:
		var chess_data = chess_configs[chess_id]
		piece_types.append(chess_id)
		
		# 添加到下拉菜单
		piece_type_option.add_item(chess_data.name + " (" + chess_id + ")")

## 创建棋子
func _create_piece(piece_id: String, position: Vector2i) -> void:
	# 获取游戏管理器
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return
	
	# 获取棋子工厂
	var chess_factory = game_manager.chess_factory
	if not chess_factory:
		return
	
	# 创建棋子
	var piece = chess_factory.create_chess_piece(piece_id)
	if not piece:
		return
	
	# 设置棋子位置
	piece.board_position = position
	piece.position = Vector2(position.x * cell_size.x + cell_size.x / 2, position.y * cell_size.y + cell_size.y / 2)
	
	# 添加到场景
	var cell = _get_cell_at(position)
	if cell:
		cell.add_child(piece)
		created_pieces.append(piece)

## 获取指定位置的格子
func _get_cell_at(position: Vector2i) -> Control:
	for cell in test_cells:
		if cell.get_meta("grid_position") == position:
			return cell
	return null

## 获取指定位置的棋子
func _get_piece_at(position: Vector2i) -> ChessPiece:
	for piece in created_pieces:
		if piece.board_position == position:
			return piece
	return null

## 清除所有棋子
func _clear_all_pieces() -> void:
	for piece in created_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	
	created_pieces.clear()

## 激活所有棋子的技能
func _activate_all_abilities() -> void:
	for piece in created_pieces:
		if is_instance_valid(piece) and piece.ability:
			# 设置满法力值
			piece.current_mana = piece.max_mana
			
			# 查找目标
			var target = _find_target_for_piece(piece)
			if target:
				piece.target = target
			
			# 激活技能
			piece.activate_ability()

## 为棋子查找目标
func _find_target_for_piece(piece: ChessPiece) -> ChessPiece:
	# 查找最近的敌方棋子
	var nearest_enemy = null
	var min_distance = INF
	
	for other_piece in created_pieces:
		if other_piece != piece and is_instance_valid(other_piece):
			var distance = piece.board_position.distance_to(other_piece.board_position)
			if distance < min_distance:
				min_distance = distance
				nearest_enemy = other_piece
	
	return nearest_enemy

## 创建棋子按钮点击处理
func _on_create_piece_button_pressed() -> void:
	# 获取选中的棋子类型
	var selected_index = piece_type_option.selected
	if selected_index < 0 or selected_index >= piece_types.size():
		return
	
	var piece_id = piece_types[selected_index]
	
	# 创建棋子到随机位置
	var x = randi() % 8
	var y = randi() % 7
	_create_piece(piece_id, Vector2i(x, y))

## 激活技能按钮点击处理
func _on_activate_ability_button_pressed() -> void:
	_activate_all_abilities()

## 清除按钮点击处理
func _on_clear_button_pressed() -> void:
	_clear_all_pieces()

## 格子点击处理
func _on_cell_clicked(position: Vector2i) -> void:
	# 检查是否已有棋子
	var existing_piece = _get_piece_at(position)
	if existing_piece:
		# 如果已有棋子，激活其技能
		existing_piece.current_mana = existing_piece.max_mana
		
		# 查找目标
		var target = _find_target_for_piece(existing_piece)
		if target:
			existing_piece.target = target
		
		# 激活技能
		existing_piece.activate_ability()
	else:
		# 如果没有棋子，创建一个
		var selected_index = piece_type_option.selected
		if selected_index < 0 or selected_index >= piece_types.size():
			return
		
		var piece_id = piece_types[selected_index]
		_create_piece(piece_id, position)

## 技能激活事件处理
func _on_ability_activated(piece: ChessPiece, target) -> void:
	print("棋子 " + piece.display_name + " 激活了技能: " + piece.ability_name)
