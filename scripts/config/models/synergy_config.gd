extends ConfigModel
class_name SynergyConfig
## 羁绊配置模型
## 用于验证和管理羁绊配置数据

# 引入羁绊常量
const SC = preload("res://scripts/game/synergy/synergy_constants.gd")

# 获取默认模式
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "羁绊ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "羁绊名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "羁绊描述"
		},
		"type": {
			"type": "string",
			"required": true,
			"description": "羁绊类型（职业、种族、特殊）"
		},
		"icon_path": {
			"type": "string",
			"required": true,
			"description": "羁绊图标路径"
		},
		"color": {
			"type": "string",
			"required": false,
			"description": "羁绊颜色（十六进制）"
		},
		"thresholds": {
			"type": "array[dictionary]",
			"required": true,
			"description": "羁绊阈值",
			"schema": {
				"count": {
					"type": "int",
					"required": true,
					"description": "激活所需棋子数量"
				},
				"description": {
					"type": "string",
					"required": false,
					"description": "阈值描述"
				},
				"effects": {
					"type": "array[dictionary]",
					"required": true,
					"description": "阈值效果",
					"schema": {
						"id": {
							"type": "string",
							"required": false,
							"description": "效果ID"
						},
						"type": {
							"type": "string",
							"required": true,
							"description": "效果类型"
						},
						"description": {
							"type": "string",
							"required": false,
							"description": "效果描述"
						}
					}
				}
			}
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证羁绊类型
	if config_data.has("type"):
		var type_str = config_data.type
		var valid_types = ["class", "race", "special"]
		if not valid_types.has(type_str):
			validation_errors.append("羁绊类型必须是有效的类型: " + ", ".join(valid_types))
		else:
			# 尝试转换为枚举值，确保有效
			var type_enum = SC.string_to_synergy_type(type_str)
			if type_enum < 0 or type_enum > SC.SynergyType.size():
				validation_errors.append("无法将羁绊类型转换为有效枚举: " + type_str)

	# 验证羁绊阈值
	if config_data.has("thresholds") and config_data.thresholds is Array:
		if config_data.thresholds.is_empty():
			validation_errors.append("羁绊必须至少有一个阈值")

		var last_count = 0

		for threshold in config_data.thresholds:
			if not threshold is Dictionary:
				validation_errors.append("阈值必须是字典")
				continue

			# 验证阈值数量
			if not threshold.has("count") or not threshold.count is int:
				validation_errors.append("阈值必须有有效的数量" + str(threshold.count))
			elif threshold.count <= last_count:
				validation_errors.append("阈值数量必须递增" + str(threshold))
			else:
				last_count = threshold.count

			# 验证阈值效果
			if not threshold.has("effects"):
				validation_errors.append("阈值必须有效果数组 " + str(threshold))
			elif not threshold.effects is Array:
				validation_errors.append("阈值效果必须是数组" + str(threshold))
			elif threshold.effects.is_empty():
				validation_errors.append("阈值效果数组不能为空" + str(threshold))
			else:
				# 验证每个效果
				for effect in threshold.effects:
					if not effect is Dictionary:
						validation_errors.append("效果必须是字典")
						continue

					# 验证效果ID
					if not effect.has("id") or not effect.id is String or effect.id.is_empty():
						validation_errors.append("效果必须有有效的ID")

					# 验证效果类型
					if not effect.has("type") or not effect.type is String or effect.type.is_empty():
						validation_errors.append("效果必须有有效的类型")
					else:
						# 尝试转换为枚举值，确保有效
						var effect_type_str = effect.type
						var effect_type_enum = SC.string_to_effect_type(effect_type_str)
						if effect_type_enum < 0 or effect_type_enum > SC.EffectType.size():
							validation_errors.append("无法将效果类型转换为有效枚举: " + effect_type_str)

						# 根据效果类型验证必要字段
						match effect_type_enum:
							SC.EffectType.ATTRIBUTE:
								if not effect.has("attribute") or not effect.attribute is String or effect.attribute.is_empty():
									validation_errors.append("属性效果必须指定属性名称")
								if not effect.has("value") or (not effect.value is int and not effect.value is float):
									validation_errors.append("属性效果必须指定数值")
								if not effect.has("operation") or not effect.operation is String or effect.operation.is_empty():
									validation_errors.append("属性效果必须指定操作类型")
							SC.EffectType.ABILITY:
								if not effect.has("ability_id") or not effect.ability_id is String or effect.ability_id.is_empty():
									validation_errors.append("技能效果必须指定技能ID")
							SC.EffectType.SPECIAL:
								if not effect.has("special_id") or not effect.special_id is String or effect.special_id.is_empty():
									validation_errors.append("特殊效果必须指定特殊ID")
							SC.EffectType.CRIT:
								if not effect.has("chance") or not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
									validation_errors.append("暴击效果必须指定有效的几率(0-1)")
								if not effect.has("damage") or not (effect.damage is float or effect.damage is int) or effect.damage < 0:
									validation_errors.append("暴击效果必须指定有效的伤害倍率")
							SC.EffectType.DODGE:
								if not effect.has("chance") or not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
									validation_errors.append("闪避效果必须指定有效的几率(0-1)")
							SC.EffectType.ELEMENTAL_EFFECT:
								if not effect.has("chance") or not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
									validation_errors.append("元素效果必须指定有效的几率(0-1)")
							SC.EffectType.COOLDOWN_REDUCTION:
								if not effect.has("chance") or not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
									validation_errors.append("冷却减少效果必须指定有效的几率(0-1)")
								if not effect.has("reduction") or not (effect.reduction is float or effect.reduction is int) or effect.reduction <= 0:
									validation_errors.append("冷却减少效果必须指定有效的减少值")
							SC.EffectType.SPELL_AMP:
								if not effect.has("amp") or not (effect.amp is float or effect.amp is int):
									validation_errors.append("法术增强效果必须指定有效的增强系数")
							SC.EffectType.DOUBLE_ATTACK:
								if not effect.has("chance") or not (effect.chance is float or effect.chance is int) or effect.chance < 0 or effect.chance > 1:
									validation_errors.append("双重攻击效果必须指定有效的几率(0-1)")
							SC.EffectType.SUMMON_BOOST:
								if not effect.has("damage") or not (effect.damage is float or effect.damage is int):
									validation_errors.append("召唤物增强效果必须指定有效的伤害增强")
								if not effect.has("health") or not (effect.health is float or effect.health is int):
									validation_errors.append("召唤物增强效果必须指定有效的生命增强")
							SC.EffectType.TEAM_BUFF:
								if not effect.has("stats") or not effect.stats is Dictionary or effect.stats.is_empty():
									validation_errors.append("团队增益效果必须指定有效的属性字典")
							SC.EffectType.STAT_BOOST:
								if not effect.has("stats") or not effect.stats is Dictionary or effect.stats.is_empty():
									validation_errors.append("属性增益效果必须指定有效的属性字典")

					# 验证目标选择器
					if effect.has("target_selector"):
						var selector_str = effect.target_selector
						var selector_enum = SC.string_to_target_selector(selector_str)
						if selector_enum < 0 or selector_enum > SC.TargetSelector.size():
							validation_errors.append("无效的目标选择器: " + selector_str)

						# 如果是特定属性选择器，验证属性名
						if selector_enum == SC.TargetSelector.HIGHEST_ATTRIBUTE or selector_enum == SC.TargetSelector.LOWEST_ATTRIBUTE:
							if not effect.has("target_attribute") or not effect.target_attribute is String or effect.target_attribute.is_empty():
								validation_errors.append("属性选择器必须指定目标属性名称")

# 获取羁绊ID
func get_id() -> String:
	return data.get("id", "")

# 获取羁绊名称
func get_synergy_name() -> String:
	return data.get("name", "")

# 获取羁绊描述
func get_description() -> String:
	return data.get("description", "")

# 获取羁绊类型字符串
func get_type_string() -> String:
	return data.get("type", "")

# 获取羁绊类型枚举
func get_type() -> int:
	var type_str = get_type_string()
	return SC.string_to_synergy_type(type_str)

# 获取羁绊图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取羁绊颜色
func get_color() -> String:
	return data.get("color", "#FFFFFF")

# 获取羁绊阈值
func get_thresholds() -> Array:
	return data.get("thresholds", [])

# 获取特定数量的阈值
func get_threshold_for_count(count: int) -> Dictionary:
	var thresholds = get_thresholds()
	var matching_threshold = {}

	for threshold in thresholds:
		if threshold.has("count") and threshold.count <= count:
			if matching_threshold.is_empty() or threshold.count > matching_threshold.count:
				matching_threshold = threshold

	return matching_threshold

# 获取所有阈值数量
func get_all_threshold_counts() -> Array:
	var thresholds = get_thresholds()
	var counts = []

	for threshold in thresholds:
		if threshold.has("count"):
			counts.append(threshold.count)

	return counts

# 获取最大阈值数量
func get_max_threshold_count() -> int:
	var thresholds = get_thresholds()
	var max_count = 0

	for threshold in thresholds:
		if threshold.has("count") and threshold.count > max_count:
			max_count = threshold.count

	return max_count

# 获取特定阈值的效果
func get_effects_for_threshold(count: int) -> Array:
	var threshold = get_threshold_for_count(count)

	if threshold.has("effects"):
		return threshold.effects

	return []

# 获取特定等级的效果
func get_effects_for_level(level: int) -> Array:
	return get_effects_for_threshold(level)

# 检查是否为职业羁绊
func is_class_synergy() -> bool:
	return get_type() == SC.SynergyType.CLASS

# 检查是否为种族羁绊
func is_race_synergy() -> bool:
	return get_type() == SC.SynergyType.RACE

# 检查是否为特殊羁绊
func is_special_synergy() -> bool:
	return get_type() == SC.SynergyType.SPECIAL

# 获取效果类型枚举
func get_effect_type(effect: Dictionary) -> int:
	if not effect.has("type") or not effect.type is String:
		return SC.EffectType.SPECIAL

	return SC.string_to_effect_type(effect.type)

# 获取目标选择器枚举
func get_target_selector(effect: Dictionary) -> int:
	if not effect.has("target_selector") or not effect.target_selector is String:
		# 默认使用同羁绊选择器
		return SC.TargetSelector.SAME_SYNERGY

	return SC.string_to_target_selector(effect.target_selector)
