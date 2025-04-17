extends "res://scripts/managers/core/base_manager.gd"
## 场景管理器
## 负责管理场景的加载、切换和过渡效果

# 信号
signal scene_loading_started(scene_name: String)
signal scene_loading_progress(progress: float)
signal scene_loading_finished(scene_name: String)
signal scene_changed(old_scene: String, new_scene: String)

# 常量
const SCENE_PATH = "res://scenes/"
const TRANSITION_DURATION = 0.5  # 过渡动画时间

# 场景状态
enum SceneManagerState {
	IDLE,      # 空闲状态
	LOADING,   # 加载状态
	CHANGING,  # 切换状态
	TRANSITION # 过渡状态
}

# 当前场景状态
var current_state: SceneManagerState = SceneManagerState.IDLE

# 当前场景名称
var current_scene: String = ""

# 上一个场景名称
var previous_scene: String = ""

# 场景历史记录
var scene_history: Array = []

# 场景缓存
var scene_cache: Dictionary = {}

# 加载线程
var loading_thread: Thread = null

# 引用
var ui_manager = null

# 初始化
func _ready() -> void:
	# 初始化管理器
	initialize()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SceneManager"

	# 连接信号
	EventBus.ui.connect_event("transition_midpoint", _on_transition_midpoint)

	# 获取当前场景
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1).name

	# 输出初始化完成信息
	EventBus.debug.emit_event("debug_message", ["SceneManager 初始化完成", 0])

# 加载场景
func load_scene(scene_name: String, use_transition: bool = true, cache_scene: bool = false) -> void:
	# 检查当前状态
	if current_state != SceneManagerState.IDLE:
		EventBus.debug.emit_event("debug_message", ["场景管理器正忙，无法加载场景: " + scene_name, 1])
		return

	# 更新状态
	current_state = SceneManagerState.LOADING

	# 发送信号
	scene_loading_started.emit(scene_name)

	# 检查场景缓存
	if scene_cache.has(scene_name):
		_on_scene_loaded(scene_name, scene_cache[scene_name], use_transition)
		return

	# 构建场景路径
	var scene_path = SCENE_PATH

	# 根据场景名称确定具体路径
	match scene_name:
		"main_menu":
			scene_path += "main_menu.tscn"
		"map":
			scene_path += "map/map_scene.tscn"
		"battle":
			scene_path += "battle/battle_scene.tscn"
		"shop":
			scene_path += "shop/shop_scene.tscn"
		"event":
			scene_path += "event/event_scene.tscn"
		"altar":
			scene_path += "altar/altar_scene.tscn"
		"blacksmith":
			scene_path += "blacksmith/blacksmith_scene.tscn"
		_:
			# 尝试直接使用场景名称
			scene_path += scene_name + ".tscn"

	# 开始加载场景
	if ResourceLoader.has_cached(scene_path):
		# 场景已缓存，直接加载
		var scene = ResourceLoader.load(scene_path)
		_on_scene_loaded(scene_name, scene, use_transition)
	else:
		# 场景未缓存，使用线程加载
		loading_thread = Thread.new()
		loading_thread.start(_load_scene_thread.bind(scene_path, scene_name, use_transition, cache_scene))

# 线程加载场景
func _load_scene_thread(scene_path: String, scene_name: String, use_transition: bool, cache_scene: bool) -> void:
	# 使用ResourceLoader加载场景
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		EventBus.debug.emit_event("debug_message", ["无法加载场景: " + scene_path + ", 错误: " + str(err), 2])
		current_state = SceneManagerState.IDLE
		return

	var progress = [0.0]
	var scene = null

	# 等待加载完成
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)

		# 发送加载进度信号
		scene_loading_progress.emit(progress[0])

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				# 加载完成
				scene = ResourceLoader.load_threaded_get(scene_path)
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				# 加载失败
				EventBus.debug.emit_event("debug_message", ["加载场景失败: " + scene_path, 2])
				current_state = SceneManagerState.IDLE
				return
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				# 无效资源
				EventBus.debug.emit_event("debug_message", ["无效的场景资源: " + scene_path, 2])
				current_state = SceneManagerState.IDLE
				return

		# 等待一帧
		await get_tree().process_frame

	# 缓存场景
	if cache_scene:
		scene_cache[scene_name] = scene

	# 切换到主线程完成场景加载
	call_deferred("_on_scene_loaded", scene_name, scene, use_transition)

# 场景加载完成处理
func _on_scene_loaded(scene_name: String, scene: PackedScene, use_transition: bool) -> void:
	# 更新状态
	current_state = SceneManagerState.CHANGING

	# 发送信号
	scene_loading_finished.emit(scene_name)

	# 保存上一个场景
	previous_scene = current_scene

	# 添加到历史记录
	scene_history.append(current_scene)

	# 更新当前场景
	current_scene = scene_name

	# 使用过渡效果
	if use_transition:
		current_state = SceneManagerState.TRANSITION
		EventBus.ui.emit_event("start_transition", ["fade", TRANSITION_DURATION])
	else:
		_change_scene(scene)

# 过渡中点处理
func _on_transition_midpoint() -> void:
	# 获取场景实例
	var scene = scene_cache.get(current_scene)
	if scene == null:
		# 构建场景路径
		var scene_path = SCENE_PATH

		# 根据场景名称确定具体路径
		match current_scene:
			"main_menu":
				scene_path += "main_menu.tscn"
			"map":
				scene_path += "map/map_scene.tscn"
			"battle":
				scene_path += "battle/battle_scene.tscn"
			"shop":
				scene_path += "shop/shop_scene.tscn"
			"event":
				scene_path += "event/event_scene.tscn"
			"altar":
				scene_path += "altar/altar_scene.tscn"
			"blacksmith":
				scene_path += "blacksmith/blacksmith_scene.tscn"
			_:
				# 尝试直接使用场景名称
				scene_path += current_scene + ".tscn"

		# 加载场景
		scene = load(scene_path)

	# 切换场景
	_change_scene(scene)

# 切换场景
func _change_scene(scene: PackedScene) -> void:
	# 获取当前场景
	var root = get_tree().get_root()
	var current = root.get_child(root.get_child_count() - 1)

	# 移除当前场景
	root.remove_child(current)
	current.queue_free()

	# 添加新场景
	var new_scene = scene.instantiate()
	root.add_child(new_scene)

	# 发送场景变化信号
	scene_changed.emit(previous_scene, current_scene)

	# 更新状态
	current_state = SceneManagerState.IDLE

# 返回上一个场景
func go_back(use_transition: bool = true) -> void:
	# 检查历史记录
	if scene_history.size() == 0:
		EventBus.debug.emit_event("debug_message", ["没有上一个场景可返回", 1])
		return

	# 获取上一个场景
	var previous = scene_history.pop_back()

	# 加载上一个场景
	load_scene(previous, use_transition)

# 获取当前场景状态
func get_current_state() -> SceneManagerState:
	return current_state

# 获取当前场景名称
func get_current_scene() -> String:
	return current_scene

# 获取上一个场景名称
func get_previous_scene() -> String:
	return previous_scene

# 清除场景缓存
func clear_scene_cache() -> void:
	scene_cache.clear()

# 预加载场景
func preload_scene(scene_name: String) -> void:
	# 构建场景路径
	var scene_path = SCENE_PATH

	# 根据场景名称确定具体路径
	match scene_name:
		"main_menu":
			scene_path += "main_menu.tscn"
		"map":
			scene_path += "map/map_scene.tscn"
		"battle":
			scene_path += "battle/battle_scene.tscn"
		"shop":
			scene_path += "shop/shop_scene.tscn"
		"event":
			scene_path += "event/event_scene.tscn"
		"altar":
			scene_path += "altar/altar_scene.tscn"
		"blacksmith":
			scene_path += "blacksmith/blacksmith_scene.tscn"
		_:
			# 尝试直接使用场景名称
			scene_path += scene_name + ".tscn"

	# 检查场景是否已缓存
	if scene_cache.has(scene_name):
		return

	# 开始加载场景
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		EventBus.debug.emit_event("debug_message", ["无法预加载场景: " + scene_path + ", 错误: " + str(err), 1])
		return

	# 创建线程监控加载进度
	var thread = Thread.new()
	thread.start(_monitor_preload.bind(scene_path, scene_name))

# 监控预加载进度
func _monitor_preload(scene_path: String, scene_name: String) -> void:
	var progress = [0.0]

	# 等待加载完成
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				# 加载完成
				var scene = ResourceLoader.load_threaded_get(scene_path)
				scene_cache[scene_name] = scene
				EventBus.debug.emit_event("debug_message", ["场景预加载完成: " + scene_name, 0])
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				# 加载失败
				EventBus.debug.emit_event("debug_message", ["预加载场景失败: " + scene_path, 1])
				break
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				# 无效资源
				EventBus.debug.emit_event("debug_message", ["无效的预加载场景资源: " + scene_path, 1])
				break

		# 等待一帧
		OS.delay_msec(100)  # 等待100毫秒

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])
