extends Control
## 环境特效测试场景
## 用于测试各种环境特效

# 环境特效管理器
var environment_effect_manager: EnvironmentEffectManager

# 当前选中的特效类型
var selected_effect_type: String = ""

# 当前活动的特效ID
var active_effect_id: String = ""

# 特效设置
var effect_settings = {
	"intensity": 1.0,
	"duration": 10.0,
	"wind_direction": Vector2(0.2, 0),
	"wind_strength": 0.5,
	"sound_enabled": true,
	"sound_volume": 0.8,
	"affect_gameplay": true
}

# 初始化
func _ready():
	# 获取环境特效管理器
	environment_effect_manager = GameManager.environment_effect_manager
	
	# 连接信号
	environment_effect_manager.environment_effect_started.connect(_on_environment_effect_started)
	environment_effect_manager.environment_effect_ended.connect(_on_environment_effect_ended)
	
	# 加载特效列表
	_load_effect_list()
	
	# 加载预览背景
	_load_preview_background()
	
	# 更新UI
	_update_ui()

# 加载特效列表
func _load_effect_list() -> void:
	# 获取特效列表容器
	var container = $EffectList/VBoxContainer
	
	# 清空现有内容
	for child in container.get_children():
		if child.name != "EffectListTitle":
			child.queue_free()
	
	# 获取所有特效配置
	var effect_configs = environment_effect_manager.effect_configs
	
	# 按类型分组
	var effects_by_type = {}
	for effect_type in effect_configs:
		var config = effect_configs[effect_type]
		var type = config.get("type", "other")
		
		if not effects_by_type.has(type):
			effects_by_type[type] = []
		
		effects_by_type[type].append({
			"type": effect_type,
			"name": config.get("name", effect_type),
			"description": config.get("description", "")
		})
	
	# 添加分组标题和特效项
	for type in effects_by_type:
		# 添加分组标题
		var type_label = Label.new()
		type_label.text = _get_type_display_name(type)
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 16)
		type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
		container.add_child(type_label)
		
		# 添加分隔线
		var separator = HSeparator.new()
		container.add_child(separator)
		
		# 添加特效项
		for effect in effects_by_type[type]:
			var item = _create_effect_item(effect)
			container.add_child(item)
		
		# 添加空行
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		container.add_child(spacer)

# 创建特效项
func _create_effect_item(effect: Dictionary) -> Control:
	# 创建容器
	var item = VBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建特效名称按钮
	var button = Button.new()
	button.text = effect.name
	button.tooltip_text = effect.description
	button.pressed.connect(_on_effect_button_pressed.bind(effect.type))
	item.add_child(button)
	
	return item

# 加载预览背景
func _load_preview_background() -> void:
	# 加载背景图像
	var background = $EffectPreview/PreviewScene/PreviewContainer/Background
	var texture = load("res://assets/images/backgrounds/forest.png")
	if texture:
		background.texture = texture

# 更新UI
func _update_ui() -> void:
	# 更新设置值
	$EffectSettings/VBoxContainer/IntensityContainer/IntensitySlider.value = effect_settings.intensity
	$EffectSettings/VBoxContainer/IntensityContainer/IntensityValue.text = str(effect_settings.intensity)
	
	$EffectSettings/VBoxContainer/DurationContainer/DurationSpinBox.value = effect_settings.duration
	
	$EffectSettings/VBoxContainer/WindDirectionContainer/WindDirectionSlider.value = effect_settings.wind_direction.x
	$EffectSettings/VBoxContainer/WindDirectionContainer/WindDirectionValue.text = str(effect_settings.wind_direction.x)
	
	$EffectSettings/VBoxContainer/WindStrengthContainer/WindStrengthSlider.value = effect_settings.wind_strength
	$EffectSettings/VBoxContainer/WindStrengthContainer/WindStrengthValue.text = str(effect_settings.wind_strength)
	
	$EffectSettings/VBoxContainer/SoundEnabledContainer/SoundEnabledCheckBox.button_pressed = effect_settings.sound_enabled
	
	$EffectSettings/VBoxContainer/SoundVolumeContainer/SoundVolumeSlider.value = effect_settings.sound_volume
	$EffectSettings/VBoxContainer/SoundVolumeContainer/SoundVolumeValue.text = str(effect_settings.sound_volume)
	
	$EffectSettings/VBoxContainer/AffectGameplayContainer/AffectGameplayCheckBox.button_pressed = effect_settings.affect_gameplay
	
	# 更新按钮状态
	$EffectSettings/VBoxContainer/ButtonContainer/StartButton.disabled = selected_effect_type.is_empty() or not active_effect_id.is_empty()
	$EffectSettings/VBoxContainer/ButtonContainer/StopButton.disabled = active_effect_id.is_empty()
	$EffectSettings/VBoxContainer/ButtonContainer/UpdateButton.disabled = active_effect_id.is_empty()

# 获取类型显示名称
func _get_type_display_name(type: String) -> String:
	match type:
		"weather": return "天气特效"
		"ambient": return "环境氛围特效"
		"terrain": return "地形特效"
		"background": return "背景特效"
		"foreground": return "前景特效"
		"lighting": return "光照特效"
		"particle": return "粒子特效"
		_: return type.capitalize()

# 特效按钮点击处理
func _on_effect_button_pressed(effect_type: String) -> void:
	# 设置选中的特效类型
	selected_effect_type = effect_type
	
	# 获取特效配置
	var config = environment_effect_manager.effect_configs.get(effect_type, {})
	
	# 更新设置
	var default_params = config.get("default_params", {})
	for key in default_params:
		if effect_settings.has(key):
			if key == "wind_direction" and default_params[key] is Dictionary:
				effect_settings.wind_direction = Vector2(default_params[key].x, default_params[key].y)
			else:
				effect_settings[key] = default_params[key]
	
	# 更新UI
	_update_ui()

# 强度滑块值变化处理
func _on_intensity_slider_value_changed(value: float) -> void:
	effect_settings.intensity = value
	$EffectSettings/VBoxContainer/IntensityContainer/IntensityValue.text = str(value)
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"intensity": value})

# 持续时间微调框值变化处理
func _on_duration_spin_box_value_changed(value: float) -> void:
	effect_settings.duration = value

# 风向滑块值变化处理
func _on_wind_direction_slider_value_changed(value: float) -> void:
	effect_settings.wind_direction.x = value
	$EffectSettings/VBoxContainer/WindDirectionContainer/WindDirectionValue.text = str(value)
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"wind_direction": effect_settings.wind_direction})

# 风力滑块值变化处理
func _on_wind_strength_slider_value_changed(value: float) -> void:
	effect_settings.wind_strength = value
	$EffectSettings/VBoxContainer/WindStrengthContainer/WindStrengthValue.text = str(value)
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"wind_strength": value})

# 启用声音复选框切换处理
func _on_sound_enabled_check_box_toggled(button_pressed: bool) -> void:
	effect_settings.sound_enabled = button_pressed
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"sound_enabled": button_pressed})

# 音量滑块值变化处理
func _on_sound_volume_slider_value_changed(value: float) -> void:
	effect_settings.sound_volume = value
	$EffectSettings/VBoxContainer/SoundVolumeContainer/SoundVolumeValue.text = str(value)
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"sound_volume": value})

# 影响游戏玩法复选框切换处理
func _on_affect_gameplay_check_box_toggled(button_pressed: bool) -> void:
	effect_settings.affect_gameplay = button_pressed
	
	# 如果有活动特效，更新它
	if not active_effect_id.is_empty():
		environment_effect_manager.update_effect(active_effect_id, {"affect_gameplay": button_pressed})

# 启动按钮处理
func _on_start_button_pressed() -> void:
	# 如果没有选中特效类型，返回
	if selected_effect_type.is_empty():
		return
	
	# 如果已经有活动特效，先停止它
	if not active_effect_id.is_empty():
		environment_effect_manager.stop_effect(active_effect_id)
		active_effect_id = ""
	
	# 准备参数
	var params = effect_settings.duplicate()
	
	# 启动特效
	active_effect_id = environment_effect_manager.start_effect(selected_effect_type, params)
	
	# 更新UI
	_update_ui()

# 停止按钮处理
func _on_stop_button_pressed() -> void:
	# 如果没有活动特效，返回
	if active_effect_id.is_empty():
		return
	
	# 停止特效
	environment_effect_manager.stop_effect(active_effect_id)
	active_effect_id = ""
	
	# 更新UI
	_update_ui()

# 更新按钮处理
func _on_update_button_pressed() -> void:
	# 如果没有活动特效，返回
	if active_effect_id.is_empty():
		return
	
	# 准备参数
	var params = effect_settings.duplicate()
	
	# 更新特效
	environment_effect_manager.update_effect(active_effect_id, params)

# 清除按钮处理
func _on_clear_button_pressed() -> void:
	# 清除所有特效
	environment_effect_manager.clear_all_effects()
	
	# 清除活动特效ID
	active_effect_id = ""
	
	# 更新UI
	_update_ui()

# 保存按钮处理
func _on_save_button_pressed() -> void:
	# 创建保存对话框
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.json", "JSON文件")
	dialog.title = "保存特效设置"
	dialog.current_path = "res://configs/effects/custom_effect.json"
	dialog.size = Vector2(500, 400)
	
	# 连接信号
	dialog.file_selected.connect(_on_save_dialog_file_selected)
	
	# 显示对话框
	add_child(dialog)
	dialog.popup_centered()

# 保存对话框文件选择处理
func _on_save_dialog_file_selected(path: String) -> void:
	# 准备保存数据
	var save_data = {
		"effect_type": selected_effect_type,
		"settings": effect_settings
	}
	
	# 保存到文件
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	# 显示保存成功提示
	var info_dialog = AcceptDialog.new()
	info_dialog.title = "保存成功"
	info_dialog.dialog_text = "特效设置已保存到: " + path
	add_child(info_dialog)
	info_dialog.popup_centered()

# 加载按钮处理
func _on_load_button_pressed() -> void:
	# 创建加载对话框
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.json", "JSON文件")
	dialog.title = "加载特效设置"
	dialog.size = Vector2(500, 400)
	
	# 连接信号
	dialog.file_selected.connect(_on_load_dialog_file_selected)
	
	# 显示对话框
	add_child(dialog)
	dialog.popup_centered()

# 加载对话框文件选择处理
func _on_load_dialog_file_selected(path: String) -> void:
	# 加载文件
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		
		# 设置特效类型
		if data.has("effect_type"):
			selected_effect_type = data.effect_type
		
		# 设置特效设置
		if data.has("settings"):
			for key in data.settings:
				if effect_settings.has(key):
					if key == "wind_direction" and data.settings[key] is Dictionary:
						effect_settings.wind_direction = Vector2(data.settings[key].x, data.settings[key].y)
					else:
						effect_settings[key] = data.settings[key]
		
		# 更新UI
		_update_ui()
	else:
		# 显示错误提示
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "加载失败"
		error_dialog.dialog_text = "无法解析特效设置文件: " + json.get_error_message()
		add_child(error_dialog)
		error_dialog.popup_centered()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 清除所有特效
	environment_effect_manager.clear_all_effects()
	
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 环境特效开始处理
func _on_environment_effect_started(effect_id: String, effect_type: String) -> void:
	# 如果是当前活动特效，更新UI
	if effect_id == active_effect_id:
		_update_ui()

# 环境特效结束处理
func _on_environment_effect_ended(effect_id: String, effect_type: String) -> void:
	# 如果是当前活动特效，清除活动特效ID并更新UI
	if effect_id == active_effect_id:
		active_effect_id = ""
		_update_ui()
