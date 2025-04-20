extends BaseEffect
class_name HealEffect
## 治疗效果类
## 治疗目标

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_heal_value: float = 0.0, p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.HEAL, p_name, p_description,
			0.0, p_heal_value, p_source, p_target, false)  # 治疗效果默认为增益

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 计算治疗量
	var heal_amount = value

	# 应用法术强度加成
	if source and is_instance_valid(source):
		heal_amount += source.spell_power

	var final_heal = 0.0

	# 使用战斗管理器应用治疗
	final_heal = GameManager.battle_manager.apply_heal(source, target, heal_amount)

	# 创建视觉效果
	_create_visual_effect(final_heal)

	# 播放音效
	play_sound_effect()

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "heal", final_heal])

# 创建视觉效果
func _create_visual_effect(heal_amount: float) -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建视觉特效参数
	var params = {
		"color": GameManager.effect_manager.get_effect_color("heal"),
		"duration": 1.0,
		"heal_amount": heal_amount
	}

	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(
		GameManager.effect_manager.VisualEffectType.HEAL,
		target,
		params
	)

# 获取效果数据
func get_data() -> Dictionary:
	return super.get_data()

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> HealEffect:
	return HealEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("value", 0.0),
		source,
		target
	)
