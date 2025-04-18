extends Control
## 棋子测试场景
## 用于测试棋子升星、合并和羁绊效果

# 棋子工厂
var chess_factory: ChessFactory

# 羁绊管理器
var synergy_manager: SynergyManager

# 选中的棋子
var selected_chess: ChessPiece = null

# 选中的羁绊
var selected_synergy: String = ""

# 合并选择的棋子
var merge_selection: Array = []

# 初始化
func _ready():
	# 获取管理器
	chess_factory = get_node("/root/GameManager/ChessFactory")
	synergy_manager = get_node("/root/GameManager/SynergyManager")

	# 连接信号
	EventBus.connect("chess_piece_upgraded", _on_chess_piece_upgraded)
	EventBus.connect("chess_pieces_merged", _on_chess_pieces_merged)
	EventBus.connect("synergy_activated", _on_synergy_activated)
	EventBus.connect("synergy_deactivated", _on_synergy_deactivated)

	# 加载棋子列表
	_load_chess_list()

	# 加载羁绊列表
	_load_synergy_list()

	# 更新状态标签
	_update_status_label()

# 加载棋子列表
func _load_chess_list() -> void:
	# 获取棋子列表容器
	var container = $ChessList/VBoxContainer

	# 清空现有内容
	for child in container.get_children():
		if child.name != "ChessListTitle":
			child.queue_free()

	# 获取所有棋子配置
	var chess_configs = ConfigManager.get_all_chess_pieces()

	# 添加棋子到列表
	for id in chess_configs:
		var config = chess_configs[id]

		# 创建棋子项
		var item = _create_chess_item(id, config)
		container.add_child(item)

# 加载羁绊列表
func _load_synergy_list() -> void:
	# 获取羁绊列表容器
	var container = $SynergyList/VBoxContainer

	# 清空现有内容
	for child in container.get_children():
		if child.name != "SynergyListTitle":
			child.queue_free()

	# 获取所有羁绊配置
	var synergy_configs = synergy_manager.get_all_synergy_configs()

	# 添加羁绊到列表
	for id in synergy_configs:
		var config = synergy_configs[id]

		# 创建羁绊项
		var item = _create_synergy_item(id, config)
		container.add_child(item)

# 创建棋子项
func _create_chess_item(id: String, config: Dictionary) -> Control:
	# 创建容器
	var item = HBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 创建棋子名称标签
	var name_label = Label.new()
	name_label.text = config.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	# 创建羁绊标签
	var synergy_label = Label.new()
	var synergy_text = ""
	for synergy in config.synergies:
		if synergy_text != "":
			synergy_text += ", "
		synergy_text += synergy
	synergy_label.text = synergy_text
	synergy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(synergy_label)

	# 创建选择按钮
	var select_button = Button.new()
	select_button.text = "选择"
	select_button.pressed.connect(_on_chess_selected.bind(id))
	item.add_child(select_button)

	return item

# 创建羁绊项
func _create_synergy_item(id: String, config: Dictionary) -> Control:
	# 创建容器
	var item = HBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 创建羁绊名称标签
	var name_label = Label.new()
	name_label.text = config.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	# 创建羁绊等级标签
	var level_label = Label.new()
	var level_text = ""
	for level in config.thresholds:
		if level_text != "":
			level_text += ", "
		level_text += str(level.count) + "=" + str(level.level)
	level_label.text = level_text
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(level_label)

	# 创建选择按钮
	var select_button = Button.new()
	select_button.text = "选择"
	select_button.pressed.connect(_on_synergy_selected.bind(id))
	item.add_child(select_button)

	return item

# 更新状态标签
func _update_status_label() -> void:
	var status_text = "状态: "

	if selected_chess:
		var star_level = selected_chess.get_property("star_level") if selected_chess.has_method("get_property") else selected_chess.data.star_level
		var display_name = selected_chess.get_property("display_name") if selected_chess.has_method("get_property") else selected_chess.data.display_name

		status_text += "已选择棋子 " + display_name + " (星级: " + str(star_level) + ")"

		if selected_synergy:
			status_text += ", 已选择羁绊 " + selected_synergy

		if merge_selection.size() > 0:
			status_text += ", 已选择 " + str(merge_selection.size()) + " 个棋子用于合并"
	else:
		status_text += "未选择棋子"

	$TestArea/StatusLabel.text = status_text

# 棋子选择处理
func _on_chess_selected(id: String) -> void:
	# 创建棋子
	var chess = chess_factory.create_chess_piece(id, 1, true)

	# 如果已有选中棋子，释放它
	if selected_chess:
		chess_factory.release_chess_piece(selected_chess)

	# 设置新选中棋子
	selected_chess = chess

	# 设置棋子位置
	selected_chess.global_position = $TestArea.global_position + Vector2($TestArea.size.x / 2, $TestArea.size.y / 2)

	# 更新状态标签
	_update_status_label()

# 羁绊选择处理
func _on_synergy_selected(id: String) -> void:
	selected_synergy = id

	# 更新状态标签
	_update_status_label()

# 升星按钮处理
func _on_upgrade_button_pressed() -> void:
	if selected_chess and selected_chess.star_level < 3:
		selected_chess.upgrade()

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece: ChessPiece) -> void:
	# 更新状态标签
	_update_status_label()

# 合并按钮处理
func _on_merge_button_pressed() -> void:
	if not selected_chess:
		return

	# 如果合并选择中已有该棋子，移除它
	for i in range(merge_selection.size()):
		if merge_selection[i] == selected_chess:
			merge_selection.remove_at(i)
			_update_status_label()
			return

	# 添加到合并选择
	merge_selection.append(selected_chess)

	# 如果已经选择了3个棋子，执行合并
	if merge_selection.size() >= 3:
		var result = chess_factory.merge_chess_pieces(merge_selection)
		if result:
			selected_chess = result
			merge_selection.clear()

	# 更新状态标签
	_update_status_label()

# 棋子合并事件处理
func _on_chess_pieces_merged(source_pieces: Array, result_piece: ChessPiece) -> void:
	# 更新状态标签
	_update_status_label()

# 测试羁绊按钮处理
func _on_test_synergy_button_pressed() -> void:
	if selected_synergy == "":
		return

	# 获取当前羁绊等级
	var current_level = synergy_manager.get_synergy_level(selected_synergy)

	# 如果羁绊未激活，激活它
	if current_level == 0:
		synergy_manager.force_activate_synergy(selected_synergy, 1)
	else:
		# 如果已激活，升级或取消激活
		if current_level < 3:
			synergy_manager.force_activate_synergy(selected_synergy, current_level + 1)
		else:
			synergy_manager.deactivate_forced_synergy(selected_synergy)

# 羁绊激活事件处理
func _on_synergy_activated(synergy: String, level: int) -> void:
	# 更新状态标签
	_update_status_label()

# 羁绊取消激活事件处理
func _on_synergy_deactivated(synergy: String) -> void:
	# 更新状态标签
	_update_status_label()

# 重置按钮处理
func _on_reset_button_pressed() -> void:
	# 释放选中棋子
	if selected_chess:
		chess_factory.release_chess_piece(selected_chess)
		selected_chess = null

	# 清空合并选择
	for chess in merge_selection:
		chess_factory.release_chess_piece(chess)
	merge_selection.clear()

	# 重置羁绊
	synergy_manager.reset()

	# 清空选中羁绊
	selected_synergy = ""

	# 更新状态标签
	_update_status_label()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
