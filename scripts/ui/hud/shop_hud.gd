extends BaseHUD
class_name ShopHUD
## 商店HUD
## 显示商店相关信息，如商品列表、价格等

# 商店管理器引用
var shop_manager = null

# 经济管理器引用
var economy_manager = null

# UI节流器
var ui_throttler: UIThrottler

# 当前商店状态
var _shop_state = {
	"refresh_cost": 0,
	"is_locked": false,
	"last_update_time": 0
}

# 初始化
func _initialize() -> void:
	# 创建 UI 节流器
	ui_throttler = UIThrottler.new({
		"default_interval": 0.2,  # 200ms更新一次
		"high_fps_interval": 0.3,  # 高帧率时300ms更新一次
		"low_fps_interval": 0.1   # 低帧率时100ms更新一次
	})

	# 获取商店管理器
	shop_manager = GameManager.shop_manager

	# 获取经济管理器
	economy_manager = GameManager.economy_manager

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

	# 检查商店状态是否变化
	var current_refresh_cost = shop_manager.get_current_refresh_cost()
	var current_is_locked = shop_manager.is_locked
	var current_time = Time.get_ticks_msec()

	# 如果状态没有变化且上次更新在500ms内，跳过更新
	if current_refresh_cost == _shop_state.refresh_cost and \
	   current_is_locked == _shop_state.is_locked and \
	   current_time - _shop_state.last_update_time < 500:
		return

	# 更新商店状态
	_shop_state.refresh_cost = current_refresh_cost
	_shop_state.is_locked = current_is_locked
	_shop_state.last_update_time = current_time

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

# 进程函数
func _process(delta: float) -> void:
	# 使用节流器控制UI更新频率
	if shop_manager and ui_throttler.should_update("shop_hud", delta):
		# 检查商店状态是否变化
		var current_refresh_cost = shop_manager.get_current_refresh_cost()
		var current_is_locked = shop_manager.is_locked

		# 如果状态变化，更新UI
		if current_refresh_cost != _shop_state.refresh_cost or \
		   current_is_locked != _shop_state.is_locked:
			_update_refresh_button()
			_update_lock_button()

			# 更新商店状态
			_shop_state.refresh_cost = current_refresh_cost
			_shop_state.is_locked = current_is_locked

# 棋子项对象池
var _chess_item_pool = []

# 装备项对象池
var _equipment_item_pool = []

# 更新棋子列表
func _update_chess_list(chess_list: Array) -> void:
	# 获取棋子容器
	var chess_container = get_node_or_null("ChessContainer")
	if chess_container == null:
		return

	# 隐藏所有棋子项
	for item in _chess_item_pool:
		if is_instance_valid(item):
			item.visible = false

	# 添加棋子项
	for i in range(chess_list.size()):
		var chess_data = chess_list[i]

		# 从对象池获取或创建棋子项
		var chess_item
		if i < _chess_item_pool.size() and is_instance_valid(_chess_item_pool[i]):
			chess_item = _chess_item_pool[i]
			_update_chess_item(chess_item, chess_data, i)
		else:
			chess_item = _create_chess_item(chess_data, i)
			chess_container.add_child(chess_item)

			# 添加到对象池
			if i >= _chess_item_pool.size():
				_chess_item_pool.append(chess_item)
			else:
				_chess_item_pool[i] = chess_item

		# 显示棋子项
		chess_item.visible = true

# 更新装备列表
func _update_equipment_list(equipment_list: Array) -> void:
	# 获取装备容器
	var equipment_container = get_node_or_null("EquipmentContainer")
	if equipment_container == null:
		return

	# 隐藏所有装备项
	for item in _equipment_item_pool:
		if is_instance_valid(item):
			item.visible = false

	# 添加装备项
	for i in range(equipment_list.size()):
		var equipment_id = equipment_list[i]

		# 获取装备数据
		var equipment_data = ConfigManager.get_equipment(equipment_id)
		if equipment_data == null:
			continue

		# 从对象池获取或创建装备项
		var equipment_item
		if i < _equipment_item_pool.size() and is_instance_valid(_equipment_item_pool[i]):
			equipment_item = _equipment_item_pool[i]
			_update_equipment_item(equipment_item, equipment_data, i)
		else:
			equipment_item = _create_equipment_item(equipment_data, i)
			equipment_container.add_child(equipment_item)

			# 添加到对象池
			if i >= _equipment_item_pool.size():
				_equipment_item_pool.append(equipment_item)
			else:
				_equipment_item_pool[i] = equipment_item

		# 显示装备项
		equipment_item.visible = true

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
	var player = GameManager.player_manager.get_current_player()
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

# 更新棋子项
func _update_chess_item(item: Control, chess_data: Dictionary, index: int) -> void:
	# 更新棋子名称
	var name_label = item.get_node_or_null("NameLabel")
	if name_label:
		var name_text = tr("chess." + chess_data.id + ".name")
		if name_label.text != name_text:
			name_label.text = name_text

	# 更新棋子图标
	var icon = item.get_node_or_null("Icon")
	if icon:
		var texture_path = "res://assets/images/chess/" + chess_data.id + ".png"
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture != icon.texture:
				icon.texture = texture

	# 更新棋子费用
	var cost_label = item.get_node_or_null("CostLabel")
	if cost_label:
		var cost_text = tr("ui.shop.cost", [str(shop_manager.get_current_chess_cost(chess_data))])
		if cost_label.text != cost_text:
			cost_label.text = cost_text

	# 更新点击事件
	item.gui_input.disconnect(_on_chess_item_clicked) if item.gui_input.is_connected(_on_chess_item_clicked) else null
	item.gui_input.connect(_on_chess_item_clicked.bind(index))

# 更新装备项
func _update_equipment_item(item: Control, equipment_data: Dictionary, index: int) -> void:
	# 更新装备名称
	var name_label = item.get_node_or_null("NameLabel")
	if name_label:
		var name_text = tr("equipment." + equipment_data.id + ".name")
		if name_label.text != name_text:
			name_label.text = name_text

	# 更新装备图标
	var icon = item.get_node_or_null("Icon")
	if icon:
		var texture_path = "res://assets/images/equipment/" + equipment_data.id + ".png"
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			if texture != icon.texture:
				icon.texture = texture

	# 更新装备费用
	var cost_label = item.get_node_or_null("CostLabel")
	if cost_label:
		var cost_text = tr("ui.shop.cost", [str(shop_manager.get_current_equipment_cost(equipment_data))])
		if cost_label.text != cost_text:
			cost_label.text = cost_text

	# 更新点击事件
	item.gui_input.disconnect(_on_equipment_item_clicked) if item.gui_input.is_connected(_on_equipment_item_clicked) else null
	item.gui_input.connect(_on_equipment_item_clicked.bind(index))

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
	# 重置商店状态
	_shop_state.last_update_time = 0

	# 强制更新UI
	ui_throttler.force_update("shop_hud")

	# 更新显示
	update_hud()

	# 播放刷新音效
	AudioManager.play_sfx("shop_refresh.ogg")

# 手动刷新商店处理
func _on_shop_manually_refreshed(cost: int) -> void:
	# 重置商店状态
	_shop_state.last_update_time = 0

	# 强制更新UI
	ui_throttler.force_update("shop_hud")

	# 更新显示
	update_hud()

	# 播放刷新音效
	AudioManager.play_sfx("shop_refresh.ogg")

# 物品购买处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 延迟更新，避免频繁刷新
	await get_tree().create_timer(0.1).timeout

	# 更新显示
	update_hud()

# 物品出售处理
func _on_item_sold(item_data: Dictionary) -> void:
	# 延迟更新，避免频繁刷新
	await get_tree().create_timer(0.1).timeout

	# 更新显示
	update_hud()

# 商店折扣应用处理
func _on_shop_discount_applied(discount_rate: float) -> void:
	# 重置商店状态
	_shop_state.last_update_time = 0

	# 强制更新UI
	ui_throttler.force_update("shop_hud")

	# 更新显示
	update_hud()

	# 显示折扣提示
	var discount_percent = int((1.0 - discount_rate) * 100)
	if discount_percent > 0:
		EventBus.ui.emit_event("show_toast", [tr("ui.shop.discount_applied", [str(discount_percent])]))
	else:
		EventBus.ui.emit_event("show_toast", [tr("ui.shop.discount_removed"]))
