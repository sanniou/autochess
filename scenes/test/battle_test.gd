extends Control
## 战斗测试场景
## 用于测试战斗系统的各项功能

# 战斗状态
enum BattleTestState {
	SETUP,      # 设置阶段
	SIMULATION, # 模拟阶段
	RESULTS     # 结果阶段
}

# 当前状态
var current_state: BattleTestState = BattleTestState.SETUP

# 战斗管理器
var battle_manager = null

# 棋盘管理器
var board_manager = null

# 玩家棋子列表
var player_pieces = []

# 敌方棋子列表
var enemy_pieces = []

# 战斗速度
var battle_speed: float = 1.0

# 初始化
func _ready():
	# 获取管理器引用
	battle_manager = GameManager.battle_manager
	board_manager = GameManager.board_manager
	
	# 连接信号
	if battle_manager:
		battle_manager.battle_ended.connect(_on_battle_ended)
	
	# 初始化UI
	_initialize_ui()
	
	# 初始化棋盘
	_initialize_board()
	
	# 初始化棋子选择器
	_initialize_piece_selector()

# 初始化UI
func _initialize_ui() -> void:
	# 更新状态标签
	_update_state_label()
	
	# 更新按钮状态
	_update_buttons()

# 初始化棋盘
func _initialize_board() -> void:
	# 创建棋盘格子
	if has_node("BoardContainer/ChessBoard"):
		var chess_board = $BoardContainer/ChessBoard
		# 初始化棋盘
		# 这里应该调用棋盘的初始化方法

# 初始化棋子选择器
func _initialize_piece_selector() -> void:
	# 加载所有可用棋子
	var config_manager = GameManager.config_manager
	if config_manager:
		var chess_configs = config_manager.get_config("chess_pieces")
		if chess_configs:
			# 填充棋子选择下拉菜单
			var player_dropdown = $SetupPanel/PlayerSetup/PieceSelector/PieceDropdown
			var enemy_dropdown = $SetupPanel/EnemySetup/PieceSelector/PieceDropdown
			
			if player_dropdown and enemy_dropdown:
				for piece_id in chess_configs.keys():
					var piece_data = chess_configs[piece_id]
					var piece_name = piece_data.get("name", piece_id)
					var display_name = piece_name + " (" + str(piece_data.get("cost", 1)) + "金)"
					
					player_dropdown.add_item(display_name, piece_id)
					enemy_dropdown.add_item(display_name, piece_id)

# 更新状态标签
func _update_state_label() -> void:
	if has_node("TopPanel/StateLabel"):
		var state_text = ""
		match current_state:
			BattleTestState.SETUP:
				state_text = "设置阶段"
			BattleTestState.SIMULATION:
				state_text = "模拟阶段"
			BattleTestState.RESULTS:
				state_text = "结果阶段"
		
		$TopPanel/StateLabel.text = state_text

# 更新按钮状态
func _update_buttons() -> void:
	if has_node("BottomPanel/ButtonContainer"):
		var start_button = $BottomPanel/ButtonContainer/StartButton
		var reset_button = $BottomPanel/ButtonContainer/ResetButton
		var back_button = $BottomPanel/ButtonContainer/BackButton
		
		match current_state:
			BattleTestState.SETUP:
				start_button.disabled = false
				reset_button.disabled = true
				back_button.disabled = false
			BattleTestState.SIMULATION:
				start_button.disabled = true
				reset_button.disabled = false
				back_button.disabled = true
			BattleTestState.RESULTS:
				start_button.disabled = true
				reset_button.disabled = false
				back_button.disabled = false

# 添加玩家棋子
func _add_player_piece(piece_id: String, star_level: int = 1, position: Vector2i = Vector2i(-1, -1)) -> void:
	# 创建棋子实例
	var piece = _create_chess_piece(piece_id, star_level, true)
	if piece:
		# 添加到棋盘
		if position.x >= 0 and position.y >= 0:
			board_manager.place_piece(piece, position, true)
		else:
			# 自动放置
			var available_cells = board_manager.get_available_cells(true)
			if available_cells.size() > 0:
				board_manager.place_piece(piece, available_cells[0].grid_position, true)
		
		# 添加到列表
		player_pieces.append(piece)
		
		# 更新UI
		_update_piece_list()

# 添加敌方棋子
func _add_enemy_piece(piece_id: String, star_level: int = 1, position: Vector2i = Vector2i(-1, -1)) -> void:
	# 创建棋子实例
	var piece = _create_chess_piece(piece_id, star_level, false)
	if piece:
		# 添加到棋盘
		if position.x >= 0 and position.y >= 0:
			board_manager.place_piece(piece, position, false)
		else:
			# 自动放置
			var available_cells = board_manager.get_available_cells(false)
			if available_cells.size() > 0:
				board_manager.place_piece(piece, available_cells[0].grid_position, false)
		
		# 添加到列表
		enemy_pieces.append(piece)
		
		# 更新UI
		_update_piece_list()

# 创建棋子实例
func _create_chess_piece(piece_id: String, star_level: int = 1, is_player: bool = true) -> Node:
	# 获取棋子工厂
	var chess_factory = GameManager.chess_factory
	if chess_factory:
		# 创建棋子
		var piece = chess_factory.create_chess_piece(piece_id, star_level)
		if piece:
			# 设置阵营
			piece.is_player_unit = is_player
			
			# 添加到适当的组
			if is_player:
				piece.add_to_group("player_chess_pieces")
			else:
				piece.add_to_group("enemy_chess_pieces")
			
			return piece
	
	return null

# 更新棋子列表
func _update_piece_list() -> void:
	# 更新玩家棋子列表
	if has_node("SetupPanel/PlayerSetup/PieceList"):
		var player_list = $SetupPanel/PlayerSetup/PieceList
		player_list.clear()
		
		for piece in player_pieces:
			var piece_name = piece.piece_name
			var star_text = ""
			for i in range(piece.star_level):
				star_text += "★"
			
			player_list.add_item(piece_name + " " + star_text)
	
	# 更新敌方棋子列表
	if has_node("SetupPanel/EnemySetup/PieceList"):
		var enemy_list = $SetupPanel/EnemySetup/PieceList
		enemy_list.clear()
		
		for piece in enemy_pieces:
			var piece_name = piece.piece_name
			var star_text = ""
			for i in range(piece.star_level):
				star_text += "★"
			
			enemy_list.add_item(piece_name + " " + star_text)

# 开始战斗
func _start_battle() -> void:
	# 检查是否有足够的棋子
	if player_pieces.size() == 0 or enemy_pieces.size() == 0:
		# 显示错误消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "错误：双方至少需要一个棋子"
			$MessageLabel.visible = true
			
			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)
		
		return
	
	# 更新状态
	current_state = BattleTestState.SIMULATION
	_update_state_label()
	_update_buttons()
	
	# 开始战斗
	if battle_manager:
		battle_manager.start_battle(player_pieces, enemy_pieces)
		
		# 设置战斗速度
		if has_node("TopPanel/SpeedSlider"):
			battle_speed = $TopPanel/SpeedSlider.value
			battle_manager.set_battle_speed(battle_speed)

# 重置战斗
func _reset_battle() -> void:
	# 清理棋盘
	if board_manager:
		board_manager.clear_board()
	
	# 清理棋子列表
	player_pieces.clear()
	enemy_pieces.clear()
	
	# 更新UI
	_update_piece_list()
	
	# 更新状态
	current_state = BattleTestState.SETUP
	_update_state_label()
	_update_buttons()
	
	# 重置战斗管理器
	if battle_manager:
		battle_manager.reset()

# 战斗结束处理
func _on_battle_ended(victory: bool) -> void:
	# 更新状态
	current_state = BattleTestState.RESULTS
	_update_state_label()
	_update_buttons()
	
	# 显示结果
	if has_node("ResultsPanel"):
		$ResultsPanel.visible = true
		
		if has_node("ResultsPanel/ResultLabel"):
			if victory:
				$ResultsPanel/ResultLabel.text = "战斗结果：玩家胜利！"
			else:
				$ResultsPanel/ResultLabel.text = "战斗结果：敌方胜利！"
		
		# 显示战斗统计
		if has_node("ResultsPanel/StatsLabel") and battle_manager:
			var stats = battle_manager.get_battle_stats()
			var stats_text = "战斗统计：\n"
			stats_text += "回合数：" + str(stats.get("rounds", 0)) + "\n"
			stats_text += "战斗时间：" + str(stats.get("duration", 0)) + "秒\n"
			stats_text += "玩家伤害：" + str(stats.get("player_damage", 0)) + "\n"
			stats_text += "敌方伤害：" + str(stats.get("enemy_damage", 0)) + "\n"
			
			$ResultsPanel/StatsLabel.text = stats_text

# 返回测试中心
func _on_back_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 清理资源
	if battle_manager:
		battle_manager.reset()
	
	if board_manager:
		board_manager.clear_board()
	
	# 切换场景
	get_tree().change_scene_to_file("res://scenes/test/test_hub.tscn")

# 开始按钮处理
func _on_start_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 开始战斗
	_start_battle()

# 重置按钮处理
func _on_reset_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 重置战斗
	_reset_battle()
	
	# 隐藏结果面板
	if has_node("ResultsPanel"):
		$ResultsPanel.visible = false

# 添加玩家棋子按钮处理
func _on_add_player_piece_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 获取选择的棋子
	if has_node("SetupPanel/PlayerSetup/PieceSelector/PieceDropdown"):
		var dropdown = $SetupPanel/PlayerSetup/PieceSelector/PieceDropdown
		var selected_idx = dropdown.selected
		
		if selected_idx >= 0:
			var piece_id = dropdown.get_item_id(selected_idx)
			
			# 获取星级
			var star_level = 1
			if has_node("SetupPanel/PlayerSetup/PieceSelector/StarLevelSpinBox"):
				star_level = $SetupPanel/PlayerSetup/PieceSelector/StarLevelSpinBox.value
			
			# 添加棋子
			_add_player_piece(piece_id, star_level)

# 添加敌方棋子按钮处理
func _on_add_enemy_piece_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 获取选择的棋子
	if has_node("SetupPanel/EnemySetup/PieceSelector/PieceDropdown"):
		var dropdown = $SetupPanel/EnemySetup/PieceSelector/PieceDropdown
		var selected_idx = dropdown.selected
		
		if selected_idx >= 0:
			var piece_id = dropdown.get_item_id(selected_idx)
			
			# 获取星级
			var star_level = 1
			if has_node("SetupPanel/EnemySetup/PieceSelector/StarLevelSpinBox"):
				star_level = $SetupPanel/EnemySetup/PieceSelector/StarLevelSpinBox.value
			
			# 添加棋子
			_add_enemy_piece(piece_id, star_level)

# 移除玩家棋子按钮处理
func _on_remove_player_piece_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 获取选择的棋子
	if has_node("SetupPanel/PlayerSetup/PieceList"):
		var list = $SetupPanel/PlayerSetup/PieceList
		var selected_idx = list.get_selected_items()
		
		if selected_idx.size() > 0:
			var idx = selected_idx[0]
			
			if idx >= 0 and idx < player_pieces.size():
				# 从棋盘移除
				var piece = player_pieces[idx]
				board_manager.remove_piece(piece)
				
				# 从列表移除
				player_pieces.remove_at(idx)
				
				# 更新UI
				_update_piece_list()

# 移除敌方棋子按钮处理
func _on_remove_enemy_piece_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 获取选择的棋子
	if has_node("SetupPanel/EnemySetup/PieceList"):
		var list = $SetupPanel/EnemySetup/PieceList
		var selected_idx = list.get_selected_items()
		
		if selected_idx.size() > 0:
			var idx = selected_idx[0]
			
			if idx >= 0 and idx < enemy_pieces.size():
				# 从棋盘移除
				var piece = enemy_pieces[idx]
				board_manager.remove_piece(piece)
				
				# 从列表移除
				enemy_pieces.remove_at(idx)
				
				# 更新UI
				_update_piece_list()

# 速度滑块变化处理
func _on_speed_slider_value_changed(value: float) -> void:
	# 更新战斗速度
	battle_speed = value
	
	# 更新标签
	if has_node("TopPanel/SpeedLabel"):
		$TopPanel/SpeedLabel.text = "速度: " + str(battle_speed) + "x"
	
	# 如果战斗正在进行，更新战斗引擎速度
	if current_state == BattleTestState.SIMULATION and battle_manager:
		battle_manager.set_battle_speed(battle_speed)

# 随机生成按钮处理
func _on_random_generate_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 清理当前棋子
	_reset_battle()
	
	# 获取配置
	var config_manager = GameManager.config_manager
	if config_manager:
		var chess_configs = config_manager.get_config("chess_pieces")
		if chess_configs:
			# 获取所有棋子ID
			var piece_ids = chess_configs.keys()
			
			# 随机生成玩家棋子
			var player_count = randi() % 5 + 1  # 1-5个棋子
			for i in range(player_count):
				var random_id = piece_ids[randi() % piece_ids.size()]
				var random_star = randi() % 3 + 1  # 1-3星
				_add_player_piece(random_id, random_star)
			
			# 随机生成敌方棋子
			var enemy_count = randi() % 5 + 1  # 1-5个棋子
			for i in range(enemy_count):
				var random_id = piece_ids[randi() % piece_ids.size()]
				var random_star = randi() % 3 + 1  # 1-3星
				_add_enemy_piece(random_id, random_star)

# 保存配置按钮处理
func _on_save_config_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 构建配置数据
	var config_data = {
		"player_pieces": [],
		"enemy_pieces": []
	}
	
	# 保存玩家棋子
	for piece in player_pieces:
		var piece_data = {
			"id": piece.piece_id,
			"star_level": piece.star_level,
			"position": {
				"x": piece.grid_position.x,
				"y": piece.grid_position.y
			}
		}
		config_data.player_pieces.append(piece_data)
	
	# 保存敌方棋子
	for piece in enemy_pieces:
		var piece_data = {
			"id": piece.piece_id,
			"star_level": piece.star_level,
			"position": {
				"x": piece.grid_position.x,
				"y": piece.grid_position.y
			}
		}
		config_data.enemy_pieces.append(piece_data)
	
	# 保存到文件
	var save_path = "user://battle_test_config.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config_data, "  "))
		file.close()
		
		# 显示消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "配置已保存"
			$MessageLabel.visible = true
			
			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 加载配置按钮处理
func _on_load_config_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 加载配置文件
	var load_path = "user://battle_test_config.json"
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json_result = JSON.parse_string(json_text)
			if json_result:
				# 清理当前棋子
				_reset_battle()
				
				# 加载玩家棋子
				if json_result.has("player_pieces"):
					for piece_data in json_result.player_pieces:
						var piece_id = piece_data.id
						var star_level = piece_data.star_level
						var position = Vector2i(piece_data.position.x, piece_data.position.y)
						
						_add_player_piece(piece_id, star_level, position)
				
				# 加载敌方棋子
				if json_result.has("enemy_pieces"):
					for piece_data in json_result.enemy_pieces:
						var piece_id = piece_data.id
						var star_level = piece_data.star_level
						var position = Vector2i(piece_data.position.x, piece_data.position.y)
						
						_add_enemy_piece(piece_id, star_level, position)
				
				# 显示消息
				if has_node("MessageLabel"):
					$MessageLabel.text = "配置已加载"
					$MessageLabel.visible = true
					
					# 3秒后隐藏消息
					var timer = get_tree().create_timer(3.0)
					timer.timeout.connect(func(): $MessageLabel.visible = false)
	else:
		# 显示错误消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "错误：配置文件不存在"
			$MessageLabel.visible = true
			
			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)
