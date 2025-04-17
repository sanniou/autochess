extends Control
## 装备测试场景
## 用于测试装备系统的功能

# 引用
@onready var equipment_list = $EquipmentPanel/VBoxContainer/EquipmentList/ScrollContainer/VBoxContainer
@onready var chess_list = $ChessPanel/VBoxContainer/ChessList/ScrollContainer/VBoxContainer
@onready var effect_list = $EffectPanel/VBoxContainer/EffectList/ScrollContainer/VBoxContainer
@onready var status_label = $StatusPanel/VBoxContainer/StatusLabel

# 装备场景
var equipment_scene = preload("res://scenes/equipment/equipment_item.tscn")
var chess_piece_scene = preload("res://scenes/chess/chess_piece.tscn")

# 当前选中的装备和棋子
var selected_equipment: Equipment = null
var selected_chess: ChessPiece = null

# 测试装备数据
var test_equipments = [
	"sword", "bow", "staff", "armor", "cloak", "amulet", "gloves",
	"giant_sword", "rapid_bow", "arcane_staff", "plate_armor", "dragon_cloak", "shadow_amulet", "assassin_gloves"
]

# 测试棋子数据
var test_chess_pieces = [
	{
		"id": "warrior",
		"name": "战士",
		"description": "近战物理攻击单位",
		"cost": 1,
		"health": 100,
		"attack_damage": 10,
		"attack_speed": 1.0,
		"attack_range": 1,
		"armor": 5,
		"magic_resist": 0,
		"move_speed": 300,
		"synergies": ["fighter", "human"]
	},
	{
		"id": "archer",
		"name": "弓箭手",
		"description": "远程物理攻击单位",
		"cost": 2,
		"health": 80,
		"attack_damage": 15,
		"attack_speed": 0.8,
		"attack_range": 3,
		"armor": 0,
		"magic_resist": 0,
		"move_speed": 280,
		"synergies": ["ranger", "elf"]
	},
	{
		"id": "mage",
		"name": "法师",
		"description": "远程魔法攻击单位",
		"cost": 3,
		"health": 70,
		"attack_damage": 8,
		"attack_speed": 0.7,
		"attack_range": 4,
		"armor": 0,
		"magic_resist": 10,
		"move_speed": 270,
		"synergies": ["mage", "human"]
	}
]

# 初始化
func _ready():
	# 连接信号
	EventBus.connect("equipment_equipped", _on_equipment_equipped)
	EventBus.connect("equipment_unequipped", _on_equipment_unequipped)
	EventBus.connect("equipment_effect_triggered", _on_equipment_effect_triggered)
	EventBus.connect("equipment_combined", _on_equipment_combined)
	EventBus.connect("equipment_combine_animation_started", _on_equipment_combine_animation_started)
	EventBus.connect("equipment_combine_animation_completed", _on_equipment_combine_animation_completed)

	# 加载装备列表
	_load_equipment_list()

	# 加载棋子列表
	_load_chess_list()

	# 更新状态标签
	_update_status_label()

# 加载装备列表
func _load_equipment_list():
	# 清空列表
	for child in equipment_list.get_children():
		child.queue_free()

	# 获取装备管理器
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")

	# 添加测试装备
	for equipment_id in test_equipments:
		var equipment = equipment_manager.get_equipment(equipment_id)
		if equipment:
			var item = _create_equipment_item(equipment)
			equipment_list.add_child(item)

# 加载棋子列表
func _load_chess_list():
	# 清空列表
	for child in chess_list.get_children():
		child.queue_free()

	# 添加测试棋子
	for piece_data in test_chess_pieces:
		var piece = chess_piece_scene.instantiate()
		piece.initialize(piece_data)

		var item = _create_chess_item(piece)
		chess_list.add_child(item)

# 创建装备项
func _create_equipment_item(equipment: Equipment):
	var item = HBoxContainer.new()

	# 创建图标
	var icon = TextureRect.new()
	icon.texture = load("res://assets/images/equipment/placeholder.png")  # 使用占位图标
	icon.custom_minimum_size = Vector2(32, 32)
	item.add_child(icon)

	# 创建名称标签
	var name_label = Label.new()
	name_label.text = equipment.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	# 创建选择按钮
	var select_button = Button.new()
	select_button.text = "选择"
	select_button.pressed.connect(_on_equipment_selected.bind(equipment))
	item.add_child(select_button)

	return item

# 创建棋子项
func _create_chess_item(chess: ChessPiece):
	var item = HBoxContainer.new()

	# 创建图标
	var icon = TextureRect.new()
	icon.texture = load("res://assets/images/chess/placeholder.png")  # 使用占位图标
	icon.custom_minimum_size = Vector2(32, 32)
	item.add_child(icon)

	# 创建名称标签
	var name_label = Label.new()
	name_label.text = chess.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	# 创建选择按钮
	var select_button = Button.new()
	select_button.text = "选择"
	select_button.pressed.connect(_on_chess_selected.bind(chess))
	item.add_child(select_button)

	return item

# 创建效果项
func _create_effect_item(effect_data: Dictionary):
	var item = HBoxContainer.new()

	# 创建名称标签
	var name_label = Label.new()
	name_label.text = effect_data.description
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)

	return item

# 装备选择处理
func _on_equipment_selected(equipment: Equipment):
	selected_equipment = equipment
	_update_status_label()

	# 显示可能的合成结果
	_show_possible_combinations(equipment)

# 棋子选择处理
func _on_chess_selected(chess: ChessPiece):
	selected_chess = chess
	_update_status_label()
	_update_effect_list()

# 装备按钮处理
func _on_equip_button_pressed():
	if selected_equipment and selected_chess:
		# 装备到棋子
		selected_chess.equip_item(selected_equipment)

		# 更新状态
		_update_status_label()
		_update_effect_list()

# 卸下按钮处理
func _on_unequip_button_pressed():
	if selected_chess:
		# 获取装备槽位
		var slot = $EquipPanel/VBoxContainer/SlotSelection/OptionButton.get_item_text(
			$EquipPanel/VBoxContainer/SlotSelection/OptionButton.selected
		)

		# 卸下装备
		selected_chess.unequip_item(slot.to_lower())

		# 更新状态
		_update_status_label()
		_update_effect_list()

# 触发效果按钮处理
func _on_trigger_effect_button_pressed():
	if selected_chess:
		# 模拟攻击触发
		selected_chess.emit_signal("ability_activated", null)

		# 模拟受伤触发
		selected_chess.emit_signal("health_changed", selected_chess.current_health, selected_chess.current_health - 10)

		# 模拟闪避触发
		selected_chess.emit_signal("dodge_successful", null)

		# 模拟暴击触发
		selected_chess.emit_signal("critical_hit", null, 20)

		# 更新状态
		_update_status_label()

# 装备装备事件处理
func _on_equipment_equipped(equipment: Equipment, chess: ChessPiece):
	if chess == selected_chess:
		_update_status_label()
		_update_effect_list()

# 卸下装备事件处理
func _on_equipment_unequipped(equipment: Equipment, chess: ChessPiece):
	if chess == selected_chess:
		_update_status_label()
		_update_effect_list()

# 装备效果触发事件处理
func _on_equipment_effect_triggered(equipment: Equipment, effect_data: Dictionary):
	# 添加效果到列表
	var item = _create_effect_item(effect_data)
	effect_list.add_child(item)

	# 更新状态
	_update_status_label()

# 装备合成事件处理
func _on_equipment_combined(equipment1: Equipment, equipment2: Equipment, result: Equipment):
	# 更新装备列表
	_load_equipment_list()

	# 更新状态
	_update_status_label()

	# 显示合成结果提示
	var message = "合成成功: %s + %s = %s" % [equipment1.display_name, equipment2.display_name, result.display_name]
	print(message)

	# 选中合成结果
	selected_equipment = result

# 装备合成动画开始事件处理
func _on_equipment_combine_animation_started(equipment1: Equipment, equipment2: Equipment, result: Equipment):
	# 创建合成动画容器
	var animation_container = Control.new()
	animation_container.name = "CombineAnimationContainer"
	animation_container.size = Vector2(200, 200)
	animation_container.position = Vector2(get_viewport_rect().size / 2 - Vector2(100, 100))
	add_child(animation_container)

	# 创建装备图标
	var icon1 = ColorRect.new()
	icon1.color = Color(0.8, 0.8, 0.8)
	icon1.size = Vector2(50, 50)
	icon1.position = Vector2(25, 75)
	animation_container.add_child(icon1)

	var icon2 = ColorRect.new()
	icon2.color = Color(0.8, 0.8, 0.8)
	icon2.size = Vector2(50, 50)
	icon2.position = Vector2(125, 75)
	animation_container.add_child(icon2)

	var result_icon = ColorRect.new()
	result_icon.color = Color(1.0, 0.8, 0.0)
	result_icon.size = Vector2(60, 60)
	result_icon.position = Vector2(70, 70)
	result_icon.modulate = Color(1, 1, 1, 0)
	animation_container.add_child(result_icon)

	# 创建装备名称标签
	var label1 = Label.new()
	label1.text = equipment1.display_name
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label1.size = Vector2(80, 20)
	label1.position = Vector2(10, 130)
	animation_container.add_child(label1)

	var label2 = Label.new()
	label2.text = equipment2.display_name
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label2.size = Vector2(80, 20)
	label2.position = Vector2(110, 130)
	animation_container.add_child(label2)

	var result_label = Label.new()
	result_label.text = result.display_name
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.size = Vector2(100, 20)
	result_label.position = Vector2(50, 40)
	result_label.modulate = Color(1, 1, 1, 0)
	animation_container.add_child(result_label)

	# 创建加号标签
	var plus_label = Label.new()
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.size = Vector2(20, 20)
	plus_label.position = Vector2(90, 90)
	animation_container.add_child(plus_label)

	# 创建动画
	var tween = create_tween()
	tween.tween_property(icon1, "position", Vector2(60, 75), 0.5)
	tween.parallel().tween_property(icon2, "position", Vector2(90, 75), 0.5)
	tween.tween_property(plus_label, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(result_icon, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(result_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_property(result_icon, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(result_icon, "scale", Vector2(1.0, 1.0), 0.2)

# 装备合成动画完成事件处理
func _on_equipment_combine_animation_completed(equipment1: Equipment, equipment2: Equipment, result: Equipment):
	# 移除合成动画容器
	if has_node("CombineAnimationContainer"):
		var container = get_node("CombineAnimationContainer")
		var tween = create_tween()
		tween.tween_property(container, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(container.queue_free)

# 更新效果列表
func _update_effect_list():
	# 清空列表
	for child in effect_list.get_children():
		child.queue_free()

	if selected_chess:
		# 获取所有效果
		var effects = []

		# 获取装备效果
		if selected_chess.weapon_slot:
			effects.append_array(selected_chess.weapon_slot.effects)
		if selected_chess.armor_slot:
			effects.append_array(selected_chess.armor_slot.effects)
		if selected_chess.accessory_slot:
			effects.append_array(selected_chess.accessory_slot.effects)

		# 获取状态效果
		if selected_chess.status_effect_manager:
			var status_effects = selected_chess.status_effect_manager.get_all_effects()
			for effect in status_effects:
				effects.append({
					"description": effect.name + ": " + effect.description + " (" + effect.get_remaining_time_text() + ")"
				})

		# 添加效果到列表
		for effect in effects:
			var item = _create_effect_item(effect)
			effect_list.add_child(item)

# 更新状态标签
func _update_status_label():
	var status_text = ""

	if selected_equipment:
		status_text += "选中装备: " + selected_equipment.display_name + "\n"
		status_text += "类型: " + selected_equipment.type + "\n"
		status_text += "稀有度: " + selected_equipment.rarity + "\n"
		status_text += "属性: "

		for stat in selected_equipment.stats:
			status_text += stat + ": " + str(selected_equipment.stats[stat]) + ", "

		status_text += "\n"

	if selected_chess:
		status_text += "选中棋子: " + selected_chess.display_name + "\n"
		status_text += "生命值: " + str(selected_chess.current_health) + "/" + str(selected_chess.max_health) + "\n"
		status_text += "攻击力: " + str(selected_chess.attack_damage) + "\n"
		status_text += "攻击速度: " + str(selected_chess.attack_speed) + "\n"
		status_text += "护甲: " + str(selected_chess.armor) + "\n"
		status_text += "魔抗: " + str(selected_chess.magic_resist) + "\n"
		status_text += "装备: "

		if selected_chess.weapon_slot:
			status_text += "武器: " + selected_chess.weapon_slot.display_name + ", "

		if selected_chess.armor_slot:
			status_text += "护甲: " + selected_chess.armor_slot.display_name + ", "

		if selected_chess.accessory_slot:
			status_text += "饰品: " + selected_chess.accessory_slot.display_name

	status_label.text = status_text

# 重置按钮处理
func _on_reset_button_pressed():
	# 重置选择
	selected_equipment = null
	selected_chess = null

	# 清空效果列表
	for child in effect_list.get_children():
		child.queue_free()

	# 清空合成结果列表
	if has_node("CombineResultsList"):
		var combine_list = get_node("CombineResultsList")
		for child in combine_list.get_children():
			child.queue_free()

	# 重新加载列表
	_load_equipment_list()
	_load_chess_list()

	# 更新状态
	_update_status_label()

# 返回按钮处理
func _on_back_button_pressed():
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 显示可能的合成结果
func _show_possible_combinations(equipment: Equipment):
	# 获取装备管理器
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")

	# 获取可能的合成结果
	var combinations = equipment_manager.get_possible_combinations(equipment)

	# 创建合成结果列表
	if has_node("CombineResultsList"):
		var combine_list = get_node("CombineResultsList")
		for child in combine_list.get_children():
			child.queue_free()
	else:
		var combine_list = VBoxContainer.new()
		combine_list.name = "CombineResultsList"
		combine_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combine_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		combine_list.position = Vector2(500, 100)
		combine_list.size = Vector2(300, 400)
		add_child(combine_list)

		# 添加标题
		var title = Label.new()
		title.text = "可能的合成结果"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combine_list.add_child(title)

	# 添加合成结果
	var combine_list = get_node("CombineResultsList")
	if combinations.size() > 0:
		for combination in combinations:
			var item = _create_combination_item(equipment, combination.ingredient, combination.result)
			combine_list.add_child(item)
	else:
		var no_result = Label.new()
		no_result.text = "没有可用的合成结果"
		no_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combine_list.add_child(no_result)

# 创建合成结果项
func _create_combination_item(equipment1: Equipment, equipment2: Equipment, result: Equipment):
	var item = HBoxContainer.new()

	# 创建第一个装备名称
	var name1 = Label.new()
	name1.text = equipment1.display_name
	name1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name1)

	# 创建加号
	var plus = Label.new()
	plus.text = "+"
	item.add_child(plus)

	# 创建第二个装备名称
	var name2 = Label.new()
	name2.text = equipment2.display_name
	name2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name2)

	# 创建等号
	var equals = Label.new()
	equals.text = "="
	item.add_child(equals)

	# 创建结果装备名称
	var result_name = Label.new()
	result_name.text = result.display_name
	result_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(result_name)

	# 创建合成按钮
	var combine_button = Button.new()
	combine_button.text = "合成"
	combine_button.pressed.connect(_on_combine_button_pressed.bind(equipment1, equipment2))
	item.add_child(combine_button)

	return item

# 合成按钮处理
func _on_combine_button_pressed(equipment1: Equipment, equipment2: Equipment):
	# 获取装备管理器
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")

	# 合成装备
	var result = equipment_manager.combine_equipments(equipment1, equipment2)

	if result:
		# 选中合成结果
		selected_equipment = result

		# 更新状态
		_update_status_label()

		# 更新装备列表
		_load_equipment_list()

		# 更新合成结果列表
		_show_possible_combinations(result)
