extends Control
## 黑市商店特效
## 为黑市商店提供特殊的视觉效果

# 变量
var flicker_intensity: float = 0.05
var overlay_tween: Tween = null

# 节点引用
@onready var background_overlay = $BackgroundOverlay
@onready var smoke_particles = $SmokeParticles
@onready var flicker_timer = $FlickerTimer

# 初始化
func _ready():
	# 设置初始状态
	background_overlay.modulate = Color(1, 1, 1, 0.7)
	
	# 开始背景动画
	_start_background_animation()

# 开始背景动画
func _start_background_animation():
	# 停止之前的动画
	if overlay_tween:
		overlay_tween.kill()
	
	# 创建新的动画
	overlay_tween = create_tween()
	overlay_tween.set_loops()
	overlay_tween.set_trans(Tween.TRANS_SINE)
	overlay_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 设置背景动画
	overlay_tween.tween_property(background_overlay, "modulate", Color(1, 1, 1, 0.5), 2.0)
	overlay_tween.tween_property(background_overlay, "modulate", Color(1, 1, 1, 0.7), 2.0)

# 闪烁效果
func _on_flicker_timer_timeout():
	# 随机调整背景透明度，模拟灯光闪烁
	var random_alpha = randf_range(-flicker_intensity, flicker_intensity)
	var current_alpha = background_overlay.modulate.a
	background_overlay.modulate.a = clamp(current_alpha + random_alpha, 0.4, 0.8)
	
	# 随机调整粒子发射速率
	smoke_particles.speed_scale = randf_range(0.4, 0.6)
	
	# 随机调整闪烁计时器间隔
	flicker_timer.wait_time = randf_range(0.05, 0.2)
