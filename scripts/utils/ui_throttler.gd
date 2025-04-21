extends RefCounted
class_name UIThrottler
## UI更新节流工具
## 用于控制UI更新频率，减少不必要的重绘

# 节流配置
var config = {
	"enabled": true,           # 是否启用节流
	"default_interval": 0.1,   # 默认更新间隔（秒）
	"high_fps_interval": 0.2,  # 高帧率时的更新间隔
	"low_fps_interval": 0.05,  # 低帧率时的更新间隔
	"fps_threshold": 40,       # 帧率阈值
	"adaptive": true           # 是否启用自适应间隔
}

# 计时器字典
var _timers = {}

# 上次更新时间字典
var _last_update_times = {}

# 当前帧率
var _current_fps = 60

## 初始化节流器
func _init(custom_config: Dictionary = {}) -> void:
	# 合并自定义配置
	for key in custom_config:
		if config.has(key):
			config[key] = custom_config[key]
	
	# 获取当前帧率
	_update_fps()

## 更新帧率
func _update_fps() -> void:
	_current_fps = Engine.get_frames_per_second()

## 检查是否应该更新
## 返回true表示应该更新，false表示应该跳过
func should_update(id: String, delta: float, custom_interval: float = -1) -> bool:
	if not config.enabled:
		return true
	
	# 更新帧率
	_update_fps()
	
	# 初始化计时器
	if not _timers.has(id):
		_timers[id] = 0.0
		_last_update_times[id] = Time.get_ticks_msec()
		return true
	
	# 更新计时器
	_timers[id] += delta
	
	# 确定更新间隔
	var interval = custom_interval
	if interval < 0:
		if config.adaptive:
			# 自适应间隔
			if _current_fps < config.fps_threshold:
				interval = config.low_fps_interval
			else:
				interval = config.high_fps_interval
		else:
			interval = config.default_interval
	
	# 检查是否达到更新间隔
	if _timers[id] >= interval:
		_timers[id] = 0.0
		_last_update_times[id] = Time.get_ticks_msec()
		return true
	
	return false

## 强制更新
func force_update(id: String) -> void:
	_timers[id] = 0.0
	_last_update_times[id] = Time.get_ticks_msec()

## 获取距离上次更新的时间（毫秒）
func get_time_since_last_update(id: String) -> int:
	if not _last_update_times.has(id):
		return 0
	
	return Time.get_ticks_msec() - _last_update_times[id]

## 重置所有计时器
func reset_all() -> void:
	_timers.clear()
	_last_update_times.clear()

## 设置配置
func set_config(key: String, value) -> void:
	if config.has(key):
		config[key] = value
