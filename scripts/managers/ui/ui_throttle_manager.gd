extends "res://scripts/managers/core/base_manager.gd"
class_name UIThrottleManager
## UI节流管理器
## 负责管理UI更新频率，减少不必要的重绘，提高UI响应速度

# 节流器字典
var _throttlers: Dictionary = {}

# 全局节流配置
var global_config = {
	"enabled": true,           # 是否启用节流
	"default_interval": 0.1,   # 默认更新间隔（秒）
	"high_fps_interval": 0.2,  # 高帧率时的更新间隔
	"low_fps_interval": 0.05,  # 低帧率时的更新间隔
	"fps_threshold": 40,       # 帧率阈值
	"adaptive": true           # 是否启用自适应间隔
}

# 当前帧率
var _current_fps = 60

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "UIThrottleManager"

	# 添加依赖
	add_dependency("UIManager")

	# 连接信号
	GlobalEventBus.ui.add_class_listener(UIEvents.RegisterUIThrottlerEvent, _on_register_ui_throttler)
	GlobalEventBus.ui.add_class_listener(UIEvents.UnregisterUIThrottlerEvent, _on_unregister_ui_throttler)
	GlobalEventBus.ui.add_class_listener(UIEvents.ForceUIUpdateEvent, _on_force_ui_update)

	# 更新帧率
	_update_fps()

static var fps_timer = 0.0

# 进程函数
func _process(_delta: float) -> void:
	# 每秒更新一次帧率
	fps_timer += _delta

	if fps_timer >= 1.0:
		fps_timer = 0.0
		_update_fps()

# 更新帧率
func _update_fps() -> void:
	_current_fps = Engine.get_frames_per_second()

# 获取节流器
func get_throttler(id: String) -> UIThrottler:
	if not _throttlers.has(id):
		# 创建新的节流器
		var throttler = UIThrottler.new(global_config)
		_throttlers[id] = throttler

	return _throttlers[id]

# 检查是否应该更新
func should_update(ui_id: String, component_id: String, delta: float, custom_interval: float = -1) -> bool:
	var throttler = get_throttler(ui_id)
	return throttler.should_update(component_id, delta, custom_interval)

# 强制更新
func force_update(ui_id: String, component_id: String = "") -> void:
	if _throttlers.has(ui_id):
		var throttler = _throttlers[ui_id]

		if component_id.is_empty():
			# 强制更新所有组件
			throttler.reset_all()
		else:
			# 强制更新指定组件
			throttler.force_update(component_id)

# 注册UI节流器事件处理
func _on_register_ui_throttler(event: UIEvents.RegisterUIThrottlerEvent) -> void:
	var throttler = UIThrottler.new(global_config if event.data.is_empty() else event.data)
	_throttlers[event.type] = throttler

# 注销UI节流器事件处理
func _on_unregister_ui_throttler(event: UIEvents.UnregisterUIThrottlerEvent) -> void:
	if _throttlers.has(event.ui_id):
		_throttlers.erase(event.ui_id)

# 强制UI更新事件处理
func _on_force_ui_update(event: UIEvents.ForceUIUpdateEvent) -> void:
	force_update(event.ui_id, event.component_id)

# 设置全局配置
func set_global_config(config: Dictionary) -> void:
	for key in config:
		if global_config.has(key):
			global_config[key] = config[key]

	# 更新所有节流器的配置
	for throttler in _throttlers.values():
		throttler.set_config("enabled", global_config.enabled)
		throttler.set_config("adaptive", global_config.adaptive)
		throttler.set_config("default_interval", global_config.default_interval)
		throttler.set_config("high_fps_interval", global_config.high_fps_interval)
		throttler.set_config("low_fps_interval", global_config.low_fps_interval)
		throttler.set_config("fps_threshold", global_config.fps_threshold)

# 启用/禁用节流
func set_throttling_enabled(enabled: bool) -> void:
	global_config.enabled = enabled

	# 更新所有节流器
	for throttler in _throttlers.values():
		throttler.set_config("enabled", enabled)

# 获取当前帧率
func get_current_fps() -> int:
	return _current_fps
