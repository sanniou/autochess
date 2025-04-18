extends StatEffect
class_name DebuffEffect
## 减益效果类
## 为目标提供减益效果

# 减益类型
enum DebuffType {
	ATTACK,     # 攻击减益
	DEFENSE,    # 防御减益
	SPEED,      # 速度减益
	HEALTH,     # 生命减益
	SPELL,      # 法术减益
	CRIT        # 暴击减益
}

var debuff_type: int = DebuffType.ATTACK  # 减益类型

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_value: float = 0.0, p_debuff_type: int = DebuffType.ATTACK,
		p_source = null, p_target = null) -> void:
	# 创建空的属性字典
	var stats = {}
	
	# 根据减益类型设置属性（注意这里的值是负数）
	match p_debuff_type:
		DebuffType.ATTACK:
			stats["attack_damage"] = -p_value
			if p_name.is_empty():
				p_name = "攻击减益"
		DebuffType.DEFENSE:
			stats["armor"] = -p_value
			stats["magic_resist"] = -p_value
			if p_name.is_empty():
				p_name = "防御减益"
		DebuffType.SPEED:
			stats["attack_speed"] = -p_value
			stats["move_speed"] = -p_value * 10.0  # 移动速度通常需要更大的值
			if p_name.is_empty():
				p_name = "速度减益"
		DebuffType.HEALTH:
			stats["max_health"] = -p_value
			if p_name.is_empty():
				p_name = "生命减益"
		DebuffType.SPELL:
			stats["spell_power"] = -p_value
			if p_name.is_empty():
				p_name = "法术减益"
		DebuffType.CRIT:
			stats["crit_chance"] = -p_value
			stats["crit_damage"] = -p_value * 0.5
			if p_name.is_empty():
				p_name = "暴击减益"
	
	# 调用父类初始化
	super._init(p_id, p_name, p_description, p_duration, stats, p_source, p_target, true)
	
	# 设置减益类型
	debuff_type = p_debuff_type

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["debuff_type"] = debuff_type
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> DebuffEffect:
	return DebuffEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("value", 0.0),
		data.get("debuff_type", DebuffType.ATTACK),
		source,
		target
	)
