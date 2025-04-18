extends EffectVisual
class_name BuffVisual
## 增益视觉效果
## 显示增益效果

# 特效节点
@onready var buff_particles: GPUParticles2D = $BuffParticles
@onready var glow_particles: GPUParticles2D = $GlowParticles

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if buff_particles:
		buff_particles.emitting = false
	
	if glow_particles:
		glow_particles.emitting = false

# 播放buff特效
func play() -> void:
	play_buff_effect(effect_color)

# 播放buff特效
func play_buff_effect(color: Color = Color(0.0, 0.8, 0.8, 0.8)) -> void:
	# 设置粒子颜色
	if buff_particles:
		var material = buff_particles.process_material
		if material:
			material.color = color
		
		buff_particles.emitting = true
	
	if glow_particles:
		var material = glow_particles.process_material
		if material:
			material.color = color.lightened(0.3)
		
		glow_particles.emitting = true
	
	# 设置特效持续时间
	var max_lifetime = 0.0
	if buff_particles:
		max_lifetime = max(max_lifetime, buff_particles.lifetime)
	if glow_particles:
		max_lifetime = max(max_lifetime, glow_particles.lifetime)
	
	set_duration(max_lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	super._process(delta)
	
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if buff_particles and buff_particles.emitting:
		all_finished = false
	
	if glow_particles and glow_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
