extends AbilityEffect
class_name DamageEffect
## 伤害效果
## 对目标造成伤害

# 伤害类型
var damage_type: String = "magical"  # 伤害类型(physical/magical/true)

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 计算伤害
	var actual_damage = value

	# 应用法术强度加成
	if damage_type == "magical" and source:
		actual_damage += source.spell_power

	# 造成伤害
	var final_damage = target.take_damage(actual_damage, damage_type, source)

	# 发送效果应用信号
	EventBus.ability_effect_applied.emit(source, target, "damage", final_damage)

	# 播放伤害特效
	_play_damage_effect()

# 播放伤害特效
func _play_damage_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()

	# 根据伤害类型设置颜色
	match damage_type:
		"physical":
			effect.color = Color(0.8, 0.2, 0.2, 0.5)  # 红色
		"magical":
			effect.color = Color(0.2, 0.2, 0.8, 0.5)  # 蓝色
		"true":
			effect.color = Color(0.8, 0.8, 0.2, 0.5)  # 黄色
		"fire":
			effect.color = Color(0.8, 0.4, 0.0, 0.5)  # 橙色
		"ice":
			effect.color = Color(0.0, 0.8, 0.8, 0.5)  # 青色
		"lightning":
			effect.color = Color(0.8, 0.8, 0.0, 0.5)  # 黄色
		"poison":
			effect.color = Color(0.0, 0.8, 0.0, 0.5)  # 绿色
		_:
			effect.color = Color(0.8, 0.2, 0.2, 0.5)  # 默认红色

	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)

	# 检查是否是暴击
	var is_crit = false
	if source and source.has_meta("last_attack_was_crit"):
		is_crit = source.get_meta("last_attack_was_crit")
