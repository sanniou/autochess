extends Node2D
class_name BaseEffect
## 基础特效类
## 所有特效的基类

# 特效是否完成
var is_finished: bool = false

# 特效持续时间
var duration: float = 1.0

# 特效计时器
var timer: float = 0.0

# 初始化
func _ready():
	# 默认1秒后自动销毁
	await get_tree().create_timer(duration).timeout
	queue_free()

# 检查特效是否完成
func is_effect_finished() -> bool:
	return is_finished

# 设置特效持续时间
func set_duration(new_duration: float) -> void:
	duration = new_duration

# 播放特效
func play() -> void:
	# 基类不做任何事情，子类应该重写此方法
	pass

# 停止特效
func stop() -> void:
	# 停止所有粒子发射
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = false
	
	# 标记为完成
	is_finished = true
