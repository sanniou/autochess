extends BaseEffect
class_name TeleportEffect
## 传送特效
## 包含消失和出现特效

# 特效节点
@onready var disappear_particles: GPUParticles2D = $DisappearParticles
@onready var appear_particles: GPUParticles2D = $AppearParticles
@onready var damage_particles: GPUParticles2D = $DamageParticles

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if disappear_particles:
		disappear_particles.emitting = false
	
	if appear_particles:
		appear_particles.emitting = false
	
	if damage_particles:
		damage_particles.emitting = false

# 播放消失特效
func play_disappear_effect() -> void:
	if disappear_particles:
		disappear_particles.emitting = true
		
		# 设置特效持续时间
		set_duration(disappear_particles.lifetime * 1.5)

# 播放出现特效
func play_appear_effect() -> void:
	if appear_particles:
		appear_particles.emitting = true
		
		# 设置特效持续时间
		set_duration(appear_particles.lifetime * 1.5)

# 播放伤害特效
func play_damage_effect(color: Color = Color(0.8, 0.2, 0.8, 0.8)) -> void:
	if damage_particles:
		# 设置粒子颜色
		var material = damage_particles.process_material
		if material:
			material.color = color
		
		damage_particles.emitting = true
		
		# 设置特效持续时间
		set_duration(damage_particles.lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if disappear_particles and disappear_particles.emitting:
		all_finished = false
	
	if appear_particles and appear_particles.emitting:
		all_finished = false
	
	if damage_particles and damage_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
