extends Node
class_name EquipmentTierManager
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

# 引用
@onready var config_manager = get_node("/root/GameManager/ConfigManager")

# 生成随机装备
func generate_random_equipment(base_equipment_id: String, tier: int = EquipmentTier.NORMAL) -> Equipment:
	# 获取基础装备配置
	var base_config = config_manager.get_equipment(base_equipment_id)
	if not base_config:
		return null
	
	# 创建新的装备配置
	var new_config = base_config.duplicate(true)
	
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
	var base_config = config_manager.get_equipment(base_id)
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
func _apply_tier_to_config(config: Dictionary, tier: int) -> void:
	# 保存原始ID
	var original_id = config.id
	
	# 修改ID
	config.id = original_id + "_" + str(tier)
	
	# 修改名称
	var prefix = TIER_PREFIXES[tier][randi() % TIER_PREFIXES[tier].size()]
	var suffix = TIER_SUFFIXES[tier][randi() % TIER_SUFFIXES[tier].size()]
	
	if suffix:
		config.name = prefix + config.name + "之" + suffix
	else:
		config.name = prefix + config.name
	
	# 修改描述
	config.description = TIER_NAMES[tier] + "品质: " + config.description
	
	# 应用属性加成
	var multiplier = TIER_STAT_MULTIPLIERS[tier]
	if config.has("stats"):
		for stat in config.stats:
			config.stats[stat] *= multiplier
	
	# 添加额外属性
	var extra_stats_count = TIER_EXTRA_STATS[tier]
	if extra_stats_count > 0:
		# 确保有stats字段
		if not config.has("stats"):
			config.stats = {}
		
		# 获取可能的额外属性
		var possible_stats = POSSIBLE_EXTRA_STATS.keys()
		
		# 随机选择额外属性
		for i in range(extra_stats_count):
			if possible_stats.size() == 0:
				break
			
			var random_index = randi() % possible_stats.size()
			var stat_name = possible_stats[random_index]
			
			# 如果已经有这个属性，增加它的值
			if config.stats.has(stat_name):
				var stat_range = POSSIBLE_EXTRA_STATS[stat_name]
				var extra_value = randf_range(stat_range.min, stat_range.max)
				config.stats[stat_name] += extra_value
			else:
				# 否则添加新属性
				var stat_range = POSSIBLE_EXTRA_STATS[stat_name]
				var value = randf_range(stat_range.min, stat_range.max)
				config.stats[stat_name] = value
			
			# 移除已选择的属性，避免重复
			possible_stats.remove_at(random_index)
	
	# 添加特殊效果
	if tier >= EquipmentTier.RARE and not config.has("effects"):
		config.effects = []
		
		# 根据装备类型添加不同的特殊效果
		match config.type:
			"weapon":
				# 武器效果：攻击时有几率造成额外伤害
				config.effects.append({
					"type": "on_attack",
					"trigger": "attack",
					"effect": "extra_damage",
					"chance": 0.15 + 0.05 * (tier - EquipmentTier.RARE),
					"damage": 10.0 * multiplier,
					"description": "攻击时有几率造成额外伤害"
				})
			
			"armor":
				# 护甲效果：受到伤害时有几率减免伤害
				config.effects.append({
					"type": "on_hit",
					"trigger": "take_damage",
					"effect": "damage_reduction",
					"chance": 0.15 + 0.05 * (tier - EquipmentTier.RARE),
					"reduction": 0.2 + 0.1 * (tier - EquipmentTier.RARE),
					"description": "受到伤害时有几率减免伤害"
				})
			
			"accessory":
				# 饰品效果：生命值低时增加属性
				config.effects.append({
					"type": "on_low_health",
					"trigger": "health_percent",
					"effect": "damage_boost",
					"threshold": 0.3,
					"boost": 0.2 + 0.1 * (tier - EquipmentTier.RARE),
					"description": "生命值低于30%时增加攻击力"
				})
	
	# 传说级装备添加特殊被动效果
	if tier == EquipmentTier.LEGENDARY and not config.has("passive_effect"):
		match config.type:
			"weapon":
				# 武器被动：每次攻击有几率触发连击
				config.passive_effect = {
					"type": "passive",
					"effect": "multi_attack",
					"chance": 0.2,
					"attacks": 2,
					"description": "攻击时有20%几率触发连击"
				}
			
			"armor":
				# 护甲被动：受到致命伤害时有几率免疫并恢复生命值
				config.passive_effect = {
					"type": "passive",
					"effect": "death_immunity",
					"chance": 0.3,
					"cooldown": 60.0,
					"heal_percent": 0.3,
					"description": "受到致命伤害时有30%几率免疫并恢复30%生命值（冷却时间60秒）"
				}
			
			"accessory":
				# 饰品被动：周期性提供增益效果
				config.passive_effect = {
					"type": "passive",
					"effect": "periodic_buff",
					"interval": 10.0,
					"duration": 3.0,
					"stats": {
						"attack_speed": 0.3,
						"move_speed": 50.0
					},
					"description": "每10秒获得3秒的攻击速度和移动速度提升"
				}
		
		# 如果有被动效果，添加到effects数组
		if config.has("passive_effect"):
			if not config.has("effects"):
				config.effects = []
			config.effects.append(config.passive_effect)

# 获取品质颜色
func get_tier_color(tier: int) -> Color:
	if TIER_COLORS.has(tier):
		return TIER_COLORS[tier]
	return Color(1, 1, 1)  # 默认白色

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
