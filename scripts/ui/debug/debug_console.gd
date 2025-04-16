extends Control
## 调试控制台
## 用于执行调试命令和显示调试信息

# 引用
@onready var input_field = $ConsoleContainer/InputContainer/InputField
@onready var output_text = $ConsoleContainer/OutputContainer/OutputText
@onready var history_button = $ConsoleContainer/ControlsContainer/HistoryButton
@onready var clear_button = $ConsoleContainer/ControlsContainer/ClearButton
@onready var close_button = $ConsoleContainer/ControlsContainer/CloseButton

# 调试管理器
var debug_manager = null

# 命令历史
var command_history = []
var history_index = -1

# 最大历史记录数
const MAX_HISTORY = 50

# 初始化
func _ready() -> void:
	# 获取调试管理器
	debug_manager = get_node_or_null("/root/DebugManager")
	
	# 连接信号
	input_field.text_submitted.connect(_on_input_field_submitted)
	history_button.pressed.connect(_on_history_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 初始隐藏
	visible = false
	
	# 添加欢迎消息
	_add_output_text("调试控制台已启动。输入 'help' 获取可用命令列表。")

# 输入处理
func _input(event: InputEvent) -> void:
	# 检查是否按下了波浪键（~）或F12键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F12:
			# 切换控制台显示
			toggle_console()
		elif event.keycode == KEY_ESCAPE and visible:
			# 如果控制台可见，按ESC键隐藏
			hide_console()
		elif visible and event.keycode == KEY_UP:
			# 浏览历史记录（向上）
			_navigate_history(-1)
		elif visible and event.keycode == KEY_DOWN:
			# 浏览历史记录（向下）
			_navigate_history(1)

# 切换控制台显示
func toggle_console() -> void:
	visible = !visible
	
	if visible:
		# 聚焦输入框
		input_field.grab_focus()

# 显示控制台
func show_console() -> void:
	visible = true
	input_field.grab_focus()

# 隐藏控制台
func hide_console() -> void:
	visible = false

# 执行命令
func execute_command(command: String) -> void:
	if command.strip_edges().is_empty():
		return
	
	# 添加到历史记录
	_add_to_history(command)
	
	# 显示命令
	_add_output_text("> " + command)
	
	# 清空输入框
	input_field.clear()
	
	# 如果没有调试管理器，显示错误
	if not debug_manager:
		_add_output_text("错误: 调试管理器不可用")
		return
	
	# 执行命令
	var result = debug_manager.execute_command(command)
	
	# 显示结果
	_add_output_text(result)

# 添加输出文本
func _add_output_text(text: String) -> void:
	# 添加文本到输出区域
	output_text.text += text + "\n"
	
	# 滚动到底部
	output_text.scroll_to_line(output_text.get_line_count() - 1)

# 添加到历史记录
func _add_to_history(command: String) -> void:
	# 如果命令已经在历史记录中，先移除它
	var index = command_history.find(command)
	if index >= 0:
		command_history.remove_at(index)
	
	# 添加到历史记录
	command_history.append(command)
	
	# 限制历史记录大小
	if command_history.size() > MAX_HISTORY:
		command_history.pop_front()
	
	# 重置历史索引
	history_index = -1

# 浏览历史记录
func _navigate_history(direction: int) -> void:
	if command_history.is_empty():
		return
	
	# 更新历史索引
	if direction < 0 and history_index < command_history.size() - 1:
		history_index += 1
	elif direction > 0 and history_index >= 0:
		history_index -= 1
	
	# 设置输入文本
	if history_index >= 0:
		input_field.text = command_history[command_history.size() - 1 - history_index]
		# 将光标移到末尾
		input_field.caret_column = input_field.text.length()
	else:
		input_field.clear()

# 清除输出
func clear_output() -> void:
	output_text.clear()
	_add_output_text("输出已清除")

# 显示历史记录
func show_history() -> void:
	_add_output_text("命令历史记录:")
	
	for i in range(command_history.size()):
		var index = command_history.size() - 1 - i
		_add_output_text(str(i + 1) + ". " + command_history[index])

# 输入框提交处理
func _on_input_field_submitted(text: String) -> void:
	execute_command(text)

# 历史按钮处理
func _on_history_button_pressed() -> void:
	show_history()

# 清除按钮处理
func _on_clear_button_pressed() -> void:
	clear_output()

# 关闭按钮处理
func _on_close_button_pressed() -> void:
	hide_console()
