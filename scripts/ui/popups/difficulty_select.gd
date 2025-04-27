extends BaseWindowPopup
class_name DifficultySelect
## 难度选择弹窗
## 用于选择游戏难度

# 信号
signal difficulty_selected(difficulty: int)

# 难度按钮组
var difficulty_buttons: ButtonGroup = null

# 初始化
func _initialize() -> void:
	# 创建按钮组
	difficulty_buttons = ButtonGroup.new()
	
	# 连接按钮信号
	if has_node("ButtonContainer/EasyButton"):
		var easy_button = get_node("ButtonContainer/EasyButton")
		easy_button.button_group = difficulty_buttons
		easy_button.pressed.connect(_on_easy_button_pressed)
	
	if has_node("ButtonContainer/NormalButton"):
		var normal_button = get_node("ButtonContainer/NormalButton")
		normal_button.button_group = difficulty_buttons
		normal_button.pressed.connect(_on_normal_button_pressed)
	
	if has_node("ButtonContainer/HardButton"):
		var hard_button = get_node("ButtonContainer/HardButton")
		hard_button.button_group = difficulty_buttons
		hard_button.pressed.connect(_on_hard_button_pressed)
	
	if has_node("StartButton"):
		get_node("StartButton").pressed.connect(_on_start_button_pressed)
	
	if has_node("CancelButton"):
		get_node("CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 默认选择普通难度
	if has_node("ButtonContainer/NormalButton"):
		get_node("ButtonContainer/NormalButton").button_pressed = true
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	title = tr("ui.difficulty.title")
	
	# 设置难度描述
	_update_difficulty_description()

# 更新难度描述
func _update_difficulty_description() -> void:
	if has_node("DescriptionLabel"):
		var description_label = get_node("DescriptionLabel")
		var difficulty = _get_selected_difficulty()
		
		match difficulty:
			1: # 简单
				description_label.text = tr("ui.difficulty.easy_desc")
			2: # 普通
				description_label.text = tr("ui.difficulty.normal_desc")
			3: # 困难
				description_label.text = tr("ui.difficulty.hard_desc")
			_:
				description_label.text = ""

# 获取选中的难度
func _get_selected_difficulty() -> int:
	if difficulty_buttons == null:
		return 2 # 默认普通难度
	
	var selected_button = difficulty_buttons.get_pressed_button()
	if selected_button == null:
		return 2 # 默认普通难度
	
	if selected_button.name == "EasyButton":
		return 1
	elif selected_button.name == "NormalButton":
		return 2
	elif selected_button.name == "HardButton":
		return 3
	
	return 2 # 默认普通难度

# 简单按钮点击处理
func _on_easy_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 更新难度描述
	_update_difficulty_description()

# 普通按钮点击处理
func _on_normal_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 更新难度描述
	_update_difficulty_description()

# 困难按钮点击处理
func _on_hard_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 更新难度描述
	_update_difficulty_description()

# 开始按钮点击处理
func _on_start_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 获取选中的难度
	var difficulty = _get_selected_difficulty()
	
	# 发送难度选择信号
	difficulty_selected.emit(difficulty)
	
	# 关闭弹窗
	close_popup()

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
