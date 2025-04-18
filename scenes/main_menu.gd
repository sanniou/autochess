extends Control
## 主菜单场景
## 游戏的主入口

# 游戏版本
const GAME_VERSION = "1.0.0"

# 是否正在执行动画
var _is_animating: bool = false

# 初始化
func _ready():
	# 初始化界面
	_initialize_ui()

	# 播放背景音乐
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_music("main_menu.ogg")

	# 检查存档
	_check_saves()

# 初始化界面
func _initialize_ui() -> void:
	# 设置版本标签
	if has_node("VersionLabel"):
		$VersionLabel.text = "版本 " + GAME_VERSION

	# 初始化标题动画
	_animate_title()

	# 初始化按钮动画
	_animate_buttons()

# 检查存档
func _check_saves() -> void:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return

	# 获取存档列表
	var saves = save_manager.get_save_list()

	# 更新继续按钮状态
	if has_node("ButtonContainer/ContinueButton"):
		$ButtonContainer/ContinueButton.disabled = saves.size() == 0

# 标题动画
func _animate_title() -> void:
	_is_animating = true

	# 设置初始状态
	$Title.modulate.a = 0
	$Subtitle.modulate.a = 0

	# 创建标题动画
	var title_tween = create_tween()
	title_tween.tween_property($Title, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)
	title_tween.tween_property($Subtitle, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

# 按钮动画
func _animate_buttons() -> void:
	# 设置初始状态
	if has_node("ButtonContainer/ButtonBackground"):
		$ButtonContainer/ButtonBackground.modulate.a = 0

	$ButtonContainer.modulate.a = 0
	$ButtonContainer.position.y += 50

	# 创建按钮动画
	var button_tween = create_tween()
	button_tween.tween_interval(1.0)  # 等待标题动画完成

	if has_node("ButtonContainer/ButtonBackground"):
		button_tween.tween_property($ButtonContainer/ButtonBackground, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	button_tween.tween_property($ButtonContainer, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	button_tween.parallel().tween_property($ButtonContainer, "position:y", $ButtonContainer.position.y - 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	button_tween.tween_callback(func(): _is_animating = false)

# 开始游戏按钮处理
func _on_start_game_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	# 播放按钮音效
	_play_button_sound()

	# 显示难度选择对话框
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("start_new_game"):
		# 创建过渡动画
		_transition_to_scene("res://scenes/game.tscn")
	else:
		# 如果没有GameManager，直接转场
		_transition_to_scene("res://scenes/game.tscn")

# 播放按钮音效
func _play_button_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_ui_sound("button_click.ogg")

# 场景过渡动画
func _transition_to_scene(scene_path: String) -> void:
	_is_animating = true

	# 创建淡出动画
	var fade_tween = create_tween()

	# 淡出标题
	if has_node("Title"):
		fade_tween.parallel().tween_property($Title, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	# 淡出副标题
	if has_node("Subtitle"):
		fade_tween.parallel().tween_property($Subtitle, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)

	# 淡出按钮背景
	if has_node("ButtonContainer/ButtonBackground"):
		fade_tween.parallel().tween_property($ButtonContainer/ButtonBackground, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	# 淡出按钮
	if has_node("ButtonContainer"):
		fade_tween.parallel().tween_property($ButtonContainer, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		fade_tween.parallel().tween_property($ButtonContainer, "position:y", $ButtonContainer.position.y + 50, 0.5).set_ease(Tween.EASE_IN)

	# 创建过渡效果
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)

	# 添加淡入黑色效果
	fade_tween.parallel().tween_property(transition, "color:a", 1.0, 0.8)

	# 动画完成后切换场景
	fade_tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

# 战斗测试按钮处理
func _on_battle_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/battle_test.tscn")

# 装备测试按钮处理
func _on_equipment_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/equipment_test.tscn")

# 棋子测试按钮处理
func _on_chess_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/chess_test.tscn")

# 地图测试按钮处理
func _on_map_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/map_test.tscn")

# 事件测试按钮处理
func _on_event_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/event_test.tscn")

# 商店测试按钮处理
func _on_shop_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/shop_test.tscn")

# 环境特效测试按钮处理
func _on_environment_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/environment_test.tscn")

# 性能测试按钮处理
func _on_performance_test_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/performance_test.tscn")

# 测试菜单按钮处理
func _on_test_menu_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/test_menu.tscn")

# 设置按钮处理
func _on_settings_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/settings.tscn")

# 皮肤按钮处理
func _on_skins_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/skins.tscn")

# 退出按钮处理
func _on_quit_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()

	# 显示确认对话框
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("quit_game"):
		# 使用GameManager退出游戏
		_play_exit_animation(func(): game_manager.quit_game())
	else:
		# 直接退出游戏
		_play_exit_animation(func(): get_tree().quit())

# 播放退出动画
func _play_exit_animation(callback: Callable) -> void:
	_is_animating = true

	# 创建淡出动画
	var fade_tween = create_tween()

	# 淡出标题
	if has_node("Title"):
		fade_tween.parallel().tween_property($Title, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	# 淡出副标题
	if has_node("Subtitle"):
		fade_tween.parallel().tween_property($Subtitle, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)

	# 淡出按钮背景
	if has_node("ButtonContainer/ButtonBackground"):
		fade_tween.parallel().tween_property($ButtonContainer/ButtonBackground, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)

	# 淡出按钮
	if has_node("ButtonContainer"):
		fade_tween.parallel().tween_property($ButtonContainer, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		fade_tween.parallel().tween_property($ButtonContainer, "position:y", $ButtonContainer.position.y + 50, 0.5).set_ease(Tween.EASE_IN)

	# 创建过渡效果
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)

	# 添加淡入黑色效果
	fade_tween.parallel().tween_property(transition, "color:a", 1.0, 0.8)

	# 动画完成后执行回调
	fade_tween.tween_callback(callback)
