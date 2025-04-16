extends Node
class_name RenderOptimizer
## 渲染优化器
## 用于优化游戏的渲染性能

# 信号
signal optimization_level_changed(old_level, new_level)
signal culling_stats_updated(stats)

# 优化级别
enum OptimizationLevel {
	OFF,      # 不进行优化
	LOW,      # 低级优化
	MEDIUM,   # 中级优化
	HIGH,     # 高级优化
	ULTRA     # 超级优化
}

# 当前优化级别
var current_optimization_level = OptimizationLevel.MEDIUM

# 优化设置
var optimization_settings = {
	OptimizationLevel.OFF: {
		"enable_culling": false,
		"enable_lod": false,
		"max_particles": 1000,
		"shadow_quality": 2,  # 0-2，越高质量越好
		"msaa": Viewport.MSAA_4X,
		"fxaa": true,
		"vsync": true,
		"max_fps": 0  # 0表示不限制
	},
	OptimizationLevel.LOW: {
		"enable_culling": true,
		"enable_lod": false,
		"max_particles": 800,
		"shadow_quality": 2,
		"msaa": Viewport.MSAA_4X,
		"fxaa": true,
		"vsync": true,
		"max_fps": 0
	},
	OptimizationLevel.MEDIUM: {
		"enable_culling": true,
		"enable_lod": true,
		"max_particles": 600,
		"shadow_quality": 1,
		"msaa": Viewport.MSAA_2X,
		"fxaa": true,
		"vsync": true,
		"max_fps": 0
	},
	OptimizationLevel.HIGH: {
		"enable_culling": true,
		"enable_lod": true,
		"max_particles": 400,
		"shadow_quality": 0,
		"msaa": Viewport.MSAA_DISABLED,
		"fxaa": true,
		"vsync": true,
		"max_fps": 60
	},
	OptimizationLevel.ULTRA: {
		"enable_culling": true,
		"enable_lod": true,
		"max_particles": 200,
		"shadow_quality": 0,
		"msaa": Viewport.MSAA_DISABLED,
		"fxaa": false,
		"vsync": false,
		"max_fps": 30
	}
}

# 视口剔除设置
var culling_settings = {
	"enabled": true,
	"margin": 100,  # 视口边缘额外的剔除边距
	"check_interval": 0.2,  # 检查间隔（秒）
	"max_objects_per_frame": 50  # 每帧最多处理的对象数量
}

# 剔除统计
var culling_stats = {
	"total_objects": 0,
	"visible_objects": 0,
	"culled_objects": 0,
	"last_check_time": 0
}

# 需要剔除的对象组
var _cullable_groups = ["cullable", "chess_pieces", "effects", "ui_elements"]

# 剔除对象列表
var _cullable_objects = []

# 当前处理的对象索引
var _current_object_index = 0

# 计时器
var _culling_timer = 0.0

# 初始化
func _ready() -> void:
	# 应用当前优化级别的设置
	apply_optimization_settings()
	
	# 连接信号
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

# 进程
func _process(delta: float) -> void:
	# 更新剔除计时器
	_culling_timer += delta
	
	# 检查是否需要进行剔除
	if culling_settings.enabled and _culling_timer >= culling_settings.check_interval:
		_culling_timer = 0.0
		_update_culling()

## 设置优化级别
func set_optimization_level(level: int) -> void:
	if level < OptimizationLevel.OFF or level > OptimizationLevel.ULTRA:
		push_error("无效的优化级别: " + str(level))
		return
	
	var old_level = current_optimization_level
	current_optimization_level = level
	
	# 应用新的优化设置
	apply_optimization_settings()
	
	# 发送信号
	optimization_level_changed.emit(old_level, current_optimization_level)
	
	EventBus.debug_message.emit("渲染优化级别已设置为: " + _get_level_name(level), 0)

## 应用优化设置
func apply_optimization_settings() -> void:
	var settings = optimization_settings[current_optimization_level]
	
	# 更新剔除设置
	culling_settings.enabled = settings.enable_culling
	
	# 应用渲染设置
	_apply_render_settings(settings)
	
	# 应用粒子设置
	_apply_particle_settings(settings)
	
	# 应用LOD设置
	_apply_lod_settings(settings)

## 应用渲染设置
func _apply_render_settings(settings: Dictionary) -> void:
	# 获取主视口
	var viewport = get_viewport()
	if viewport == null:
		return
	
	# 设置MSAA
	viewport.msaa = settings.msaa
	
	# 设置FXAA
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if settings.fxaa else Viewport.SCREEN_SPACE_AA_DISABLED
	
	# 设置垂直同步
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	
	# 设置最大FPS
	Engine.max_fps = settings.max_fps
	
	# 设置阴影质量
	# 注意：在Godot 4中，阴影质量设置可能需要通过环境资源或全局设置来实现
	# 这里仅作为示例

## 应用粒子设置
func _apply_particle_settings(settings: Dictionary) -> void:
	# 遍历所有粒子系统
	var particles = get_tree().get_nodes_in_group("particles")
	for particle in particles:
		if particle is GPUParticles2D:
			# 设置最大粒子数量
			particle.amount = min(particle.amount, settings.max_particles)

## 应用LOD设置
func _apply_lod_settings(settings: Dictionary) -> void:
	# 启用或禁用LOD
	var lod_objects = get_tree().get_nodes_in_group("lod")
	for obj in lod_objects:
		if obj.has_method("set_lod_enabled"):
			obj.set_lod_enabled(settings.enable_lod)

## 更新视口剔除
func _update_culling() -> void:
	if _cullable_objects.is_empty():
		return
	
	# 获取视口矩形
	var viewport_rect = get_viewport().get_visible_rect()
	
	# 扩展视口矩形（添加边距）
	var culling_rect = viewport_rect.grow(culling_settings.margin)
	
	# 重置统计
	culling_stats.visible_objects = 0
	culling_stats.culled_objects = 0
	
	# 处理一批对象
	var objects_processed = 0
	var total_objects = _cullable_objects.size()
	
	while objects_processed < culling_settings.max_objects_per_frame and objects_processed < total_objects:
		# 获取当前对象
		var obj = _cullable_objects[_current_object_index]
		
		# 检查对象是否有效
		if is_instance_valid(obj) and obj.has_method("set_visible"):
			# 获取对象在视口中的位置
			var obj_pos = obj.global_position
			
			# 检查对象是否在视口内
			var is_visible = culling_rect.has_point(obj_pos)
			
			# 设置对象可见性
			obj.set_visible(is_visible)
			
			# 更新统计
			if is_visible:
				culling_stats.visible_objects += 1
			else:
				culling_stats.culled_objects += 1
		
		# 更新索引
		_current_object_index = (_current_object_index + 1) % total_objects
		objects_processed += 1
	
	# 更新总对象数
	culling_stats.total_objects = total_objects
	
	# 更新最后检查时间
	culling_stats.last_check_time = Time.get_unix_time_from_system()
	
	# 发送统计更新信号
	culling_stats_updated.emit(culling_stats)

## 添加可剔除对象
func add_cullable_object(obj: Node2D) -> void:
	if not _cullable_objects.has(obj):
		_cullable_objects.append(obj)

## 移除可剔除对象
func remove_cullable_object(obj: Node2D) -> void:
	_cullable_objects.erase(obj)

## 节点添加事件处理
func _on_node_added(node: Node) -> void:
	# 检查节点是否属于可剔除组
	for group in _cullable_groups:
		if node.is_in_group(group) and node is Node2D:
			add_cullable_object(node)
			break

## 节点移除事件处理
func _on_node_removed(node: Node) -> void:
	if node is Node2D and _cullable_objects.has(node):
		remove_cullable_object(node)

## 获取优化级别名称
func _get_level_name(level: int) -> String:
	match level:
		OptimizationLevel.OFF:
			return "关闭"
		OptimizationLevel.LOW:
			return "低"
		OptimizationLevel.MEDIUM:
			return "中"
		OptimizationLevel.HIGH:
			return "高"
		OptimizationLevel.ULTRA:
			return "超级"
		_:
			return "未知"

## 添加可剔除组
func add_cullable_group(group_name: String) -> void:
	if not _cullable_groups.has(group_name):
		_cullable_groups.append(group_name)
		
		# 添加现有组中的对象
		var nodes = get_tree().get_nodes_in_group(group_name)
		for node in nodes:
			if node is Node2D:
				add_cullable_object(node)

## 移除可剔除组
func remove_cullable_group(group_name: String) -> void:
	if _cullable_groups.has(group_name):
		_cullable_groups.erase(group_name)
		
		# 移除该组中的对象
		var nodes = get_tree().get_nodes_in_group(group_name)
		for node in nodes:
			if node is Node2D and _cullable_objects.has(node):
				remove_cullable_object(node)

## 设置剔除设置
func set_culling_settings(settings: Dictionary) -> void:
	# 更新设置
	if settings.has("enabled"):
		culling_settings.enabled = settings.enabled
	
	if settings.has("margin"):
		culling_settings.margin = max(0, settings.margin)
	
	if settings.has("check_interval"):
		culling_settings.check_interval = max(0.05, settings.check_interval)
	
	if settings.has("max_objects_per_frame"):
		culling_settings.max_objects_per_frame = max(10, settings.max_objects_per_frame)
	
	EventBus.debug_message.emit("视口剔除设置已更新", 0)

## 获取当前优化设置
func get_current_settings() -> Dictionary:
	return optimization_settings[current_optimization_level]

## 获取剔除统计
func get_culling_stats() -> Dictionary:
	return culling_stats

## 自动检测并设置最佳优化级别
func auto_detect_optimization_level() -> void:
	# 获取系统信息
	var video_adapter_name = OS.get_video_adapter_driver_info()
	var processor_name = OS.get_processor_name()
	var processor_count = OS.get_processor_count()
	var memory_mb = OS.get_static_memory_usage() / (1024 * 1024)
	
	# 根据系统信息选择优化级别
	var level = OptimizationLevel.MEDIUM
	
	# 这里的逻辑需要根据实际情况调整
	# 这只是一个简单的示例
	if processor_count >= 8 and memory_mb >= 8192:
		level = OptimizationLevel.LOW  # 高性能设备使用低优化（高质量）
	elif processor_count >= 4 and memory_mb >= 4096:
		level = OptimizationLevel.MEDIUM
	elif processor_count >= 2 and memory_mb >= 2048:
		level = OptimizationLevel.HIGH
	else:
		level = OptimizationLevel.ULTRA  # 低性能设备使用超级优化
	
	# 设置检测到的优化级别
	set_optimization_level(level)
	
	EventBus.debug_message.emit("自动检测优化级别: " + _get_level_name(level), 0)
