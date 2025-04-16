extends Control
## 主菜单场景
## 游戏的主入口

# 初始化
func _ready():
	# 初始化界面
	_initialize_ui()

	# 播放背景音乐
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_music("main_menu.ogg")

# 初始化界面
func _initialize_ui() -> void:
	# 初始化标题动画
	_animate_title()

	# 初始化按钮动画
	_animate_buttons()

# 标题动画
func _animate_title() -> void:
	# 设置初始状态
	$Title.modulate.a = 0
	$Subtitle.modulate.a = 0

	# 创建标题动画
	var title_tween = create_tween()
	title_tween.tween_property($Title, "modulate:a", 1.0, 1.0)
	title_tween.tween_property($Subtitle, "modulate:a", 1.0, 0.5)

# 按钮动画
func _animate_buttons() -> void:
	# 设置初始状态
	$ButtonContainer.modulate.a = 0
	$ButtonContainer.position.y += 50

	# 创建按钮动画
	var button_tween = create_tween()
	button_tween.tween_interval(1.0)  # 等待标题动画完成
	button_tween.tween_property($ButtonContainer, "modulate:a", 1.0, 0.5)
	button_tween.parallel().tween_property($ButtonContainer, "position:y", $ButtonContainer.position.y - 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# 开始游戏按钮处理
func _on_start_game_button_pressed():
	# 播放按钮音效
	_play_button_sound()

	# 创建过渡动画
	_transition_to_scene("res://scenes/game.tscn")

# 播放按钮音效
func _play_button_sound() -> void:
	if has_node("/root/AudioManager"):
		var audio_manager = get_node("/root/AudioManager")
		audio_manager.play_ui_sound("button_click.ogg")

# 场景过渡动画
func _transition_to_scene(scene_path: String) -> void:
	# 创建过渡效果
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)

	# 创建过渡动画
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

# 战斗测试按钮处理
func _on_battle_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/battle_test.tscn")

# 装备测试按钮处理
func _on_equipment_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/equipment_test.tscn")

# 棋子测试按钮处理
func _on_chess_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/chess_test.tscn")

# 地图测试按钮处理
func _on_map_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/map_test.tscn")

# 事件测试按钮处理
func _on_event_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/event_test.tscn")

# 商店测试按钮处理
func _on_shop_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/shop_test.tscn")

# 环境特效测试按钮处理
func _on_environment_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/environment_test.tscn")

# 性能测试按钮处理
func _on_performance_test_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/performance_test.tscn")

# 测试菜单按钮处理
func _on_test_menu_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/test/test_menu.tscn")

# 设置按钮处理
func _on_settings_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/settings.tscn")

# 皮肤按钮处理
func _on_skins_button_pressed():
	_play_button_sound()
	_transition_to_scene("res://scenes/skins.tscn")

# 退出按钮处理
func _on_quit_button_pressed():
	_play_button_sound()

	# 创建退出动画
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)

	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().quit())
