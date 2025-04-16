extends Panel
## 皮肤项
## 用于显示和选择皮肤

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
func set_skin_rarity(rarity: String) -> void:
	var rarity_text = "稀有度: "
	var rarity_color = Color.WHITE
	
	match rarity:
		"common":
			rarity_text += "普通"
			rarity_color = Color(0.8, 0.8, 0.8)
		"uncommon":
			rarity_text += "优秀"
			rarity_color = Color(0.2, 0.8, 0.2)
		"rare":
			rarity_text += "稀有"
			rarity_color = Color(0.2, 0.2, 0.8)
		"epic":
			rarity_text += "史诗"
			rarity_color = Color(0.8, 0.2, 0.8)
		"legendary":
			rarity_text += "传说"
			rarity_color = Color(1.0, 0.8, 0.0)
		_:
			rarity_text += rarity
	
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
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_ui_sound("select.ogg")

# 预览按钮处理
func _on_preview_button_pressed() -> void:
	# 发送预览信号
	skin_preview_requested.emit(skin_id, skin_type)
	
	# 播放按钮音效
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_ui_sound("button_click.ogg")
	
	# 显示预览对话框
	var dialog = AcceptDialog.new()
	dialog.title = "皮肤预览"
	dialog.dialog_text = "正在预览皮肤: " + skin_data.name
	
	# 添加预览图像
	if skin_data.has("preview") and skin_data.preview:
		var texture = load(skin_data.preview)
		if texture:
			var preview_image = TextureRect.new()
			preview_image.texture = texture
			preview_image.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
			preview_image.custom_minimum_size = Vector2(300, 200)
			
			var container = VBoxContainer.new()
			container.add_child(preview_image)
			container.add_child(Label.new())  # 添加一个空行
			
			var label = Label.new()
			label.text = skin_data.description
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			container.add_child(label)
			
			dialog.add_child(container)
	
	add_child(dialog)
	dialog.popup_centered()

# 解锁按钮处理
func _on_unlock_button_pressed() -> void:
	# 发送解锁信号
	skin_unlock_requested.emit(skin_id, skin_type)
	
	# 播放按钮音效
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_ui_sound("button_click.ogg")
	
	# 显示解锁确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "解锁皮肤"
	dialog.dialog_text = "确定要解锁皮肤: " + skin_data.name + " 吗？"
	
	# 添加价格信息
	if skin_data.has("unlock_cost") and skin_data.unlock_cost:
		dialog.dialog_text += "\n\n解锁价格: " + str(skin_data.unlock_cost) + " 金币"
	
	dialog.confirmed.connect(func():
		# 尝试解锁皮肤
		if has_node("/root/SkinManager"):
			var skin_manager = get_node("/root/SkinManager")
			var success = skin_manager.unlock_skin(skin_id, skin_type)
			
			if success:
				# 更新解锁状态
				is_unlocked = true
				_update_skin_state()
				
				# 播放解锁音效
				if has_node("/root/AudioManager"):
					var audio_manager = get_node("/root/AudioManager")
					audio_manager.play_sfx("unlock.ogg")
				
				# 显示解锁成功提示
				var success_dialog = AcceptDialog.new()
				success_dialog.title = "解锁成功"
				success_dialog.dialog_text = "皮肤已成功解锁！"
				add_child(success_dialog)
				success_dialog.popup_centered()
			else:
				# 显示解锁失败提示
				var fail_dialog = AcceptDialog.new()
				fail_dialog.title = "解锁失败"
				fail_dialog.dialog_text = "金币不足或其他原因导致解锁失败。"
				add_child(fail_dialog)
				fail_dialog.popup_centered()
	)
	
	add_child(dialog)
	dialog.popup_centered()
