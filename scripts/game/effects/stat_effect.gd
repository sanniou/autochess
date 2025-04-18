extends BaseEffect
class_name StatEffect
## 属性效果类
## 修改目标的属性

# 属性映射
var stats: Dictionary = {}  # 属性名称 -> 属性值

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_stats: Dictionary = {}, p_source = null,
		p_target = null, p_is_debuff: bool = false) -> void:
	super._init(p_id, BaseEffect.EffectType.STAT, p_name, p_description,
			p_duration, 0.0, p_source, p_target, p_is_debuff)
	stats = p_stats

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target):
		return

	# 应用属性修改
	for stat_name in stats:
		var stat_value = stats[stat_name]
		_apply_stat_change(stat_name, stat_value)

	# 创建视觉效果
	_create_visual_effect()

	# 播放音效
	play_sound_effect()

	# 发送效果应用信号
	var effect_type = "debuff" if is_debuff else "buff"
	EventBus.battle.emit_event("ability_effect_applied", [source, target, effect_type, value])

# 移除效果
func remove() -> void:
	if not target or not is_instance_valid(target):
		return

	# 移除属性修改
	for stat_name in stats:
		var stat_value = stats[stat_name]
		_apply_stat_change(stat_name, -stat_value)

# 应用属性变化
func _apply_stat_change(stat_name: String, stat_value: float) -> void:
	# 根据属性名称应用变化
	if not target or not is_instance_valid(target):
		return

	match stat_name:
		"attack_damage":
			target.attack_damage += stat_value
		"attack_speed":
			target.attack_speed += stat_value
		"armor":
			target.armor += stat_value
		"magic_resist":
			target.magic_resist += stat_value
		"move_speed":
			target.move_speed += stat_value
		"max_health":
			target.max_health += stat_value
			# 如果增加最大生命值，同时增加当前生命值
			if stat_value > 0:
				target.current_health += stat_value
		"spell_power":
			target.spell_power += stat_value
		"crit_chance":
			target.crit_chance += stat_value
		"crit_damage":
			target.crit_damage += stat_value
		"dodge_chance":
			target.dodge_chance += stat_value
		"control_resistance":
			target.control_resistance += stat_value

# 创建视觉效果
func _create_visual_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 获取特效管理器
	var game_manager = target.get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"id": id + "_visual",
		"name": name + "特效",
		"description": "显示" + name + "特效",
		"visual_type": VisualEffect.VisualType.PARTICLE,
		"is_debuff": is_debuff,
		"buff_type": "buff",
		"debuff_type": "debuff",
		"duration": duration
	}

	# 使用 BaseEffect.create 创建视觉效果
	BaseEffect.create(BaseEffect.EffectType.VISUAL, params, source, target)

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["stats"] = stats
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> StatEffect:
	return StatEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("stats", {}),
		source,
		target,
		data.get("is_debuff", false)
	)
