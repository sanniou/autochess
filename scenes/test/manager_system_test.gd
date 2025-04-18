extends Control
## 管理器系统测试场景
## 用于测试新的管理器系统功能

# 引用
@onready var manager_list = $ManagerList
@onready var manager_info = $ManagerInfo
@onready var action_buttons = $ActionButtons

# 管理器系统
var manager_system = null

# 选中的管理器
var selected_manager = null

# 初始化
func _ready():
	# 连接按钮信号
	$ActionButtons/InitializeButton.pressed.connect(_on_initialize_button_pressed)
	$ActionButtons/ResetButton.pressed.connect(_on_reset_button_pressed)
	$ActionButtons/CleanupButton.pressed.connect(_on_cleanup_button_pressed)
	$ActionButtons/RefreshButton.pressed.connect(_on_refresh_button_pressed)
	$ActionButtons/BackButton.pressed.connect(_on_back_button_pressed)
	
	# 获取GameManager引用
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		manager_system = game_manager.manager_system
		
	# 加载管理器列表
	_load_manager_list()
	
	# 清空管理器信息
	_clear_manager_info()

# 加载管理器列表
func _load_manager_list():
	# 清空列表
	manager_list.clear()
	
	# 如果管理器系统不可用，显示错误
	if not manager_system:
		manager_list.add_item("无法获取管理器系统")
		return
	
	# 获取所有管理器名称
	var manager_names = manager_system.get_all_manager_names()
	
	# 添加到列表
	for manager_name in manager_names:
		var is_initialized = manager_system.is_initialized(manager_name)
		var prefix = "[✓] " if is_initialized else "[ ] "
		manager_list.add_item(prefix + manager_name)
	
	# 连接列表信号
	if not manager_list.item_selected.is_connected(_on_manager_selected):
		manager_list.item_selected.connect(_on_manager_selected)

# 清空管理器信息
func _clear_manager_info():
	manager_info.text = "选择一个管理器查看详细信息"

# 显示管理器信息
func _show_manager_info(manager_name: String):
	# 如果管理器系统不可用，显示错误
	if not manager_system:
		manager_info.text = "无法获取管理器系统"
		return
	
	# 获取管理器
	var manager = manager_system.get_manager(manager_name)
	if not manager:
		manager_info.text = "无法获取管理器: " + manager_name
		return
	
	# 构建信息文本
	var info_text = "管理器: " + manager_name + "\n\n"
	
	# 添加初始化状态
	var is_initialized = manager_system.is_initialized(manager_name)
	info_text += "初始化状态: " + ("已初始化" if is_initialized else "未初始化") + "\n\n"
	
	# 添加依赖信息
	var dependencies = manager_system.get_dependencies(manager_name)
	info_text += "依赖管理器:\n"
	if dependencies.is_empty():
		info_text += "  无依赖\n"
	else:
		for dependency in dependencies:
			var dep_initialized = manager_system.is_initialized(dependency)
			var status = "✓" if dep_initialized else "✗"
			info_text += "  " + dependency + " [" + status + "]\n"
	
	# 添加管理器类型信息
	info_text += "\n管理器类型: " + manager.get_class() + "\n"
	
	# 添加管理器状态信息（如果有）
	if manager.has_method("get_status"):
		var status = manager.get_status()
		info_text += "\n状态信息:\n"
		for key in status:
			info_text += "  " + key + ": " + str(status[key]) + "\n"
	
	# 添加错误信息（如果有）
	if manager.has_method("get_error") and not manager.get_error().is_empty():
		info_text += "\n错误信息:\n"
		info_text += "  " + manager.get_error() + "\n"
	
	# 显示信息
	manager_info.text = info_text

# 管理器选择处理
func _on_manager_selected(index: int):
	# 获取管理器名称
	var item_text = manager_list.get_item_text(index)
	var manager_name = item_text.substr(4)  # 移除前缀
	
	# 设置选中的管理器
	selected_manager = manager_name
	
	# 显示管理器信息
	_show_manager_info(manager_name)
	
	# 更新按钮状态
	_update_button_states()

# 更新按钮状态
func _update_button_states():
	# 如果没有选中管理器，禁用所有按钮
	if not selected_manager:
		$ActionButtons/InitializeButton.disabled = true
		$ActionButtons/ResetButton.disabled = true
		$ActionButtons/CleanupButton.disabled = true
		return
	
	# 如果管理器系统不可用，禁用所有按钮
	if not manager_system:
		$ActionButtons/InitializeButton.disabled = true
		$ActionButtons/ResetButton.disabled = true
		$ActionButtons/CleanupButton.disabled = true
		return
	
	# 获取管理器初始化状态
	var is_initialized = manager_system.is_initialized(selected_manager)
	
	# 更新按钮状态
	$ActionButtons/InitializeButton.disabled = is_initialized
	$ActionButtons/ResetButton.disabled = not is_initialized
	$ActionButtons/CleanupButton.disabled = not is_initialized

# 初始化按钮处理
func _on_initialize_button_pressed():
	if not selected_manager or not manager_system:
		return
	
	# 初始化管理器
	var success = manager_system.initialize(selected_manager)
	
	# 更新UI
	_load_manager_list()
	_show_manager_info(selected_manager)
	_update_button_states()
	
	# 显示结果
	if success:
		print("管理器初始化成功: " + selected_manager)
	else:
		print("管理器初始化失败: " + selected_manager)

# 重置按钮处理
func _on_reset_button_pressed():
	if not selected_manager or not manager_system:
		return
	
	# 获取管理器
	var manager = manager_system.get_manager(selected_manager)
	if not manager:
		return
	
	# 重置管理器
	var success = false
	if manager.has_method("reset"):
		success = manager.reset()
	
	# 更新UI
	_show_manager_info(selected_manager)
	
	# 显示结果
	if success:
		print("管理器重置成功: " + selected_manager)
	else:
		print("管理器重置失败: " + selected_manager)

# 清理按钮处理
func _on_cleanup_button_pressed():
	if not selected_manager or not manager_system:
		return
	
	# 获取管理器
	var manager = manager_system.get_manager(selected_manager)
	if not manager:
		return
	
	# 清理管理器
	var success = false
	if manager.has_method("cleanup"):
		success = manager.cleanup()
	
	# 更新UI
	_load_manager_list()
	_show_manager_info(selected_manager)
	_update_button_states()
	
	# 显示结果
	if success:
		print("管理器清理成功: " + selected_manager)
	else:
		print("管理器清理失败: " + selected_manager)

# 刷新按钮处理
func _on_refresh_button_pressed():
	# 重新加载管理器列表
	_load_manager_list()
	
	# 如果有选中的管理器，更新信息
	if selected_manager:
		_show_manager_info(selected_manager)
		_update_button_states()

# 返回按钮处理
func _on_back_button_pressed():
	# 返回测试菜单
	get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
