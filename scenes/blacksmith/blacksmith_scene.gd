extends Node
class_name BlacksmithScene
## 铁匠铺场景
## 玩家可以在此升级、修复、重铸或附魔装备

# 铁匠铺折扣
var discount: float = 0.0

# 引用
@onready var game_manager = get_node("/root/GameManager")
@onready var ui_manager = game_manager.ui_manager

# 初始化
func _ready() -> void:
	# 获取铁匠铺参数
	var blacksmith_params = game_manager.blacksmith_params
	if blacksmith_params:
		discount = blacksmith_params.get("discount", 0.0)

	# 连接信号
	EventBus.equipment_upgraded.connect(_on_equipment_upgraded)

	# 播放背景音乐
	AudioManager.play_music("blacksmith_theme.ogg")

	# 显示铁匠铺效果
	_show_blacksmith_effect()

# 显示铁匠铺效果
func _show_blacksmith_effect() -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 50
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 100.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount = 5.0
	particles.color = Color(1.0, 0.5, 0.0, 0.8)
	add_child(particles)

	# 如果有折扣，显示折扣效果
	if discount > 0:
		_show_discount_effect()

# 显示折扣效果
func _show_discount_effect() -> void:
	# 创建折扣标签
	var label = Label.new()
	label.text = tr("ui.blacksmith.discount").format({"percent": str(int(discount * 100))})
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport().size.x / 2 - 100, 100)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	add_child(label)

	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops(3)
	tween.tween_callback(label.queue_free)

# 装备升级事件处理
func _on_equipment_upgraded(equipment_data: Dictionary, success: bool) -> void:
	if success:
		# 播放成功音效
		AudioManager.play_sfx("blacksmith_success.ogg")

		# 显示成功效果
		_show_success_effect(equipment_data)
	else:
		# 播放失败音效
		AudioManager.play_sfx("blacksmith_fail.ogg")

		# 显示失败效果
		_show_fail_effect(equipment_data)

# 显示成功效果
func _show_success_effect(equipment_data: Dictionary) -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 200
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 150.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount = 8.0
	particles.color = Color(0.2, 0.8, 0.2, 0.8)
	add_child(particles)

	# 显示成功文本
	var label = Label.new()
	label.text = tr("ui.blacksmith.success")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y / 2 - 50)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	add_child(label)

	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

# 显示失败效果
func _show_fail_effect(equipment_data: Dictionary) -> void:
	# 创建粒子效果
	var particles = CPUParticles2D.new()
	particles.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	particles.amount = 100
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 150.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount = 8.0
	particles.color = Color(0.8, 0.2, 0.2, 0.8)
	add_child(particles)

	# 显示失败文本
	var label = Label.new()
	label.text = tr("ui.blacksmith.fail")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y / 2 - 50)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	add_child(label)

	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)
