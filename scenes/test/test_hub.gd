extends Control
## 测试中心场景
## 提供各种测试场景的入口

# 初始化
func _ready():
	# 播放背景音乐
	AudioManager.play_music("main_menu.ogg")
	
	# 初始化UI
	_initialize_ui()

# 初始化UI
func _initialize_ui() -> void:
	# 设置标题动画
	_animate_title()
	
	# 设置按钮动画
	_animate_buttons()

# 标题动画
func _animate_title() -> void:
	# 设置初始状态
	if has_node("Title"):
		$Title.modulate.a = 0
		$Title.position.y += 30

	# 创建动画
	var title_tween = create_tween()

	# 标题淡入
	if has_node("Title"):
		title_tween.tween_property($Title, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		title_tween.parallel().tween_property($Title, "position:y", $Title.position.y - 30, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# 按钮动画
func _animate_buttons() -> void:
	# 设置初始状态
	if has_node("ScrollContainer"):
		$ScrollContainer.modulate.a = 0
		$ScrollContainer.position.y += 50
	
	if has_node("BackButton"):
		$BackButton.modulate.a = 0

	# 创建动画
	var button_tween = create_tween()

	# 按钮淡入
	if has_node("ScrollContainer"):
		button_tween.tween_property($ScrollContainer, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		button_tween.parallel().tween_property($ScrollContainer, "position:y", $ScrollContainer.position.y - 50, 0.5).set_ease(Tween.EASE_OUT)
	
	if has_node("BackButton"):
		button_tween.tween_property($BackButton, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

# 播放按钮音效
func _play_button_sound() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

# 场景过渡动画
func _transition_to_scene(scene_path: String) -> void:
	# 创建淡出动画
	var fade_tween = create_tween()

	# 淡出标题
	if has_node("Title"):
		fade_tween.parallel().tween_property($Title, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)

	# 淡出按钮
	if has_node("ScrollContainer"):
		fade_tween.parallel().tween_property($ScrollContainer, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	
	if has_node("BackButton"):
		fade_tween.parallel().tween_property($BackButton, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)

	# 创建过渡效果
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)

	# 添加淡入黑色效果
	fade_tween.parallel().tween_property(transition, "color:a", 1.0, 0.5)

	# 动画完成后切换场景
	fade_tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

# 返回按钮处理
func _on_back_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/main_menu.tscn")

# 战斗测试按钮处理
func _on_battle_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/battle_test.tscn")

# 地图测试按钮处理
func _on_map_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/map_integration_test.tscn")

# 商店测试按钮处理
func _on_shop_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/shop_test.tscn")

# 棋子测试按钮处理
func _on_chess_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/chess_test.tscn")

# 战斗模拟测试按钮处理
func _on_battle_simulation_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/battle_simulation_test.tscn")

# 装备测试按钮处理
func _on_equipment_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/equipment_test.tscn")

# 事件测试按钮处理
func _on_event_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/event_test.tscn")

# 环境特效测试按钮处理
func _on_environment_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/environment_test.tscn")

# 性能测试按钮处理
func _on_performance_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/performance_test.tscn")

# 自动化测试按钮处理
func _on_automation_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/automation_test.tscn")
