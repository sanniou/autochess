extends Control
## 棋子信息面板
## 显示棋子的详细信息

# 引用
@onready var name_label = $VBoxContainer/NameLabel
@onready var type_label = $VBoxContainer/TypeLabel
@onready var star_container = $VBoxContainer/StarContainer
@onready var stats_container = $VBoxContainer/StatsContainer
@onready var abilities_container = $VBoxContainer/AbilitiesContainer
@onready var synergies_container = $VBoxContainer/SynergiesContainer
@onready var equipment_container = $VBoxContainer/EquipmentContainer

# 当前显示的棋子
var current_piece: ChessPieceEntity = null

func _ready():
	# 初始隐藏面板
	visible = false
	
	# 连接信号
	EventBus.chess.connect_event("show_chess_info", _on_show_chess_info)
	EventBus.chess.connect_event("hide_chess_info", _on_hide_chess_info)

## 显示棋子信息
func _on_show_chess_info(piece: ChessPieceEntity) -> void:
	if not piece:
		return
	
	current_piece = piece
	
	# 更新面板位置（跟随鼠标，但不超出屏幕边界）
	var mouse_pos = get_viewport().get_mouse_position()
	var panel_size = size
	var viewport_size = get_viewport_rect().size
	
	var pos_x = mouse_pos.x + 20
	var pos_y = mouse_pos.y - panel_size.y / 2
	
	# 确保面板不超出屏幕右侧
	if pos_x + panel_size.x > viewport_size.x:
		pos_x = mouse_pos.x - panel_size.x - 20
	
	# 确保面板不超出屏幕上下边界
	if pos_y < 0:
		pos_y = 0
	elif pos_y + panel_size.y > viewport_size.y:
		pos_y = viewport_size.y - panel_size.y
	
	position = Vector2(pos_x, pos_y)
	
	# 更新面板内容
	_update_panel_content(piece)
	
	# 显示面板
	visible = true

## 隐藏棋子信息
func _on_hide_chess_info() -> void:
	visible = false
	current_piece = null

## 更新面板内容
func _update_panel_content(piece: ChessPieceEntity) -> void:
	# 更新基本信息
	name_label.text = piece.piece_name
	type_label.text = "%s - %s" % [piece.piece_type, piece.rarity]
	
	# 更新星级
	_update_star_display(piece.star_level)
	
	# 更新属性
	_update_stats_display(piece)
	
	# 更新技能
	_update_abilities_display(piece)
	
	# 更新协同效果
	_update_synergies_display(piece)
	
	# 更新装备
	_update_equipment_display(piece)

## 更新星级显示
func _update_star_display(star_level: int) -> void:
	# 清除现有星星
	for child in star_container.get_children():
		child.queue_free()
	
	# 添加星星
	for i in range(star_level):
		var star = TextureRect.new()
		star.texture = preload("res://assets/textures/effects/fire.png")
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(20, 20)
		star_container.add_child(star)

## 更新属性显示
func _update_stats_display(piece: ChessPieceEntity) -> void:
	# 清除现有属性
	for child in stats_container.get_children():
		child.queue_free()
	
	# 添加属性
	_add_stat_row("生命值", "%d / %d" % [piece.health, piece.max_health])
	_add_stat_row("攻击力", str(piece.attack_damage))
	_add_stat_row("攻击速度", "%.2f" % piece.attack_speed)
	_add_stat_row("攻击范围", str(piece.attack_range))
	_add_stat_row("护甲", str(piece.armor))
	_add_stat_row("魔抗", str(piece.magic_resist))
	_add_stat_row("暴击几率", "%.0f%%" % (piece.crit_chance * 100))
	_add_stat_row("暴击伤害", "+%.0f%%" % (piece.crit_damage * 100))
	_add_stat_row("闪避几率", "%.0f%%" % (piece.dodge_chance * 100))

## 添加属性行
func _add_stat_row(stat_name: String, stat_value: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = stat_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	hbox.add_child(name_label)
	hbox.add_child(value_label)
	stats_container.add_child(hbox)

## 更新技能显示
func _update_abilities_display(piece: ChessPieceEntity) -> void:
	# 清除现有技能
	for child in abilities_container.get_children():
		child.queue_free()
	
	# 添加技能标题
	var title = Label.new()
	title.text = "技能"
	title.add_theme_font_size_override("font_size", 16)
	abilities_container.add_child(title)
	
	# 添加技能
	if piece.ability:
		var ability_box = VBoxContainer.new()
		ability_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var ability_name = Label.new()
		ability_name.text = piece.ability.ability_name
		ability_name.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		
		var ability_desc = Label.new()
		ability_desc.text = piece.ability.description
		ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		ability_box.add_child(ability_name)
		ability_box.add_child(ability_desc)
		abilities_container.add_child(ability_box)
	else:
		var no_ability = Label.new()
		no_ability.text = "无技能"
		abilities_container.add_child(no_ability)

## 更新协同效果显示
func _update_synergies_display(piece: ChessPieceEntity) -> void:
	# 清除现有协同效果
	for child in synergies_container.get_children():
		child.queue_free()
	
	# 添加协同效果标题
	var title = Label.new()
	title.text = "协同效果"
	title.add_theme_font_size_override("font_size", 16)
	synergies_container.add_child(title)
	
	# 添加协同效果
	if piece.synergies.size() > 0:
		for synergy in piece.synergies:
			var synergy_box = HBoxContainer.new()
			synergy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var synergy_icon = TextureRect.new()
			synergy_icon.texture = load("res://assets/ui/icons/synergy_%s.png" % synergy.to_lower())
			synergy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			synergy_icon.custom_minimum_size = Vector2(20, 20)
			
			var synergy_name = Label.new()
			synergy_name.text = synergy
			
			synergy_box.add_child(synergy_icon)
			synergy_box.add_child(synergy_name)
			synergies_container.add_child(synergy_box)
	else:
		var no_synergy = Label.new()
		no_synergy.text = "无协同效果"
		synergies_container.add_child(no_synergy)

## 更新装备显示
func _update_equipment_display(piece: ChessPieceEntity) -> void:
	# 清除现有装备
	for child in equipment_container.get_children():
		child.queue_free()
	
	# 添加装备标题
	var title = Label.new()
	title.text = "装备"
	title.add_theme_font_size_override("font_size", 16)
	equipment_container.add_child(title)
	
	# 添加装备
	if piece.equipments.size() > 0:
		for equipment in piece.equipments:
			var equip_box = VBoxContainer.new()
			equip_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var equip_name = Label.new()
			equip_name.text = equipment.equipment_name
			equip_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			
			var equip_desc = Label.new()
			equip_desc.text = equipment.description
			equip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
			equip_box.add_child(equip_name)
			equip_box.add_child(equip_desc)
			equipment_container.add_child(equip_box)
	else:
		var no_equipment = Label.new()
		no_equipment.text = "无装备"
		equipment_container.add_child(no_equipment)
