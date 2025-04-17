extends AbilityEffect
class_name BuffEffect
## 增益效果
## 为目标提供增益效果

# 增益类型
var buff_type: String = "attack"  # 增益类型(attack/defense/speed/health)

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 创建效果数据
	var effect_id = "buff_" + str(source.get_instance_id()) if source else "buff_" + str(randi())
	var effect_data = {
		"id": effect_id,
		"duration": duration,
		"stats": {},
		"name": buff_type.capitalize() + " Buff",
		"is_debuff": false
	}

	# 根据增益类型设置效果
	match buff_type:
		"attack":
			effect_data.stats["attack_damage"] = value
			effect_data.name = "攻击增益"
		"defense":
			effect_data.stats["armor"] = value
			effect_data.stats["magic_resist"] = value
			effect_data.name = "防御增益"
		"speed":
			effect_data.stats["attack_speed"] = value
			effect_data.stats["move_speed"] = value
			effect_data.name = "速度增益"
		"health":
			effect_data.stats["max_health"] = value
			effect_data.name = "生命增益"
			# 同时增加当前生命值
			var heal_amount = target.heal(value, source)
			# 发送治疗信号
			EventBus.battle.emit_event("heal_received", [target, heal_amount, source])
		"spell_power":
			effect_data.stats["spell_power"] = value
			effect_data.name = "法术增益"
		"crit":
			effect_data.stats["crit_chance"] = value
			effect_data.stats["crit_damage"] = value * 0.5
			effect_data.name = "暴击增益"

	# 应用效果
	target.add_effect(effect_data)

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "buff", value])

	# 播放增益特效
	_play_buff_effect()

# 播放增益特效
func _play_buff_effect() -> void:
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
