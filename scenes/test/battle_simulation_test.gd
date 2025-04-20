extends Control
## 战斗模拟测试场景
## 用于测试棋子、羁绊和战斗系统的完整功能

# 管理器引用
var chess_manager = null
var board_manager = null
var battle_manager = null
var synergy_manager = null
var player_manager = null

# 测试状态
enum TestState {
	SETUP,      # 设置阶段（放置棋子）
	BATTLE,     # 战斗阶段
	RESULT      # 结果阶段
}

# 当前测试状态
var current_state: int = TestState.SETUP

# UI 组件引用
@onready var chess_list = $LeftPanel/ChessList/VBoxContainer
@onready var board_container = $CenterPanel/BoardContainer
@onready var info_panel = $RightPanel/InfoPanel
@onready var control_panel = $BottomPanel/ControlPanel
@onready var status_label = $BottomPanel/StatusLabel

# 初始化
func _ready():
	# 获取管理器引用
	chess_manager = GameManager.get_manager("ChessManager")
	board_manager = GameManager.get_manager("BoardManager")
	battle_manager = GameManager.get_manager("BattleManager")
	synergy_manager = GameManager.get_manager("SynergyManager")
	player_manager = GameManager.get_manager("PlayerManager")

	# 连接信号
	_connect_signals()

	# 初始化棋盘
	_initialize_board()

	# 加载棋子列表
	_load_chess_list()

	# 初始化控制面板
	_initialize_control_panel()

	# 初始化信息面板
	_initialize_info_panel()

	# 更新状态标签
	_update_status_label()

# 连接信号
func _connect_signals() -> void:
	# 连接 EventBus 信号
	EventBus.chess.connect_event("chess_piece_created", _on_chess_piece_created)
	EventBus.chess.connect_event("chess_piece_upgraded", _on_chess_piece_upgraded)
	EventBus.battle.connect_event("battle_started", _on_battle_started)
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
	EventBus.battle.connect_event("battle_round_ended", _on_battle_round_ended)
	EventBus.chess.connect_event("synergy_activated", _on_synergy_activated)
	EventBus.chess.connect_event("synergy_deactivated", _on_synergy_deactivated)

	# 连接控制面板按钮信号
	$BottomPanel/ControlPanel/StartBattleButton.pressed.connect(_on_start_battle_button_pressed)
	$BottomPanel/ControlPanel/ResetButton.pressed.connect(_on_reset_button_pressed)
	$BottomPanel/ControlPanel/BackButton.pressed.connect(_on_back_button_pressed)
	$BottomPanel/ControlPanel/SpeedSlider.value_changed.connect(_on_speed_slider_changed)

# 初始化棋盘
func _initialize_board() -> void:
	# 创建棋盘场景实例
	var board_scene = load("res://scenes/chess_board/chess_board.tscn")
	var board_instance = board_scene.instantiate()

	# 添加到棋盘容器
	board_container.add_child(board_instance)

	# 设置棋盘大小
	board_instance.board_width = 8
	board_instance.board_height = 4
	board_instance.bench_size = 9

	# 初始化棋盘
	board_instance._ready()

# 加载棋子列表
func _load_chess_list() -> void:
	# 清空现有内容
	for child in chess_list.get_children():
		if child.name != "ChessListTitle":
			child.queue_free()

	# 获取所有棋子配置
	var chess_configs = GameManager.get_manager("ConfigManager").get_all_chess_pieces()

	# 添加棋子到列表
	for id in chess_configs:
		var config = chess_configs[id]

		# 创建棋子项
		var item = _create_chess_item(id, config)
		chess_list.add_child(item)

# 创建棋子项
func _create_chess_item(id: String, config) -> Control:
	# 创建棋子项容器
	var item = Button.new()
	item.text = config.get_name() + " (" + str(config.get_cost()) + "费)"
	item.custom_minimum_size = Vector2(250, 40)
	item.size_flags_horizontal = Control.SIZE_FILL
	item.tooltip_text = config.get_description()

	# 设置样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	item.add_theme_stylebox_override("normal", style)

	# 连接信号
	item.pressed.connect(_on_chess_item_pressed.bind(id))

	return item

# 初始化控制面板
func _initialize_control_panel() -> void:
	# 设置按钮样式
	for button in control_panel.get_children():
		if button is Button:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.5, 0.5, 0.5, 1.0)
			style.corner_radius_top_left = 5
			style.corner_radius_top_right = 5
			style.corner_radius_bottom_left = 5
			style.corner_radius_bottom_right = 5
			button.add_theme_stylebox_override("normal", style)

	# 设置速度滑块
	$BottomPanel/ControlPanel/SpeedSlider.min_value = 0.5
	$BottomPanel/ControlPanel/SpeedSlider.max_value = 3.0
	$BottomPanel/ControlPanel/SpeedSlider.value = 1.0
	$BottomPanel/ControlPanel/SpeedSlider.step = 0.1

# 初始化信息面板
func _initialize_info_panel() -> void:
	# 创建信息面板标签
	var title_label = Label.new()
	title_label.text = "战斗信息"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_panel.add_child(title_label)

	# 创建羁绊信息区域
	var synergy_label = Label.new()
	synergy_label.text = "激活的羁绊:"
	info_panel.add_child(synergy_label)

	var synergy_container = VBoxContainer.new()
	synergy_container.name = "SynergyContainer"
	info_panel.add_child(synergy_container)

	# 创建战斗事件区域
	var events_label = Label.new()
	events_label.text = "战斗事件:"
	info_panel.add_child(events_label)

	var events_container = VBoxContainer.new()
	events_container.name = "EventsContainer"
	info_panel.add_child(events_container)

	# 创建棋子状态区域
	var chess_status_label = Label.new()
	chess_status_label.text = "棋子状态:"
	info_panel.add_child(chess_status_label)

	var chess_status_container = VBoxContainer.new()
	chess_status_container.name = "ChessStatusContainer"
	info_panel.add_child(chess_status_container)

# 更新状态标签
func _update_status_label() -> void:
	var status_text = "状态: "

	# 根据当前状态设置状态文本
	match current_state:
		TestState.SETUP:
			status_text += "设置阶段 - 请放置棋子"
		TestState.BATTLE:
			status_text += "战斗阶段 - 回合 " + str(battle_manager.current_round)
		TestState.RESULT:
			status_text += "结果阶段 - "
			if battle_manager.battle_result.is_victory:
				status_text += "胜利"
			else:
				status_text += "失败"

	# 设置状态文本
	status_label.text = status_text

# 添加战斗事件
func _add_battle_event(event_text: String) -> void:
	var events_container = info_panel.get_node("EventsContainer")

	# 创建事件标签
	var event_label = Label.new()
	event_label.text = event_text
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 添加到事件容器
	events_container.add_child(event_label)

	# 如果事件太多，移除最早的事件
	if events_container.get_child_count() > 20:
		var oldest_event = events_container.get_child(0)
		events_container.remove_child(oldest_event)
		oldest_event.queue_free()

# 更新羁绊信息
func _update_synergy_info() -> void:
	var synergy_container = info_panel.get_node("SynergyContainer")

	# 清空现有内容
	for child in synergy_container.get_children():
		child.queue_free()

	# 获取激活的羁绊
	var active_synergies = synergy_manager.get_active_synergies()

	# 添加羁绊信息
	for synergy_id in active_synergies:
		var level = active_synergies[synergy_id]

		# 获取羁绊配置
		var synergy_config = GameManager.get_manager("ConfigManager").get_synergy_config(synergy_id)
		if synergy_config:
			var synergy_name = synergy_config.get_name()

			# 创建羁绊标签
			var synergy_label = Label.new()
			synergy_label.text = synergy_name + " Lv." + str(level)

			# 设置颜色
			match level:
				1: synergy_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
				2: synergy_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
				3: synergy_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
				_: synergy_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))

			# 添加到羁绊容器
			synergy_container.add_child(synergy_label)

# 更新棋子状态
func _update_chess_status() -> void:
	var chess_status_container = info_panel.get_node("ChessStatusContainer")

	# 清空现有内容
	for child in chess_status_container.get_children():
		child.queue_free()

	# 获取棋盘上的棋子
	var pieces = board_manager.get_all_pieces()

	# 添加棋子状态
	for piece in pieces:
		# 创建棋子状态标签
		var chess_label = Label.new()
		var health_percent = piece.get_property("current_health") / piece.get_property("max_health") * 100
		chess_label.text = piece.get_property("name") + " (" + str(piece.get_property("star_level")) + "★) - HP: " + str(int(health_percent)) + "%"

		# 设置颜色
		if health_percent > 70:
			chess_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		elif health_percent > 30:
			chess_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
		else:
			chess_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

		# 添加到棋子状态容器
		chess_status_container.add_child(chess_label)

# 棋子项点击处理
func _on_chess_item_pressed(id: String) -> void:
	# 只在设置阶段可以添加棋子
	if current_state != TestState.SETUP:
		return

	# 创建棋子
	var chess_piece = chess_manager.create_chess_piece(id, 1, true)

	if chess_piece:
		# 添加到备战区
		var bench_cells = board_manager.get_bench_cells()
		for cell in bench_cells:
			if not cell.has_piece():
				# 放置棋子
				cell.place_piece(chess_piece)
				break

# 开始战斗按钮点击处理
func _on_start_battle_button_pressed() -> void:
	# 只在设置阶段可以开始战斗
	if current_state != TestState.SETUP:
		return

	# 开始战斗
	battle_manager.start_battle()

	# 更新状态
	current_state = TestState.BATTLE

	# 更新状态标签
	_update_status_label()

# 重置按钮点击处理
func _on_reset_button_pressed() -> void:
	# 结束战斗
	if current_state == TestState.BATTLE:
		battle_manager.end_battle(true)

	# 清空棋盘
	board_manager.clear_board()

	# 重置羁绊
	synergy_manager.reset()

	# 清空信息面板
	_initialize_info_panel()

	# 更新状态
	current_state = TestState.SETUP

	# 更新状态标签
	_update_status_label()

# 返回按钮点击处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 速度滑块变化处理
func _on_speed_slider_changed(value: float) -> void:
	# 设置战斗速度
	battle_manager.set_battle_speed(value)

# 棋子创建事件处理
func _on_chess_piece_created(chess_piece: ChessPiece) -> void:
	# 添加战斗事件
	_add_battle_event("创建棋子: " + chess_piece.get_property("name"))

# 棋子升级事件处理
func _on_chess_piece_upgraded(chess_piece: ChessPiece) -> void:
	# 添加战斗事件
	_add_battle_event("升级棋子: " + chess_piece.get_property("name") + " 到 " + str(chess_piece.get_property("star_level")) + "星")

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 添加战斗事件
	_add_battle_event("战斗开始")

	# 更新状态标签
	_update_status_label()

# 战斗结束事件处理
func _on_battle_ended(result) -> void:
	# 添加战斗事件
	if result.is_victory:
		_add_battle_event("战斗结束: 胜利")
	else:
		_add_battle_event("战斗结束: 失败")

	# 更新状态
	current_state = TestState.RESULT

	# 更新状态标签
	_update_status_label()

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 添加战斗事件
	_add_battle_event("回合 " + str(round_number) + " 开始")

	# 更新状态标签
	_update_status_label()

	# 更新棋子状态
	_update_chess_status()

# 回合结束事件处理
func _on_battle_round_ended(round_number: int) -> void:
	# 添加战斗事件
	_add_battle_event("回合 " + str(round_number) + " 结束")

	# 更新状态标签
	_update_status_label()

	# 更新棋子状态
	_update_chess_status()

# 羁绊激活事件处理
func _on_synergy_activated(synergy_id: String, level: int) -> void:
	# 获取羁绊配置
	var synergy_config = GameManager.get_manager("ConfigManager").get_synergy_config(synergy_id)
	if synergy_config:
		var synergy_name = synergy_config.get_name()

		# 添加战斗事件
		_add_battle_event("激活羁绊: " + synergy_name + " Lv." + str(level))

	# 更新羁绊信息
	_update_synergy_info()

# 羁绊停用事件处理
func _on_synergy_deactivated(synergy_id: String) -> void:
	# 获取羁绊配置
	var synergy_config = GameManager.get_manager("ConfigManager").get_synergy_config(synergy_id)
	if synergy_config:
		var synergy_name = synergy_config.get_name()

		# 添加战斗事件
		_add_battle_event("停用羁绊: " + synergy_name)

	# 更新羁绊信息
	_update_synergy_info()
