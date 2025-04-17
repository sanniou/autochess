extends BaseHUD
class_name ShopHUD
## 商店HUD
## 显示商店相关信息，如商品列表、价格等

# 商店管理器引用
var shop_manager = null

# 经济管理器引用
var economy_manager = null

# 初始化
func _initialize() -> void:
	# 获取商店管理器
	shop_manager = game_manager.shop_manager
	
	# 获取经济管理器
	economy_manager = game_manager.economy_manager
	
	if shop_manager == null:
		EventBus.debug.emit_event("debug_message", ["无法获取商店管理器", 1])
		return
	
	# 连接商店信号
	EventBus.economy.connect_event("shop_refreshed", _on_shop_refreshed)
	EventBus.economy.connect_event("shop_manually_refreshed", _on_shop_manually_refreshed)
	EventBus.economy.connect_event("item_purchased", _on_item_purchased)
	EventBus.economy.connect_event("item_sold", _on_item_sold)
	EventBus.economy.connect_event("shop_discount_applied", _on_shop_discount_applied)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	if shop_manager == null:
		return
	
	# 获取商店物品
	var shop_items = shop_manager.get_shop_items()
	
	# 更新棋子列表
	_update_chess_list(shop_items.chess)
	
	# 更新装备列表
	_update_equipment_list(shop_items.equipment)
	
	# 更新刷新按钮
	_update_refresh_button()
	
	# 更新锁定按钮
	_update_lock_button()
	
	# 调用父类方法
	super.update_hud()

# 更新棋子列表
func _update_chess_list(chess_list: Array) -> void:
	# 获取棋子容器
	var chess_container = get_node_or_null("ChessContainer")
	if chess_container == null:
		return
	
	# 清空容器
	for child in chess_container.get_children():
		child.queue_free()
	
	# 添加棋子项
	for i in range(chess_list.size()):
		var chess_data = chess_list[i]
		
		# 创建棋子项
		var chess_item = _create_chess_item(chess_data, i)
		chess_container.add_child(chess_item)

# 更新装备列表
func _update_equipment_list(equipment_list: Array) -> void:
	# 获取装备容器
	var equipment_container = get_node_or_null("EquipmentContainer")
	if equipment_container == null:
		return
	
	# 清空容器
	for child in equipment_container.get_children():
		child.queue_free()
	
	# 添加装备项
	for i in range(equipment_list.size()):
		var equipment_id = equipment_list[i]
		
		# 获取装备数据
		var equipment_data = config_manager.get_equipment(equipment_id)
		if equipment_data == null:
			continue
		
		# 创建装备项
		var equipment_item = _create_equipment_item(equipment_data, i)
		equipment_container.add_child(equipment_item)

# 更新刷新按钮
func _update_refresh_button() -> void:
	# 获取刷新按钮
	var refresh_button = get_node_or_null("RefreshButton")
	if refresh_button == null:
		return
	
	# 获取刷新费用
	var refresh_cost = shop_manager.get_current_refresh_cost()
	
	# 更新按钮文本
	refresh_button.text = tr("ui.shop.refresh", [str(refresh_cost)])
	
	# 检查玩家金币是否足够
	var player = game_manager.player_manager.get_current_player()
	if player and player.gold < refresh_cost:
		refresh_button.disabled = true
	else:
		refresh_button.disabled = false

# 更新锁定按钮
func _update_lock_button() -> void:
	# 获取锁定按钮
	var lock_button = get_node_or_null("LockButton")
	if lock_button == null:
		return
	
	# 更新按钮文本
	if shop_manager.is_locked:
		lock_button.text = tr("ui.shop.unlock")
	else:
		lock_button.text = tr("ui.shop.lock")

# 创建棋子项
func _create_chess_item(chess_data: Dictionary, index: int) -> Control:
	# 创建棋子项容器
	var item = Panel.new()
	item.name = "ChessItem_" + str(index)
	item.custom_minimum_size = Vector2(120, 150)
	
	# 创建棋子名称标签
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = tr("chess." + chess_data.id + ".name")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(120, 30)
	name_label.position = Vector2(0, 0)
	
	# 创建棋子图标
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/images/chess/" + chess_data.id + ".png")
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(80, 80)
	icon.position = Vector2(20, 30)
	
	# 创建棋子费用标签
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.text = tr("ui.shop.cost", [str(shop_manager.get_current_chess_cost(chess_data))])
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.custom_minimum_size = Vector2(120, 30)
	cost_label.position = Vector2(0, 120)
	
	# 添加子节点
	item.add_child(name_label)
	item.add_child(icon)
	item.add_child(cost_label)
	
	# 添加点击事件
	item.gui_input.connect(_on_chess_item_clicked.bind(index))
	
	return item

# 创建装备项
func _create_equipment_item(equipment_data: Dictionary, index: int) -> Control:
	# 创建装备项容器
	var item = Panel.new()
	item.name = "EquipmentItem_" + str(index)
	item.custom_minimum_size = Vector2(120, 150)
	
	# 创建装备名称标签
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = tr("equipment." + equipment_data.id + ".name")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(120, 30)
	name_label.position = Vector2(0, 0)
	
	# 创建装备图标
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/images/equipment/" + equipment_data.id + ".png")
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(80, 80)
	icon.position = Vector2(20, 30)
	
	# 创建装备费用标签
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.text = tr("ui.shop.cost", [str(shop_manager.get_current_equipment_cost(equipment_data))])
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.custom_minimum_size = Vector2(120, 30)
	cost_label.position = Vector2(0, 120)
	
	# 添加子节点
	item.add_child(name_label)
	item.add_child(icon)
	item.add_child(cost_label)
	
	# 添加点击事件
	item.gui_input.connect(_on_equipment_item_clicked.bind(index))
	
	return item

# 棋子项点击处理
func _on_chess_item_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 购买棋子
		var chess_piece = shop_manager.purchase_chess(index)
		
		if chess_piece == null:
			# 购买失败，显示提示
			EventBus.ui.emit_event("show_toast", [tr("ui.shop.purchase_failed"]))
		else:
			# 购买成功，播放音效
			AudioManager.play_sfx("purchase_success.ogg")

# 装备项点击处理
func _on_equipment_item_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 购买装备
		var equipment = shop_manager.purchase_equipment(index)
		
		if equipment == null:
			# 购买失败，显示提示
			EventBus.ui.emit_event("show_toast", [tr("ui.shop.purchase_failed"]))
		else:
			# 购买成功，播放音效
			AudioManager.play_sfx("purchase_success.ogg")

# 商店刷新处理
func _on_shop_refreshed() -> void:
	# 更新显示
	update_hud()
	
	# 播放刷新音效
	AudioManager.play_sfx("shop_refresh.ogg")

# 手动刷新商店处理
func _on_shop_manually_refreshed(cost: int) -> void:
	# 更新显示
	update_hud()
	
	# 播放刷新音效
	AudioManager.play_sfx("shop_refresh.ogg")

# 物品购买处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 更新显示
	update_hud()

# 物品出售处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 更新显示
	update_hud()

# 商店折扣应用处理
func _on_shop_discount_applied(discount_rate: float) -> void:
	# 更新显示
	update_hud()
	
	# 显示折扣提示
	var discount_percent = int((1.0 - discount_rate) * 100)
	if discount_percent > 0:
		EventBus.ui.emit_event("show_toast", [tr("ui.shop.discount_applied", [str(discount_percent])]))
	else:
		EventBus.ui.emit_event("show_toast", [tr("ui.shop.discount_removed"]))
