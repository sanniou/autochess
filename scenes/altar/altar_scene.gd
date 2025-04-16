extends Node
class_name AltarScene
## 祭坛场景
## 玩家可以在此牺牲物品获得特殊效果

# 祭坛类型
var altar_type: String = ""

# 引用
@onready var game_manager = get_node("/root/GameManager")
@onready var ui_manager = game_manager.ui_manager

# 初始化
func _ready() -> void:
	# 获取祭坛参数
	var altar_params = game_manager.altar_params
	if altar_params:
		altar_type = altar_params.get("altar_type", "")
	
	# 连接信号
	EventBus.altar_sacrifice_made.connect(_on_altar_sacrifice_made)
	
	# 播放背景音乐
	AudioManager.play_music("altar_theme.ogg")
	
	# 显示祭坛效果
	_show_altar_effect()

# 显示祭坛效果
func _show_altar_effect() -> void:
	# 根据祭坛类型显示不同的效果
	match altar_type:
		"health":
			# 显示生命祭坛效果
			_show_health_altar_effect()
		"attack":
			# 显示攻击祭坛效果
			_show_attack_altar_effect()
		"defense":
			# 显示防御祭坛效果
			_show_defense_altar_effect()
		"ability":
			# 显示技能祭坛效果
			_show_ability_altar_effect()
		"gold":
			# 显示财富祭坛效果
			_show_gold_altar_effect()

# 显示生命祭坛效果
func _show_health_altar_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(0.0, 1.0, 0.0, 0.8)
	add_child(particles)

# 显示攻击祭坛效果
func _show_attack_altar_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(1.0, 0.0, 0.0, 0.8)
	add_child(particles)

# 显示防御祭坛效果
func _show_defense_altar_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(0.0, 0.0, 1.0, 0.8)
	add_child(particles)

# 显示技能祭坛效果
func _show_ability_altar_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(0.8, 0.0, 0.8, 0.8)
	add_child(particles)

# 显示财富祭坛效果
func _show_gold_altar_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(1.0, 0.8, 0.0, 0.8)
	add_child(particles)

# 祭坛牺牲事件处理
func _on_altar_sacrifice_made(altar_type: String, sacrifice_data: Dictionary) -> void:
	# 播放牺牲音效
	AudioManager.play_sfx("altar_sacrifice.ogg")
	
	# 显示牺牲效果
	_show_sacrifice_effect(sacrifice_data)
	
	# 延迟返回地图
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): game_manager.change_state(GameManager.GameState.MAP))

# 显示牺牲效果
func _show_sacrifice_effect(sacrifice_data: Dictionary) -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 200
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_sphere_radius = 150.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount = 8.0
	
	# 根据物品类型设置颜色
	match sacrifice_data.type:
		"chess":
			particles.color = Color(0.2, 0.8, 0.2, 0.8)
		"equipment":
			particles.color = Color(0.2, 0.6, 1.0, 0.8)
		"spellbook":
			particles.color = Color(0.8, 0.2, 0.8, 0.8)
		"relic":
			particles.color = Color(1.0, 0.8, 0.2, 0.8)
	
	add_child(particles)
	
	# 显示获得效果的文本
	var label = Label.new()
	label.text = "+" + str(sacrifice_data.value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport().size.x / 2 - 50, get_viewport().size.y / 2 - 50)
	label.add_theme_font_size_override("font_size", 48)
	
	# 根据物品类型设置颜色
	match sacrifice_data.type:
		"chess":
			label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		"equipment":
			label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		"spellbook":
			label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.8))
		"relic":
			label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	
	add_child(label)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)
