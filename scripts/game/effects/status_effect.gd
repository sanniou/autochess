extends BaseEffect
class_name StatusEffect
## 状态效果类
## 添加状态效果（眩晕、沉默等）

# 状态类型
enum StatusType {
	STUN,       # 眩晕：无法行动
	SILENCE,    # 沉默：无法施放技能
	DISARM,     # 缴械：无法普通攻击
	ROOT,       # 定身：无法移动
	TAUNT,      # 嘲讽：强制攻击施法者
	FROZEN      # 冰冻：无法移动
}

# 状态属性
var status_type: int = StatusType.STUN  # 状态类型
var is_stackable: bool = false          # 是否可叠加
var stack_count: int = 1                # 叠加层数
var immunity_time: float = 0.5          # 免疫时间(秒)

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_status_type: int = StatusType.STUN,
		p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.STATUS, p_name, p_description,
			p_duration, 0.0, p_source, p_target, true)  # 状态效果默认为减益
	status_type = p_status_type

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 检查控制抗性
	if _check_resistance():
		# 目标抵抗了控制效果
		_play_resist_effect()

		# 发送效果抵抗信号
		EventBus.status_effect.emit_event("status_effect_resisted", [target, id])
		return

	# 根据状态类型应用效果
	match status_type:
		StatusType.STUN:
			# 眩晕效果
			target.change_state(target.ChessState.STUNNED)

		StatusType.SILENCE:
			# 沉默效果
			target.is_silenced = true

		StatusType.DISARM:
			# 缴械效果
			target.is_disarmed = true

		StatusType.ROOT:
			# 定身效果
			target.is_frozen = true

		StatusType.TAUNT:
			# 嘲讽效果
			if source and is_instance_valid(source):
				target.taunted_by = source

		StatusType.FROZEN:
			# 冰冻效果
			target.is_frozen = true
			target.move_speed = 0

	# 创建视觉效果
	_create_visual_effect()

	# 播放音效
	play_sound_effect()

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "control", value])

# 移除效果
func remove() -> void:
	if not target or not is_instance_valid(target):
		return

	# 根据状态类型移除效果
	match status_type:
		StatusType.STUN:
			# 取消眩晕效果
			if target.current_state == target.ChessState.STUNNED:
				target.change_state(target.ChessState.IDLE)

		StatusType.SILENCE:
			# 取消沉默效果
			target.is_silenced = false

		StatusType.DISARM:
			# 取消缴械效果
			target.is_disarmed = false

		StatusType.ROOT:
			# 取消定身效果
			target.is_frozen = false

		StatusType.TAUNT:
			# 取消嘲讽效果
			target.taunted_by = null

		StatusType.FROZEN:
			# 取消冰冻效果
			target.is_frozen = false
			target.move_speed = target.base_move_speed

# 检查抗性
func _check_resistance() -> bool:
	if not target or not is_instance_valid(target):
		return false

	# 获取控制抗性
	var resist_chance = target.control_resistance

	# 根据状态类型调整抗性
	match status_type:
		StatusType.STUN:
			# 眩晕效果更难抵抗
			resist_chance *= 0.8
		StatusType.SILENCE:
			# 沉默效果正常抵抗
			resist_chance *= 1.0
		StatusType.DISARM:
			# 缴械效果正常抵抗
			resist_chance *= 1.0
		StatusType.ROOT:
			# 定身效果更容易抵抗
			resist_chance *= 1.2
		StatusType.FROZEN:
			# 冰冻效果更难抵抗
			resist_chance *= 0.9

	# 检查是否抵抗成功
	return randf() < resist_chance

# 播放抵抗效果
func _play_resist_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建抵抗效果
	var resist_text = Label.new()
	resist_text.text = "抵抗"
	resist_text.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	resist_text.position = Vector2(-20, -50)

	# 添加到目标
	target.add_child(resist_text)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(resist_text, "position", Vector2(-20, -70), 0.5)
	tween.parallel().tween_property(resist_text, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(resist_text.queue_free)

# 创建视觉效果
func _create_visual_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 根据状态类型选择特效类型和颜色
	var effect_type = game_manager.effect_manager.VisualEffectType.DEBUFF
	var status_name = ""

	match status_type:
		StatusType.STUN:
			effect_type = game_manager.effect_manager.VisualEffectType.STUN
			status_name = "stun"
		StatusType.SILENCE:
			status_name = "silence"
		StatusType.DISARM:
			status_name = "disarm"
		StatusType.TAUNT:
			status_name = "taunt"
		StatusType.FROZEN:
			status_name = "frozen"

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(status_name),
		"duration": duration,
		"debuff_type": status_name
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		effect_type,
		target,
		params
	)

# 增加叠加层数
func add_stack() -> void:
	if is_stackable:
		stack_count += 1

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["status_type"] = status_type
	data["is_stackable"] = is_stackable
	data["stack_count"] = stack_count
	data["immunity_time"] = immunity_time
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> StatusEffect:
	var effect = StatusEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("status_type", StatusType.STUN),
		source,
		target
	)

	effect.is_stackable = data.get("is_stackable", false)
	effect.stack_count = data.get("stack_count", 1)
	effect.immunity_time = data.get("immunity_time", 0.5)

	return effect

# 获取状态名称
static func get_status_name(status_type: int) -> String:
	match status_type:
		StatusType.STUN:
			return "眩晕"
		StatusType.SILENCE:
			return "沉默"
		StatusType.DISARM:
			return "缴械"
		StatusType.ROOT:
			return "定身"
		StatusType.TAUNT:
			return "嘲讽"
		StatusType.FROZEN:
			return "冰冻"
		_:
			return "未知状态"

# 获取状态描述
static func get_status_description(status_type: int) -> String:
	match status_type:
		StatusType.STUN:
			return "无法行动"
		StatusType.SILENCE:
			return "无法施放技能"
		StatusType.DISARM:
			return "无法普通攻击"
		StatusType.ROOT:
			return "无法移动"
		StatusType.TAUNT:
			return "强制攻击施法者"
		StatusType.FROZEN:
			return "冰冻无法移动"
		_:
			return "未知状态效果"
