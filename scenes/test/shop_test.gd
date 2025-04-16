extends Control
## 商店测试场景
## 用于测试商店系统的功能

# 商店管理器
var shop_manager: ShopManager

# 配置管理器
var config_manager: ConfigManager

# 玩家金币
var player_gold: int = 100

# 商店等级
var shop_tier: int = 1

# 是否应用折扣
var has_discount: bool = false

# 初始化
func _ready():
	# 获取管理器
	shop_manager = get_node("/root/GameManager/ShopManager")
	config_manager = get_node("/root/GameManager/ConfigManager")
	
	# 连接信号
	EventBus.connect("shop_item_purchased", _on_shop_item_purchased)
	
	# 刷新商店
	_refresh_shop()
	
	# 更新玩家信息
	_update_player_info()

# 刷新商店
func _refresh_shop() -> void:
	# 清空商店物品
	for child in $ShopPanel/ItemsContainer.get_children():
		child.queue_free()
	
	# 生成商店物品
	var shop_items = shop_manager.generate_shop_items(shop_tier, has_discount)
	
	# 添加物品到商店
	for item in shop_items:
		var item_panel = _create_shop_item_panel(item)
		$ShopPanel/ItemsContainer.add_child(item_panel)

# 创建商店物品面板
func _create_shop_item_panel(item: Dictionary) -> Control:
	# 创建物品面板
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 200)
	
	# 创建物品名称标签
	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(10, 10)
	name_label.size = Vector2(260, 30)
	panel.add_child(name_label)
	
	# 创建物品类型标签
	var type_label = Label.new()
	type_label.text = "类型: " + item.type
	type_label.position = Vector2(10, 50)
	type_label.size = Vector2(260, 20)
	panel.add_child(type_label)
	
	# 创建物品描述标签
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.position = Vector2(10, 80)
	desc_label.size = Vector2(260, 60)
	panel.add_child(desc_label)
	
	# 创建物品价格标签
	var price_label = Label.new()
	price_label.text = "价格: " + str(item.price) + " 金币"
	price_label.position = Vector2(10, 150)
	price_label.size = Vector2(260, 20)
	panel.add_child(price_label)
	
	# 创建购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.position = Vector2(180, 150)
	buy_button.size = Vector2(80, 30)
	buy_button.pressed.connect(_on_buy_button_pressed.bind(item))
	panel.add_child(buy_button)
	
	return panel

# 更新玩家信息
func _update_player_info() -> void:
	$PlayerInfo/GoldLabel.text = "金币: " + str(player_gold)

# 购买按钮处理
func _on_buy_button_pressed(item: Dictionary) -> void:
	# 检查金币是否足够
	if player_gold < item.price:
		# 显示金币不足提示
		var dialog = AcceptDialog.new()
		dialog.title = "购买失败"
		dialog.dialog_text = "金币不足!"
		add_child(dialog)
		dialog.popup_centered()
		return
	
	# 扣除金币
	player_gold -= item.price
	
	# 更新玩家信息
	_update_player_info()
	
	# 发送购买信号
	EventBus.shop_item_purchased.emit(item)
	
	# 显示购买成功提示
	var dialog = AcceptDialog.new()
	dialog.title = "购买成功"
	dialog.dialog_text = "成功购买: " + item.name
	add_child(dialog)
	dialog.popup_centered()

# 商店物品购买事件处理
func _on_shop_item_purchased(item: Dictionary) -> void:
	# 根据物品类型处理
	match item.type:
		"equipment":
			print("获得装备: ", item.id)
		"chess_piece":
			print("获得棋子: ", item.id)
		"relic":
			print("获得遗物: ", item.id)
		"consumable":
			print("获得消耗品: ", item.id)
		_:
			print("获得未知物品: ", item.id)

# 增加金币按钮处理
func _on_add_gold_button_pressed() -> void:
	# 增加金币
	player_gold += 50
	
	# 更新玩家信息
	_update_player_info()

# 刷新商店按钮处理
func _on_refresh_button_pressed() -> void:
	# 刷新商店
	_refresh_shop()

# 提升商店等级按钮处理
func _on_upgrade_tier_button_pressed() -> void:
	# 提升商店等级
	shop_tier = min(shop_tier + 1, 3)
	
	# 刷新商店
	_refresh_shop()
	
	# 显示提示
	var dialog = AcceptDialog.new()
	dialog.title = "商店升级"
	dialog.dialog_text = "商店等级提升至: " + str(shop_tier)
	add_child(dialog)
	dialog.popup_centered()

# 应用折扣按钮处理
func _on_discount_button_pressed() -> void:
	# 切换折扣状态
	has_discount = !has_discount
	
	# 刷新商店
	_refresh_shop()
	
	# 显示提示
	var dialog = AcceptDialog.new()
	dialog.title = "折扣状态"
	dialog.dialog_text = "折扣状态: " + ("已启用" if has_discount else "已禁用")
	add_child(dialog)
	dialog.popup_centered()

# 重置按钮处理
func _on_reset_button_pressed() -> void:
	# 重置商店
	shop_tier = 1
	has_discount = false
	player_gold = 100
	
	# 刷新商店
	_refresh_shop()
	
	# 更新玩家信息
	_update_player_info()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
