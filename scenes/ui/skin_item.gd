extends Panel
## 皮肤项
## 用于显示和选择皮肤

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")

# 信号
signal skin_selected(skin_id, skin_type)
signal skin_preview_requested(skin_id, skin_type)
signal skin_unlock_requested(skin_id, skin_type)

# 皮肤数据
var skin_id: String = ""
var skin_type: String = ""
var skin_data: Dictionary = {}

# 皮肤状态
var is_selected: bool = false
var is_unlocked: bool = true

# 初始化
func _ready():
	# 更新皮肤状态
	_update_skin_state()

# 设置皮肤名称
func set_skin_name(name: String) -> void:
	$VBoxContainer/NameLabel.text = name

# 设置皮肤图标
func set_skin_icon(icon_path: String) -> void:
	var texture = load(icon_path)
	if texture:
		$VBoxContainer/IconContainer/SkinIcon.texture = texture

# 设置皮肤描述
func set_skin_description(description: String) -> void:
	$VBoxContainer/DescriptionLabel.text = description

# 设置皮肤稀有度
func set_skin_rarity(rarity: int) -> void:
	# 获取稀有度名称和颜色
	var rarity_text = "稀有度: " + GameConsts.get_rarity_name(rarity)
	var rarity_color = GameConsts.get_rarity_color(rarity)

	$VBoxContainer/RarityLabel.text = rarity_text
	$VBoxContainer/RarityLabel.add_theme_color_override("font_color", rarity_color)

# 设置皮肤状态
func set_skin_state(selected: bool, unlocked: bool) -> void:
	is_selected = selected
	is_unlocked = unlocked

	_update_skin_state()

# 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected

	_update_skin_state()

# 更新皮肤状态
func _update_skin_state() -> void:
	# 更新选中状态
	$SelectedIndicator.visible = is_selected

	if is_selected:
		# 添加选中效果
		var style_box = get_theme_stylebox("panel").duplicate()
		style_box.border_color = Color(0.2, 0.8, 0.2, 0.8)
		style_box.border_width_left = 3
		style_box.border_width_top = 3
		style_box.border_width_right = 3
		style_box.border_width_bottom = 3
		add_theme_stylebox_override("panel", style_box)
	else:
		# 恢复默认效果
		add_theme_stylebox_override("panel", null)

	# 更新解锁状态
	$LockedOverlay.visible = !is_unlocked
	$VBoxContainer/ButtonContainer/SelectButton.disabled = !is_unlocked

# 选择按钮处理
func _on_select_button_pressed() -> void:
	# 如果未解锁，则不能选择
	if !is_unlocked:
		return

	# 发送选择信号
	skin_selected.emit(skin_id, skin_type)

	# 更新选中状态
	is_selected = true
	_update_skin_state()

	# 播放选择音效
	var audio_manager = AudioManager
	audio_manager.play_ui_sound("select.ogg")

# 预览按钮处理
func _on_preview_button_pressed() -> void:
	# 发送预览信号
	skin_preview_requested.emit(skin_id, skin_type)

	var audio_manager = AudioManager
	audio_manager.play_ui_sound("button_click.ogg")

	# 创建预览对话框
	var dialog = AcceptDialog.new()
	dialog.title = "皮肤预览: " + skin_data.name

	# 创建预览容器
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(400, 300)

	# 创建预览图像
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(300, 200)

	# 加载预览图像
	var preview_texture = null

	# 尝试不同的预览图像来源
	if skin_data.has("preview") and skin_data.preview and ResourceLoader.exists(skin_data.preview):
		preview_texture = load(skin_data.preview)
	elif skin_data.has("preview_path") and ResourceLoader.exists(skin_data.preview_path):
		preview_texture = load(skin_data.preview_path)
	elif skin_type == "chess" and skin_data.has("chess_pieces"):
		# 尝试加载棋子皮肤的预览
		for piece_id in skin_data.chess_pieces.keys():
			if ResourceLoader.exists(skin_data.chess_pieces[piece_id]):
				preview_texture = load(skin_data.chess_pieces[piece_id])
				break
	elif skin_type == "board" and skin_data.has("board") and skin_data.board.has("background"):
		# 尝试加载棋盘皮肤的预览
		if ResourceLoader.exists(skin_data.board.background):
			preview_texture = load(skin_data.board.background)
	elif skin_type == "ui" and skin_data.has("ui") and skin_data.ui.has("main_menu_background"):
		# 尝试加载UI皮肤的预览
		if ResourceLoader.exists(skin_data.ui.main_menu_background):
			preview_texture = load(skin_data.ui.main_menu_background)
	elif $VBoxContainer/IconContainer/SkinIcon.texture:
		# 使用图标作为预览
		preview_texture = $VBoxContainer/IconContainer/SkinIcon.texture

	# 设置预览图像
	if preview_texture:
		preview.texture = preview_texture

	# 创建描述标签
	var description = Label.new()
	description.text = skin_data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 添加到容器
	container.add_child(preview)
	container.add_child(HSeparator.new())
	container.add_child(description)

	# 添加特性信息（如果有）
	if skin_data.has("features") and skin_data.features is Array and not skin_data.features.is_empty():
		container.add_child(HSeparator.new())

		var features_label = Label.new()
		features_label.text = "特性:"
		features_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(features_label)

		for feature in skin_data.features:
			var feature_label = Label.new()
			feature_label.text = "- " + feature
			feature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(feature_label)

	# 添加到对话框
	dialog.add_child(container)

	# 显示对话框
	add_child(dialog)
	dialog.popup_centered(Vector2(500, 400))

# 解锁按钮处理
func _on_unlock_button_pressed() -> void:
	# 发送解锁信号
	skin_unlock_requested.emit(skin_id, skin_type)

	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 显示解锁确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "解锁皮肤"
	dialog.dialog_text = "确定要解锁皮肤: " + skin_data.name + " 吗？"

	# 添加价格信息
	if skin_data.has("unlock_cost") and skin_data.unlock_cost:
		dialog.dialog_text += "\n\n解锁价格: " + str(skin_data.unlock_cost) + " 金币"

	dialog.confirmed.connect(func():
		# 尝试解锁皮肤
		var skin_manager = GameManager.skin_manager
		var success = skin_manager.unlock_skin(skin_id, skin_type)
		if success:
			# 更新解锁状态
			is_unlocked = true
			_update_skin_state()
			# 播放解锁音效
			AudioManager.play_sfx("unlock.ogg")
			# 显示解锁成功提示
			var success_dialog = AcceptDialog.new()
			success_dialog.title = "解锁成功"
			success_dialog.dialog_text = "皮肤已成功解锁！"
			add_child(success_dialog)
			success_dialog.popup_centered()
	)

	add_child(dialog)
	dialog.popup_centered()
