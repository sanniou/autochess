extends Control
## 装备管理场景
## 玩家可以在此管理装备

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var config_manager = get_node("/root/ConfigManager")

# 当前玩家
var current_player = null

# 选中的装备和棋子
var selected_equipment = null
var selected_chess = null

# 初始化
func _ready():
	# 获取当前玩家
	current_player = player_manager.get_current_player()
	
	# 设置标题
	$MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/TitleLabel.text = "装备管理"
	
	# 加载装备列表
	_load_equipment_list()
	
	# 加载棋子列表
	_load_chess_list()
	
	# 连接信号
	EventBus.equipment_equipped.connect(_on_equipment_equipped)
	EventBus.equipment_unequipped.connect(_on_equipment_unequipped)
	EventBus.equipment_created.connect(_on_equipment_created)

# 加载装备列表
func _load_equipment_list():
	# 清空装备列表
	var grid = $MarginContainer/VBoxContainer/ContentPanel/HBoxContainer/EquipmentList/VBoxContainer/EquipmentGrid
	for child in grid.get_children():
		child.queue_free()
	
	# 获取玩家装备
	var equipments = []
	if current_player:
		equipments = current_player.equipments
	
	# 添加装备到列表
	for equipment in equipments:
		var item = _create_equipment_item(equipment)
		grid.add_child(item)

# 加载棋子列表
func _load_chess_list():
	# 清空棋子列表
	var grid = $MarginContainer/VBoxContainer/ContentPanel/HBoxContainer/ChessList/VBoxContainer/ChessGrid
	for child in grid.get_children():
		child.queue_free()
	
	# 获取玩家棋子
	var chess_pieces = []
	if current_player:
		chess_pieces = current_player.chess_pieces
	
	# 添加棋子到列表
	for chess in chess_pieces:
		var item = _create_chess_item(chess)
		grid.add_child(item)

# 创建装备项
func _create_equipment_item(equipment):
	# 复制模板
	var template = $EquipmentItemTemplate
	var item = template.duplicate()
	item.visible = true
	
	# 设置装备图标
	var icon = item.get_node("VBoxContainer/EquipmentIcon")
	var icon_path = "res://assets/images/equipment/" + equipment.icon
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	# 设置装备名称
	var name_label = item.get_node("VBoxContainer/EquipmentName")
	name_label.text = equipment.display_name
	
	# 设置装备类型
	var type_label = item.get_node("VBoxContainer/EquipmentType")
	match equipment.type:
		"weapon":
			type_label.text = "武器"
		"armor":
			type_label.text = "护甲"
		"accessory":
			type_label.text = "饰品"
	
	# 设置装备描述
	var desc_label = item.get_node("VBoxContainer/EquipmentDesc")
	desc_label.text = equipment.description
	
	# 设置选择按钮
	var select_button = item.get_node("VBoxContainer/SelectButton")
	select_button.pressed.connect(_on_equipment_selected.bind(equipment))
	
	# 如果装备已经装备，禁用按钮
	if equipment.current_owner != null:
		select_button.disabled = true
		select_button.text = "已装备"
	
	return item

# 创建棋子项
func _create_chess_item(chess):
	# 复制模板
	var template = $ChessItemTemplate
	var item = template.duplicate()
	item.visible = true
	
	# 设置棋子图标
	var icon = item.get_node("VBoxContainer/ChessIcon")
	var icon_path = "res://assets/images/chess/" + chess.id + ".png"
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	# 设置棋子名称
	var name_label = item.get_node("VBoxContainer/ChessName")
	name_label.text = chess.display_name
	
	# 设置装备槽状态
	var weapon_slot = item.get_node("VBoxContainer/EquipmentSlots/WeaponSlot")
	var armor_slot = item.get_node("VBoxContainer/EquipmentSlots/ArmorSlot")
	var accessory_slot = item.get_node("VBoxContainer/EquipmentSlots/AccessorySlot")
	
	weapon_slot.color = Color(0.8, 0.2, 0.2, 0.3)
	armor_slot.color = Color(0.2, 0.2, 0.8, 0.3)
	accessory_slot.color = Color(0.8, 0.8, 0.2, 0.3)
	
	if chess.weapon_slot:
		weapon_slot.color = Color(0.8, 0.2, 0.2, 0.7)
	if chess.armor_slot:
		armor_slot.color = Color(0.2, 0.2, 0.8, 0.7)
	if chess.accessory_slot:
		accessory_slot.color = Color(0.8, 0.8, 0.2, 0.7)
	
	# 设置选择按钮
	var select_button = item.get_node("VBoxContainer/SelectButton")
	select_button.pressed.connect(_on_chess_selected.bind(chess))
	
	return item

# 装备选择处理
func _on_equipment_selected(equipment):
	selected_equipment = equipment
	
	# 更新信息标签
	if selected_equipment and selected_chess:
		$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "点击装备按钮将 %s 装备到 %s" % [selected_equipment.display_name, selected_chess.display_name]
		
		# 检查是否可以装备
		if _can_equip_to_chess(selected_equipment, selected_chess):
			# 装备到棋子
			_equip_to_chess(selected_equipment, selected_chess)
			
			# 重置选择
			selected_equipment = null
			selected_chess = null
			
			# 更新信息标签
			$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "选择装备和棋子进行装备"
			
			# 重新加载列表
			_load_equipment_list()
			_load_chess_list()
	else:
		$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "已选择装备: %s，请选择棋子" % selected_equipment.display_name

# 棋子选择处理
func _on_chess_selected(chess):
	selected_chess = chess
	
	# 更新信息标签
	if selected_equipment and selected_chess:
		$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "点击装备按钮将 %s 装备到 %s" % [selected_equipment.display_name, selected_chess.display_name]
		
		# 检查是否可以装备
		if _can_equip_to_chess(selected_equipment, selected_chess):
			# 装备到棋子
			_equip_to_chess(selected_equipment, selected_chess)
			
			# 重置选择
			selected_equipment = null
			selected_chess = null
			
			# 更新信息标签
			$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "选择装备和棋子进行装备"
			
			# 重新加载列表
			_load_equipment_list()
			_load_chess_list()
	elif selected_chess and not selected_equipment:
		$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "已选择棋子: %s，请选择装备" % selected_chess.display_name
		
		# 检查是否有已装备的装备
		var has_equipment = false
		if selected_chess.weapon_slot:
			has_equipment = true
			# 卸下武器
			var equipment = selected_chess.unequip_item("weapon")
			if equipment:
				# 重新加载列表
				_load_equipment_list()
				_load_chess_list()
		
		if selected_chess.armor_slot:
			has_equipment = true
			# 卸下护甲
			var equipment = selected_chess.unequip_item("armor")
			if equipment:
				# 重新加载列表
				_load_equipment_list()
				_load_chess_list()
		
		if selected_chess.accessory_slot:
			has_equipment = true
			# 卸下饰品
			var equipment = selected_chess.unequip_item("accessory")
			if equipment:
				# 重新加载列表
				_load_equipment_list()
				_load_chess_list()
		
		if has_equipment:
			# 重置选择
			selected_chess = null
			
			# 更新信息标签
			$MarginContainer/VBoxContainer/FooterPanel/HBoxContainer/InfoLabel.text = "已卸下装备，请选择装备和棋子"

# 检查是否可以装备到棋子
func _can_equip_to_chess(equipment, chess):
	# 检查装备类型
	match equipment.type:
		"weapon":
			return chess.weapon_slot == null
		"armor":
			return chess.armor_slot == null
		"accessory":
			return chess.accessory_slot == null
	
	return false

# 装备到棋子
func _equip_to_chess(equipment, chess):
	# 装备到棋子
	chess.equip_item(equipment)

# 合成按钮处理
func _on_combine_button_pressed():
	# 打开装备合成场景
	GameManager.change_scene("res://scenes/equipment/equipment_combine.tscn")

# 关闭按钮处理
func _on_close_button_pressed():
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 装备装备事件处理
func _on_equipment_equipped(equipment, chess):
	# 重新加载列表
	_load_equipment_list()
	_load_chess_list()

# 装备卸下事件处理
func _on_equipment_unequipped(equipment, chess):
	# 重新加载列表
	_load_equipment_list()
	_load_chess_list()

# 装备创建事件处理
func _on_equipment_created(equipment):
	# 重新加载列表
	_load_equipment_list()
