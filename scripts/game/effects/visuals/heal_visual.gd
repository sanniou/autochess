extends EffectVisual
class_name HealVisual
## 治疗视觉效果
## 显示治疗效果

# 特效节点
@onready var heal_particles: GPUParticles2D = $HealParticles
@onready var glow_particles: GPUParticles2D = $GlowParticles
@onready var number_label: Label = $NumberLabel

# 治疗数值
var heal_amount: float = 0.0

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if heal_particles:
		heal_particles.emitting = false
	
	if glow_particles:
		glow_particles.emitting = false
	
	# 默认隐藏数字标签
	if number_label:
		number_label.visible = false

# 播放特效
func play() -> void:
	play_heal_effect(heal_amount)

# 播放治疗特效
func play_heal_effect(p_heal_amount: float = 0.0) -> void:
	# 保存治疗数值
	heal_amount = p_heal_amount
	
	# 设置粒子颜色
	if heal_particles:
		var material = heal_particles.process_material
		if material:
			material.color = Color(0.0, 0.8, 0.0, 0.8)  # 绿色
		
		heal_particles.emitting = true
	
	if glow_particles:
		var material = glow_particles.process_material
		if material:
			material.color = Color(0.0, 1.0, 0.0, 0.8)  # 亮绿色
		
		glow_particles.emitting = true
	
	# 显示治疗数字
	if number_label:
		number_label.text = "+" + str(int(heal_amount))
		number_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
		number_label.visible = true
		
		# 创建数字动画
		var tween = create_tween()
		tween.tween_property(number_label, "position:y", number_label.position.y - 30, 0.5)
		tween.parallel().tween_property(number_label, "modulate:a", 0.0, 0.5)
	
	# 设置特效持续时间
	var max_lifetime = 0.0
	if heal_particles:
		max_lifetime = max(max_lifetime, heal_particles.lifetime)
	if glow_particles:
		max_lifetime = max(max_lifetime, glow_particles.lifetime)
	
	set_duration(max_lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	super._process(delta)
	
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if heal_particles and heal_particles.emitting:
		all_finished = false
	
	if glow_particles and glow_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
