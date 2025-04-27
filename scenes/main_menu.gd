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
	AudioManager.play_music("main_menu.ogg")

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
	var save_manager = SaveManager

	# 获取存档列表
	var saves = save_manager.get_save_list()

	# 更新继续按钮状态
	if has_node("MainContainer/GameButtonContainer/ContinueButton"):
		$MainContainer/GameButtonContainer/ContinueButton.disabled = saves.size() == 0

# 标题动画
func _animate_title() -> void:
	# 设置初始状态
	if has_node("Title"):
		$Title.modulate.a = 0
		$Title.position.y += 50

	if has_node("Subtitle"):
		$Subtitle.modulate.a = 0
		$Subtitle.position.y += 30

	# 创建动画
	var title_tween = create_tween()
	_is_animating = true

	# 标题淡入
	if has_node("Title"):
		title_tween.tween_property($Title, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
		title_tween.parallel().tween_property($Title, "position:y", $Title.position.y - 50, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 副标题淡入
	if has_node("Subtitle"):
		title_tween.tween_property($Subtitle, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		title_tween.parallel().tween_property($Subtitle, "position:y", $Subtitle.position.y - 30, 0.5).set_ease(Tween.EASE_OUT)

# 按钮动画
func _animate_buttons() -> void:
	# 设置初始状态
	if has_node("MainContainer"):
		$MainContainer.modulate.a = 0
		$MainContainer.position.y += 50

	# 创建动画
	var button_tween = create_tween()

	# 按钮淡入
	if has_node("MainContainer"):
		button_tween.tween_property($MainContainer, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
		button_tween.parallel().tween_property($MainContainer, "position:y", $MainContainer.position.y - 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		button_tween.tween_callback(func(): _is_animating = false)

# 播放按钮音效
func _play_button_sound() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

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

	# 淡出按钮
	if has_node("MainContainer"):
		fade_tween.parallel().tween_property($MainContainer, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		fade_tween.parallel().tween_property($MainContainer, "position:y", $MainContainer.position.y + 50, 0.5).set_ease(Tween.EASE_IN)

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

	# 淡出按钮
	if has_node("MainContainer"):
		fade_tween.parallel().tween_property($MainContainer, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		fade_tween.parallel().tween_property($MainContainer, "position:y", $MainContainer.position.y + 50, 0.5).set_ease(Tween.EASE_IN)

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

# 开始游戏按钮处理
func _on_start_game_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	# 播放按钮音效
	_play_button_sound()

	# 显示难度选择对话框
	# 创建过渡动画
	_transition_to_scene("res://scenes/game.tscn")

# 继续游戏按钮处理
func _on_continue_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	# 播放按钮音效
	_play_button_sound()

	# 加载最新存档
	# 创建过渡动画
	_transition_to_scene("res://scenes/game.tscn")

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
	_play_exit_animation(func(): GameManager.quit_game())

# 开发者模式按钮处理
func _on_developer_mode_button_pressed():
	# 如果正在执行动画，忽略点击
	if _is_animating:
		return

	_play_button_sound()
	_transition_to_scene("res://scenes/test/test_hub.tscn")

# 开发者模式快捷键处理
func _input(event):
	# 检测Ctrl+D组合键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D and event.ctrl_pressed:
			_on_developer_mode_button_pressed()
