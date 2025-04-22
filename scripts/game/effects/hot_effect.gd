extends GameEffect
class_name HotEffect
## 持续治疗效果
## 用于对目标提供持续治疗

# 每秒治疗值
var heal_per_second: float = 0.0

# 上次治疗时间
var last_heal_time: float = 0.0

# 治疗间隔
var tick_interval: float = 1.0

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, heal_per_second_param: float = 0.0,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.HOT, effect_source, effect_target, effect_params)
	
	heal_per_second = heal_per_second_param
	
	# 设置治疗间隔
	tick_interval = effect_params.get("tick_interval", 1.0)
	
	# 设置标签
	if not tags.has("hot"):
		tags.append("hot")
	if not tags.has("buff"):
		tags.append("buff")
	
	# 设置图标路径
	icon_path = "res://assets/icons/hot/regeneration.png"
	
	# 设置名称和描述
	if name.is_empty():
		name = "生命恢复"
	
	if description.is_empty():
		description = "每秒恢复 " + str(heal_per_second) + " 点生命值"

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 立即提供第一次治疗
	_apply_heal()
	
	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 更新上次治疗时间
	last_heal_time += delta
	
	# 检查是否到达治疗间隔
	if last_heal_time >= tick_interval:
		# 重置上次治疗时间
		last_heal_time = 0.0
		
		# 提供治疗
		_apply_heal()
	
	return true

# 应用治疗
func _apply_heal() -> void:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return
	
	# 检查目标是否可以被治疗
	if not target.has_method("heal"):
		return
	
	# 计算本次治疗
	var heal = heal_per_second * tick_interval
	
	# 对目标进行治疗
	target.heal(heal, source, false)
	
	# 发送持续治疗事件
	if EventBus:
		EventBus.emit_signal("hot_heal", {
			"source": source,
			"target": target,
			"value": heal
		})

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["heal_per_second"] = heal_per_second
	data["tick_interval"] = tick_interval
	data["last_heal_time"] = last_heal_time
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> HotEffect:
	var effect = HotEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("heal_per_second", 0.0),
		source,
		target,
		data.get("params", {})
	)
	
	effect.last_heal_time = data.get("last_heal_time", 0.0)
	
	return effect
