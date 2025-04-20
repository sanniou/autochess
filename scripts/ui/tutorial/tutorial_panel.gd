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

# 引用
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var content_label = $Panel/VBoxContainer/ContentLabel
@onready var image_rect = $Panel/VBoxContainer/ImageRect
@onready var progress_label = $Panel/VBoxContainer/NavigationPanel/ProgressLabel
@onready var prev_button = $Panel/VBoxContainer/NavigationPanel/PrevButton
@onready var next_button = $Panel/VBoxContainer/NavigationPanel/NextButton
@onready var skip_button = $Panel/VBoxContainer/SkipButton

# 初始化
func _ready() -> void:
	# 连接按钮信号
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	
	# 更新UI
	_update_ui()

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
	current_step = step
	total_steps = steps
	
	# 更新UI
	_update_step_ui(step_data)

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
	# 设置内容
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
	next_button.text =  tr("ui.tutorial.finish") if current_step == total_steps - 1 else tr("ui.tutorial.next")

# 上一步按钮处理
func _on_prev_button_pressed() -> void:
	if tutorial_manager:
		tutorial_manager.previous_tutorial_step()

# 下一步按钮处理
func _on_next_button_pressed() -> void:
	if tutorial_manager:
		tutorial_manager.next_tutorial_step()

# 跳过按钮处理
func _on_skip_button_pressed() -> void:
	if tutorial_manager:
		tutorial_manager.skip_tutorial(tutorial_id)
		
		# 隐藏面板
		hide()
