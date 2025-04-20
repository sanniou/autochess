extends BaseHUD
class_name BlacksmithHUD
## 铁匠铺HUD
## 显示铁匠铺相关信息和交互界面

# 铁匠铺服务类型
enum BlacksmithService {
	UPGRADE,   # 升级装备
	REPAIR,    # 修复装备
	REFORGE,   # 重铸装备
	ENCHANT    # 附魔装备
}

# 当前选择的服务
var current_service: BlacksmithService = BlacksmithService.UPGRADE

# 当前选择的装备
var selected_equipment: Dictionary = {}

# 铁匠铺折扣
var discount: float = 0.0

# 初始化
func _initialize() -> void:
	# 获取铁匠铺参数
	var blacksmith_params = GameManager.blacksmith_params
	if blacksmith_params:
		discount = blacksmith_params.get("discount", 0.0)
	
	# 连接服务按钮信号
	if has_node("ServiceContainer"):
		var service_container = get_node("ServiceContainer")
		
		if service_container.has_node("UpgradeButton"):
			service_container.get_node("UpgradeButton").pressed.connect(
				func(): _on_service_button_pressed(BlacksmithService.UPGRADE)
			)
		
		if service_container.has_node("RepairButton"):
			service_container.get_node("RepairButton").pressed.connect(
				func(): _on_service_button_pressed(BlacksmithService.REPAIR)
			)
		
		if service_container.has_node("ReforgeButton"):
			service_container.get_node("ReforgeButton").pressed.connect(
				func(): _on_service_button_pressed(BlacksmithService.REFORGE)
			)
		
		if service_container.has_node("EnchantButton"):
			service_container.get_node("EnchantButton").pressed.connect(
				func(): _on_service_button_pressed(BlacksmithService.ENCHANT)
			)
	
	# 连接操作按钮信号
	if has_node("ActionContainer"):
		var action_container = get_node("ActionContainer")
		
		if action_container.has_node("ConfirmButton"):
			action_container.get_node("ConfirmButton").pressed.connect(_on_confirm_button_pressed)
		
		if action_container.has_node("CancelButton"):
			action_container.get_node("CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新标题
	if has_node("TitleLabel"):
		var title_label = get_node("TitleLabel")
		title_label.text = tr("ui.blacksmith.title")
		
		# 如果有折扣，显示折扣信息
		if discount > 0:
			title_label.text += " (" + tr("ui.blacksmith.discount", [str(int(discount * 100))]) + ")"
	
	# 更新服务描述
	if has_node("ServiceDescriptionLabel"):
		var desc_label = get_node("ServiceDescriptionLabel")
		desc_label.text = _get_service_description(current_service)
	
	# 更新装备列表
	_update_equipment_list()
	
	# 更新服务按钮状态
	_update_service_buttons()
	
	# 更新操作按钮状态
	_update_action_buttons()
	
	# 调用父类方法
	super.update_hud()

# 获取服务描述
func _get_service_description(service: BlacksmithService) -> String:
	match service:
		BlacksmithService.UPGRADE:
			return tr("ui.blacksmith.upgrade_desc")
		BlacksmithService.REPAIR:
			return tr("ui.blacksmith.repair_desc")
		BlacksmithService.REFORGE:
			return tr("ui.blacksmith.reforge_desc")
		BlacksmithService.ENCHANT:
			return tr("ui.blacksmith.enchant_desc")
		_:
			return ""

# 更新装备列表
func _update_equipment_list() -> void:
	# 获取装备容器
	var equipment_container = get_node_or_null("EquipmentContainer")
	if equipment_container == null:
		return
	
	# 清空容器
	for child in equipment_container.get_children():
		child.queue_free()
	
	# 获取玩家装备
	var equipment_manager = GameManager.equipment_manager
	if equipment_manager == null:
		return
	
	var equipments = equipment_manager.get_player_equipments()
	
	# 过滤装备
	var filtered_equipments = []
	
	match current_service:
		BlacksmithService.UPGRADE:
			# 可升级的装备（未达到最高品质）
			for equip in equipments:
				if equip.quality < equipment_manager.MAX_QUALITY:
					filtered_equipments.append(equip)
		
		BlacksmithService.REPAIR:
			# 需要修复的装备（耐久度不满）
			for equip in equipments:
				if equip.durability < equip.max_durability:
					filtered_equipments.append(equip)
		
		BlacksmithService.REFORGE:
			# 可重铸的装备（任何装备）
			filtered_equipments = equipments
		
		BlacksmithService.ENCHANT:
			# 可附魔的装备（未附魔或可重新附魔）
			for equip in equipments:
				if equip.enchantments.size() < equipment_manager.MAX_ENCHANTMENTS:
					filtered_equipments.append(equip)
	
	# 添加装备到容器
	for i in range(filtered_equipments.size()):
		var equip = filtered_equipments[i]
		
		# 创建装备项
		var item = _create_equipment_item(equip, i)
		equipment_container.add_child(item)
	
	# 如果没有可用装备，显示提示
	if filtered_equipments.size() == 0:
		var label = Label.new()
		label.text = tr("ui.blacksmith.no_equipment")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_FILL
		equipment_container.add_child(label)

# 创建装备项
func _create_equipment_item(equipment: Dictionary, index: int) -> Control:
	# 创建装备容器
	var item = Panel.new()
	item.name = "Equipment_" + str(index)
	item.custom_minimum_size = Vector2(120, 150)
	
	# 如果是选中的装备，设置高亮
	if selected_equipment.has("id") and selected_equipment.id == equipment.id:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.5, 0.8, 0.5)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		item.add_theme_stylebox_override("panel", style)
	
	# 创建垂直布局
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_FILL
	vbox.size_flags_vertical = Control.SIZE_FILL
	item.add_child(vbox)
	
	# 创建图标
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if ResourceLoader.exists(equipment.icon_path):
		icon.texture = load(equipment.icon_path)
	
	vbox.add_child(icon)
	
	# 创建名称标签
	var name_label = Label.new()
	name_label.text = equipment.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# 创建品质标签
	var quality_label = Label.new()
	quality_label.text = tr("ui.equipment.quality", [str(equipment.quality)])
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 根据品质设置颜色
	match equipment.quality:
		1:
			quality_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		2:
			quality_label.add_theme_color_override("font_color", Color(0.0, 0.7, 0.0))
		3:
			quality_label.add_theme_color_override("font_color", Color(0.0, 0.0, 1.0))
		4:
			quality_label.add_theme_color_override("font_color", Color(0.7, 0.0, 0.7))
		5:
			quality_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	
	vbox.add_child(quality_label)
	
	# 根据服务类型添加额外信息
	match current_service:
		BlacksmithService.UPGRADE:
			# 显示升级后的品质
			var upgrade_label = Label.new()
			upgrade_label.text = "→ " + tr("ui.equipment.quality", [str(equipment.quality + 1)])
			upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# 设置升级后品质的颜色
			match equipment.quality + 1:
				2:
					upgrade_label.add_theme_color_override("font_color", Color(0.0, 0.7, 0.0))
				3:
					upgrade_label.add_theme_color_override("font_color", Color(0.0, 0.0, 1.0))
				4:
					upgrade_label.add_theme_color_override("font_color", Color(0.7, 0.0, 0.7))
				5:
					upgrade_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
			
			vbox.add_child(upgrade_label)
		
		BlacksmithService.REPAIR:
			# 显示耐久度
			var durability_label = Label.new()
			durability_label.text = tr("ui.equipment.durability", [str(equipment.durability), str(equipment.max_durability)])
			durability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(durability_label)
		
		BlacksmithService.REFORGE:
			# 显示重铸提示
			var reforge_label = Label.new()
			reforge_label.text = tr("ui.blacksmith.reforge_hint")
			reforge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reforge_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.0))
			vbox.add_child(reforge_label)
		
		BlacksmithService.ENCHANT:
			# 显示附魔数量
			var enchant_label = Label.new()
			enchant_label.text = tr("ui.equipment.enchantments", [str(equipment.enchantments.size()), str(GameManager.equipment_manager.MAX_ENCHANTMENTS)])
			enchant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(enchant_label)
	
	# 添加点击事件
	item.gui_input.connect(_on_equipment_item_clicked.bind(equipment))
	
	return item

# 更新服务按钮状态
func _update_service_buttons() -> void:
	if not has_node("ServiceContainer"):
		return
	
	var service_container = get_node("ServiceContainer")
	
	# 更新按钮高亮状态
	for service in BlacksmithService.values():
		var button_name = ""
		
		match service:
			BlacksmithService.UPGRADE:
				button_name = "UpgradeButton"
			BlacksmithService.REPAIR:
				button_name = "RepairButton"
			BlacksmithService.REFORGE:
				button_name = "ReforgeButton"
			BlacksmithService.ENCHANT:
				button_name = "EnchantButton"
		
		if service_container.has_node(button_name):
			var button = service_container.get_node(button_name)
			
			# 设置按钮状态
			if service == current_service:
				button.disabled = true
			else:
				button.disabled = false

# 更新操作按钮状态
func _update_action_buttons() -> void:
	if not has_node("ActionContainer"):
		return
	
	var action_container = get_node("ActionContainer")
	
	# 更新确认按钮状态
	if action_container.has_node("ConfirmButton"):
		var confirm_button = action_container.get_node("ConfirmButton")
		
		# 如果有选中的装备，启用确认按钮
		if selected_equipment.has("id"):
			confirm_button.disabled = false
			
			# 更新按钮文本，显示价格
			var price = _calculate_service_price(current_service, selected_equipment)
			confirm_button.text = tr("ui.blacksmith.confirm", [str(price)])
		else:
			confirm_button.disabled = true
			confirm_button.text = tr("ui.blacksmith.confirm_default")

# 计算服务价格
func _calculate_service_price(service: BlacksmithService, equipment: Dictionary) -> int:
	var base_price = 0
	
	match service:
		BlacksmithService.UPGRADE:
			# 升级价格基于品质
			base_price = equipment.quality * 100
		
		BlacksmithService.REPAIR:
			# 修复价格基于缺失的耐久度
			var missing_durability = equipment.max_durability - equipment.durability
			base_price = missing_durability * 10
		
		BlacksmithService.REFORGE:
			# 重铸价格基于品质
			base_price = equipment.quality * 150
		
		BlacksmithService.ENCHANT:
			# 附魔价格基于品质和当前附魔数量
			base_price = equipment.quality * 200 + equipment.enchantments.size() * 100
	
	# 应用折扣
	if discount > 0:
		base_price = int(base_price * (1.0 - discount))
	
	return max(base_price, 10)  # 最低价格为10金币

# 服务按钮点击处理
func _on_service_button_pressed(service: BlacksmithService) -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 更新当前服务
	current_service = service
	
	# 清除选中的装备
	selected_equipment = {}
	
	# 更新显示
	update_hud()

# 装备项点击处理
func _on_equipment_item_clicked(event: InputEvent, equipment: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 播放选择音效
		play_ui_sound("select.ogg")
		
		# 更新选中的装备
		selected_equipment = equipment
		
		# 更新显示
		update_hud()

# 确认按钮点击处理
func _on_confirm_button_pressed() -> void:
	# 检查是否有选中的装备
	if not selected_equipment.has("id"):
		return
	
	# 计算服务价格
	var price = _calculate_service_price(current_service, selected_equipment)
	
	# 检查玩家金币是否足够
	var player_manager = GameManager.player_manager
	if player_manager == null or player_manager.get_gold() < price:
		# 显示金币不足提示
		EventBus.ui.emit_event("show_toast", [tr("ui.blacksmith.not_enough_gold")])
		return
	
	# 扣除金币
	player_manager.remove_gold(price)
	
	# 执行服务
	var success = _perform_service(current_service, selected_equipment)
	
	if success:
		# 播放成功音效
		play_ui_sound("blacksmith_success.ogg")
		
		# 显示成功提示
		EventBus.ui.emit_event("show_toast", [_get_service_success_message(current_service)])
		
		# 发送装备升级信号
		EventBus.map.emit_event("equipment_upgraded", [selected_equipment, true])
		
		# 清除选中的装备
		selected_equipment = {}
		
		# 更新显示
		update_hud()
	else:
		# 播放失败音效
		play_ui_sound("blacksmith_fail.ogg")
		
		# 显示失败提示
		EventBus.ui.emit_event("show_toast", [_get_service_fail_message(current_service)])
		
		# 发送装备升级信号
		EventBus.map.emit_event("equipment_upgraded", [selected_equipment, false])
	}

# 执行服务
func _perform_service(service: BlacksmithService, equipment: Dictionary) -> bool:
	var equipment_manager = GameManager.equipment_manager
	if equipment_manager == null:
		return false
	
	match service:
		BlacksmithService.UPGRADE:
			# 升级装备
			return equipment_manager.upgrade_equipment(equipment.id)
		
		BlacksmithService.REPAIR:
			# 修复装备
			return equipment_manager.repair_equipment(equipment.id)
		
		BlacksmithService.REFORGE:
			# 重铸装备
			return equipment_manager.reforge_equipment(equipment.id)
		
		BlacksmithService.ENCHANT:
			# 附魔装备
			return equipment_manager.enchant_equipment(equipment.id)
	
	return false

# 获取服务成功消息
func _get_service_success_message(service: BlacksmithService) -> String:
	match service:
		BlacksmithService.UPGRADE:
			return tr("ui.blacksmith.upgrade_success")
		BlacksmithService.REPAIR:
			return tr("ui.blacksmith.repair_success")
		BlacksmithService.REFORGE:
			return tr("ui.blacksmith.reforge_success")
		BlacksmithService.ENCHANT:
			return tr("ui.blacksmith.enchant_success")
		_:
			return tr("ui.blacksmith.service_success")

# 获取服务失败消息
func _get_service_fail_message(service: BlacksmithService) -> String:
	match service:
		BlacksmithService.UPGRADE:
			return tr("ui.blacksmith.upgrade_fail")
		BlacksmithService.REPAIR:
			return tr("ui.blacksmith.repair_fail")
		BlacksmithService.REFORGE:
			return tr("ui.blacksmith.reforge_fail")
		BlacksmithService.ENCHANT:
			return tr("ui.blacksmith.enchant_fail")
		_:
			return tr("ui.blacksmith.service_fail")

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)
