extends GameEffect
class_name StatusEffect
## 状态效果
## 用于改变单位的状态，如眩晕、沉默等

# 状态类型枚举
enum StatusType {
	STUN,     # 眩晕
	SILENCE,  # 沉默
	DISARM,   # 缴械
	ROOT,     # 定身
	TAUNT,    # 嘲讽
	FROZEN    # 冰冻
}

# 状态类型
var status_type: int = StatusType.STUN

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, status_type_value: int = StatusType.STUN,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.STATUS, effect_source, effect_target, effect_params)
	
	status_type = status_type_value
	
	# 设置标签
	if not tags.has("status"):
		tags.append("status")
	if not tags.has("debuff"):
		tags.append("debuff")
	
	# 设置图标路径
	icon_path = _get_status_icon_path(status_type)
	
	# 设置名称和描述
	if name.is_empty():
		name = _get_status_name(status_type)
	
	if description.is_empty():
		description = _get_status_description(status_type)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 根据状态类型应用不同的效果
	match status_type:
		StatusType.STUN:
			_apply_stun()
		StatusType.SILENCE:
			_apply_silence()
		StatusType.DISARM:
			_apply_disarm()
		StatusType.ROOT:
			_apply_root()
		StatusType.TAUNT:
			_apply_taunt()
		StatusType.FROZEN:
			_apply_frozen()
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 根据状态类型移除不同的效果
	match status_type:
		StatusType.STUN:
			_remove_stun()
		StatusType.SILENCE:
			_remove_silence()
		StatusType.DISARM:
			_remove_disarm()
		StatusType.ROOT:
			_remove_root()
		StatusType.TAUNT:
			_remove_taunt()
		StatusType.FROZEN:
			_remove_frozen()
	
	return true

# 应用眩晕
func _apply_stun() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("stun", duration)
	
	# 如果目标有移动组件，禁用移动
	if target.has_method("disable_movement"):
		target.disable_movement()
	
	# 如果目标有技能组件，禁用技能
	if target.has_method("disable_skills"):
		target.disable_skills()
	
	# 如果目标有攻击组件，禁用攻击
	if target.has_method("disable_attack"):
		target.disable_attack()

# 移除眩晕
func _remove_stun() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("stun")
	
	# 如果目标有移动组件，启用移动
	if target.has_method("enable_movement"):
		target.enable_movement()
	
	# 如果目标有技能组件，启用技能
	if target.has_method("enable_skills"):
		target.enable_skills()
	
	# 如果目标有攻击组件，启用攻击
	if target.has_method("enable_attack"):
		target.enable_attack()

# 应用沉默
func _apply_silence() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("silence", duration)
	
	# 如果目标有技能组件，禁用技能
	if target.has_method("disable_skills"):
		target.disable_skills()

# 移除沉默
func _remove_silence() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("silence")
	
	# 如果目标有技能组件，启用技能
	if target.has_method("enable_skills"):
		target.enable_skills()

# 应用缴械
func _apply_disarm() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("disarm", duration)
	
	# 如果目标有攻击组件，禁用攻击
	if target.has_method("disable_attack"):
		target.disable_attack()

# 移除缴械
func _remove_disarm() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("disarm")
	
	# 如果目标有攻击组件，启用攻击
	if target.has_method("enable_attack"):
		target.enable_attack()

# 应用定身
func _apply_root() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("root", duration)
	
	# 如果目标有移动组件，禁用移动
	if target.has_method("disable_movement"):
		target.disable_movement()

# 移除定身
func _remove_root() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("root")
	
	# 如果目标有移动组件，启用移动
	if target.has_method("enable_movement"):
		target.enable_movement()

# 应用嘲讽
func _apply_taunt() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("taunt", duration)
	
	# 如果目标有AI组件，设置嘲讽目标
	if target.has_method("set_taunt_target") and source and is_instance_valid(source):
		target.set_taunt_target(source)

# 移除嘲讽
func _remove_taunt() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("taunt")
	
	# 如果目标有AI组件，清除嘲讽目标
	if target.has_method("clear_taunt_target"):
		target.clear_taunt_target()

# 应用冰冻
func _apply_frozen() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("add_status"):
		target.add_status("frozen", duration)
	
	# 如果目标有移动组件，禁用移动
	if target.has_method("disable_movement"):
		target.disable_movement()
	
	# 如果目标有技能组件，禁用技能
	if target.has_method("disable_skills"):
		target.disable_skills()
	
	# 如果目标有攻击组件，禁用攻击
	if target.has_method("disable_attack"):
		target.disable_attack()
	
	# 如果目标有动画组件，播放冰冻动画
	if target.has_method("play_animation"):
		target.play_animation("frozen")

# 移除冰冻
func _remove_frozen() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否有状态组件
	if target.has_method("remove_status"):
		target.remove_status("frozen")
	
	# 如果目标有移动组件，启用移动
	if target.has_method("enable_movement"):
		target.enable_movement()
	
	# 如果目标有技能组件，启用技能
	if target.has_method("enable_skills"):
		target.enable_skills()
	
	# 如果目标有攻击组件，启用攻击
	if target.has_method("enable_attack"):
		target.enable_attack()
	
	# 如果目标有动画组件，播放默认动画
	if target.has_method("play_animation"):
		target.play_animation("idle")

# 获取状态图标路径
func _get_status_icon_path(status_type: int) -> String:
	match status_type:
		StatusType.STUN:
			return "res://assets/icons/status/stun.png"
		StatusType.SILENCE:
			return "res://assets/icons/status/silence.png"
		StatusType.DISARM:
			return "res://assets/icons/status/disarm.png"
		StatusType.ROOT:
			return "res://assets/icons/status/root.png"
		StatusType.TAUNT:
			return "res://assets/icons/status/taunt.png"
		StatusType.FROZEN:
			return "res://assets/icons/status/frozen.png"
	
	return ""

# 获取状态名称
func _get_status_name(status_type: int) -> String:
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
	
	return "未知状态"

# 获取状态描述
func _get_status_description(status_type: int) -> String:
	match status_type:
		StatusType.STUN:
			return "无法移动、攻击或使用技能"
		StatusType.SILENCE:
			return "无法使用技能"
		StatusType.DISARM:
			return "无法进行普通攻击"
		StatusType.ROOT:
			return "无法移动"
		StatusType.TAUNT:
			return "被迫攻击嘲讽者"
		StatusType.FROZEN:
			return "被冰冻，无法移动、攻击或使用技能"
	
	return "未知状态效果"

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["status_type"] = status_type
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> StatusEffect:
	return StatusEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("status_type", StatusType.STUN),
		source,
		target,
		data.get("params", {})
	)
