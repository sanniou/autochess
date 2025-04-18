extends StatEffect
class_name BuffEffect
## 增益效果类
## 为目标提供增益效果

# 增益类型
enum BuffType {
	ATTACK,     # 攻击增益
	DEFENSE,    # 防御增益
	SPEED,      # 速度增益
	HEALTH,     # 生命增益
	SPELL,      # 法术增益
	CRIT        # 暴击增益
}

var buff_type: int = BuffType.ATTACK  # 增益类型

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_value: float = 0.0, p_buff_type: int = BuffType.ATTACK,
		p_source = null, p_target = null) -> void:
	# 创建空的属性字典
	var stats = {}
	
	# 根据增益类型设置属性
	match p_buff_type:
		BuffType.ATTACK:
			stats["attack_damage"] = p_value
			if p_name.is_empty():
				p_name = "攻击增益"
		BuffType.DEFENSE:
			stats["armor"] = p_value
			stats["magic_resist"] = p_value
			if p_name.is_empty():
				p_name = "防御增益"
		BuffType.SPEED:
			stats["attack_speed"] = p_value
			stats["move_speed"] = p_value * 10.0  # 移动速度通常需要更大的值
			if p_name.is_empty():
				p_name = "速度增益"
		BuffType.HEALTH:
			stats["max_health"] = p_value
			if p_name.is_empty():
				p_name = "生命增益"
		BuffType.SPELL:
			stats["spell_power"] = p_value
			if p_name.is_empty():
				p_name = "法术增益"
		BuffType.CRIT:
			stats["crit_chance"] = p_value
			stats["crit_damage"] = p_value * 0.5
			if p_name.is_empty():
				p_name = "暴击增益"
	
	# 调用父类初始化
	super._init(p_id, p_name, p_description, p_duration, stats, p_source, p_target, false)
	
	# 设置增益类型
	buff_type = p_buff_type

# 应用效果
func apply() -> void:
	# 调用父类的应用方法
	super.apply()
	
	# 特殊处理：如果是生命增益，同时增加当前生命值
	if buff_type == BuffType.HEALTH and target and is_instance_valid(target):
		var heal_amount = target.heal(value, source)
		
		# 发送治疗信号
		EventBus.battle.emit_event("heal_received", [target, heal_amount, source])

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["buff_type"] = buff_type
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> BuffEffect:
	return BuffEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("value", 0.0),
		data.get("buff_type", BuffType.ATTACK),
		source,
		target
	)
