extends Control
## 商店场景
## 玩家可以购买棋子和装备的场景

# 商店刷新费用
const REFRESH_COST = 2

# 是否锁定商店
var is_locked = false

# 玩家金币
var player_gold = 0

# 商店物品
var shop_items = {
	"chess": [],
	"equipment": []
}

func _ready():
	# 设置标题
	$Title.text = LocalizationManager.tr("ui.shop.title")
	
	# 设置按钮文本
	$BottomPanel/ButtonContainer/RefreshButton.text = LocalizationManager.tr("ui.shop.refresh_cost", [str(REFRESH_COST)])
	$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")
	$BottomPanel/ButtonContainer/BackButton.text = LocalizationManager.tr("ui.common.back")
	
	# 更新玩家信息
	_update_player_info()
	
	# 刷新商店
	_refresh_shop()
	
	# 播放商店音乐
	AudioManager.play_music("shop.ogg")

## 更新玩家信息
func _update_player_info() -> void:
	# 这里应该从玩家管理器获取数据
	# 暂时使用示例数据
	player_gold = 10
	
	$BottomPanel/PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health", ["100", "100"])
	$BottomPanel/PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold", [str(player_gold)])
	$BottomPanel/PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level", ["1"])

## 刷新商店
func _refresh_shop() -> void:
	if is_locked:
		return
	
	# 清除现有商品
	for child in $ShopContainer/ChessContainer.get_children():
		child.queue_free()
	
	for child in $ShopContainer/EquipmentContainer.get_children():
		child.queue_free()
	
	# 生成新的棋子
	_generate_chess_items()
	
	# 生成新的装备
	_generate_equipment_items()
	
	# 发送商店刷新信号
	EventBus.shop_refreshed.emit()

## 生成棋子商品
func _generate_chess_items() -> void:
	# 获取所有棋子配置
	var all_chess = ConfigManager.get_all_chess_pieces()
	var chess_list = all_chess.values()
	
	# 随机选择5个棋子
	var selected_chess = []
	for i in range(5):
		if chess_list.size() > 0:
			var index = randi() % chess_list.size()
			selected_chess.append(chess_list[index])
			chess_list.remove_at(index)
	
	# 创建棋子商品
	for chess_data in selected_chess:
		var item = _create_shop_item(chess_data, "chess")
		$ShopContainer/ChessContainer.add_child(item)
	
	# 保存商店棋子
	shop_items.chess = selected_chess

## 生成装备商品
func _generate_equipment_items() -> void:
	# 获取所有装备配置
	var all_equipment = ConfigManager.get_all_equipment()
	var equipment_list = []
	
	# 只选择基础装备
	for equip_id in all_equipment.keys():
		var equip_data = all_equipment[equip_id]
		if not equip_data.has("recipe"):  # 基础装备没有合成配方
			equipment_list.append(equip_data)
	
	# 随机选择3个装备
	var selected_equipment = []
	for i in range(3):
		if equipment_list.size() > 0:
			var index = randi() % equipment_list.size()
			selected_equipment.append(equipment_list[index])
			equipment_list.remove_at(index)
	
	# 创建装备商品
	for equip_data in selected_equipment:
		var item = _create_shop_item(equip_data, "equipment")
		$ShopContainer/EquipmentContainer.add_child(item)
	
	# 保存商店装备
	shop_items.equipment = selected_equipment

## 创建商店物品
func _create_shop_item(item_data: Dictionary, item_type: String) -> Control:
	var item = Panel.new()
	item.custom_minimum_size = Vector2(120, 150)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item.add_child(vbox)
	
	# 物品图标
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED
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
	price_label.text = LocalizationManager.tr("ui.shop.cost", [str(price)])
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
	
	# 检查金币是否足够
	if player_gold < price:
		# 显示金币不足提示
		return
	
	# 扣除金币
	player_gold -= price
	_update_player_info()
	
	# 添加物品到玩家背包
	if item_type == "chess":
		# 添加棋子
		# 这里应该调用棋子管理器
		EventBus.chess_piece_created.emit(item_data)
	else:
		# 添加装备
		# 这里应该调用装备管理器
		EventBus.equipment_created.emit(item_data)
	
	# 发送物品购买信号
	EventBus.item_purchased.emit(item_data)
	
	# 播放购买音效
	AudioManager.play_sfx("item_pickup.ogg")

## 刷新按钮处理
func _on_refresh_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 检查金币是否足够
	if player_gold < REFRESH_COST:
		# 显示金币不足提示
		return
	
	# 扣除金币
	player_gold -= REFRESH_COST
	_update_player_info()
	
	# 刷新商店
	_refresh_shop()

## 锁定按钮处理
func _on_lock_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	
	is_locked = !is_locked
	
	if is_locked:
		$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.unlock")
	else:
		$BottomPanel/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")

## 返回按钮处理
func _on_back_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)
