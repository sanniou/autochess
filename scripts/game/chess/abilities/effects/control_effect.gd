extends AbilityEffect
class_name ControlEffect
## 控制效果
## 控制目标行为

# 控制类型
var control_type: String = "stun"  # 控制类型(stun/silence/disarm/root/taunt)

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 检查控制抗性
	var resist_chance = target.control_resistance
	if randf() < resist_chance:
		# 目标抵抗了控制效果
		_play_resist_effect()

		# 发送效果抵抗信号
		var effect_id = "control_" + control_type
		EventBus.status_effect_resisted.emit(target, effect_id)
		return

	# 创建效果数据
	var effect_id = "control_" + control_type
	var effect_data = {
		"id": effect_id,
		"duration": duration,
		"source": source,
		"name": "",
		"is_debuff": true
	}

	# 根据控制类型应用效果
	match control_type:
		"stun":
			# 眩晕效果
			target.status_effect_manager.add_stun_effect(duration, source)
			effect_data.name = "眩晕"
		"silence":
			# 沉默效果
			target.status_effect_manager.add_silence_effect(duration, source)
			effect_data.name = "沉默"
		"disarm":
			# 缴械效果
			target.status_effect_manager.add_disarm_effect(duration, source)
			effect_data.name = "缴械"
		"root":
			# 定身效果
			target.status_effect_manager.add_root_effect(duration, source)
			effect_data.name = "定身"
		"taunt":
			# 嘲讽效果
			if source:
				target.status_effect_manager.add_taunt_effect(duration, source)
				effect_data.name = "嘲讽"

	# 发送效果应用信号
	EventBus.ability_effect_applied.emit(source, target, "control", control_type)

	# 发送状态效果添加信号
	EventBus.status_effect_added.emit(target, effect_id, effect_data)

	# 播放控制特效
	_play_control_effect()

# 播放控制特效
func _play_control_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()

	# 根据控制类型设置颜色
	match control_type:
		"stun":
			effect.color = Color(0.8, 0.8, 0.0, 0.5)  # 黄色
		"silence":
			effect.color = Color(0.0, 0.0, 0.8, 0.5)  # 蓝色
		"disarm":
			effect.color = Color(0.8, 0.4, 0.0, 0.5)  # 橙色
		"root":
			effect.color = Color(0.0, 0.8, 0.0, 0.5)  # 绿色
		"taunt":
			effect.color = Color(0.8, 0.0, 0.0, 0.5)  # 红色
		_:
			effect.color = Color(0.8, 0.8, 0.0, 0.5)  # 默认黄色

	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)

# 播放抵抗特效
func _play_resist_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.8, 0.8, 0.5)  # 灰色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)

	# 创建抵抗文本
	var resist_label = Label.new()
	resist_label.text = "抵抗!"
	resist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resist_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resist_label.position = Vector2(-20, -40)
	resist_label.size = Vector2(40, 20)

	# 添加到目标
	target.add_child(resist_label)

	# 创建消失动画
	var label_tween = target.create_tween()
	label_tween.tween_property(resist_label, "position", Vector2(-20, -60), 0.5)
	label_tween.parallel().tween_property(resist_label, "modulate", Color(1, 1, 1, 0), 0.5)
	label_tween.tween_callback(resist_label.queue_free)
