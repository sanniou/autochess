extends "res://scripts/managers/core/base_manager.gd"
class_name EquipmentTierManager

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EquipmentTierManager"
## 装备拉格管理器
## 负责管理装备的品质和随机属性

# 装备品质枚举
enum EquipmentTier {
	NORMAL,    # 普通
	MAGIC,     # 魔法
	RARE,      # 稀有
	EPIC,      # 史诗
	LEGENDARY  # 传说
}

# 品质颜色
const TIER_COLORS = {
	EquipmentTier.NORMAL: Color(0.8, 0.8, 0.8),  # 灰白色
	EquipmentTier.MAGIC: Color(0.2, 0.6, 1.0),   # 蓝色
	EquipmentTier.RARE: Color(1.0, 0.8, 0.0),    # 金色
	EquipmentTier.EPIC: Color(0.8, 0.2, 0.8),    # 紫色
	EquipmentTier.LEGENDARY: Color(1.0, 0.4, 0.0) # 橙色
}

# 品质名称
const TIER_NAMES = {
	EquipmentTier.NORMAL: "普通",
	EquipmentTier.MAGIC: "魔法",
	EquipmentTier.RARE: "稀有",
	EquipmentTier.EPIC: "史诗",
	EquipmentTier.LEGENDARY: "传说"
}

# 品质前缀
const TIER_PREFIXES = {
	EquipmentTier.NORMAL: ["普通的", "简单的", "粗糙的"],
	EquipmentTier.MAGIC: ["魔法的", "附魔的", "闪光的"],
	EquipmentTier.RARE: ["稀有的", "精良的", "强化的"],
	EquipmentTier.EPIC: ["史诗的", "卓越的", "华丽的"],
	EquipmentTier.LEGENDARY: ["传说的", "神话的", "不朽的"]
}

# 品质后缀
const TIER_SUFFIXES = {
	EquipmentTier.NORMAL: ["", "", ""],
	EquipmentTier.MAGIC: ["魔力", "秘术", "奥术"],
	EquipmentTier.RARE: ["精华", "精准", "迅捷"],
	EquipmentTier.EPIC: ["毁灭", "统治", "征服"],
	EquipmentTier.LEGENDARY: ["永恒", "神威", "天启"]
}

# 属性加成系数
const TIER_STAT_MULTIPLIERS = {
	EquipmentTier.NORMAL: 1.0,
	EquipmentTier.MAGIC: 1.2,
	EquipmentTier.RARE: 1.5,
	EquipmentTier.EPIC: 2.0,
	EquipmentTier.LEGENDARY: 3.0
}

# 额外属性数量
const TIER_EXTRA_STATS = {
	EquipmentTier.NORMAL: 0,
	EquipmentTier.MAGIC: 1,
	EquipmentTier.RARE: 2,
	EquipmentTier.EPIC: 3,
	EquipmentTier.LEGENDARY: 4
}

# 可能的额外属性
const POSSIBLE_EXTRA_STATS = {
	"attack_damage": {"min": 5, "max": 20},
	"attack_speed": {"min": 0.05, "max": 0.2},
	"armor": {"min": 5, "max": 15},
	"magic_resist": {"min": 5, "max": 15},
	"health": {"min": 20, "max": 100},
	"spell_power": {"min": 5, "max": 20},
	"crit_chance": {"min": 0.05, "max": 0.15},
	"crit_damage": {"min": 0.1, "max": 0.3},
	"dodge_chance": {"min": 0.03, "max": 0.1},
	"move_speed": {"min": 10, "max": 30}
}

# 装备特效相关常量
const DEFAULT_COOLDOWN_TIME = 60.0  # 默认冷却时间（60秒）

# 生成随机装备
func generate_random_equipment(base_equipment_id: String, tier: int = EquipmentTier.NORMAL) -> Equipment:
	# 获取基础装备配置
	var base_config: EquipmentConfig = ConfigManager.get_equipment_config(base_equipment_id)

	# 创建新的装备配置
	var new_config = base_config.get_data()

	# 应用品质
	_apply_tier_to_config(new_config, tier)

	# 创建装备实例
	var equipment = Equipment.new()
	equipment.initialize(new_config)

	return equipment

# 升级装备品质
func upgrade_equipment_tier(equipment: Equipment, new_tier: int) -> Equipment:
	if not equipment:
		return null

	# 获取基础装备配置
	var base_id = equipment.id.split("_")[0] if "_" in equipment.id else equipment.id
	var base_config = ConfigManager.get_equipment_config(base_id)
	if not base_config:
		return null

	# 创建新的装备配置
	var new_config = base_config.duplicate(true)

	# 应用品质
	_apply_tier_to_config(new_config, new_tier)

	# 创建装备实例
	var new_equipment = Equipment.new()
	new_equipment.initialize(new_config)

	return new_equipment

# 应用品质到配置
func _apply_tier_to_config(config: Dictionary, tier: int) -> Dictionary:
	# 保存原始ID
	var original_id = config.get("id", "")

	# 修改ID
	config["id"] = original_id + "_" + str(tier)

	# 获取装备类型和属性
	var equipment_type = config.get("type", "weapon")
	var equipment_stats = config.get("stats", {})

	# 根据装备类型选择适合的前缀和后缀
	var type_prefixes = _get_type_specific_prefixes(equipment_type, tier)
	var type_suffixes = _get_type_specific_suffixes(equipment_type, tier)

	# 选择前缀和后缀
	var prefix = type_prefixes[randi() % type_prefixes.size()]
	var suffix = ""
	if tier > EquipmentTier.NORMAL:
		var suffix_list = type_suffixes
		if suffix_list.size() > 0:
			suffix = suffix_list[randi() % suffix_list.size()]

	# 修改名称
	var original_name = config.get("name", "")
	if suffix:
		config["name"] = prefix + original_name + "之" + suffix
	else:
		config["name"] = prefix + original_name

	# 修改描述
	var original_description = config.get("description", "")
	var tier_name = TIER_NAMES.get(tier, "未知")
	var tier_color_code = _get_tier_color_code(tier)
	config["description"] = "[color=%s]%s品质[/color]: %s" % [tier_color_code, tier_name, original_description]

	# 应用属性加成
	var base_multiplier = TIER_STAT_MULTIPLIERS.get(tier, 1.0)
	if config.has("stats"):
		for stat in config["stats"]:
			# 根据属性类型调整乘数
			var stat_multiplier = _get_stat_specific_multiplier(stat, equipment_type, base_multiplier)
			config["stats"][stat] *= stat_multiplier

			# 四舍五入属性值，使其更易读
			if config["stats"][stat] is float:
				config["stats"][stat] = round(config["stats"][stat] * 100) / 100.0
			elif config["stats"][stat] is int:
				config["stats"][stat] = int(config["stats"][stat])

	# 添加额外属性
	var extra_stats_count = TIER_EXTRA_STATS.get(tier, 0)
	if extra_stats_count > 0:
		# 确保有stats字段
		if not config.has("stats"):
			config["stats"] = {}

		# 获取适合当前装备类型的额外属性
		var suitable_stats = _get_suitable_stats_for_type(equipment_type)

		# 随机选择额外属性
		for i in range(extra_stats_count):
			if suitable_stats.size() == 0:
				break

			var random_index = randi() % suitable_stats.size()
			var stat_name = suitable_stats[random_index]

			# 如果已经有这个属性，增加它的值
			if config["stats"].has(stat_name):
				var stat_range = POSSIBLE_EXTRA_STATS[stat_name]
				var extra_value = randf() * (stat_range.max - stat_range.min) + stat_range.min
				extra_value *= base_multiplier
				config["stats"][stat_name] += extra_value
			else:
				# 否则添加新属性
				var stat_range = POSSIBLE_EXTRA_STATS[stat_name]
				var value = randf() * (stat_range.max - stat_range.min) + stat_range.min
				value *= base_multiplier
				config["stats"][stat_name] = value

			# 四舍五入属性值
			if config["stats"][stat_name] is float:
				config["stats"][stat_name] = round(config["stats"][stat_name] * 100) / 100.0
			elif config["stats"][stat_name] is int:
				config["stats"][stat_name] = int(config["stats"][stat_name])

			# 移除已选择的属性，避免重复
			suitable_stats.remove_at(random_index)

	# 添加特殊效果
	if tier >= EquipmentTier.RARE:
		if not config.has("effects"):
			config["effects"] = []

		# 根据装备类型添加不同的特殊效果
		var effect = _generate_effect_for_type(equipment_type, tier, base_multiplier)
		if effect:
			config["effects"].append(effect)

	# 传说级装备添加特殊被动效果
	if tier == EquipmentTier.LEGENDARY:
		var passive_effect = _generate_legendary_passive(equipment_type, base_multiplier)
		if passive_effect:
			config["passive_effect"] = passive_effect

			# 如果有被动效果，添加到effects数组
			if not config.has("effects"):
				config["effects"] = []
			config["effects"].append(passive_effect)

	# 添加品质标记
	config["tier"] = tier

	# 触发装备品质变化事件
	EventBus.equipment.emit_event("equipment_tier_changed", [original_id, tier, config])
	return config

# 获取品质颜色
func get_tier_color(tier: int) -> Color:
	if TIER_COLORS.has(tier):
		return TIER_COLORS[tier]
	return Color(1, 1, 1)  # 默认白色

# 获取品质颜色代码
func _get_tier_color_code(tier: int) -> String:
	var color = get_tier_color(tier)
	return color.to_html(false)

# 获取品质名称
func get_tier_name(tier: int) -> String:
	if TIER_NAMES.has(tier):
		return TIER_NAMES[tier]
	return "未知"

# 从装备ID获取品质
func get_tier_from_id(equipment_id: String) -> int:
	var parts = equipment_id.split("_")
	if parts.size() > 1:
		var tier_str = parts[-1]
		if tier_str.is_valid_int():
			var tier = tier_str.to_int()
			if tier >= EquipmentTier.NORMAL and tier <= EquipmentTier.LEGENDARY:
				return tier

	return EquipmentTier.NORMAL  # 默认为普通品质

# 根据装备类型获取特定的前缀
func _get_type_specific_prefixes(equipment_type: String, tier: int) -> Array:
	# 基础前缀
	var base_prefixes = TIER_PREFIXES.get(tier, [])

	# 根据装备类型添加特定前缀
	var type_prefixes = base_prefixes.duplicate()

	# 根据装备类型添加特定前缀
	match equipment_type:
		"weapon":
			if tier >= EquipmentTier.RARE:
				type_prefixes.append_array(["锐利的", "毁灭的", "战争的"])
		"armor":
			if tier >= EquipmentTier.RARE:
				type_prefixes.append_array(["坚固的", "守护的", "不毁的"])
		"accessory":
			if tier >= EquipmentTier.RARE:
				type_prefixes.append_array(["神秘的", "奇异的", "奇妙的"])

	return type_prefixes

# 根据装备类型获取特定的后缀
func _get_type_specific_suffixes(equipment_type: String, tier: int) -> Array:
	# 基础后缀
	var base_suffixes = TIER_SUFFIXES.get(tier, [])

	# 根据装备类型添加特定后缀
	var type_suffixes = base_suffixes.duplicate()

	# 根据装备类型添加特定后缀
	match equipment_type:
		"weapon":
			if tier >= EquipmentTier.EPIC:
				type_suffixes.append_array(["屠杀", "毁灭", "战争"])
		"armor":
			if tier >= EquipmentTier.EPIC:
				type_suffixes.append_array(["守护", "坚韧", "不毁"])
		"accessory":
			if tier >= EquipmentTier.EPIC:
				type_suffixes.append_array(["智慧", "神秘", "奇迹"])

	return type_suffixes

# 根据属性类型获取特定的乘数
func _get_stat_specific_multiplier(stat_name: String, equipment_type: String, base_multiplier: float) -> float:
	# 基础乘数
	var multiplier = base_multiplier

	# 根据属性和装备类型调整乘数
	match equipment_type:
		"weapon":
			if stat_name in ["attack_damage", "attack_speed", "spell_power"]:
				multiplier *= 1.1  # 武器的攻击属性加成
		"armor":
			if stat_name in ["armor", "magic_resist", "health"]:
				multiplier *= 1.1  # 护甲的防御属性加成
		"accessory":
			if stat_name in ["crit_chance", "crit_damage", "dodge_chance"]:
				multiplier *= 1.1  # 饰品的特殊属性加成

	return multiplier

# 获取适合当前装备类型的额外属性
func _get_suitable_stats_for_type(equipment_type: String) -> Array:
	# 所有可能的属性
	var all_stats = POSSIBLE_EXTRA_STATS.keys()

	# 根据装备类型过滤属性
	var suitable_stats = []

	match equipment_type:
		"weapon":
			# 武器适合攻击相关属性
			for stat in all_stats:
				if stat in ["attack_damage", "attack_speed", "spell_power", "crit_chance", "crit_damage"]:
					suitable_stats.append(stat)
		"armor":
			# 护甲适合防御相关属性
			for stat in all_stats:
				if stat in ["armor", "magic_resist", "health", "dodge_chance"]:
					suitable_stats.append(stat)
		"accessory":
			# 饰品适合特殊属性
			for stat in all_stats:
				if stat in ["crit_chance", "crit_damage", "dodge_chance", "move_speed", "spell_power"]:
					suitable_stats.append(stat)
		_:
			# 默认返回所有属性
			suitable_stats = all_stats.duplicate()

	return suitable_stats

# 根据装备类型生成特殊效果
func _generate_effect_for_type(equipment_type: String, tier: int, multiplier: float) -> Dictionary:
	var effect = {}

	# 根据装备类型生成不同的效果
	match equipment_type:
		"weapon":
			# 武器效果：攻击时有几率造成额外伤害
			var chance = 0.15 + 0.05 * (tier - EquipmentTier.RARE)
			var damage = 10.0 * multiplier

			effect = {
				"type": "on_attack",
				"trigger": "attack",
				"effect": "extra_damage",
				"chance": chance,
				"damage": damage,
				"description": "攻击时有%.0f%%几率造成%.1f点额外伤害" % [chance * 100, damage]
			}

		"armor":
			# 护甲效果：受到伤害时有几率减免伤害
			var chance = 0.15 + 0.05 * (tier - EquipmentTier.RARE)
			var reduction = 0.2 + 0.1 * (tier - EquipmentTier.RARE)

			effect = {
				"type": "on_hit",
				"trigger": "take_damage",
				"effect": "damage_reduction",
				"chance": chance,
				"reduction": reduction,
				"description": "受到伤害时有%.0f%%几率减免%.0f%%伤害" % [chance * 100, reduction * 100]
			}

		"accessory":
			# 饰品效果：生命值低时增加属性
			var threshold = 0.3
			var boost = 0.2 + 0.1 * (tier - EquipmentTier.RARE)

			effect = {
				"type": "on_low_health",
				"trigger": "health_percent",
				"effect": "damage_boost",
				"threshold": threshold,
				"boost": boost,
				"description": "生命值低于%.0f%%时增加%.0f%%攻击力" % [threshold * 100, boost * 100]
			}

	return effect

# 生成传说级装备的被动效果
func _generate_legendary_passive(equipment_type: String, multiplier: float) -> Dictionary:
	var passive_effect = {}

	# 根据装备类型生成不同的被动效果
	match equipment_type:
		"weapon":
			# 武器被动：每次攻击有几率触发连击
			var chance = 0.2
			var attacks = 2

			passive_effect = {
				"type": "passive",
				"effect": "multi_attack",
				"chance": chance,
				"attacks": attacks,
				"description": "攻击时有%.0f%%几率触发%d次连击" % [chance * 100, attacks]
			}

		"armor":
			# 护甲被动：受到致命伤害时有几率免疫并恢复生命值
			var chance = 0.3
			var cooldown_time = DEFAULT_COOLDOWN_TIME
			var heal_percent = 0.3

			passive_effect = {
				"type": "passive",
				"effect": "death_immunity",
				"chance": chance,
				"cooldown_time": cooldown_time,
				"heal_percent": heal_percent,
				"description": "受到致命伤害时有%.0f%%几率免疫并恢复%.0f%%生命值（冷却时间%.0f秒）" % [chance * 100, heal_percent * 100, cooldown_time]
			}

		"accessory":
			# 饰品被动：周期性提供增益效果
			var interval = 10.0
			var duration = 3.0
			var attack_speed_boost = 0.3
			var move_speed_boost = 50.0

			passive_effect = {
				"type": "passive",
				"effect": "periodic_buff",
				"interval": interval,
				"duration": duration,
				"stats": {
					"attack_speed": attack_speed_boost,
					"move_speed": move_speed_boost
				},
				"description": "每%.0f秒获得%.0f秒的攻击速度提升%.0f%%和移动速度提升%.0f" % [interval, duration, attack_speed_boost * 100, move_speed_boost]
			}

	return passive_effect

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写重置方法
func _do_reset() -> void:
	_log_info("装备品质管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	_log_info("装备品质管理器清理完成")