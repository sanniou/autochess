extends Node2D
## 伤害数字
## 显示战斗中的伤害、治疗、经验值等数字

# 动画持续时间
const ANIMATION_DURATION = 1.0

# 移动距离
const MOVE_DISTANCE = 50.0

# 初始化
func _ready():
	# 开始动画
	_start_animation()

# 设置伤害
func set_damage(amount: float, damage_type: String = "physical", is_critical: bool = false) -> void:
	# 获取伤害管理器
	var damage_manager = get_node_or_null("/root/GameManager/DamageNumberManager")
	
	# 设置伤害文本
	var damage_text = str(int(amount))
	$Label.text = damage_text
	
	# 设置伤害颜色
	if damage_manager:
		$Label.add_theme_color_override("font_color", damage_manager.get_damage_color(damage_type))
	else:
		# 默认颜色
		match damage_type:
			"physical": $Label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			"magical": $Label.add_theme_color_override("font_color", Color(0.5, 0.3, 1.0))
			"fire": $Label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
			"ice": $Label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
			"lightning": $Label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
			"poison": $Label.add_theme_color_override("font_color", Color(0.0, 0.8, 0.0))
			"true": $Label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			"heal": $Label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	
	# 如果是暴击，增大字体并添加暴击标记
	if is_critical:
		$Label.add_theme_font_size_override("font_size", 32)
		$Label.text = damage_text + "!"

# 设置经验值
func set_exp(amount: float) -> void:
	# 设置经验值文本
	$Label.text = "+" + str(int(amount)) + " EXP"
	
	# 设置经验值颜色
	$Label.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))

# 设置金币
func set_gold(amount: float) -> void:
	# 设置金币文本
	$Label.text = "+" + str(int(amount)) + " 金币"
	
	# 设置金币颜色
	$Label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))

# 设置状态文本
func set_status(text: String, color: Color = Color.WHITE) -> void:
	# 设置状态文本
	$Label.text = text
	
	# 设置状态颜色
	$Label.add_theme_color_override("font_color", color)

# 开始动画
func _start_animation() -> void:
	# 创建动画序列
	var tween = create_tween()
	
	# 设置初始状态
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)
	
	# 淡入动画
	tween.tween_property(self, "modulate:a", 1.0, ANIMATION_DURATION * 0.2)
	
	# 缩放动画
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), ANIMATION_DURATION * 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 上移动画
	tween.parallel().tween_property(self, "position:y", position.y - MOVE_DISTANCE, ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# 淡出动画
	tween.tween_property(self, "modulate:a", 0.0, ANIMATION_DURATION * 0.3).set_delay(ANIMATION_DURATION * 0.7)
	
	# 动画完成后移除
	tween.tween_callback(queue_free)
