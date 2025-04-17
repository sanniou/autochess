extends AbilityEffect
class_name DebuffEffect
## 减益效果
## 为目标提供减益效果

# 减益类型
var debuff_type: String = "attack"  # 减益类型(attack/defense/speed/health)

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 创建效果数据
	var effect_id = "debuff_" + str(source.get_instance_id()) if source else "debuff_" + str(randi())
	var effect_data = {
		"id": effect_id,
		"duration": duration,
		"stats": {},
		"name": debuff_type.capitalize() + " Debuff",
		"is_debuff": true
	}

	# 根据减益类型设置效果
	match debuff_type:
		"attack":
			effect_data.stats["attack_damage"] = -value
			effect_data.name = "攻击减益"
		"defense":
			effect_data.stats["armor"] = -value
			effect_data.stats["magic_resist"] = -value
			effect_data.name = "防御减益"
		"speed":
			effect_data.stats["attack_speed"] = -value
			effect_data.stats["move_speed"] = -value
			effect_data.name = "速度减益"
		"health":
			effect_data.stats["max_health"] = -value
			effect_data.name = "生命减益"
			# 如果当前生命值超过最大生命值，减少当前生命值
			if target.current_health > target.max_health - value:
				target.current_health = target.max_health - value
		"spell_power":
			effect_data.stats["spell_power"] = -value
			effect_data.name = "法术减益"
		"crit":
			effect_data.stats["crit_chance"] = -value
			effect_data.stats["crit_damage"] = -value * 0.5
			effect_data.name = "暴击减益"

	# 应用效果
	target.add_effect(effect_data)

	# 发送效果应用信号
	EventBus.battle.ability_effect_applied.emit(source, target, "debuff", value)

	# 播放减益特效
	_play_debuff_effect()

# 播放减益特效
func _play_debuff_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.0, 0.0, 0.5)  # 红色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)
