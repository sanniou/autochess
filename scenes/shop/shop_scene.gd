extends Control
## 商店场景
## 玩家可以购买棋子、装备和遗物的场景

# 商店类型
enum ShopType {
	CHESS,
	EQUIPMENT,
	RELIC
}

# 当前玩家
var current_player = null

# 当前商店类型
var current_shop_type = ShopType.CHESS

# 商店物品卡片场景
const SHOP_ITEM_CARD = preload("res://scenes/shop/shop_item_card.tscn")

# 初始化
func _ready():
	# 获取当前玩家
	current_player = GameManager.player_manager.get_current_player()

	# 设置标题
	$VBoxContainer/HeaderPanel/HBoxContainer/TitleLabel.text = LocalizationManager.tr("ui.shop.title")

	# 设置按钮文本
	$VBoxContainer/BottomPanel/HBoxContainer/ButtonContainer/RefreshButton.text = LocalizationManager.tr("ui.shop.refresh_cost").format({"cost": str(GameManager.shop_manager.get_current_refresh_cost())})
	$VBoxContainer/BottomPanel/HBoxContainer/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")
	$VBoxContainer/BottomPanel/HBoxContainer/ButtonContainer/BackButton.text = LocalizationManager.tr("ui.common.back")

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

	# 设置商店效果面板
	_update_shop_effects_panel()

	# 检查特殊商店类型
	_check_special_shop_type()

## 更新玩家信息
func _update_player_info() -> void:
	if current_player == null:
		return

	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health").format({"current": str(current_player.current_health), "max": str(current_player.max_health)})
	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold").format({"amount": str(current_player.gold)})
	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level").format({"level": str(current_player.level)})

## 刷新商店
func _refresh_shop() -> void:
	# 清除现有商品
	_clear_shop_items()

	# 获取商店物品
	var shop_items = GameManager.shop_manager.get_shop_items()

	# 根据当前商店类型显示物品
	match current_shop_type:
		ShopType.CHESS:
			_display_chess_items(shop_items.chess)
		ShopType.EQUIPMENT:
			_display_equipment_items(shop_items.equipment)
		ShopType.RELIC:
			_display_relic_items(shop_items.get("relic", []))

## 清除商店物品
func _clear_shop_items() -> void:
	for child in $VBoxContainer/TabContainer/棋子商店/ChessContainer.get_children():
		child.queue_free()

	for child in $VBoxContainer/TabContainer/装备商店/EquipmentContainer.get_children():
		child.queue_free()

	for child in $VBoxContainer/TabContainer/遗物商店/RelicContainer.get_children():
		child.queue_free()

## 显示棋子物品
func _display_chess_items(chess_items: Array) -> void:
	for i in range(chess_items.size()):
		var chess_id = chess_items[i]

		# 从 ChessManager 获取棋子实例
		var chess_piece = GameManager.chess_manager.get_chess(chess_id)
		if chess_piece == null:
			continue

		# 获取棋子数据用于显示
		var chess_config = GameManager.config_manager.get_chess_piece_config(chess_id)
		var chess_data = chess_config.get_data()

		# 获取棋子价格
		var price = GameManager.shop_manager.get_current_chess_cost(chess_piece)

		# 创建商店物品卡
		var item_card = SHOP_ITEM_CARD.instantiate()
		item_card.initialize(chess_data, "chess", price, i)
		item_card.item_purchased.connect(_on_item_purchased)

		# 设置是否可购买
		if current_player:
			item_card.set_purchasable(current_player.gold >= price)

		$VBoxContainer/TabContainer/棋子商店/ChessContainer.add_child(item_card)

## 显示装备物品
func _display_equipment_items(equipment_items: Array) -> void:
	for i in range(equipment_items.size()):
		var equip_id = equipment_items[i]
		# 直接从 EquipmentManager 获取装备实例
		var equipment = GameManager.equipment_manager.get_equipment(equip_id)
		if equipment == null:
			continue

		# 获取装备数据
		var equip_data = equipment.get_data()
		# 获取装备价格
		var price = GameManager.shop_manager.get_current_equipment_cost(equipment)

		var item_card = SHOP_ITEM_CARD.instantiate()
		item_card.initialize(equip_data, "equipment", price, i)
		item_card.item_purchased.connect(_on_item_purchased)

		# 设置是否可购买
		if current_player:
			item_card.set_purchasable(current_player.gold >= price)

		$VBoxContainer/TabContainer/装备商店/EquipmentContainer.add_child(item_card)

## 显示遗物物品
func _display_relic_items(relic_items: Array) -> void:
	for i in range(relic_items.size()):
		var relic_id = relic_items[i]

		# 获取遗物数据
		var relic_data = GameManager.relic_manager.get_relic_data(relic_id)
		if relic_data.is_empty():
			continue

		# 获取遗物价格
		var price = GameManager.shop_manager.get_current_relic_cost(relic_data)

		# 创建商店物品卡
		var item_card = SHOP_ITEM_CARD.instantiate()
		item_card.initialize(relic_data, "relic", price, i)
		item_card.item_purchased.connect(_on_item_purchased)

		# 设置是否可购买
		if current_player:
			item_card.set_purchasable(current_player.gold >= price)

		$VBoxContainer/TabContainer/遗物商店/RelicContainer.add_child(item_card)

## 物品购买事件处理
func _on_item_purchased(item_data: Dictionary, item_type: String, price: int) -> void:
	if current_player == null:
		return

	# 检查金币是否足够
	if current_player.gold < price:
		# 显示金币不足提示
		EventBus.debug.emit_event("debug_message", ["金币不足", 1])
		return

	# 购买物品
	var purchase_success = false

	if item_type == "chess":
		# 查找棋子索引
		var shop_items = GameManager.shop_manager.get_shop_items()
		var chess_index = -1
		for i in range(shop_items.chess.size()):
			var chess_id = shop_items.chess[i]
			var chess_config = GameManager.config_manager.get_chess_piece_config(chess_id)
			if chess_config and chess_config.get_id() == item_data.id:
				chess_index = i
				break

		if chess_index != -1:
			# 购买棋子
			var chess_piece = GameManager.shop_manager.purchase_chess(chess_index)
			if chess_piece:
				purchase_success = true
	elif item_type == "equipment":
		# 查找装备索引
		var shop_items = GameManager.shop_manager.get_shop_items()
		var equip_index = -1
		for i in range(shop_items.equipment.size()):
			if shop_items.equipment[i] == item_data.id:
				equip_index = i
				break

		if equip_index != -1:
			# 购买装备
			var equipment = GameManager.shop_manager.purchase_equipment(equip_index)
			if equipment:
				purchase_success = true
	elif item_type == "relic":
		# 查找遗物索引
		var shop_items = GameManager.shop_manager.get_shop_items()
		if shop_items.has("relic"):
			# 遗物ID已经存储在shop_items.relic中
			var relic_id = item_data.id
			var relic_index = shop_items.relic.find(relic_id)
			if relic_index != -1:
				# 扣除金币
				if current_player.spend_gold(price):
					# 获取遗物
					var relic = GameManager.relic_manager.acquire_relic(relic_id, current_player)
					if relic:
						# 从商店移除
						shop_items.relic.remove_at(relic_index)
						purchase_success = true

	if purchase_success:
		# 刷新商店显示
		_refresh_shop()
		# 播放购买音效
		AudioManager.play_sfx("item_pickup.ogg")
		# 显示购买成功提示
		EventBus.debug.emit_event("debug_message", ["购买成功", 0])

## 刷新按钮处理
func _on_refresh_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 手动刷新商店
	if GameManager.shop_manager.manual_refresh_shop():
		# 刷新商店显示
		_refresh_shop()
	else:
		# 显示金币不足提示
		EventBus.debug.emit_event("debug_message", ["金币不足", 1])

## 锁定按钮处理
func _on_lock_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 切换商店锁定状态
	var is_locked = GameManager.shop_manager.toggle_shop_lock()

	if is_locked:
		$VBoxContainer/BottomPanel/HBoxContainer/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.unlock")
	else:
		$VBoxContainer/BottomPanel/HBoxContainer/ButtonContainer/LockButton.text = LocalizationManager.tr("ui.shop.lock")

## 返回按钮处理
func _on_back_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

## 标签切换事件处理
func _on_tab_container_tab_changed(tab: int) -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 更新当前商店类型
	current_shop_type = tab

	# 刷新商店显示
	_refresh_shop()

## 玩家金币变化事件处理
func _on_player_gold_changed(old_value: int, new_value: int) -> void:
	# 更新金币显示
	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/GoldLabel.text = LocalizationManager.tr("ui.player.gold").format({"amount": str(new_value)})

	# 更新物品可购买状态
	_update_items_purchasable_state()

## 玩家生命值变化事件处理
func _on_player_health_changed(old_value: int, new_value: int) -> void:
	# 更新生命值显示
	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/HealthLabel.text = LocalizationManager.tr("ui.player.health").format({"current": str(new_value), "max": str(current_player.max_health)})

## 玩家等级变化事件处理
func _on_player_level_changed(old_level: int, new_level: int) -> void:
	# 更新等级显示
	$VBoxContainer/BottomPanel/HBoxContainer/PlayerInfo/LevelLabel.text = LocalizationManager.tr("ui.player.level").format({"level": str(new_level)})

	# 刷新商店（等级变化可能影响可购买的棋子和装备）
	GameManager.shop_manager.refresh_shop(true)
	_refresh_shop()

## 更新物品可购买状态
func _update_items_purchasable_state() -> void:
	if current_player == null:
		return

	# 更新棋子物品
	for item_card in $VBoxContainer/TabContainer/棋子商店/ChessContainer.get_children():
		item_card.set_purchasable(current_player.gold >= item_card.item_price)

	# 更新装备物品
	for item_card in $VBoxContainer/TabContainer/装备商店/EquipmentContainer.get_children():
		item_card.set_purchasable(current_player.gold >= item_card.item_price)

	# 更新遗物物品
	for item_card in $VBoxContainer/TabContainer/遗物商店/RelicContainer.get_children():
		item_card.set_purchasable(current_player.gold >= item_card.item_price)

## 更新商店效果面板
func _update_shop_effects_panel() -> void:
	var shop_params = GameManager.shop_manager.get_shop_params()

	# 更新折扣信息
	var discount_text = "折扣: " + str(int(shop_params.discount_rate * 100)) + "%"
	$ShopEffectsPanel/VBoxContainer/EffectsContainer/DiscountLabel.text = discount_text

	# 更新特价商品信息
	var special_offer_text = "特价商品: " + ("是" if shop_params.special_offer else "否")
	$ShopEffectsPanel/VBoxContainer/EffectsContainer/SpecialOfferLabel.text = special_offer_text

	# 更新商店类型效果
	var shop_type_effect = ""
	if shop_params.is_black_market:
		shop_type_effect = "黑市商人"
	elif shop_params.is_mystery_shop:
		shop_type_effect = "神秘商店"
	elif shop_params.is_equipment_shop:
		shop_type_effect = "装备商店"
	else:
		shop_type_effect = "普通商店"

	$ShopEffectsPanel/VBoxContainer/EffectsContainer/ShopTypeEffectLabel.text = shop_type_effect

	# 显示商店效果面板
	$ShopEffectsPanel.visible = shop_params.discount_rate != 1.0 or shop_params.special_offer or shop_params.is_black_market or shop_params.is_mystery_shop or shop_params.is_equipment_shop

## 检查特殊商店类型
func _check_special_shop_type() -> void:
	var shop_params = GameManager.shop_manager.get_shop_params()

	# 更新商店类型标签
	var shop_type_text = "普通商店"
	if shop_params.is_black_market:
		shop_type_text = "黑市商人"
	elif shop_params.is_mystery_shop:
		shop_type_text = "神秘商店"
	elif shop_params.is_equipment_shop:
		shop_type_text = "装备商店"

	$VBoxContainer/HeaderPanel/HBoxContainer/ShopTypeLabel.text = shop_type_text

	# 如果是装备商店，默认显示装备标签
	if shop_params.is_equipment_shop:
		$VBoxContainer/TabContainer.current_tab = ShopType.EQUIPMENT
		current_shop_type = ShopType.EQUIPMENT
		_refresh_shop()
