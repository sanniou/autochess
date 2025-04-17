extends BaseEffect
class_name SummonEffect
## 召唤特效
## 显示召唤效果

# 特效节点
@onready var summon_particles: GPUParticles2D = $SummonParticles
@onready var glow_particles: GPUParticles2D = $GlowParticles
@onready var circle_particles: GPUParticles2D = $CircleParticles

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if summon_particles:
		summon_particles.emitting = false
	
	if glow_particles:
		glow_particles.emitting = false
		
	if circle_particles:
		circle_particles.emitting = false

# 播放召唤特效
func play_summon_effect(color: Color = Color(0.2, 0.8, 0.2, 0.8)) -> void:
	# 设置粒子颜色
	if summon_particles:
		var material = summon_particles.process_material
		if material:
			material.color = color
		
		summon_particles.emitting = true
	
	if glow_particles:
		var material = glow_particles.process_material
		if material:
			material.color = color.lightened(0.3)
		
		glow_particles.emitting = true
		
	if circle_particles:
		var material = circle_particles.process_material
		if material:
			material.color = color.darkened(0.2)
			
		circle_particles.emitting = true
	
	# 设置特效持续时间
	var max_lifetime = 0.0
	if summon_particles:
		max_lifetime = max(max_lifetime, summon_particles.lifetime)
	if glow_particles:
		max_lifetime = max(max_lifetime, glow_particles.lifetime)
	if circle_particles:
		max_lifetime = max(max_lifetime, circle_particles.lifetime)
	
	set_duration(max_lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if summon_particles and summon_particles.emitting:
		all_finished = false
	
	if glow_particles and glow_particles.emitting:
		all_finished = false
		
	if circle_particles and circle_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
