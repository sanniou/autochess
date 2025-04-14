extends Node
## 对象池
## 用于管理和重用游戏对象，提高性能

# 对象池
var _pools = {}

# 对象池配置
var _pool_configs = {}

# 对象池状态
var _pool_stats = {}

## 创建对象池
func create_pool(pool_name: String, object_scene: PackedScene, initial_size: int = 0, grow_size: int = 5, max_size: int = 100) -> void:
	if _pools.has(pool_name):
		push_error("对象池已存在: " + pool_name)
		return
	
	# 创建新池
	_pools[pool_name] = []
	
	# 保存配置
	_pool_configs[pool_name] = {
		"scene": object_scene,
		"grow_size": grow_size,
		"max_size": max_size
	}
	
	# 初始化统计信息
	_pool_stats[pool_name] = {
		"created": 0,
		"active": 0,
		"peak": 0
	}
	
	# 预创建对象
	if initial_size > 0:
		_grow_pool(pool_name, initial_size)

## 从池中获取对象
func get_object(pool_name: String) -> Node:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return null
	
	# 查找可用对象
	for obj in _pools[pool_name]:
		if not obj.is_inside_tree():
			_pool_stats[pool_name].active += 1
			if _pool_stats[pool_name].active > _pool_stats[pool_name].peak:
				_pool_stats[pool_name].peak = _pool_stats[pool_name].active
			
			# 重置对象状态
			if obj.has_method("reset"):
				obj.reset()
			
			return obj
	
	# 如果没有可用对象，尝试增长池
	var config = _pool_configs[pool_name]
	if _pools[pool_name].size() < config.max_size:
		_grow_pool(pool_name, config.grow_size)
		return get_object(pool_name)
	
	# 如果池已满，返回null
	push_warning("对象池已满: " + pool_name)
	return null

## 释放对象回池
func release_object(pool_name: String, obj: Node) -> void:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return
	
	if not _pools[pool_name].has(obj):
		push_error("对象不属于此池: " + pool_name)
		return
	
	# 如果对象在场景树中，移除它
	if obj.is_inside_tree():
		obj.get_parent().remove_child(obj)
	
	_pool_stats[pool_name].active -= 1

## 清空对象池
func clear_pool(pool_name: String) -> void:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return
	
	# 销毁所有对象
	for obj in _pools[pool_name]:
		if obj.is_inside_tree():
			obj.get_parent().remove_child(obj)
		obj.queue_free()
	
	_pools[pool_name].clear()
	_pool_stats[pool_name].created = 0
	_pool_stats[pool_name].active = 0
	_pool_stats[pool_name].peak = 0

## 获取对象池统计信息
func get_pool_stats(pool_name: String = "") -> Dictionary:
	if pool_name == "":
		return _pool_stats
	
	if not _pool_stats.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return {}
	
	return _pool_stats[pool_name]

## 增长对象池
func _grow_pool(pool_name: String, count: int) -> void:
	var config = _pool_configs[pool_name]
	var scene = config.scene
	
	for i in range(count):
		if _pools[pool_name].size() >= config.max_size:
			break
		
		var obj = scene.instantiate()
		_pools[pool_name].append(obj)
		_pool_stats[pool_name].created += 1
		
		# 如果对象有初始化方法，调用它
		if obj.has_method("init_pooled"):
			obj.init_pooled()
	
	EventBus.debug_message.emit("对象池 " + pool_name + " 增长了 " + str(count) + " 个对象", 0)
