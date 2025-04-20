extends Control
## 皮肤选择界面
## 用于选择游戏皮肤

# 皮肤管理器
var skin_manager = null

# 当前选中的皮肤
var selected_skins = {
	"chess": "",
	"board": "",
	"ui": ""
}

# 皮肤项模板
var skin_item_scene = preload("res://scenes/ui/skin_item.tscn")

# 初始化
func _ready():

	skin_manager =GameManager.skin_manager
	
	# 加载皮肤
	_load_skins()
	
	# 添加动画效果
	_add_animations()
	
	# 播放背景音乐
	AudioManager.play_music("menu.ogg")

# 加载皮肤
func _load_skins() -> void:
	if skin_manager:
		# 获取当前选中的皮肤
		selected_skins = skin_manager.get_selected_skins()
		
		# 加载棋子皮肤
		_load_chess_skins()
		
		# 加载棋盘皮肤
		_load_board_skins()
		
		# 加载UI皮肤
		_load_ui_skins()

# 加载棋子皮肤
func _load_chess_skins() -> void:
	var container = $TabContainer/棋子皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有棋子皮肤
	var chess_skins = skin_manager.get_all_skins("chess")
	
	# 添加皮肤项
	for skin_id in chess_skins:
		var skin_data = chess_skins[skin_id]
		var item = _create_skin_item(skin_id, skin_data, "chess")
		container.add_child(item)

# 加载棋盘皮肤
func _load_board_skins() -> void:
	var container = $TabContainer/棋盘皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有棋盘皮肤
	var board_skins = skin_manager.get_all_skins("board")
	
	# 添加皮肤项
	for skin_id in board_skins:
		var skin_data = board_skins[skin_id]
		var item = _create_skin_item(skin_id, skin_data, "board")
		container.add_child(item)

# 加载UI皮肤
func _load_ui_skins() -> void:
	var container = $TabContainer/UI皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有UI皮肤
	var ui_skins = skin_manager.get_all_skins("ui")
	
	# 添加皮肤项
	for skin_id in ui_skins:
		var skin_data = ui_skins[skin_id]
		var item = _create_skin_item(skin_id, skin_data, "ui")
		container.add_child(item)

# 创建皮肤项
func _create_skin_item(skin_id: String, skin_data: Dictionary, skin_type: String) -> Control:
	var item = skin_item_scene.instantiate()
	item.skin_id = skin_id
	item.skin_type = skin_type
	item.skin_data = skin_data
	
	# 设置皮肤名称
	item.set_skin_name(skin_data.name)
	
	# 设置皮肤图标
	if skin_data.has("icon") and skin_data.icon:
		item.set_skin_icon(skin_data.icon)
	
	# 设置皮肤描述
	if skin_data.has("description") and skin_data.description:
		item.set_skin_description(skin_data.description)
	
	# 设置皮肤稀有度
	if skin_data.has("rarity") and skin_data.rarity:
		item.set_skin_rarity(skin_data.rarity)
	
	# 设置皮肤状态
	var is_selected = selected_skins[skin_type] == skin_id
	var is_unlocked = skin_manager.is_skin_unlocked(skin_id, skin_type)
	item.set_skin_state(is_selected, is_unlocked)
	
	# 连接信号
	item.skin_selected.connect(_on_skin_selected)
	
	return item

# 添加动画效果
func _add_animations() -> void:
	# 标题动画
	var title_tween = create_tween()
	title_tween.tween_property($Title, "modulate:a", 1.0, 0.5)
	
	# 选项卡动画
	var tab_tween = create_tween()
	tab_tween.tween_interval(0.3)  # 等待标题动画
	tab_tween.tween_property($TabContainer, "modulate:a", 1.0, 0.5)
	
	# 按钮容器动画
	var button_tween = create_tween()
	button_tween.tween_interval(0.6)  # 等待选项卡动画
	button_tween.tween_property($ButtonContainer, "modulate:a", 1.0, 0.5)

# 皮肤选择处理
func _on_skin_selected(skin_id: String, skin_type: String) -> void:
	# 更新选中的皮肤
	selected_skins[skin_type] = skin_id
	
	# 更新皮肤项状态
	var container
	match skin_type:
		"chess":
			container = $TabContainer/棋子皮肤/ScrollContainer/GridContainer
		"board":
			container = $TabContainer/棋盘皮肤/ScrollContainer/GridContainer
		"ui":
			container = $TabContainer/UI皮肤/ScrollContainer/GridContainer
	
	for child in container.get_children():
		if child.skin_type == skin_type:
			child.set_selected(child.skin_id == skin_id)
	
	# 播放选择音效
	AudioManager.play_ui_sound("select.ogg")

# 应用按钮处理
func _on_apply_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 应用选中的皮肤
	if skin_manager:
		skin_manager.apply_skins(selected_skins)
	
	# 显示应用成功提示
	var dialog = AcceptDialog.new()
	dialog.title = "皮肤已应用"
	dialog.dialog_text = "皮肤设置已成功应用。"
	add_child(dialog)
	dialog.popup_centered()

# 皮肤商店按钮处理
func _on_shop_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 创建过渡动画
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/skin_shop.tscn"))

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 创建过渡动画
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
