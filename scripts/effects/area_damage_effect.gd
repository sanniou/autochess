extends BaseEffect
class_name AreaDamageEffect
## 区域伤害特效
## 显示区域伤害效果

# 特效节点
@onready var explosion_particles: GPUParticles2D = $ExplosionParticles
@onready var wave_particles: GPUParticles2D = $WaveParticles
@onready var impact_particles: GPUParticles2D = $ImpactParticles

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if explosion_particles:
		explosion_particles.emitting = false
	
	if wave_particles:
		wave_particles.emitting = false
		
	if impact_particles:
		impact_particles.emitting = false

# 播放区域伤害特效
func play_area_damage_effect(color: Color = Color(0.8, 0.2, 0.2, 0.8), radius: float = 100.0) -> void:
	# 设置粒子颜色
	if explosion_particles:
		var material = explosion_particles.process_material
		if material:
			material.color = color
		
		# 调整粒子发射区域
		material.emission_sphere_radius = radius * 0.5
		explosion_particles.emitting = true
	
	if wave_particles:
		var material = wave_particles.process_material
		if material:
			material.color = color.lightened(0.2)
		
		# 调整粒子大小
		wave_particles.scale = Vector2(radius / 100.0, radius / 100.0)
		wave_particles.emitting = true
		
	if impact_particles:
		var material = impact_particles.process_material
		if material:
			material.color = color.darkened(0.2)
			
		# 调整粒子发射区域
		material.emission_sphere_radius = radius * 0.8
		impact_particles.emitting = true
	
	# 设置特效持续时间
	var max_lifetime = 0.0
	if explosion_particles:
		max_lifetime = max(max_lifetime, explosion_particles.lifetime)
	if wave_particles:
		max_lifetime = max(max_lifetime, wave_particles.lifetime)
	if impact_particles:
		max_lifetime = max(max_lifetime, impact_particles.lifetime)
	
	set_duration(max_lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if explosion_particles and explosion_particles.emitting:
		all_finished = false
	
	if wave_particles and wave_particles.emitting:
		all_finished = false
		
	if impact_particles and impact_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
