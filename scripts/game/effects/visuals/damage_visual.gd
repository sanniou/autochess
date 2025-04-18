extends EffectVisual
class_name DamageVisual
## 伤害视觉效果
## 显示伤害效果

# 特效节点
@onready var damage_particles: GPUParticles2D = $DamageParticles
@onready var impact_particles: GPUParticles2D = $ImpactParticles
@onready var number_label: Label = $NumberLabel

# 伤害数值
var damage_amount: float = 0.0

# 是否暴击
var is_critical: bool = false

# 初始化
func _ready():
	super._ready()
	
	# 默认不发射粒子
	if damage_particles:
		damage_particles.emitting = false
	
	if impact_particles:
		impact_particles.emitting = false
	
	# 默认隐藏数字标签
	if number_label:
		number_label.visible = false

# 播放特效
func play() -> void:
	play_damage_effect(effect_color, damage_amount)

# 播放伤害特效
func play_damage_effect(color: Color = Color(0.8, 0.2, 0.2, 0.8), p_damage_amount: float = 0.0) -> void:
	# 保存伤害数值
	damage_amount = p_damage_amount
	
	# 设置粒子颜色
	if damage_particles:
		var material = damage_particles.process_material
		if material:
			material.color = color
		
		damage_particles.emitting = true
	
	if impact_particles:
		var material = impact_particles.process_material
		if material:
			material.color = color
		
		impact_particles.emitting = true
	
	# 显示伤害数字
	if number_label:
		number_label.text = str(int(damage_amount))
		
		# 如果是暴击，设置为红色并放大
		if is_critical:
			number_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
			number_label.add_theme_font_size_override("font_size", 24)
		else:
			number_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			number_label.add_theme_font_size_override("font_size", 16)
		
		number_label.visible = true
		
		# 创建数字动画
		var tween = create_tween()
		tween.tween_property(number_label, "position:y", number_label.position.y - 30, 0.5)
		tween.parallel().tween_property(number_label, "modulate:a", 0.0, 0.5)
	
	# 设置特效持续时间
	var max_lifetime = 0.0
	if damage_particles:
		max_lifetime = max(max_lifetime, damage_particles.lifetime)
	if impact_particles:
		max_lifetime = max(max_lifetime, impact_particles.lifetime)
	
	set_duration(max_lifetime * 1.5)

# 检查特效是否完成
func _process(delta: float) -> void:
	super._process(delta)
	
	# 检查所有粒子是否都已完成
	var all_finished = true
	
	if damage_particles and damage_particles.emitting:
		all_finished = false
	
	if impact_particles and impact_particles.emitting:
		all_finished = false
	
	# 如果所有粒子都已完成，标记特效为完成
	if all_finished and not is_finished:
		is_finished = true
