extends Control
## 遗物面板
## 显示玩家拥有的遗物和详细信息

# 引用
@onready var relic_grid = $VBoxContainer/ScrollContainer/RelicGrid
@onready var relic_info_panel = $RelicInfoPanel
@onready var name_label = $RelicInfoPanel/VBoxContainer/NameLabel
@onready var texture_rect = $RelicInfoPanel/VBoxContainer/TextureRect
@onready var description_label = $RelicInfoPanel/VBoxContainer/DescriptionLabel
@onready var effects_container = $RelicInfoPanel/VBoxContainer/EffectsContainer
@onready var EventBus = get_node("/root/EventBus")
# 遗物管理器引用
var relic_manager: RelicManager

# 遗物项预制体
const RELIC_ITEM_SCENE = preload("res://scenes/ui/relic/relic_item.tscn")

func _ready():
	# 隐藏遗物信息面板
	relic_info_panel.visible = false
	
	# 获取遗物管理器引用
	relic_manager = get_node_or_null("/root/GameManager/RelicManager")
	
	# 连接信号
	EventBus.relic.connect_event("relic_acquired", _on_relic_acquired)
	EventBus.relic.connect_event("show_relic_info", _on_show_relic_info)
	
	# 初始化遗物列表
	_initialize_relic_list()

## 初始化遗物列表
func _initialize_relic_list() -> void:
	# 清空遗物网格
	for child in relic_grid.get_children():
		child.queue_free()
	
	# 获取玩家遗物
	if relic_manager:
		var player_relics = relic_manager.get_player_relics()
		
		# 添加遗物项
		for relic in player_relics:
			_add_relic_item(relic)

## 添加遗物项
func _add_relic_item(relic) -> void:
	# 实例化遗物项
	var relic_item = RELIC_ITEM_SCENE.instantiate()
	relic_grid.add_child(relic_item)
	
	# 设置遗物数据
	relic_item.set_relic_data(relic)
	
	# 连接信号
	relic_item.relic_clicked.connect(_on_relic_item_clicked)

## 遗物获取事件处理
func _on_relic_acquired(relic) -> void:
	# 添加新获取的遗物
	_add_relic_item(relic)

## 遗物项点击事件处理
func _on_relic_item_clicked(relic) -> void:
	# 显示遗物详细信息
	_on_show_relic_info(relic)

## 显示遗物信息
func _on_show_relic_info(relic) -> void:
	# 设置遗物信息
	name_label.text = relic.display_name
	
	# 设置遗物图标
	if relic.icon:
		texture_rect.texture = relic.icon
	
	# 设置遗物描述
	description_label.text = relic.description
	
	# 清空效果容器
	for child in effects_container.get_children():
		child.queue_free()
	
	# 添加效果
	for effect in relic.effects:
		var effect_label = Label.new()
		
		if effect.has("description"):
			effect_label.text = "• " + effect.description
		else:
			# 根据效果类型生成描述
			var effect_desc = _generate_effect_description(effect)
			effect_label.text = "• " + effect_desc
		
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effects_container.add_child(effect_label)
	
	# 显示信息面板
	relic_info_panel.visible = true

## 生成效果描述
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

## 获取属性显示名称
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

## 关闭按钮点击事件处理
func _on_close_button_pressed() -> void:
	# 隐藏信息面板
	relic_info_panel.visible = false
