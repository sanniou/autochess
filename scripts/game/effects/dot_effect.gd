extends BaseEffect
class_name DotEffect
## 持续伤害效果类
## 对目标造成持续伤害

# 持续伤害属性
var damage_type: String = "magical"  # 伤害类型(physical/magical/true/fire/ice/lightning/poison)
var tick_interval: float = 1.0       # 伤害间隔（秒）
var last_tick_time: float = 0.0      # 上次造成伤害的时间

# 持续伤害类型
enum DotType {
	BURNING,    # 燃烧
	POISONED,   # 中毒
	BLEEDING    # 流血
}

var dot_type: int = DotType.BURNING  # 持续伤害类型

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_damage_per_second: float = 0.0,
		p_damage_type: String = "magical", p_dot_type: int = DotType.BURNING,
		p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.DOT, p_name, p_description,
			p_duration, p_damage_per_second, p_source, p_target, true)  # 持续伤害效果默认为减益
	damage_type = p_damage_type
	dot_type = p_dot_type

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 创建视觉效果
	_create_visual_effect()

	# 播放音效
	play_sound_effect()

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "dot", value])

# 更新效果
func update(delta: float) -> bool:
	# 先调用父类的更新方法
	var is_active = super.update(delta)

	if not is_active:
		return false

	# 更新计时器
	last_tick_time += delta

	# 检查是否到达伤害间隔
	if last_tick_time >= tick_interval:
		# 重置计时器
		last_tick_time = 0.0

		# 应用伤害
		_apply_damage()

	return true

# 应用伤害
func _apply_damage() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 计算伤害
	var damage = value * tick_interval

	# 造成伤害
	var final_damage = target.take_damage(damage, damage_type, source)

	# 播放持续伤害效果
	_play_dot_effect()

	# 发送持续伤害触发信号
	EventBus.status_effect.emit_event("status_effect_dot_triggered", [target, self, final_damage])

# 播放持续伤害效果
func _play_dot_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 根据持续伤害类型创建不同的效果
	var effect_color = Color.WHITE

	match dot_type:
		DotType.BURNING:
			effect_color = Color(1.0, 0.5, 0.0, 0.7)  # 橙色
		DotType.POISONED:
			effect_color = Color(0.0, 0.8, 0.0, 0.7)  # 绿色
		DotType.BLEEDING:
			effect_color = Color(1.0, 0.0, 0.0, 0.7)  # 红色

	# 创建粒子效果
	if target.has_method("_play_effect"):
		var effect_name = ""
		match dot_type:
			DotType.BURNING:
				effect_name = "burning"
			DotType.POISONED:
				effect_name = "poisoned"
			DotType.BLEEDING:
				effect_name = "bleeding"

		target._play_effect(effect_name, effect_color)

# 创建视觉效果
func _create_visual_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(damage_type),
		"duration": duration,
		"damage_type": damage_type,
		"dot_type": dot_type
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.DOT,
		target,
		params
	)

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["damage_type"] = damage_type
	data["tick_interval"] = tick_interval
	data["dot_type"] = dot_type
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> DotEffect:
	var effect = DotEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("value", 0.0),
		data.get("damage_type", "magical"),
		data.get("dot_type", DotType.BURNING),
		source,
		target
	)

	effect.tick_interval = data.get("tick_interval", 1.0)

	return effect

# 获取持续伤害名称
static func get_dot_name(dot_type: int) -> String:
	match dot_type:
		DotType.BURNING:
			return "燃烧"
		DotType.POISONED:
			return "中毒"
		DotType.BLEEDING:
			return "流血"
		_:
			return "未知持续伤害"

# 获取持续伤害描述
static func get_dot_description(dot_type: int) -> String:
	match dot_type:
		DotType.BURNING:
			return "每秒造成火系伤害"
		DotType.POISONED:
			return "每秒造成毒系伤害"
		DotType.BLEEDING:
			return "每秒造成物理伤害"
		_:
			return "每秒造成伤害"
