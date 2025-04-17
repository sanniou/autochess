extends "res://scripts/managers/core/base_manager.gd"
# 不使用 class_name 以避免与自动加载单例冲突
## 资源管理器
## 负责管理游戏中的资源加载、缓存和释放

# 信号
signal resource_loaded(resource_path: String)
signal resource_unloaded(resource_path: String)
signal cache_cleared()

# 资源类型
enum ResourceType {
	TEXTURE,    # 纹理
	AUDIO,      # 音频
	SCENE,      # 场景
	SHADER,     # 着色器
	FONT,       # 字体
	MATERIAL,   # 材质
	ANIMATION,  # 动画
	SCRIPT,     # 脚本
	OTHER       # 其他
}

# 资源缓存
var texture_cache: Dictionary = {}
var audio_cache: Dictionary = {}
var scene_cache: Dictionary = {}
var shader_cache: Dictionary = {}
var font_cache: Dictionary = {}
var material_cache: Dictionary = {}
var animation_cache: Dictionary = {}
var script_cache: Dictionary = {}
var other_cache: Dictionary = {}

# 资源路径
const TEXTURE_PATH = "res://assets/textures/"
const AUDIO_PATH = "res://assets/audio/"
const SCENE_PATH = "res://scenes/"
const SHADER_PATH = "res://assets/shaders/"
const FONT_PATH = "res://assets/fonts/"
const MATERIAL_PATH = "res://assets/materials/"
const ANIMATION_PATH = "res://assets/animations/"
const SCRIPT_PATH = "res://scripts/"

# 资源加载设置
var resource_settings = {
	"preload_common": true,        # 是否预加载常用资源
	"async_loading": true,         # 是否异步加载
	"cache_limit": 100,            # 每种类型的缓存限制
	"auto_unload": true,           # 是否自动卸载不常用资源
	"unload_check_interval": 60.0, # 卸载检查间隔（秒）
	"usage_threshold": 300.0       # 使用时间阈值（秒）
}

# 资源使用统计
var resource_stats = {
	"loaded_count": 0,             # 已加载资源数量
	"cache_hits": 0,               # 缓存命中次数
	"cache_misses": 0,             # 缓存未命中次数
	"load_time": 0.0,              # 资源加载总时间
	"memory_usage": 0.0            # 资源内存使用量
}

# 资源使用记录
var resource_usage = {}

# 线程
var loading_mutex: Mutex = Mutex.new()
var loading_thread: Thread = null
var loading_queue = []
var loading_completed = []

# 计时器
var _unload_timer = 0.0

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ResourceManager"

	# 原 _ready 函数的内容
	# 预加载常用资源
	if resource_settings.preload_common:
		_preload_common_resources()

	# 启动资源加载线程
	if resource_settings.async_loading:
		_start_loading_thread()

	# 处理
func _process(delta: float) -> void:
	# 处理已完成的异步加载
	_process_completed_loads()

	# 检查是否需要卸载资源
	if resource_settings.auto_unload:
		_unload_timer += delta
		if _unload_timer >= resource_settings.unload_check_interval:
			_unload_timer = 0.0
			_check_resources_for_unload()

# 退出时清理
func _exit_tree() -> void:
	# 停止加载线程
	if loading_thread and loading_thread.is_started():
		loading_thread.wait_to_finish()

	# 清理资源
	clear_all_caches()

## 获取纹理
func get_texture(path: String) -> Texture2D:
	return _get_resource(path, ResourceType.TEXTURE) as Texture2D

## 获取音频
func get_audio(path: String) -> AudioStream:
	return _get_resource(path, ResourceType.AUDIO) as AudioStream

## 获取场景
func get_scene(path: String) -> PackedScene:
	return _get_resource(path, ResourceType.SCENE) as PackedScene

## 获取着色器
func get_shader(path: String) -> Shader:
	return _get_resource(path, ResourceType.SHADER) as Shader

## 获取字体
func get_font(path: String) -> Font:
	return _get_resource(path, ResourceType.FONT) as Font

## 获取材质
func get_material(path: String) -> Material:
	return _get_resource(path, ResourceType.MATERIAL) as Material

## 获取动画
func get_animation(path: String) -> Animation:
	return _get_resource(path, ResourceType.ANIMATION) as Animation

## 获取脚本
func get_gdscript(path: String) -> GDScript:
	return _get_resource(path, ResourceType.SCRIPT) as GDScript

## 获取任意资源
func get_resource(path: String) -> Resource:
	return _get_resource(path, ResourceType.OTHER)

## 异步加载纹理
func load_texture_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.TEXTURE, callback)

## 异步加载音频
func load_audio_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.AUDIO, callback)

## 异步加载场景
func load_scene_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.SCENE, callback)

## 异步加载着色器
func load_shader_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.SHADER, callback)

## 异步加载字体
func load_font_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.FONT, callback)

## 异步加载材质
func load_material_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.MATERIAL, callback)

## 异步加载动画
func load_animation_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.ANIMATION, callback)

## 异步加载脚本
func load_gdscript_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.SCRIPT, callback)

## 异步加载任意资源
func load_resource_async(path: String, callback: Callable) -> void:
	_load_resource_async(path, ResourceType.OTHER, callback)

## 预加载资源
func preload_resource(path: String, type: int) -> void:
	_get_resource(path, type)

## 卸载资源
func unload_resource(path: String, type: int) -> void:
	var cache = _get_cache_for_type(type)
	if cache.has(path):
		cache.erase(path)
		resource_usage.erase(path)
		resource_stats.loaded_count -= 1
		resource_unloaded.emit(path)

## 清除纹理缓存
func clear_texture_cache() -> void:
	texture_cache.clear()
	_update_stats_after_clear(ResourceType.TEXTURE)

## 清除音频缓存
func clear_audio_cache() -> void:
	audio_cache.clear()
	_update_stats_after_clear(ResourceType.AUDIO)

## 清除场景缓存
func clear_scene_cache() -> void:
	scene_cache.clear()
	_update_stats_after_clear(ResourceType.SCENE)

## 清除着色器缓存
func clear_shader_cache() -> void:
	shader_cache.clear()
	_update_stats_after_clear(ResourceType.SHADER)

## 清除字体缓存
func clear_font_cache() -> void:
	font_cache.clear()
	_update_stats_after_clear(ResourceType.FONT)

## 清除材质缓存
func clear_material_cache() -> void:
	material_cache.clear()
	_update_stats_after_clear(ResourceType.MATERIAL)

## 清除动画缓存
func clear_animation_cache() -> void:
	animation_cache.clear()
	_update_stats_after_clear(ResourceType.ANIMATION)

## 清除脚本缓存
func clear_script_cache() -> void:
	script_cache.clear()
	_update_stats_after_clear(ResourceType.SCRIPT)

## 清除其他缓存
func clear_other_cache() -> void:
	other_cache.clear()
	_update_stats_after_clear(ResourceType.OTHER)

## 清除所有缓存
func clear_all_caches() -> void:
	clear_texture_cache()
	clear_audio_cache()
	clear_scene_cache()
	clear_shader_cache()
	clear_font_cache()
	clear_material_cache()
	clear_animation_cache()
	clear_script_cache()
	clear_other_cache()

	resource_usage.clear()
	resource_stats.loaded_count = 0
	cache_cleared.emit()

## 获取资源统计信息
func get_resource_stats() -> Dictionary:
	# 更新内存使用量
	_update_memory_usage()

	return resource_stats

## 获取资源使用情况
func get_resource_usage() -> Dictionary:
	return resource_usage

## 获取缓存大小
func get_cache_size(type: int) -> int:
	var cache = _get_cache_for_type(type)
	return cache.size()

## 获取总缓存大小
func get_total_cache_size() -> int:
	return (
		texture_cache.size() +
		audio_cache.size() +
		scene_cache.size() +
		shader_cache.size() +
		font_cache.size() +
		material_cache.size() +
		animation_cache.size() +
		script_cache.size() +
		other_cache.size()
	)

## 获取资源
func _get_resource(path: String, type: int) -> Resource:
	# 检查路径是否为空
	if path.is_empty():
		push_error("资源路径为空")
		return null

	# 构建完整路径
	var full_path = _get_full_path(path, type)

	# 检查缓存
	var cache = _get_cache_for_type(type)
	if cache.has(full_path):
		# 更新使用记录
		_update_resource_usage(full_path)

		# 更新统计信息
		resource_stats.cache_hits += 1

		return cache[full_path]

	# 缓存未命中
	resource_stats.cache_misses += 1

	# 检查文件是否存在
	if not FileAccess.file_exists(full_path):
		push_error("资源文件不存在: " + full_path)
		return null

	# 加载资源
	var start_time = Time.get_ticks_msec()
	var resource = load(full_path)
	var end_time = Time.get_ticks_msec()

	# 更新统计信息
	resource_stats.load_time += (end_time - start_time) / 1000.0

	if resource:
		# 检查缓存大小
		if cache.size() >= resource_settings.cache_limit:
			# 移除最不常用的资源
			_remove_least_used_resource(type)

		# 缓存资源
		cache[full_path] = resource

		# 更新使用记录
		_update_resource_usage(full_path)

		# 更新统计信息
		resource_stats.loaded_count += 1

		# 发送信号
		resource_loaded.emit(full_path)
	else:
		push_error("无法加载资源: " + full_path)

	return resource

## 异步加载资源
func _load_resource_async(path: String, type: int, callback: Callable) -> void:
	# 检查路径是否为空
	if path.is_empty():
		push_error("资源路径为空")
		callback.call(null)
		return

	# 构建完整路径
	var full_path = _get_full_path(path, type)

	# 检查缓存
	var cache = _get_cache_for_type(type)
	if cache.has(full_path):
		# 更新使用记录
		_update_resource_usage(full_path)

		# 更新统计信息
		resource_stats.cache_hits += 1

		# 直接调用回调
		callback.call(cache[full_path])
		return

	# 缓存未命中
	resource_stats.cache_misses += 1

	# 检查文件是否存在
	if not FileAccess.file_exists(full_path):
		push_error("资源文件不存在: " + full_path)
		callback.call(null)
		return

	# 添加到加载队列
	loading_mutex.lock()
	loading_queue.append({
		"path": full_path,
		"type": type,
		"callback": callback
	})
	loading_mutex.unlock()

## 启动加载线程
func _start_loading_thread() -> void:
	if loading_thread and loading_thread.is_started():
		return

	loading_thread = Thread.new()
	loading_thread.start(_loading_thread_function)

## 加载线程函数
func _loading_thread_function() -> void:
	while true:
		# 检查是否有资源需要加载
		loading_mutex.lock()
		var has_items = not loading_queue.is_empty()
		loading_mutex.unlock()

		if not has_items:
			# 没有资源需要加载，休眠一段时间
			OS.delay_msec(10)
			continue

		# 获取下一个资源
		loading_mutex.lock()
		var item = loading_queue.pop_front()
		loading_mutex.unlock()

		# 加载资源
		var start_time = Time.get_ticks_msec()
		var resource = load(item.path)
		var end_time = Time.get_ticks_msec()

		# 添加到已完成队列
		loading_mutex.lock()
		loading_completed.append({
			"path": item.path,
			"type": item.type,
			"resource": resource,
			"callback": item.callback,
			"load_time": (end_time - start_time) / 1000.0
		})
		loading_mutex.unlock()

## 处理已完成的加载
func _process_completed_loads() -> void:
	if loading_completed.is_empty():
		return

	loading_mutex.lock()
	var completed = loading_completed.duplicate()
	loading_completed.clear()
	loading_mutex.unlock()

	for item in completed:
		var cache = _get_cache_for_type(item.type)

		if item.resource:
			# 检查缓存大小
			if cache.size() >= resource_settings.cache_limit:
				# 移除最不常用的资源
				_remove_least_used_resource(item.type)

			# 缓存资源
			cache[item.path] = item.resource

			# 更新使用记录
			_update_resource_usage(item.path)

			# 更新统计信息
			resource_stats.loaded_count += 1
			resource_stats.load_time += item.load_time

			# 在主线程中发送信号
			call_deferred("_emit_resource_loaded", item.path)
		else:
			push_error("无法加载资源: " + item.path)

		# 调用回调
		item.callback.call(item.resource)

## 预加载常用资源
func _preload_common_resources() -> void:
	# 预加载常用纹理
	var common_textures = [
		"ui/button_normal.png",
		"ui/button_pressed.png",
		"ui/button_hover.png",
		"ui/panel_background.png",
		"ui/icons/coin.png",
		"ui/icons/health.png",
		"ui/icons/mana.png",
		"ui/icons/attack.png",
		"ui/icons/defense.png",
		"effects/particle.png",
		"effects/explosion.png",
		"effects/smoke.png",
		"effects/fire.png"
	]

	for texture in common_textures:
		preload_resource(texture, ResourceType.TEXTURE)

	# 预加载常用音频
	var common_audio = [
		"sfx/click.ogg",
		"sfx/hover.ogg",
		"sfx/victory.ogg",
		"sfx/defeat.ogg",
		"sfx/coin.ogg",
		"sfx/level_up.ogg"
	]

	for audio in common_audio:
		preload_resource(audio, ResourceType.AUDIO)

	# 预加载常用场景
	var common_scenes = [
		"ui/loading_screen.tscn",
		"ui/message_box.tscn",
		"ui/tooltip.tscn",
		"effects/particle_effect.tscn",
		"effects/sprite_effect.tscn"
	]

	for scene in common_scenes:
		preload_resource(scene, ResourceType.SCENE)

## 检查资源是否需要卸载
func _check_resources_for_unload() -> void:
	var current_time = Time.get_unix_time_from_system()
	var resources_to_unload = []

	# 检查所有资源
	for path in resource_usage:
		var last_used = resource_usage[path].last_used
		var time_since_last_use = current_time - last_used

		# 如果资源长时间未使用，标记为卸载
		if time_since_last_use > resource_settings.usage_threshold:
			resources_to_unload.append({
				"path": path,
				"type": resource_usage[path].type
			})

	# 卸载资源
	for item in resources_to_unload:
		unload_resource(item.path, item.type)

## 移除最不常用的资源
func _remove_least_used_resource(type: int) -> void:
	var cache = _get_cache_for_type(type)
	if cache.is_empty():
		return

	var least_used_path = ""
	var least_used_time = INF

	# 查找最不常用的资源
	for path in cache:
		if resource_usage.has(path):
			var last_used = resource_usage[path].last_used
			if last_used < least_used_time:
				least_used_time = last_used
				least_used_path = path

	# 移除资源
	if not least_used_path.is_empty():
		cache.erase(least_used_path)
		resource_usage.erase(least_used_path)
		resource_stats.loaded_count -= 1
		resource_unloaded.emit(least_used_path)

## 更新资源使用记录
func _update_resource_usage(path: String) -> void:
	var current_time = Time.get_unix_time_from_system()

	if resource_usage.has(path):
		resource_usage[path].last_used = current_time
		resource_usage[path].use_count += 1
	else:
		# 确定资源类型
		var type = ResourceType.OTHER
		if path.begins_with(TEXTURE_PATH):
			type = ResourceType.TEXTURE
		elif path.begins_with(AUDIO_PATH):
			type = ResourceType.AUDIO
		elif path.begins_with(SCENE_PATH):
			type = ResourceType.SCENE
		elif path.begins_with(SHADER_PATH):
			type = ResourceType.SHADER
		elif path.begins_with(FONT_PATH):
			type = ResourceType.FONT
		elif path.begins_with(MATERIAL_PATH):
			type = ResourceType.MATERIAL
		elif path.begins_with(ANIMATION_PATH):
			type = ResourceType.ANIMATION
		elif path.begins_with(SCRIPT_PATH):
			type = ResourceType.SCRIPT

		resource_usage[path] = {
			"type": type,
			"first_used": current_time,
			"last_used": current_time,
			"use_count": 1
		}

## 更新内存使用量
func _update_memory_usage() -> void:
	# 这只是一个粗略的估计，实际内存使用量需要更复杂的计算
	var total_size = 0.0

	# 估计纹理内存
	for path in texture_cache:
		var texture = texture_cache[path]
		if texture is Texture2D:
			var width = texture.get_width()
			var height = texture.get_height()
			# 假设每个像素4字节
			total_size += width * height * 4

	# 估计音频内存
	for path in audio_cache:
		var audio = audio_cache[path]
		if audio is AudioStream:
			# 粗略估计
			total_size += 1024 * 1024  # 假设每个音频文件平均1MB

	# 估计场景内存
	total_size += scene_cache.size() * 512 * 1024  # 假设每个场景平均512KB

	# 估计其他资源内存
	total_size += (
		shader_cache.size() * 64 * 1024 +  # 假设每个着色器平均64KB
		font_cache.size() * 256 * 1024 +   # 假设每个字体平均256KB
		material_cache.size() * 32 * 1024 + # 假设每个材质平均32KB
		animation_cache.size() * 128 * 1024 + # 假设每个动画平均128KB
		script_cache.size() * 16 * 1024 +  # 假设每个脚本平均16KB
		other_cache.size() * 64 * 1024     # 假设每个其他资源平均64KB
	)

	# 转换为MB
	resource_stats.memory_usage = total_size / (1024 * 1024)

## 获取完整路径
func _get_full_path(path: String, type: int) -> String:
	# 如果路径已经是完整路径，直接返回
	if path.begins_with("res://"):
		return path

	# 根据类型构建完整路径
	match type:
		ResourceType.TEXTURE:
			return TEXTURE_PATH + path
		ResourceType.AUDIO:
			return AUDIO_PATH + path
		ResourceType.SCENE:
			return SCENE_PATH + path
		ResourceType.SHADER:
			return SHADER_PATH + path
		ResourceType.FONT:
			return FONT_PATH + path
		ResourceType.MATERIAL:
			return MATERIAL_PATH + path
		ResourceType.ANIMATION:
			return ANIMATION_PATH + path
		ResourceType.SCRIPT:
			return SCRIPT_PATH + path
		_:
			return path

## 获取类型对应的缓存
func _get_cache_for_type(type: int) -> Dictionary:
	match type:
		ResourceType.TEXTURE:
			return texture_cache
		ResourceType.AUDIO:
			return audio_cache
		ResourceType.SCENE:
			return scene_cache
		ResourceType.SHADER:
			return shader_cache
		ResourceType.FONT:
			return font_cache
		ResourceType.MATERIAL:
			return material_cache
		ResourceType.ANIMATION:
			return animation_cache
		ResourceType.SCRIPT:
			return script_cache
		_:
			return other_cache

## 更新统计信息（清除缓存后）
func _update_stats_after_clear(type: int) -> void:
	# 更新已加载资源数量
	var cache = _get_cache_for_type(type)
	resource_stats.loaded_count -= cache.size()

	# 清除使用记录
	var paths_to_remove = []
	for path in resource_usage:
		if resource_usage[path].type == type:
			paths_to_remove.append(path)

	for path in paths_to_remove:
		resource_usage.erase(path)

## 在主线程中发送资源加载信号
func _emit_resource_loaded(path: String) -> void:
	resource_loaded.emit(path)

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
