extends Control
## 商店场景
## 玩家可以购买棋子和装备的场景

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var shop_manager = get_node("/root/GameManager/ShopManager")
@onready var economy_manager = get_node("/root/GameManager/EconomyManager")

# 当前玩家
var current_player = null

func _ready():
	# 获取当前玩家
	current_player = player_manager.get_current_player()

	# 设置标题
	$Title.text = LocalizationManager.tr("ui.shop.title")

	# 设置按钮文本
	$BottomPanel/ButtonContainer/RefreshButton.text = LocalizationManager.tr("ui.shop.refresh_cost").format({"cost": str(shop_manager.get_current_refresh_cost())})
	$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")
	$BottomPanel/ButtonContainer/BackButton.text = LocalizationManager.tr("ui.common.back")

	# 更新玩家信息
	_update_player_info()

	# 刷新商店
	_refresh_shop()

	# 播放商店音乐
	AudioManager.play_music("shop.ogg")

	# 连接信号
	if current_player:
		current_player.gold_changed.connect(_on_player_gold_changed)
		current_player.health_changed.connect(_on_player_health_changed)
		current_player.level_changed.connect(_on_player_level_changed)

## 更新玩家信息
func _update_player_info() -> void:
	if current_player == null:
		return

	$BottomPanel/PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health").format({"current": str(current_player.current_health), "max": str(current_player.max_health)})
	$BottomPanel/PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold").format({"amount": str(current_player.gold)})
	$BottomPanel/PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level").format({"level": str(current_player.level)})

## 刷新商店
func _refresh_shop() -> void:
	# 清除现有商品
	for child in $ShopContainer/ChessContainer.get_children():
		child.queue_free()

	for child in $ShopContainer/EquipmentContainer.get_children():
		child.queue_free()

	# 获取商店物品
	var shop_items = shop_manager.get_shop_items()

	# 创建棋子商品
	for chess_data in shop_items.chess:
		var item = _create_shop_item(chess_data, "chess")
		$ShopContainer/ChessContainer.add_child(item)

	# 创建装备商品
	for equip_id in shop_items.equipment:
		var equip_data = get_node("/root/ConfigManager").get_equipment(equip_id)
		if equip_data:
			var item = _create_shop_item(equip_data, "equipment")
			$ShopContainer/EquipmentContainer.add_child(item)



## 创建商店物品
func _create_shop_item(item_data: Dictionary, item_type: String) -> Control:
	var item = Panel.new()
	item.custom_minimum_size = Vector2(120, 150)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item.add_child(vbox)

	# 物品图标
	var icon = TextureRect.new()
	icon.expand_mode = 1 # Ignore Size
	icon.custom_minimum_size = Vector2(80, 80)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var icon_path = ""
	if item_type == "chess":
		icon_path = "res://assets/images/chess/" + item_data.icon
	else:
		icon_path = "res://assets/images/equipment/" + item_data.icon

	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)

	vbox.add_child(icon)

	# 物品名称
	var name_label = Label.new()
	if item_type == "chess":
		name_label.text = LocalizationManager.tr("game.chess." + item_data.id)
	else:
		name_label.text = LocalizationManager.tr("game.equipment." + item_data.id)

	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# 物品价格
	var price_label = Label.new()
	var price = item_data.cost if item_type == "chess" else 3  # 装备固定价格为3
	price_label.text = LocalizationManager.tr("ui.shop.cost").format({"cost": str(price)})
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)

	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = LocalizationManager.tr("ui.shop.buy")
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_button.pressed.connect(_on_buy_item_pressed.bind(item_data, item_type, price))
	vbox.add_child(buy_button)

	return item

## 购买物品按钮处理
func _on_buy_item_pressed(item_data: Dictionary, item_type: String, price: int) -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	if current_player == null:
		return

	# 检查金币是否足够
	if current_player.gold < price:
		# 显示金币不足提示
		EventBus.debug.debug_message.emit("金币不足", 1)
		return

	# 购买物品
	if item_type == "chess":
		# 查找棋子索引
		var shop_items = shop_manager.get_shop_items()
		var chess_index = shop_items.chess.find(item_data)
		if chess_index != -1:
			# 购买棋子
			var chess_piece = shop_manager.purchase_chess(chess_index)
			if chess_piece:
				# 刷新商店显示
				_refresh_shop()
				# 播放购买音效
				AudioManager.play_sfx("item_pickup.ogg")
	else:
		# 查找装备索引
		var shop_items = shop_manager.get_shop_items()
		var equip_index = -1
		for i in range(shop_items.equipment.size()):
			if shop_items.equipment[i] == item_data.id:
				equip_index = i
				break

		if equip_index != -1:
			# 购买装备
			var equipment = shop_manager.purchase_equipment(equip_index)
			if equipment:
				# 刷新商店显示
				_refresh_shop()
				# 播放购买音效
				AudioManager.play_sfx("item_pickup.ogg")

## 刷新按钮处理
func _on_refresh_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 手动刷新商店
	if shop_manager.manual_refresh_shop():
		# 刷新商店显示
		_refresh_shop()
	else:
		# 显示金币不足提示
		EventBus.debug.debug_message.emit("金币不足", 1)

## 锁定按钮处理
func _on_lock_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 切换商店锁定状态
	var is_locked = shop_manager.toggle_shop_lock()

	if is_locked:
		$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.unlock")
	else:
		$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")

## 返回按钮处理
func _on_back_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

## 玩家金币变化事件处理
func _on_player_gold_changed(old_value: int, new_value: int) -> void:
	# 更新金币显示
	$BottomPanel/PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold").format({"amount": str(new_value)})

## 玩家生命值变化事件处理
func _on_player_health_changed(old_value: int, new_value: int) -> void:
	# 更新生命值显示
	$BottomPanel/PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health").format({"current": str(new_value), "max": str(current_player.max_health)})

## 玩家等级变化事件处理
func _on_player_level_changed(old_level: int, new_level: int) -> void:
	# 更新等级显示
	$BottomPanel/PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level").format({"level": str(new_level)})

	# 刷新商店（等级变化可能影响可购买的棋子和装备）
	shop_manager.refresh_shop(true)
	_refresh_shop()
