extends BaseHUD
class_name AltarHUD
## 祭坛HUD
## 显示祭坛相关信息和交互界面

# 祭坛管理器引用
var altar_manager = null

# 当前祭坛类型
var altar_type: String = ""

# 初始化
func _initialize() -> void:
	# 获取祭坛管理器
	altar_manager = GameManager.altar_manager
	
	# 获取祭坛类型
	altar_type = GameManager.altar_params.get("altar_type", "")
	
	# 连接信号
	if has_node("SacrificeButton"):
		get_node("SacrificeButton").pressed.connect(_on_sacrifice_button_pressed)
	
	if has_node("CancelButton"):
		get_node("CancelButton").pressed.connect(_on_cancel_button_pressed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新祭坛标题
	if has_node("TitleLabel"):
		var title_label = get_node("TitleLabel")
		title_label.text = tr("ui.altar." + altar_type)
	
	# 更新祭坛描述
	if has_node("DescriptionLabel"):
		var desc_label = get_node("DescriptionLabel")
		desc_label.text = tr("ui.altar." + altar_type + "_desc")
	
	# 更新祭坛图标
	if has_node("AltarIcon"):
		var altar_icon = get_node("AltarIcon")
		var icon_path = "res://assets/images/altar/" + altar_type + ".png"
		if ResourceLoader.exists(icon_path):
			altar_icon.texture = load(icon_path)
	
	# 更新可牺牲物品列表
	_update_sacrifice_items()
	
	# 调用父类方法
	super.update_hud()

# 更新可牺牲物品列表
func _update_sacrifice_items() -> void:
	# 获取物品容器
	var items_container = get_node_or_null("ItemsContainer")
	
	# 清空容器
	for child in items_container.get_children():
		child.queue_free()
	
	# 根据祭坛类型获取可牺牲物品
	var sacrifice_items = []
	
	match altar_type:
		"health":
			# 可以牺牲棋子获得生命值
			sacrifice_items = _get_chess_sacrifice_items()
		"attack":
			# 可以牺牲装备获得攻击力
			sacrifice_items = _get_equipment_sacrifice_items("attack")
		"defense":
			# 可以牺牲装备获得防御力
			sacrifice_items = _get_equipment_sacrifice_items("defense")
		"ability":
			# 可以牺牲法术书获得技能强化
			sacrifice_items = _get_spellbook_sacrifice_items()
		"gold":
			# 可以牺牲遗物获得金币
			sacrifice_items = _get_relic_sacrifice_items()
	
	# 添加物品到容器
	for i in range(sacrifice_items.size()):
		var item_data = sacrifice_items[i]
		
		# 创建物品项
		var item = _create_sacrifice_item(item_data, i)
		items_container.add_child(item)

# 获取棋子牺牲物品
func _get_chess_sacrifice_items() -> Array:
	var chess_manager = GameManager.chess_manager
	
	# 获取玩家拥有的棋子
	var chess_pieces = chess_manager.get_player_chess_pieces()
	var sacrifice_items = []
	
	for piece in chess_pieces:
		if not piece.is_on_board:  # 只能牺牲未上场的棋子
			sacrifice_items.append({
				"type": "chess",
				"id": piece.id,
				"name": piece.name,
				"star_level": piece.star_level,
				"icon_path": piece.icon_path,
				"value": piece.max_health * 0.5  # 牺牲棋子获得的生命值
			})
	
	return sacrifice_items

# 获取装备牺牲物品
func _get_equipment_sacrifice_items(stat_type: String) -> Array:
	var equipment_manager = GameManager.equipment_manager
	
	# 获取玩家拥有的装备
	var equipments = equipment_manager.get_player_equipments()
	var sacrifice_items = []
	
	for equip in equipments:
		if not equip.is_equipped:  # 只能牺牲未装备的装备
			var value = 0
			
			# 根据装备属性计算价值
			if stat_type == "attack":
				value = equip.attack_bonus * 2
			elif stat_type == "defense":
				value = equip.defense_bonus * 2
			
			sacrifice_items.append({
				"type": "equipment",
				"id": equip.id,
				"name": equip.name,
				"quality": equip.quality,
				"icon_path": equip.icon_path,
				"value": value
			})
	
	return sacrifice_items

# 获取法术书牺牲物品
func _get_spellbook_sacrifice_items() -> Array:
	var item_manager = GameManager.item_manager
	
	# 获取玩家拥有的法术书
	var spellbooks = item_manager.get_player_items_by_type("spellbook")
	var sacrifice_items = []
	
	for book in spellbooks:
		sacrifice_items.append({
			"type": "spellbook",
			"id": book.id,
			"name": book.name,
			"quality": book.quality,
			"icon_path": book.icon_path,
			"value": book.quality * 10  # 法术书品质决定技能强化程度
		})
	
	return sacrifice_items

# 获取遗物牺牲物品
func _get_relic_sacrifice_items() -> Array:
	var relic_manager = GameManager.relic_manager

	# 获取玩家拥有的遗物
	var relics = relic_manager.get_player_relics()
	var sacrifice_items = []
	
	for relic in relics:
		sacrifice_items.append({
			"type": "relic",
			"id": relic.id,
			"name": relic.name,
			"rarity": relic.rarity,
			"icon_path": relic.icon_path,
			"value": (relic.rarity + 1) * 100  # 遗物稀有度决定获得的金币
		})
	
	return sacrifice_items

# 创建牺牲物品项
func _create_sacrifice_item(item_data: Dictionary, index: int) -> Control:
	# 创建物品容器
	var item = Panel.new()
	item.name = "Item_" + str(index)
	item.custom_minimum_size = Vector2(120, 150)
	
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
	
	if ResourceLoader.exists(item_data.icon_path):
		icon.texture = load(item_data.icon_path)
	
	vbox.add_child(icon)
	
	# 创建名称标签
	var name_label = Label.new()
	name_label.text = item_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# 创建价值标签
	var value_label = Label.new()
	value_label.text = "+" + str(item_data.value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 根据物品类型设置颜色
	match item_data.type:
		"chess":
			value_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		"equipment":
			value_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		"spellbook":
			value_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.8))
		"relic":
			value_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	
	vbox.add_child(value_label)
	
	# 添加点击事件
	item.gui_input.connect(_on_sacrifice_item_clicked.bind(index, item_data))
	
	return item

# 牺牲物品点击处理
func _on_sacrifice_item_clicked(event: InputEvent, index: int, item_data: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 显示确认对话框
		var popup = GameManager.ui_manager.show_popup("confirm_dialog", {
			"title": tr("ui.altar.sacrifice_title"),
			"message": tr("ui.altar.sacrifice_message", [item_data.name, str(item_data.value)]),
			"confirm_text": tr("ui.altar.sacrifice_confirm"),
			"cancel_text": tr("ui.altar.sacrifice_cancel")
		})
		
		# 连接确认信号
		if popup and popup.has_signal("confirmed"):
			popup.confirmed.connect(func(): _perform_sacrifice(item_data))

# 执行牺牲
func _perform_sacrifice(item_data: Dictionary) -> void:
	# 根据物品类型执行不同的牺牲效果
	match item_data.type:
		"chess":
			_sacrifice_chess(item_data)
		"equipment":
			_sacrifice_equipment(item_data)
		"spellbook":
			_sacrifice_spellbook(item_data)
		"relic":
			_sacrifice_relic(item_data)
	
	# 播放牺牲音效
	AudioManager.play_sfx("altar_sacrifice.ogg")
	
	# 发送牺牲信号
	EventBus.map.emit_event("altar_sacrifice_made", [altar_type, item_data])
	
	# 更新显示
	update_hud()
	
	# 显示提示
	EventBus.ui.emit_event("show_toast", [tr("ui.altar.sacrifice_success", [item_data.name, str(item_data.value])]))

# 牺牲棋子
func _sacrifice_chess(item_data: Dictionary) -> void:
	# 移除棋子
	var chess_manager = GameManager.chess_manager
	if chess_manager:
		chess_manager.remove_chess_piece(item_data.id)
	
	# 增加玩家生命值
	var player_manager = GameManager.player_manager
	if player_manager:
		player_manager.heal_player(item_data.value)

# 牺牲装备
func _sacrifice_equipment(item_data: Dictionary) -> void:
	# 移除装备
	var equipment_manager = GameManager.equipment_manager
	if equipment_manager:
		equipment_manager.remove_equipment(item_data.id)
	
	# 增加玩家属性
	var player_manager = GameManager.player_manager
	if player_manager:
		if altar_type == "attack":
			player_manager.add_attack_bonus(item_data.value)
		elif altar_type == "defense":
			player_manager.add_defense_bonus(item_data.value)

# 牺牲法术书
func _sacrifice_spellbook(item_data: Dictionary) -> void:
	# 移除法术书
	var item_manager = GameManager.item_manager
	if item_manager:
		item_manager.remove_item(item_data.id)
	
	# 增强玩家技能
	var ability_manager = GameManager.ability_manager
	if ability_manager:
		ability_manager.enhance_player_abilities(item_data.value)

# 牺牲遗物
func _sacrifice_relic(item_data: Dictionary) -> void:
	# 移除遗物
	var relic_manager = GameManager.relic_manager
	if relic_manager:
		relic_manager.remove_relic(item_data.id)
	
	# 增加玩家金币
	var player_manager = GameManager.player_manager
	if player_manager:
		player_manager.add_gold(item_data.value)

# 牺牲按钮点击处理
func _on_sacrifice_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 显示物品选择界面
	if has_node("ItemsContainer"):
		get_node("ItemsContainer").visible = true

# 取消按钮点击处理
func _on_cancel_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)
