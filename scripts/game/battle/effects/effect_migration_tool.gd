extends Node
class_name EffectMigrationTool
## 效果迁移工具
## 用于将旧效果系统的代码迁移到新效果系统

# 迁移效果
static func migrate_effect(old_effect, source = null, target = null) -> BattleEffect:
	# 使用迁移映射转换效果
	return EffectMigrationMap.convert_effect(old_effect, source, target)

# 迁移效果数据
static func migrate_effect_data(effect_data: Dictionary) -> Dictionary:
	var new_data = effect_data.duplicate()
	
	# 转换效果类型
	if new_data.has("type"):
		var old_type = new_data.type
		var new_type = _convert_effect_type(old_type)
		new_data.erase("type")
		new_data["effect_type"] = new_type
	
	# 转换状态类型
	if new_data.has("status_type"):
		var old_status_type = new_data.status_type
		var new_status_type = _convert_status_type(old_status_type)
		new_data["status_type"] = new_status_type
	
	# 转换持续伤害类型
	if new_data.has("dot_type"):
		var old_dot_type = new_data.dot_type
		var new_dot_type = _convert_dot_type(old_dot_type)
		new_data["dot_type"] = new_dot_type
	
	# 转换增益类型
	if new_data.has("buff_type"):
		var old_buff_type = new_data.buff_type
		var stats = _convert_buff_type_to_stats(old_buff_type, new_data.get("value", 0.0))
		new_data.erase("buff_type")
		new_data["stats"] = stats
	
	return new_data

# 转换效果类型
static func _convert_effect_type(old_type) -> int:
	if old_type is String:
		# 处理字符串类型
		match old_type:
			"BaseEffect.EffectType.STAT":
				return BattleEffect.EffectType.STAT_MOD
			"BaseEffect.EffectType.STATUS":
				return BattleEffect.EffectType.STATUS
			"BaseEffect.EffectType.DAMAGE":
				return BattleEffect.EffectType.DAMAGE
			"BaseEffect.EffectType.HEAL":
				return BattleEffect.EffectType.HEAL
			"BaseEffect.EffectType.DOT":
				return BattleEffect.EffectType.DOT
			"BaseEffect.EffectType.VISUAL":
				return BattleEffect.EffectType.VISUAL
			"BaseEffect.EffectType.SOUND":
				return BattleEffect.EffectType.SOUND
			"BaseEffect.EffectType.MOVEMENT":
				return BattleEffect.EffectType.MOVEMENT
			_:
				return BattleEffect.EffectType.STATUS
	elif old_type is int:
		# 处理枚举类型
		match old_type:
			BaseEffect.EffectType.STAT:
				return BattleEffect.EffectType.STAT_MOD
			BaseEffect.EffectType.STATUS:
				return BattleEffect.EffectType.STATUS
			BaseEffect.EffectType.DAMAGE:
				return BattleEffect.EffectType.DAMAGE
			BaseEffect.EffectType.HEAL:
				return BattleEffect.EffectType.HEAL
			BaseEffect.EffectType.DOT:
				return BattleEffect.EffectType.DOT
			BaseEffect.EffectType.VISUAL:
				return BattleEffect.EffectType.VISUAL
			BaseEffect.EffectType.SOUND:
				return BattleEffect.EffectType.SOUND
			BaseEffect.EffectType.MOVEMENT:
				return BattleEffect.EffectType.MOVEMENT
			_:
				return BattleEffect.EffectType.STATUS
	
	return BattleEffect.EffectType.STATUS

# 转换状态类型
static func _convert_status_type(old_status_type) -> int:
	if old_status_type is String:
		# 处理字符串类型
		match old_status_type:
			"StatusEffect.StatusType.STUN":
				return StatusEffect.StatusType.STUN
			"StatusEffect.StatusType.SILENCE":
				return StatusEffect.StatusType.SILENCE
			"StatusEffect.StatusType.DISARM":
				return StatusEffect.StatusType.DISARM
			"StatusEffect.StatusType.ROOT":
				return StatusEffect.StatusType.ROOT
			"StatusEffect.StatusType.TAUNT":
				return StatusEffect.StatusType.TAUNT
			"StatusEffect.StatusType.FROZEN":
				return StatusEffect.StatusType.FROZEN
			_:
				return StatusEffect.StatusType.STUN
	elif old_status_type is int:
		# 处理枚举类型
		if old_status_type >= 0 and old_status_type <= 5:
			# 旧的状态类型枚举值与新的相同
			return old_status_type
	
	return StatusEffect.StatusType.STUN

# 转换持续伤害类型
static func _convert_dot_type(old_dot_type) -> int:
	if old_dot_type is String:
		# 处理字符串类型
		match old_dot_type:
			"DotEffect.DotType.BURNING":
				return DotEffect.DotType.BURNING
			"DotEffect.DotType.POISONED":
				return DotEffect.DotType.POISONED
			"DotEffect.DotType.BLEEDING":
				return DotEffect.DotType.BLEEDING
			_:
				return DotEffect.DotType.BURNING
	elif old_dot_type is int:
		# 处理枚举类型
		if old_dot_type >= 0 and old_dot_type <= 2:
			# 旧的持续伤害类型枚举值与新的相同
			return old_dot_type
	
	return DotEffect.DotType.BURNING

# 转换增益类型为属性字典
static func _convert_buff_type_to_stats(old_buff_type, value: float) -> Dictionary:
	var stats = {}
	
	if old_buff_type is String:
		# 处理字符串类型
		match old_buff_type:
			"BuffEffect.BuffType.ATTACK":
				stats["attack_damage"] = value
			"BuffEffect.BuffType.DEFENSE":
				stats["armor"] = value
				stats["magic_resist"] = value
			"BuffEffect.BuffType.SPEED":
				stats["attack_speed"] = value
				stats["move_speed"] = value * 10.0
			"BuffEffect.BuffType.HEALTH":
				stats["max_health"] = value
			"BuffEffect.BuffType.SPELL":
				stats["spell_power"] = value
			"BuffEffect.BuffType.CRIT":
				stats["crit_chance"] = value
				stats["crit_damage"] = value * 0.5
	elif old_buff_type is int:
		# 处理枚举类型
		match old_buff_type:
			0:  # BuffEffect.BuffType.ATTACK
				stats["attack_damage"] = value
			1:  # BuffEffect.BuffType.DEFENSE
				stats["armor"] = value
				stats["magic_resist"] = value
			2:  # BuffEffect.BuffType.SPEED
				stats["attack_speed"] = value
				stats["move_speed"] = value * 10.0
			3:  # BuffEffect.BuffType.HEALTH
				stats["max_health"] = value
			4:  # BuffEffect.BuffType.SPELL
				stats["spell_power"] = value
			5:  # BuffEffect.BuffType.CRIT
				stats["crit_chance"] = value
				stats["crit_damage"] = value * 0.5
	
	return stats
