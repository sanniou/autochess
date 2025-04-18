extends BaseEffect
class_name DamageEffect
## 伤害效果类
## 对目标造成伤害

# 伤害属性
var damage_type: String = "magical"  # 伤害类型(physical/magical/true/fire/ice/lightning/poison)
var is_critical: bool = false        # 是否暴击
var is_dodgeable: bool = true        # 是否可闪避

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_damage_value: float = 0.0, p_damage_type: String = "magical",
		p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.DAMAGE, p_name, p_description,
			0.0, p_damage_value, p_source, p_target, true)  # 伤害效果默认为减益
	damage_type = p_damage_type

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 计算伤害
	var actual_damage = value

	# 应用法术强度加成
	if damage_type == "magical" and source and is_instance_valid(source):
		actual_damage += source.spell_power

	# 获取战斗管理器
	var game_manager = target.get_node_or_null("/root/GameManager")
	var final_damage = 0.0

	if game_manager and game_manager.battle_manager and game_manager.battle_manager.has_method("apply_damage"):
		# 使用战斗管理器应用伤害
		final_damage = game_manager.battle_manager.apply_damage(source, target, actual_damage, damage_type, is_critical, is_dodgeable)
	else:
		# 直接应用伤害
		final_damage = target.take_damage(actual_damage, damage_type, source)

	# 创建视觉效果
	_create_visual_effect(final_damage)

	# 播放音效
	play_sound_effect()

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "damage", final_damage])

# 创建视觉效果
func _create_visual_effect(damage_amount: float) -> void:
	if not target or not is_instance_valid(target):
		return

	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(damage_type),
		"duration": 1.0,
		"damage_type": damage_type,
		"damage_amount": damage_amount,
		"is_critical": is_critical
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.DAMAGE,
		target,
		params
	)

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["damage_type"] = damage_type
	data["is_critical"] = is_critical
	data["is_dodgeable"] = is_dodgeable
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> DamageEffect:
	var effect = DamageEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("value", 0.0),
		data.get("damage_type", "magical"),
		source,
		target
	)

	effect.is_critical = data.get("is_critical", false)
	effect.is_dodgeable = data.get("is_dodgeable", true)

	return effect
