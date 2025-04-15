extends Control
## 遗物提示
## 显示遗物的简要信息

# 引用
@onready var panel = $Panel
@onready var name_label = $Panel/VBoxContainer/NameLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel
@onready var effect_label = $Panel/VBoxContainer/EffectLabel

# 当前遗物
var relic = null

# 初始化
func _ready():
	# 默认隐藏
	visible = false

# 设置遗物数据
func set_relic_data(relic_data) -> void:
	relic = relic_data
	
	# 设置遗物名称
	name_label.text = relic.display_name
	
	# 设置遗物描述
	description_label.text = relic.description
	
	# 设置遗物效果
	var effect_text = "效果: "
	
	if relic.effects.size() > 0:
		var effect_descriptions = []
		
		for effect in relic.effects:
			if effect.has("description"):
				effect_descriptions.append(effect.description)
			else:
				# 根据效果类型生成描述
				effect_descriptions.append(_generate_effect_description(effect))
		
		effect_text += ", ".join(effect_descriptions)
	else:
		effect_text += "无特殊效果"
	
	effect_label.text = effect_text
	
	# 根据稀有度设置颜色
	match relic.rarity:
		0: # 普通
			name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		1: # 稀有
			name_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0, 1.0))
		2: # 史诗
			name_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0, 1.0))
		3: # 传说
			name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	
	# 调整面板大小
	call_deferred("_adjust_panel_size")

# 调整面板大小
func _adjust_panel_size() -> void:
	# 等待一帧以确保标签已经更新
	await get_tree().process_frame
	
	# 计算所需高度
	var required_height = name_label.size.y + description_label.size.y + effect_label.size.y + 40
	
	# 设置面板大小
	panel.size.y = required_height

# 生成效果描述
func _generate_effect_description(effect: Dictionary) -> String:
	var desc = ""
	
	if effect.has("type"):
		match effect.type:
			"stat_boost":
				if effect.has("stats"):
					var stats_desc = []
					for stat in effect.stats:
						var value = effect.stats[stat]
						var stat_name = _get_stat_display_name(stat)
						stats_desc.append("%s +%s" % [stat_name, str(value)])
					desc = "增加属性: " + ", ".join(stats_desc)
			
			"damage":
				if effect.has("value"):
					desc = "造成 %s 点%s伤害" % [str(effect.value), effect.get("damage_type", "物理")]
			
			"heal":
				if effect.has("value"):
					desc = "恢复 %s 点生命值" % str(effect.value)
			
			"gold":
				if effect.has("value"):
					if effect.get("operation", "") == "subtract":
						desc = "消耗 %s 金币" % str(effect.value)
					else:
						desc = "获得 %s 金币" % str(effect.value)
			
			"shop":
				if effect.has("operation"):
					match effect.operation:
						"refresh":
							desc = "免费刷新商店"
						"discount":
							desc = "商店折扣 %s%%" % str(int(effect.value * 100))
			
			"synergy":
				if effect.has("operation") and effect.has("synergy_id"):
					match effect.operation:
						"add_level":
							desc = "增加 %s 羁绊等级 %s 级" % [effect.synergy_id, str(effect.value)]
						"activate":
							desc = "激活 %s 羁绊" % effect.synergy_id
			
			_:
				desc = "特殊效果"
	
	return desc

# 获取属性显示名称
func _get_stat_display_name(stat: String) -> String:
	match stat:
		"health":
			return "生命值"
		"attack_damage":
			return "攻击力"
		"attack_speed":
			return "攻击速度"
		"armor":
			return "护甲"
		"magic_resist":
			return "魔抗"
		"spell_power":
			return "法术强度"
		"crit_chance":
			return "暴击几率"
		"crit_damage":
			return "暴击伤害"
		"dodge_chance":
			return "闪避几率"
		_:
			return stat
