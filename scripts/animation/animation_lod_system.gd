extends Node
class_name AnimationLODSystem
## 动画LOD系统
## 负责根据距离和重要性调整动画质量

# 信号
signal lod_changed(object, old_level, new_level)

# LOD级别
enum LODLevel {
	HIGH,    # 高质量
	MEDIUM,  # 中等质量
	LOW,     # 低质量
	CULLED   # 剔除
}

# LOD配置
var lod_config = {
	"enabled": true,
	"distance_thresholds": {
		LODLevel.HIGH: 300.0,    # 高质量阈值
		LODLevel.MEDIUM: 600.0,  # 中等质量阈值
		LODLevel.LOW: 1000.0     # 低质量阈值
	},
	"importance_weights": {
		"player": 2.0,           # 玩家权重
		"enemy": 1.0,            # 敌人权重
		"effect": 0.5,           # 特效权重
		"environment": 0.2       # 环境权重
	},
	"update_interval": 0.5,      # 更新间隔（秒）
	"cull_offscreen": true       # 是否剔除屏幕外的对象
}

# 跟踪的对象
var tracked_objects = {}

# 摄像机引用
var camera = null

# 更新计时器
var _update_timer = 0.0

# 初始化
func _init() -> void:
	# 设置进程模式
	set_process(lod_config.enabled)

# 准备完成
func _ready() -> void:
	# 查找摄像机
	_find_camera()

# 查找摄像机
func _find_camera() -> void:
	# 尝试获取当前摄像机
	camera = get_viewport().get_camera_2d()
	
	# 如果没有找到摄像机，使用默认摄像机
	if not camera:
		# 在下一帧再次尝试
		call_deferred("_find_camera")

# 处理
func _process(delta: float) -> void:
	# 如果未启用，不处理
	if not lod_config.enabled:
		return
	
	# 更新计时器
	_update_timer += delta
	
	# 检查是否需要更新LOD
	if _update_timer >= lod_config.update_interval:
		_update_timer = 0.0
		_update_lod_levels()

# 添加对象
func add_object(object, type: String = "effect") -> void:
	# 检查对象是否有效
	if not object or not is_instance_valid(object):
		return
	
	# 检查对象是否已经被跟踪
	if tracked_objects.has(object):
		return
	
	# 添加到跟踪列表
	tracked_objects[object] = {
		"type": type,
		"importance": lod_config.importance_weights.get(type, 1.0),
		"lod_level": LODLevel.HIGH,
		"position": Vector2.ZERO,
		"visible": true
	}
	
	# 连接信号
	if object.has_signal("tree_exiting"):
		if not object.tree_exiting.is_connected(_on_object_tree_exiting):
			object.tree_exiting.connect(_on_object_tree_exiting.bind(object))

# 移除对象
func remove_object(object) -> void:
	# 检查对象是否被跟踪
	if not tracked_objects.has(object):
		return
	
	# 断开信号连接
	if object.has_signal("tree_exiting"):
		if object.tree_exiting.is_connected(_on_object_tree_exiting):
			object.tree_exiting.disconnect(_on_object_tree_exiting)
	
	# 从跟踪列表移除
	tracked_objects.erase(object)

# 设置对象类型
func set_object_type(object, type: String) -> void:
	# 检查对象是否被跟踪
	if not tracked_objects.has(object):
		add_object(object, type)
		return
	
	# 更新类型和重要性
	tracked_objects[object].type = type
	tracked_objects[object].importance = lod_config.importance_weights.get(type, 1.0)
	
	# 更新LOD级别
	_update_object_lod(object)

# 设置对象重要性
func set_object_importance(object, importance: float) -> void:
	# 检查对象是否被跟踪
	if not tracked_objects.has(object):
		return
	
	# 更新重要性
	tracked_objects[object].importance = importance
	
	# 更新LOD级别
	_update_object_lod(object)

# 获取对象LOD级别
func get_object_lod_level(object) -> int:
	# 检查对象是否被跟踪
	if not tracked_objects.has(object):
		return LODLevel.HIGH
	
	# 返回LOD级别
	return tracked_objects[object].lod_level

# 启用LOD系统
func enable() -> void:
	lod_config.enabled = true
	set_process(true)
	
	# 更新所有对象的LOD级别
	_update_lod_levels()

# 禁用LOD系统
func disable() -> void:
	lod_config.enabled = false
	set_process(false)
	
	# 将所有对象设置为高质量
	for object in tracked_objects:
		_set_object_lod_level(object, LODLevel.HIGH)

# 设置距离阈值
func set_distance_threshold(level: int, threshold: float) -> void:
	# 检查级别是否有效
	if not lod_config.distance_thresholds.has(level):
		return
	
	# 更新阈值
	lod_config.distance_thresholds[level] = threshold
	
	# 更新所有对象的LOD级别
	_update_lod_levels()

# 设置重要性权重
func set_importance_weight(type: String, weight: float) -> void:
	# 更新权重
	lod_config.importance_weights[type] = weight
	
	# 更新所有对象的LOD级别
	_update_lod_levels()

# 设置更新间隔
func set_update_interval(interval: float) -> void:
	lod_config.update_interval = max(0.1, interval)

# 设置是否剔除屏幕外的对象
func set_cull_offscreen(cull: bool) -> void:
	lod_config.cull_offscreen = cull
	
	# 如果禁用剔除，恢复所有被剔除的对象
	if not cull:
		for object in tracked_objects:
			if tracked_objects[object].lod_level == LODLevel.CULLED:
				_update_object_lod(object)

# 更新所有对象的LOD级别
func _update_lod_levels() -> void:
	# 检查摄像机是否有效
	if not camera or not is_instance_valid(camera):
		_find_camera()
		return
	
	# 获取视口大小
	var viewport_rect = get_viewport().get_visible_rect()
	
	# 获取摄像机位置
	var camera_position = camera.global_position
	
	# 更新所有对象
	for object in tracked_objects.keys():
		# 检查对象是否有效
		if not is_instance_valid(object):
			tracked_objects.erase(object)
			continue
		
		# 更新对象位置
		if object is Node2D:
			tracked_objects[object].position = object.global_position
		
		# 更新对象可见性
		if object is CanvasItem:
			tracked_objects[object].visible = object.visible
		
		# 更新对象LOD级别
		_update_object_lod(object)

# 更新单个对象的LOD级别
func _update_object_lod(object) -> void:
	# 检查对象是否有效
	if not is_instance_valid(object) or not tracked_objects.has(object):
		return
	
	# 获取对象数据
	var data = tracked_objects[object]
	
	# 如果对象不可见，剔除它
	if not data.visible:
		_set_object_lod_level(object, LODLevel.CULLED)
		return
	
	# 检查摄像机是否有效
	if not camera or not is_instance_valid(camera):
		_find_camera()
		return
	
	# 获取视口大小
	var viewport_rect = get_viewport().get_visible_rect()
	
	# 获取摄像机位置
	var camera_position = camera.global_position
	
	# 计算对象到摄像机的距离
	var distance = camera_position.distance_to(data.position)
	
	# 应用重要性权重
	distance /= data.importance
	
	# 检查对象是否在屏幕外
	var is_offscreen = false
	if lod_config.cull_offscreen and object is Node2D:
		# 转换为屏幕坐标
		var screen_position = camera.get_viewport_transform() * object.global_position
		
		# 检查是否在视口内
		is_offscreen = not viewport_rect.has_point(screen_position)
	
	# 确定LOD级别
	var new_level = LODLevel.HIGH
	
	if is_offscreen:
		new_level = LODLevel.CULLED
	elif distance > lod_config.distance_thresholds[LODLevel.LOW]:
		new_level = LODLevel.CULLED
	elif distance > lod_config.distance_thresholds[LODLevel.MEDIUM]:
		new_level = LODLevel.LOW
	elif distance > lod_config.distance_thresholds[LODLevel.HIGH]:
		new_level = LODLevel.MEDIUM
	
	# 设置LOD级别
	_set_object_lod_level(object, new_level)

# 设置对象LOD级别
func _set_object_lod_level(object, level: int) -> void:
	# 检查对象是否有效
	if not is_instance_valid(object) or not tracked_objects.has(object):
		return
	
	# 获取当前LOD级别
	var current_level = tracked_objects[object].lod_level
	
	# 如果级别没有变化，不做任何操作
	if current_level == level:
		return
	
	# 更新LOD级别
	tracked_objects[object].lod_level = level
	
	# 应用LOD级别
	_apply_lod_level(object, level)
	
	# 发送信号
	lod_changed.emit(object, current_level, level)

# 应用LOD级别
func _apply_lod_level(object, level: int) -> void:
	# 检查对象是否有效
	if not is_instance_valid(object):
		return
	
	# 根据对象类型应用不同的LOD设置
	if object is CPUParticles2D:
		_apply_particle_lod(object, level)
	elif object is AnimatedSprite2D:
		_apply_sprite_lod(object, level)
	elif object is CanvasItem:
		_apply_canvas_item_lod(object, level)

# 应用粒子LOD
func _apply_particle_lod(particle: CPUParticles2D, level: int) -> void:
	match level:
		LODLevel.HIGH:
			# 高质量设置
			particle.visible = true
			particle.amount = particle.get_meta("original_amount", particle.amount)
			particle.speed_scale = 1.0
		LODLevel.MEDIUM:
			# 中等质量设置
			particle.visible = true
			particle.amount = int(particle.get_meta("original_amount", particle.amount) * 0.7)
			particle.speed_scale = 1.0
		LODLevel.LOW:
			# 低质量设置
			particle.visible = true
			particle.amount = int(particle.get_meta("original_amount", particle.amount) * 0.4)
			particle.speed_scale = 1.2
		LODLevel.CULLED:
			# 剔除
			particle.visible = false
			particle.emitting = false

# 应用精灵LOD
func _apply_sprite_lod(sprite: AnimatedSprite2D, level: int) -> void:
	match level:
		LODLevel.HIGH:
			# 高质量设置
			sprite.visible = true
			sprite.speed_scale = 1.0
		LODLevel.MEDIUM:
			# 中等质量设置
			sprite.visible = true
			sprite.speed_scale = 1.0
		LODLevel.LOW:
			# 低质量设置
			sprite.visible = true
			sprite.speed_scale = 0.5  # 降低帧率
		LODLevel.CULLED:
			# 剔除
			sprite.visible = false
			sprite.pause()

# 应用画布项LOD
func _apply_canvas_item_lod(item: CanvasItem, level: int) -> void:
	match level:
		LODLevel.HIGH, LODLevel.MEDIUM, LODLevel.LOW:
			# 可见
			item.visible = true
		LODLevel.CULLED:
			# 剔除
			item.visible = false

# 对象退出场景树回调
func _on_object_tree_exiting(object) -> void:
	# 从跟踪列表移除
	remove_object(object)
