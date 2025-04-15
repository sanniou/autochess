extends Control
## 装备合成场景
## 玩家可以在此合成装备

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var config_manager = get_node("/root/ConfigManager")

# 当前玩家
var current_player = null

# 选中的装备
var selected_equipment1 = null
var selected_equipment2 = null
var result_equipment = null

# 初始化
func _ready():
	# 获取当前玩家
	current_player = player_manager.get_current_player()
	
	# 设置标题
	$MarginContainer/VBoxContainer/HeaderPanel/TitleLabel.text = "装备合成"
	
	# 加载装备列表
	_load_equipment_list()
	
	# 加载合成配方
	_load_recipe_list()
	
	# 清空合成区域
	_clear_combine_area()
	
	# 连接信号
	EventBus.equipment_created.connect(_on_equipment_created)
	EventBus.equipment_combined.connect(_on_equipment_combined)

# 加载装备列表
func _load_equipment_list():
	# 清空装备列表
	var grid = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/EquipmentList/VBoxContainer/EquipmentGrid
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

# 加载合成配方
func _load_recipe_list():
	# 清空配方列表
	var grid = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/RecipeList/VBoxContainer/RecipeGrid
	for child in grid.get_children():
		child.queue_free()
	
	# 获取所有装备配置
	var all_equipments = config_manager.get_all_equipments()
	
	# 添加配方到列表
	for equipment_id in all_equipments:
		var equipment_data = all_equipments[equipment_id]
		
		# 检查是否有合成配方
		if equipment_data.has("recipe") and equipment_data.recipe.size() >= 2:
			var recipe_item = _create_recipe_item(equipment_data)
			grid.add_child(recipe_item)

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
	
	# 设置选择按钮
	var select_button = item.get_node("VBoxContainer/SelectButton")
	select_button.pressed.connect(_on_equipment_selected.bind(equipment))
	
	return item

# 创建配方项
func _create_recipe_item(equipment_data):
	# 复制模板
	var template = $RecipeItemTemplate
	var item = template.duplicate()
	item.visible = true
	
	# 设置配方材料图标
	var ingredient1 = item.get_node("HBoxContainer/Ingredient1")
	var ingredient2 = item.get_node("HBoxContainer/Ingredient2")
	
	if equipment_data.recipe.size() >= 2:
		var ingredient1_data = config_manager.get_equipment(equipment_data.recipe[0])
		var ingredient2_data = config_manager.get_equipment(equipment_data.recipe[1])
		
		if ingredient1_data and ingredient2_data:
			var icon1_path = "res://assets/images/equipment/" + ingredient1_data.icon
			var icon2_path = "res://assets/images/equipment/" + ingredient2_data.icon
			
			if ResourceLoader.exists(icon1_path):
				ingredient1.texture = load(icon1_path)
			if ResourceLoader.exists(icon2_path):
				ingredient2.texture = load(icon2_path)
	
	# 设置结果图标
	var result = item.get_node("HBoxContainer/Result")
	var result_path = "res://assets/images/equipment/" + equipment_data.icon
	if ResourceLoader.exists(result_path):
		result.texture = load(result_path)
	
	return item

# 清空合成区域
func _clear_combine_area():
	# 清空选中的装备
	selected_equipment1 = null
	selected_equipment2 = null
	result_equipment = null
	
	# 清空合成区域
	var slot1 = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/Slot1
	var slot2 = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/Slot2
	var result_slot = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/ResultSlot
	
	for child in slot1.get_children():
		child.queue_free()
	for child in slot2.get_children():
		child.queue_free()
	for child in result_slot.get_children():
		child.queue_free()
	
	# 禁用合成按钮
	$MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/CombineButton.disabled = true

# 更新合成区域
func _update_combine_area():
	# 清空合成区域
	var slot1 = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/Slot1
	var slot2 = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/Slot2
	var result_slot = $MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/ResultSlot
	
	for child in slot1.get_children():
		child.queue_free()
	for child in slot2.get_children():
		child.queue_free()
	for child in result_slot.get_children():
		child.queue_free()
	
	# 添加选中的装备
	if selected_equipment1:
		var item1 = _create_equipment_preview(selected_equipment1)
		slot1.add_child(item1)
	
	if selected_equipment2:
		var item2 = _create_equipment_preview(selected_equipment2)
		slot2.add_child(item2)
	
	# 检查是否可以合成
	result_equipment = null
	if selected_equipment1 and selected_equipment2:
		var result_id = selected_equipment1.get_combine_result(selected_equipment2)
		if result_id.is_empty():
			result_id = selected_equipment2.get_combine_result(selected_equipment1)
		
		if not result_id.is_empty():
			var result_data = config_manager.get_equipment(result_id)
			if result_data:
				# 创建结果预览
				var result_preview = _create_equipment_result_preview(result_data)
				result_slot.add_child(result_preview)
				
				# 启用合成按钮
				$MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/CombineButton.disabled = false
				
				# 保存结果ID
				result_equipment = result_id
				return
	
	# 禁用合成按钮
	$MarginContainer/VBoxContainer/CombinePanel/HBoxContainer/CombineArea/CombineButton.disabled = true

# 创建装备预览
func _create_equipment_preview(equipment):
	var preview = VBoxContainer.new()
	
	# 创建图标
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED
	
	var icon_path = "res://assets/images/equipment/" + equipment.icon
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	preview.add_child(icon)
	
	# 创建名称
	var name_label = Label.new()
	name_label.text = equipment.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(name_label)
	
	# 创建类型
	var type_label = Label.new()
	match equipment.type:
		"weapon":
			type_label.text = "武器"
		"armor":
			type_label.text = "护甲"
		"accessory":
			type_label.text = "饰品"
	type_label.theme_override_font_sizes = {
		"font_size": 12
	}
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(type_label)
	
	return preview

# 创建装备结果预览
func _create_equipment_result_preview(equipment_data):
	var preview = VBoxContainer.new()
	
	# 创建图标
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED
	
	var icon_path = "res://assets/images/equipment/" + equipment_data.icon
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	preview.add_child(icon)
	
	# 创建名称
	var name_label = Label.new()
	name_label.text = equipment_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(name_label)
	
	# 创建类型
	var type_label = Label.new()
	match equipment_data.type:
		"weapon":
			type_label.text = "武器"
		"armor":
			type_label.text = "护甲"
		"accessory":
			type_label.text = "饰品"
	type_label.theme_override_font_sizes = {
		"font_size": 12
	}
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(type_label)
	
	return preview

# 装备选择处理
func _on_equipment_selected(equipment):
	if selected_equipment1 == null:
		selected_equipment1 = equipment
	elif selected_equipment2 == null and selected_equipment1 != equipment:
		selected_equipment2 = equipment
	elif selected_equipment1 == equipment:
		selected_equipment1 = null
	elif selected_equipment2 == equipment:
		selected_equipment2 = null
	
	# 更新合成区域
	_update_combine_area()

# 合成按钮处理
func _on_combine_button_pressed():
	if selected_equipment1 and selected_equipment2 and result_equipment:
		# 合成装备
		equipment_manager.combine_equipments(selected_equipment1, selected_equipment2)
		
		# 清空合成区域
		_clear_combine_area()
		
		# 重新加载装备列表
		_load_equipment_list()

# 关闭按钮处理
func _on_close_button_pressed():
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 装备创建事件处理
func _on_equipment_created(equipment):
	# 重新加载装备列表
	_load_equipment_list()

# 装备合成事件处理
func _on_equipment_combined(equipment1, equipment2, result):
	# 重新加载装备列表
	_load_equipment_list()
	
	# 清空合成区域
	_clear_combine_area()
