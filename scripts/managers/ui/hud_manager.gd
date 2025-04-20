extends "res://scripts/managers/core/base_manager.gd"
class_name HUDManager
## HUD管理器
## 负责管理所有HUD的加载、显示和隐藏

# 信号
signal hud_loaded(hud_name: String, hud_instance: BaseHUD)
signal hud_unloaded(hud_name: String)
signal hud_shown(hud_name: String)
signal hud_hidden(hud_name: String)

# HUD容器
var hud_container: Control = null

# 当前加载的HUD
var loaded_huds: Dictionary = {}

# 当前显示的HUD
var visible_huds: Array[String] = []

# HUD场景路径
const HUD_SCENE_PATH = "res://scenes/ui/hud/"

# HUD脚本路径
const HUD_SCRIPT_PATH = "res://scripts/ui/hud/"

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "HUDManager"

	# 添加依赖
	add_dependency("UIManager")

	# 获取HUD容器
	var ui_manager:UIManager = GameManager.get_manager("UIManager")
	if ui_manager:
		hud_container = ui_manager.get_hud_container()

		if not hud_container:
			_log_error("UIManager没有提供HUD容器")
			return
	else:
		_log_error("UIManager不可用")
		return

	# 连接信号
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

# 加载HUD
func load_hud(hud_name: String, show_immediately: bool = true, data: Dictionary = {}) -> BaseHUD:
	# 检查是否已经加载
	if loaded_huds.has(hud_name):
		var hud = loaded_huds[hud_name]
		if show_immediately and not visible_huds.has(hud_name):
			show_hud(hud_name, data)
		elif data.size() > 0:
			hud.set_hud_data(data)
		return hud

	# 尝试加载HUD场景
	var hud_scene = load(HUD_SCENE_PATH + hud_name + ".tscn")
	if not hud_scene:
		# 如果场景不存在，尝试加载脚本并创建实例
		var hud_script = load(HUD_SCRIPT_PATH + hud_name + ".gd")
		if not hud_script:
			EventBus.debug.emit_event("debug_message", ["无法加载HUD: " + hud_name, 2])
			return null

		# 创建HUD实例
		var hud_instance = Control.new()
		hud_instance.set_script(hud_script)
		hud_container.add_child(hud_instance)

		# 设置HUD属性
		hud_instance.hud_name = hud_name
		if data.size() > 0:
			hud_instance.set_hud_data(data)

		# 存储HUD引用
		loaded_huds[hud_name] = hud_instance

		# 如果需要立即显示
		if show_immediately:
			show_hud(hud_name)
		else:
			hud_instance.hide_hud()

		# 发送信号
		hud_loaded.emit(hud_name, hud_instance)

		return hud_instance
	else:
		# 实例化场景
		var hud_instance = hud_scene.instantiate()
		hud_container.add_child(hud_instance)

		# 设置HUD属性
		hud_instance.hud_name = hud_name
		if data.size() > 0:
			hud_instance.set_hud_data(data)

		# 存储HUD引用
		loaded_huds[hud_name] = hud_instance

		# 如果需要立即显示
		if show_immediately:
			show_hud(hud_name)
		else:
			hud_instance.hide_hud()

		# 发送信号
		hud_loaded.emit(hud_name, hud_instance)

		return hud_instance

# 卸载HUD
func unload_hud(hud_name: String) -> bool:
	# 检查是否已加载
	if not loaded_huds.has(hud_name):
		return false

	# 获取HUD实例
	var hud = loaded_huds[hud_name]

	# 从可见HUD列表中移除
	if visible_huds.has(hud_name):
		visible_huds.erase(hud_name)

	# 从加载的HUD字典中移除
	loaded_huds.erase(hud_name)

	# 从场景树中移除
	hud.queue_free()

	# 发送信号
	hud_unloaded.emit(hud_name)

	return true

# 显示HUD
func show_hud(hud_name: String, data: Dictionary = {}) -> bool:
	# 检查是否已加载
	if not loaded_huds.has(hud_name):
		# 尝试加载HUD
		var hud = load_hud(hud_name, true, data)
		return hud != null

	# 获取HUD实例
	var hud = loaded_huds[hud_name]

	# 设置数据
	if data.size() > 0:
		hud.set_hud_data(data)

	# 显示HUD
	hud.show_hud()

	# 添加到可见HUD列表
	if not visible_huds.has(hud_name):
		visible_huds.append(hud_name)

	# 发送信号
	hud_shown.emit(hud_name)

	return true

# 隐藏HUD
func hide_hud(hud_name: String) -> bool:
	# 检查是否已加载
	if not loaded_huds.has(hud_name):
		return false

	# 获取HUD实例
	var hud = loaded_huds[hud_name]

	# 隐藏HUD
	hud.hide_hud()

	# 从可见HUD列表中移除
	if visible_huds.has(hud_name):
		visible_huds.erase(hud_name)

	# 发送信号
	hud_hidden.emit(hud_name)

	return true

# 切换HUD可见性
func toggle_hud(hud_name: String) -> bool:
	# 检查是否已加载
	if not loaded_huds.has(hud_name):
		return false

	# 获取HUD实例
	var hud = loaded_huds[hud_name]

	# 切换可见性
	if hud.is_visible:
		return hide_hud(hud_name)
	else:
		return show_hud(hud_name)

# 获取HUD实例
func get_hud(hud_name: String) -> BaseHUD:
	if loaded_huds.has(hud_name):
		return loaded_huds[hud_name]
	return null

# 获取所有加载的HUD
func get_loaded_huds() -> Dictionary:
	return loaded_huds.duplicate()

# 获取所有可见的HUD
func get_visible_huds() -> Array:
	return visible_huds.duplicate()

# 隐藏所有HUD
func hide_all_huds() -> void:
	for hud_name in visible_huds.duplicate():
		hide_hud(hud_name)

# 卸载所有HUD
func unload_all_huds() -> void:
	for hud_name in loaded_huds.keys().duplicate():
		unload_hud(hud_name)

# 根据游戏状态加载相应的HUD
func _on_game_state_changed(_old_state: int, new_state: int) -> void:
	# 根据游戏状态加载不同的HUD
	match new_state:
		GameManager.GameState.MAIN_MENU:
			# 主菜单不需要特殊HUD
			hide_all_huds()
		GameManager.GameState.MAP:
			load_hud("map_hud")
		GameManager.GameState.BATTLE:
			load_hud("battle_hud")
		GameManager.GameState.SHOP:
			load_hud("shop_hud")
		GameManager.GameState.EVENT:
			load_hud("event_hud")
		GameManager.GameState.ALTAR:
			load_hud("altar_hud")
		GameManager.GameState.BLACKSMITH:
			load_hud("blacksmith_hud")
		_:
			# 默认HUD
			load_hud("default_hud")

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 重写重置方法
func _do_reset() -> void:
	# 卸载所有HUD
	unload_all_huds()

	# 清空列表
	loaded_huds.clear()
	visible_huds.clear()

	_log_info("HUD管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开信号连接
	EventBus.game.disconnect_event("game_state_changed", _on_game_state_changed)

	# 卸载所有HUD
	unload_all_huds()

	# 清空列表
	loaded_huds.clear()
	visible_huds.clear()

	# 重置HUD容器引用
	hud_container = null

	_log_info("HUD管理器清理完成")
