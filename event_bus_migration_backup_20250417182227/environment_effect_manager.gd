extends "res://scripts/managers/core/base_manager.gd"2D
class_name EnvironmentEffectManager
## 环境特效管理器
## 负责管理游戏中的环境特效，如天气、环境互动等

# 信号
signal environment_effect_started(effect_id: String, effect_type: String)
signal environment_effect_ended(effect_id: String, effect_type: String)
signal environment_effect_updated(effect_id: String, effect_type: String, params: Dictionary)

# 环境特效类型
enum EffectType {
	WEATHER,    # 天气特效
	AMBIENT,    # 环境氛围特效
	TERRAIN,    # 地形特效
	BACKGROUND, # 背景特效
	FOREGROUND, # 前景特效
	LIGHTING,   # 光照特效
	PARTICLE    # 粒子特效
}

# 活动的环境特效
var active_effects = {}

# 环境特效配置
var effect_configs = {}

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EnvironmentEffectManager"
	
	# 原 _ready 函数的内容
	# 加载环境特效配置
		_load_effect_configs()
	
	# 加载环境特效配置
func _load_effect_configs() -> void:
	# 从配置文件加载环境特效配置
	var config_path = "res://configs/effects/environment_effects.json"
	
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		
		if error == OK:
			effect_configs = json.data
		else:
			EventBus.debug.debug_message.emit("无法解析环境特效配置文件: " + json.get_error_message(), 1)
	else:
		EventBus.debug.debug_message.emit("环境特效配置文件不存在: " + config_path, 1)

# 启动环境特效
func start_effect(effect_type: String, params: Dictionary = {}) -> String:
	# 检查特效类型是否存在
	if not effect_configs.has(effect_type):
		EventBus.debug.debug_message.emit("未知的环境特效类型: " + effect_type, 1)
		return ""
	
	# 获取特效配置
	var config = effect_configs[effect_type]
	
	# 创建特效ID
	var effect_id = _create_effect_id(effect_type)
	
	# 合并默认参数
	var merged_params = config.get("default_params", {}).duplicate()
	for key in params:
		merged_params[key] = params[key]
	
	# 创建特效实例
	var effect_instance = _create_effect_instance(effect_type, merged_params)
	if not effect_instance:
		return ""
	
	# 添加到场景
	add_child(effect_instance)
	
	# 保存特效数据
	var effect_data = {
		"id": effect_id,
		"type": effect_type,
		"instance": effect_instance,
		"params": merged_params,
		"start_time": Time.get_ticks_msec(),
		"duration": merged_params.get("duration", 0)
	}
	
	# 添加到活动特效
	active_effects[effect_id] = effect_data
	
	# 发送特效开始信号
	environment_effect_started.emit(effect_id, effect_type)
	
	# 如果有持续时间，设置定时器
	if effect_data.duration > 0:
		var timer = get_tree().create_timer(effect_data.duration)
		timer.timeout.connect(func(): stop_effect(effect_id))
	
	return effect_id

# 停止环境特效
func stop_effect(effect_id: String) -> bool:
	# 检查特效ID是否存在
	if not active_effects.has(effect_id):
		return false
	
	# 获取特效数据
	var effect_data = active_effects[effect_id]
	
	# 获取特效实例
	var effect_instance = effect_data.instance
	
	# 如果特效实例有stop方法，调用它
	if effect_instance.has_method("stop"):
		effect_instance.stop()
	else:
		# 否则直接移除
		effect_instance.queue_free()
	
	# 从活动特效中移除
	active_effects.erase(effect_id)
	
	# 发送特效结束信号
	environment_effect_ended.emit(effect_id, effect_data.type)
	
	return true

# 更新环境特效
func update_effect(effect_id: String, params: Dictionary) -> bool:
	# 检查特效ID是否存在
	if not active_effects.has(effect_id):
		return false
	
	# 获取特效数据
	var effect_data = active_effects[effect_id]
	
	# 获取特效实例
	var effect_instance = effect_data.instance
	
	# 更新参数
	for key in params:
		effect_data.params[key] = params[key]
		
		# 如果特效实例有set_param方法，调用它
		if effect_instance.has_method("set_param"):
			effect_instance.set_param(key, params[key])
	
	# 发送特效更新信号
	environment_effect_updated.emit(effect_id, effect_data.type, params)
	
	return true

# 获取活动的环境特效
func get_active_effects() -> Array:
	return active_effects.keys()

# 获取特效数据
func get_effect_data(effect_id: String) -> Dictionary:
	if active_effects.has(effect_id):
		return active_effects[effect_id]
	return {}

# 清除所有环境特效
func clear_all_effects() -> void:
	# 复制活动特效列表，因为我们将在遍历过程中修改它
	var effects_to_clear = active_effects.keys()
	
	# 停止所有特效
	for effect_id in effects_to_clear:
		stop_effect(effect_id)

# 创建特效ID
func _create_effect_id(effect_type: String) -> String:
	# 生成唯一ID
	var timestamp = Time.get_ticks_msec()
	var random_part = randi() % 10000
	
	# 组合ID
	return "env_" + effect_type + "_" + str(timestamp) + "_" + str(random_part)

# 创建特效实例
func _create_effect_instance(effect_type: String, params: Dictionary) -> Node:
	# 获取特效配置
	var config = effect_configs[effect_type]
	
	# 获取特效场景路径
	var scene_path = config.get("scene_path", "")
	
	# 如果没有场景路径，尝试使用脚本路径
	if scene_path.is_empty():
		var script_path = config.get("script_path", "")
		if script_path.is_empty():
			EventBus.debug.debug_message.emit("环境特效没有场景或脚本路径: " + effect_type, 1)
			return null
		
		# 加载脚本
		var script = load(script_path)
		if not script:
			EventBus.debug.debug_message.emit("无法加载环境特效脚本: " + script_path, 1)
			return null
		
		# 创建实例
		var instance = Node2D.new()
		instance.set_script(script)
		
		# 初始化参数
		if instance.has_method("initialize"):
			instance.initialize(params)
		
		return instance
	
	# 加载场景
	var scene = load(scene_path)
	if not scene:
		EventBus.debug.debug_message.emit("无法加载环境特效场景: " + scene_path, 1)
		return null
	
	# 实例化场景
	var instance = scene.instantiate()
	
	# 初始化参数
	if instance.has_method("initialize"):
		instance.initialize(params)
	
	return instance

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.debug_message.emit(error_message, 2)
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.debug_message.emit(info_message, 0)
