extends BaseControlPopup
class_name TutorialPanel
## 教程面板
## 显示教程内容和导航按钮

# 教程数据
var tutorial_id: String = ""
var tutorial_data: Dictionary = {}
var current_step: int = 0
var total_steps: int = 0

# 教程管理器引用
var tutorial_manager = null

# 动画设置
var animation_duration: float = 0.3
var highlight_color: Color = Color(1, 0.8, 0, 1)
var highlight_pulse_duration: float = 1.0
var highlight_pulse_min: float = 0.7
var highlight_pulse_max: float = 1.0

# 引用
@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var content_label = $Panel/VBoxContainer/ContentLabel
@onready var image_rect = $Panel/VBoxContainer/ImageRect
@onready var progress_label = $Panel/VBoxContainer/NavigationPanel/ProgressLabel
@onready var prev_button = $Panel/VBoxContainer/NavigationPanel/PrevButton
@onready var next_button = $Panel/VBoxContainer/NavigationPanel/NextButton
@onready var skip_button = $Panel/VBoxContainer/SkipButton
@onready var highlight_rect = $HighlightRect

# 初始化
func _ready() -> void:
	# 连接按钮信号
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)

	# 初始化高亮矩形
	if highlight_rect:
		highlight_rect.visible = false

	# 设置初始面板缩放
	panel.scale = Vector2.ZERO

	# 播放打开动画
	_play_open_animation()

	# 更新UI
	_update_ui()

# 播放打开动画
func _play_open_animation() -> void:
	# 创建缩放动画
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2.ONE, animation_duration)

	# 创建透明度动画
	var fade_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), animation_duration)

	# 设置初始透明度
	modulate = Color(1, 1, 1, 0)

# 播放关闭动画
func _play_close_animation() -> void:
	# 创建缩放动画
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2.ZERO, animation_duration)

	# 创建透明度动画
	var fade_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration)
	fade_tween.tween_callback(queue_free)

# 播放步骤切换动画
func _play_step_change_animation() -> void:
	# 创建内容淡入淡出动画
	var content_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	content_tween.tween_property(content_label, "modulate", Color(1, 1, 1, 0), animation_duration / 2)
	content_tween.tween_callback(func(): _update_step_ui(tutorial_data.steps[current_step]))
	content_tween.tween_property(content_label, "modulate", Color(1, 1, 1, 1), animation_duration / 2)

	# 如果有图片，也为图片创建动画
	if image_rect.visible:
		var image_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		image_tween.tween_property(image_rect, "modulate", Color(1, 1, 1, 0), animation_duration / 2)
		image_tween.tween_property(image_rect, "modulate", Color(1, 1, 1, 1), animation_duration / 2)
		image_tween.set_delay(animation_duration / 2)

# 设置教程数据
func set_tutorial_data(id: String, data: Dictionary, manager) -> void:
	tutorial_id = id
	tutorial_data = data
	tutorial_manager = manager

	# 如果已经准备好，更新UI
	if is_inside_tree():
		_update_ui()

# 设置步骤数据
func set_step_data(step_data: Dictionary, step: int, steps: int) -> void:
	# 保存旧步骤以检查是否需要动画
	var old_step = current_step

	# 更新步骤数据
	current_step = step
	total_steps = steps

	# 如果步骤发生变化，播放动画
	if old_step != current_step and is_inside_tree():
		_play_step_change_animation()
	else:
		# 直接更新UI
		_update_step_ui(step_data)

	# 处理高亮
	_handle_highlight(step_data)

# 更新UI
func _update_ui() -> void:
	# 检查教程数据是否有效
	if tutorial_data.is_empty():
		return

	# 设置标题
	title_label.text = tutorial_data.get("title", tr("ui.tutorial.default_title"))

	# 更新步骤UI
	if tutorial_data.has("steps") and not tutorial_data.steps.is_empty():
		total_steps = tutorial_data.steps.size()
		_update_step_ui(tutorial_data.steps[current_step])

# 更新步骤UI
func _update_step_ui(step_data: Dictionary) -> void:
	# 设置内容（支持BBCode）
	content_label.text = step_data.get("content", "")

	# 设置图片
	var image_path = step_data.get("image_path", "")
	if image_path != "":
		var texture = load(image_path)
		if texture:
			image_rect.texture = texture
			image_rect.visible = true
		else:
			image_rect.visible = false
	else:
		image_rect.visible = false

	# 设置进度
	progress_label.text = tr("ui.tutorial.progress").format({
		"current": current_step + 1,
		"total": total_steps
	})

	# 更新按钮状态
	prev_button.disabled = current_step == 0
	next_button.text = tr("ui.tutorial.finish") if current_step == total_steps - 1 else tr("ui.tutorial.next")

	# 应用步骤操作
	_apply_step_actions(step_data)

# 处理高亮
func _handle_highlight(step_data: Dictionary) -> void:
	# 检查是否需要高亮
	if not highlight_rect or not step_data.has("target") or not step_data.get("highlight", false):
		if highlight_rect:
			highlight_rect.visible = false
		return

	# 获取目标节点
	var target_path = step_data.get("target", "")
	var target_node = get_node_or_null(target_path)

	if not target_node:
		# 尝试在全局场景中查找
		target_node = get_tree().root.get_node_or_null(target_path)

	if not target_node:
		highlight_rect.visible = false
		return

	# 获取目标节点的全局位置和大小
	var target_global_rect = Rect2()

	if target_node is Control:
		target_global_rect = Rect2(
			target_node.global_position,
			target_node.size
		)
	else:
		# 对于非Control节点，尝试获取其全局变换
		var global_transform = target_node.global_transform
		var size = Vector2(50, 50)  # 默认大小

		if target_node.has_method("get_rect"):
			size = target_node.get_rect().size

		target_global_rect = Rect2(
			global_transform.origin,
			size
		)

	# 设置高亮矩形的位置和大小
	highlight_rect.global_position = target_global_rect.position
	highlight_rect.size = target_global_rect.size
	highlight_rect.visible = true

	# 创建高亮脉冲动画
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(highlight_rect, "modulate:a", highlight_pulse_min, highlight_pulse_duration / 2)
	pulse_tween.tween_property(highlight_rect, "modulate:a", highlight_pulse_max, highlight_pulse_duration / 2)

	# 设置高亮颜色
	highlight_rect.modulate = highlight_color

# 应用步骤操作
func _apply_step_actions(step_data: Dictionary) -> void:
	# 检查是否有操作
	if not step_data.has("actions") or not step_data.actions is Array:
		return

	# 执行每个操作
	for action in step_data.actions:
		if not action is Dictionary:
			continue

		var action_type = action.get("type", "")

		match action_type:
			"highlight":
				_apply_highlight_action(action)
			"focus":
				_apply_focus_action(action)
			"disable", "enable":
				_apply_enable_disable_action(action, action_type == "enable")
			"show", "hide":
				_apply_show_hide_action(action, action_type == "show")
			"wait":
				_apply_wait_action(action)
			"move_camera":
				_apply_move_camera_action(action)
			"play_animation":
				_apply_animation_action(action)

# 应用高亮操作
func _apply_highlight_action(action: Dictionary) -> void:
	# 获取目标节点
	var target_path = action.get("target", "")
	var target_node = get_node_or_null(target_path)

	if not target_node:
		# 尝试在全局场景中查找
		target_node = get_tree().root.get_node_or_null(target_path)

	if not target_node:
		return

	# 发送高亮显示事件
	var duration = action.get("duration", 3.0)
	GlobalEventBus.tutorial.dispatch_event(
		TutorialEvents.TutorialHighlightShownEvent.new(target_path, duration)
	)

	# 创建定时器在指定时间后隐藏高亮
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func():
			GlobalEventBus.tutorial.dispatch_event(
				TutorialEvents.TutorialHighlightHiddenEvent.new()
			)
		)

# 应用聚焦操作
func _apply_focus_action(action: Dictionary) -> void:
	# 获取目标节点
	var target_path = action.get("target", "")
	var target_node = get_node_or_null(target_path)

	if not target_node:
		# 尝试在全局场景中查找
		target_node = get_tree().root.get_node_or_null(target_path)

	if not target_node:
		return

	# 如果目标是Control节点，尝试聚焦它
	if target_node is Control and target_node.has_method("grab_focus"):
		target_node.grab_focus()

# 应用启用/禁用操作
func _apply_enable_disable_action(action: Dictionary, enable: bool) -> void:
	# 获取目标节点列表
	var targets = []

	if action.has("target"):
		targets.append(action.get("target"))

	if action.has("targets") and action.targets is Array:
		targets.append_array(action.targets)

	# 处理每个目标
	for target_path in targets:
		var target_node = get_node_or_null(target_path)

		if not target_node:
			# 尝试在全局场景中查找
			target_node = get_tree().root.get_node_or_null(target_path)

		if not target_node:
			continue

		# 如果目标有disabled属性，设置它
		if target_node.has_method("set_disabled"):
			target_node.set_disabled(not enable)
		elif target_node.has_property("disabled"):
			target_node.disabled = not enable

# 应用显示/隐藏操作
func _apply_show_hide_action(action: Dictionary, show: bool) -> void:
	# 获取目标节点列表
	var targets = []

	if action.has("target"):
		targets.append(action.get("target"))

	if action.has("targets") and action.targets is Array:
		targets.append_array(action.targets)

	# 处理每个目标
	for target_path in targets:
		var target_node = get_node_or_null(target_path)

		if not target_node:
			# 尝试在全局场景中查找
			target_node = get_tree().root.get_node_or_null(target_path)

		if not target_node:
			continue

		# 设置可见性
		target_node.visible = show

# 应用等待操作
func _apply_wait_action(action: Dictionary) -> void:
	# 获取等待事件
	var event_name = action.get("event", "")
	if event_name.is_empty():
		return

	# 获取超时时间
	var timeout = action.get("timeout", 0.0)

	# 这里只是记录等待事件，实际等待逻辑需要在TutorialManager中实现
	if tutorial_manager and tutorial_manager.has_method("wait_for_event"):
		tutorial_manager.wait_for_event(event_name, timeout)

# 应用移动相机操作
func _apply_move_camera_action(action: Dictionary) -> void:
	# 获取位置
	var position = action.get("position", Vector2.ZERO)
	if position is String and position.begins_with("Vector2"):
		# 解析字符串形式的Vector2
		var components = position.trim_prefix("Vector2(").trim_suffix(")").split(",")
		if components.size() >= 2:
			position = Vector2(float(components[0]), float(components[1]))

	# 获取持续时间
	var duration = action.get("duration", 1.0)

	# 这里只是记录移动相机操作，实际移动逻辑需要在相机控制器中实现
	if tutorial_manager and tutorial_manager.has_method("move_camera"):
		tutorial_manager.move_camera(position, duration)

# 应用动画操作
func _apply_animation_action(action: Dictionary) -> void:
	# 获取目标节点
	var target_path = action.get("target", "")
	var target_node = get_node_or_null(target_path)

	if not target_node:
		# 尝试在全局场景中查找
		target_node = get_tree().root.get_node_or_null(target_path)

	if not target_node:
		return

	# 获取动画名称
	var animation_name = action.get("animation", "")
	if animation_name.is_empty():
		return

	# 获取动画速度
	var speed = action.get("speed", 1.0)

	# 如果目标有AnimationPlayer，播放动画
	var animation_player = null

	if target_node is AnimationPlayer:
		animation_player = target_node
	elif target_node.has_node("AnimationPlayer"):
		animation_player = target_node.get_node("AnimationPlayer")

	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.speed_scale = speed

# 上一步按钮处理
func _on_prev_button_pressed() -> void:
	# 播放按钮动画
	_play_button_animation(prev_button)

	if tutorial_manager:
		tutorial_manager.previous_tutorial_step()

# 下一步按钮处理
func _on_next_button_pressed() -> void:
	# 播放按钮动画
	_play_button_animation(next_button)

	if tutorial_manager:
		tutorial_manager.next_tutorial_step()

# 跳过按钮处理
func _on_skip_button_pressed() -> void:
	# 播放按钮动画
	_play_button_animation(skip_button)

	if tutorial_manager:
		tutorial_manager.skip_tutorial(tutorial_id)

		# 播放关闭动画
		_play_close_animation()

# 播放按钮动画
func _play_button_animation(button: Button) -> void:
	# 创建缩放动画
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.2)

	# 创建颜色动画
	var color_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var original_color = button.modulate
	color_tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1), 0.1)
	color_tween.tween_property(button, "modulate", original_color, 0.2)
