extends Control
## 神秘商店特效
## 为神秘商店提供特殊的视觉效果

# 变量
var overlay_tween: Tween = null
var star_tween: Tween = null

# 节点引用
@onready var background_overlay = $BackgroundOverlay
@onready var magic_particles = $MagicParticles
@onready var star_particles = $StarParticles
@onready var pulse_timer = $PulseTimer

# 初始化
func _ready():
	# 设置初始状态
	background_overlay.modulate = Color(1, 1, 1, 0.7)
	
	# 开始背景动画
	_start_background_animation()
	
	# 开始星星动画
	_start_star_animation()

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
	overlay_tween.tween_property(background_overlay, "modulate", Color(1, 1, 1, 0.5), 3.0)
	overlay_tween.tween_property(background_overlay, "modulate", Color(1, 1, 1, 0.7), 3.0)

# 开始星星动画
func _start_star_animation():
	# 停止之前的动画
	if star_tween:
		star_tween.kill()
	
	# 创建新的动画
	star_tween = create_tween()
	star_tween.set_loops()
	star_tween.set_trans(Tween.TRANS_SINE)
	star_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 设置星星动画
	star_tween.tween_property(star_particles, "speed_scale", 0.5, 2.0)
	star_tween.tween_property(star_particles, "speed_scale", 0.2, 2.0)

# 脉冲效果
func _on_pulse_timer_timeout():
	# 创建脉冲动画
	var pulse_tween = create_tween()
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_OUT)
	
	# 增加粒子发射速率
	magic_particles.speed_scale = 1.0
	
	# 脉冲动画
	pulse_tween.tween_property(magic_particles, "speed_scale", 0.5, 2.0)
	
	# 随机调整脉冲计时器间隔
	pulse_timer.wait_time = randf_range(2.0, 4.0)
