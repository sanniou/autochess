extends AbilityEffect
class_name HealEffect
## 治疗效果
## 治疗目标

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 计算治疗量
	var heal_amount = value

	# 应用法术强度加成
	if source:
		heal_amount += source.spell_power

	# 治疗目标
	var final_heal = target.heal(heal_amount, source)

	# 发送效果应用信号
	EventBus.battle.ability_effect_applied.emit(source, target, "heal", final_heal)

	# 发送治疗信号
	EventBus.battle.heal_received.emit(target, final_heal, source)

	# 播放治疗特效
	_play_heal_effect()

# 播放治疗特效
func _play_heal_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.0, 0.8, 0.0, 0.5)  # 绿色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)
