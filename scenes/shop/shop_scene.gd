extends Control
## 商店场景
## 提供良好的用户体验和视觉效果

# 常量
const SHOP_ITEM_CARD = preload("res://scenes/shop/shop_item_card.tscn")

# 枚举
enum ShopType {
	CHESS,
	EQUIPMENT,
	RELIC,
	BLACK_MARKET,
	MYSTERY_SHOP
}

# 变量
var current_shop_type: int = ShopType.CHESS
var is_shop_locked: bool = false
var current_discount_rate: float = 1.0
var current_filter_rarity: int = -1
var current_filter_type: String = ""
var selected_item_data: Dictionary = {}

# 节点引用
@onready var shop_title = $MainContainer/VBoxContainer/ContentContainer/ShopContentPanel/MarginContainer/VBoxContainer/ShopTitle
@onready var items_container = $MainContainer/VBoxContainer/ContentContainer/ShopContentPanel/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var shop_type_label = $MainContainer/VBoxContainer/HeaderPanel/HBoxContainer/ShopTypeContainer/ShopTypeLabel
@onready var discount_badge = $MainContainer/VBoxContainer/HeaderPanel/HBoxContainer/ShopTypeContainer/DiscountBadge
@onready var effect_badge = $MainContainer/VBoxContainer/BottomPanel/HBoxContainer/ShopEffectsContainer/EffectBadge
@onready var refresh_button = $MainContainer/VBoxContainer/BottomPanel/HBoxContainer/ButtonsContainer/RefreshButton
@onready var lock_button = $MainContainer/VBoxContainer/BottomPanel/HBoxContainer/ButtonsContainer/LockButton
@onready var animation_player = $AnimationPlayer
@onready var item_details_panel = $ItemDetailsPanel
@onready var rarity_filter = $MainContainer/VBoxContainer/ContentContainer/NavigationPanel/VBoxContainer/RarityFilter
@onready var type_filter = $MainContainer/VBoxContainer/ContentContainer/NavigationPanel/VBoxContainer/TypeFilter
@onready var gold_label = $MainContainer/VBoxContainer/ContentContainer/NavigationPanel/VBoxContainer/PlayerInfoContainer/GoldContainer/GoldLabel
@onready var health_label = $MainContainer/VBoxContainer/ContentContainer/NavigationPanel/VBoxContainer/PlayerInfoContainer/HealthContainer/HealthLabel
@onready var level_label = $MainContainer/VBoxContainer/ContentContainer/NavigationPanel/VBoxContainer/PlayerInfoContainer/LevelContainer/LevelLabel

# 初始化
func _ready():
	# 设置初始状态
	_setup_animations()
	_update_shop_type_display()
	_update_player_info()

	# 刷新商店
	refresh_shop()

	# 播放打开动画
	animation_player.play("shop_open")

# 设置动画
func _setup_animations():
	# 创建商店打开动画
	var shop_open_anim = Animation.new()
	shop_open_anim.length = 0.5

	# 主容器缩放动画
	var main_container_track = shop_open_anim.add_track(Animation.TYPE_VALUE)
	shop_open_anim.track_set_path(main_container_track, "MainContainer:scale")
	shop_open_anim.track_insert_key(main_container_track, 0.0, Vector2(0.8, 0.8))
	shop_open_anim.track_insert_key(main_container_track, 0.5, Vector2(1.0, 1.0))

	# 主容器透明度动画
	var main_container_alpha_track = shop_open_anim.add_track(Animation.TYPE_VALUE)
	shop_open_anim.track_set_path(main_container_alpha_track, "MainContainer:modulate")
	shop_open_anim.track_insert_key(main_container_alpha_track, 0.0, Color(1, 1, 1, 0))
	shop_open_anim.track_insert_key(main_container_alpha_track, 0.5, Color(1, 1, 1, 1))

	# 背景覆盖层透明度动画
	var bg_overlay_track = shop_open_anim.add_track(Animation.TYPE_VALUE)
	shop_open_anim.track_set_path(bg_overlay_track, "BackgroundOverlay:color")
	shop_open_anim.track_insert_key(bg_overlay_track, 0.0, Color(0, 0, 0, 0))
	shop_open_anim.track_insert_key(bg_overlay_track, 0.5, Color(0, 0, 0, 0.4))

	# 添加动画到动画播放器
	animation_player.add_animation("shop_open", shop_open_anim)

	# 创建商店关闭动画
	var shop_close_anim = Animation.new()
	shop_close_anim.length = 0.5

	# 主容器缩放动画
	var close_main_container_track = shop_close_anim.add_track(Animation.TYPE_VALUE)
	shop_close_anim.track_set_path(close_main_container_track, "MainContainer:scale")
	shop_close_anim.track_insert_key(close_main_container_track, 0.0, Vector2(1.0, 1.0))
	shop_close_anim.track_insert_key(close_main_container_track, 0.5, Vector2(0.8, 0.8))

	# 主容器透明度动画
	var close_main_container_alpha_track = shop_close_anim.add_track(Animation.TYPE_VALUE)
	shop_close_anim.track_set_path(close_main_container_alpha_track, "MainContainer:modulate")
	shop_close_anim.track_insert_key(close_main_container_alpha_track, 0.0, Color(1, 1, 1, 1))
	shop_close_anim.track_insert_key(close_main_container_alpha_track, 0.5, Color(1, 1, 1, 0))

	# 背景覆盖层透明度动画
	var close_bg_overlay_track = shop_close_anim.add_track(Animation.TYPE_VALUE)
	shop_close_anim.track_set_path(close_bg_overlay_track, "BackgroundOverlay:color")
	shop_close_anim.track_insert_key(close_bg_overlay_track, 0.0, Color(0, 0, 0, 0.4))
	shop_close_anim.track_insert_key(close_bg_overlay_track, 0.5, Color(0, 0, 0, 0))

	# 添加动画到动画播放器
	animation_player.add_animation("shop_close", shop_close_anim)

	# 创建物品刷新动画
	var refresh_items_anim = Animation.new()
	refresh_items_anim.length = 0.3

	# 物品容器透明度动画
	var items_container_track = refresh_items_anim.add_track(Animation.TYPE_VALUE)
	refresh_items_anim.track_set_path(items_container_track, "MainContainer/VBoxContainer/ContentContainer/ShopContentPanel/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer:modulate")
	refresh_items_anim.track_insert_key(items_container_track, 0.0, Color(1, 1, 1, 0))
	refresh_items_anim.track_insert_key(items_container_track, 0.3, Color(1, 1, 1, 1))

	# 添加动画到动画播放器
	animation_player.add_animation("refresh_items", refresh_items_anim)

	# 创建物品详情面板动画
	var show_details_anim = Animation.new()
	show_details_anim.length = 0.3

	# 详情面板位置动画
	var details_panel_track = show_details_anim.add_track(Animation.TYPE_VALUE)
	show_details_anim.track_set_path(details_panel_track, "ItemDetailsPanel:position")
	show_details_anim.track_insert_key(details_panel_track, 0.0, Vector2(get_viewport_rect().size.x, $ItemDetailsPanel.position.y))
	show_details_anim.track_insert_key(details_panel_track, 0.3, Vector2($ItemDetailsPanel.position.x, $ItemDetailsPanel.position.y))

	# 详情面板透明度动画
	var details_alpha_track = show_details_anim.add_track(Animation.TYPE_VALUE)
	show_details_anim.track_set_path(details_alpha_track, "ItemDetailsPanel:modulate")
	show_details_anim.track_insert_key(details_alpha_track, 0.0, Color(1, 1, 1, 0))
	show_details_anim.track_insert_key(details_alpha_track, 0.3, Color(1, 1, 1, 1))

	# 添加动画到动画播放器
	animation_player.add_animation("show_details", show_details_anim)

	# 创建物品详情面板隐藏动画
	var hide_details_anim = Animation.new()
	hide_details_anim.length = 0.3

	# 详情面板位置动画
	var hide_details_panel_track = hide_details_anim.add_track(Animation.TYPE_VALUE)
	hide_details_anim.track_set_path(hide_details_panel_track, "ItemDetailsPanel:position")
	hide_details_anim.track_insert_key(hide_details_panel_track, 0.0, Vector2($ItemDetailsPanel.position.x, $ItemDetailsPanel.position.y))
	hide_details_anim.track_insert_key(hide_details_panel_track, 0.3, Vector2(get_viewport_rect().size.x, $ItemDetailsPanel.position.y))

	# 详情面板透明度动画
	var hide_details_alpha_track = hide_details_anim.add_track(Animation.TYPE_VALUE)
	hide_details_anim.track_set_path(hide_details_alpha_track, "ItemDetailsPanel:modulate")
	hide_details_anim.track_insert_key(hide_details_alpha_track, 0.0, Color(1, 1, 1, 1))
	hide_details_anim.track_insert_key(hide_details_alpha_track, 0.3, Color(1, 1, 1, 0))

	# 添加动画到动画播放器
	animation_player.add_animation("hide_details", hide_details_anim)

# 更新商店类型显示
func _update_shop_type_display():
	match current_shop_type:
		ShopType.CHESS:
			shop_title.text = "棋子商店"
			shop_type_label.text = "普通商店"
			effect_badge.visible = false
			type_filter.visible = false
		ShopType.EQUIPMENT:
			shop_title.text = "装备商店"
			shop_type_label.text = "装备商店"
			effect_badge.visible = false
			type_filter.visible = true
		ShopType.RELIC:
			shop_title.text = "遗物商店"
			shop_type_label.text = "遗物商店"
			effect_badge.visible = false
			type_filter.visible = false
		ShopType.BLACK_MARKET:
			shop_title.text = "黑市商店"
			shop_type_label.text = "黑市商人"
			effect_badge.visible = true
			effect_badge.text = "黑市商人"
			effect_badge.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
			type_filter.visible = true
		ShopType.MYSTERY_SHOP:
			shop_title.text = "神秘商店"
			shop_type_label.text = "神秘商店"
			effect_badge.visible = true
			effect_badge.text = "神秘商店"
			effect_badge.add_theme_color_override("font_color", Color(0.5, 0.2, 1))
			type_filter.visible = true

	# 更新折扣显示
	if current_discount_rate < 1.0:
		discount_badge.visible = true
		discount_badge.text = "折扣 " + str(int(current_discount_rate * 100)) + "%"
	else:
		discount_badge.visible = false

	# 更新锁定按钮文本
	if is_shop_locked:
		lock_button.text = "解锁商店"
	else:
		lock_button.text = "锁定商店"

# 更新玩家信息
func _update_player_info():
	var player = GameManager.player_manager.get_current_player()
	if player:
		gold_label.text = "金币: " + str(player.gold)
		health_label.text = "生命值: " + str(player.current_health) + "/" + str(player.max_health)
		level_label.text = "等级: " + str(player.level)

		# 更新刷新按钮文本
		var refresh_cost = GameManager.economy_manager.get_refresh_cost()
		refresh_button.text = "刷新 (" + str(refresh_cost) + "金币)"

# 刷新商店
func refresh_shop():
	# 如果商店已锁定，则不刷新
	if is_shop_locked:
		return

	# 清空物品容器
	for child in items_container.get_children():
		child.queue_free()

	# 获取商店物品
	var shop_items = _get_shop_items()

	# 应用筛选
	shop_items = _apply_filters(shop_items)

	# 设置物品容器透明度为0
	items_container.modulate = Color(1, 1, 1, 0)

	# 添加物品卡片
	for item_data in shop_items:
		var item_card = SHOP_ITEM_CARD.instantiate()
		items_container.add_child(item_card)
		item_card.initialize(item_data)
		item_card.item_clicked.connect(_on_item_clicked)

	# 播放刷新动画
	animation_player.play("refresh_items")

	# 更新玩家信息
	_update_player_info()

# 获取商店物品
func _get_shop_items() -> Array:
	var shop_manager = GameManager.get_manager("ShopManager")
	if shop_manager:
		var shop_items = shop_manager.get_shop_items()

		match current_shop_type:
			ShopType.CHESS:
				return shop_items.get("chess", [])
			ShopType.EQUIPMENT:
				return shop_items.get("equipment", [])
			ShopType.RELIC:
				return shop_items.get("relic", [])
			ShopType.BLACK_MARKET, ShopType.MYSTERY_SHOP:
				# 黑市和神秘商店可能包含多种物品类型
				var all_items = []
				all_items.append_array(shop_items.get("chess", []))
				all_items.append_array(shop_items.get("equipment", []))
				all_items.append_array(shop_items.get("relic", []))
				return all_items

	return []

# 应用筛选
func _apply_filters(items: Array) -> Array:
	var filtered_items = []

	for item in items:
		var pass_rarity_filter = true
		var pass_type_filter = true

		# 应用稀有度筛选
		if current_filter_rarity >= 0:
			pass_rarity_filter = item.get("rarity", 0) == current_filter_rarity

		# 应用类型筛选
		if not current_filter_type.is_empty():
			pass_type_filter = item.get("type", "") == current_filter_type

		# 如果通过所有筛选，则添加到结果中
		if pass_rarity_filter and pass_type_filter:
			filtered_items.append(item)

	return filtered_items

# 显示物品详情
func show_item_details(item_data: Dictionary):
	# 保存选中的物品数据
	selected_item_data = item_data

	# 设置详情面板内容
	$ItemDetailsPanel/MarginContainer/VBoxContainer/ItemNameLabel.text = item_data.get("name", "未知物品")

	# 设置物品图标
	var item_image = $ItemDetailsPanel/MarginContainer/VBoxContainer/ItemImageContainer/ItemImage
	var icon_path = item_data.get("icon_path", "")
	if not icon_path.is_empty():
		item_image.texture = load(icon_path)
	else:
		item_image.texture = null

	# 设置物品类型
	var type_text = "类型: "
	match item_data.get("type", ""):
		"weapon":
			type_text += "武器"
		"armor":
			type_text += "防具"
		"accessory":
			type_text += "饰品"
		"chess_piece":
			type_text += "棋子"
		"relic":
			type_text += "遗物"
		_:
			type_text += "未知"
	$ItemDetailsPanel/MarginContainer/VBoxContainer/ItemTypeLabel.text = type_text

	# 设置物品稀有度
	var rarity_text = "稀有度: "
	var rarity_color = Color(1, 1, 1)
	match item_data.get("rarity", 0):
		0:
			rarity_text += "普通"
			rarity_color = Color(0.8, 0.8, 0.8)
		1:
			rarity_text += "稀有"
			rarity_color = Color(0.2, 0.6, 1)
		2:
			rarity_text += "史诗"
			rarity_color = Color(0.8, 0.2, 1)
		3:
			rarity_text += "传说"
			rarity_color = Color(1, 0.8, 0.2)
		_:
			rarity_text += "未知"
	$ItemDetailsPanel/MarginContainer/VBoxContainer/ItemRarityLabel.text = rarity_text
	$ItemDetailsPanel/MarginContainer/VBoxContainer/ItemRarityLabel.add_theme_color_override("font_color", rarity_color)

	# 设置物品描述
	$ItemDetailsPanel/MarginContainer/VBoxContainer/DescriptionLabel.text = item_data.get("description", "无描述")

	# 设置物品属性
	var stats_list = $ItemDetailsPanel/MarginContainer/VBoxContainer/StatsContainer/StatsList

	# 清空属性列表
	for child in stats_list.get_children():
		child.queue_free()

	# 添加属性
	var stats = item_data.get("stats", {})
	if not stats.is_empty():
		for stat_name in stats:
			var value = stats[stat_name]
			var stat_label = Label.new()
			stat_label.add_theme_font_size_override("font_size", 14)

			var stat_text = ""
			match stat_name:
				"health":
					stat_text = "+" + str(value) + " 生命值"
				"attack_damage":
					stat_text = "+" + str(value) + " 攻击力"
				"attack_speed":
					stat_text = "+" + str(value) + "% 攻击速度"
				"armor":
					stat_text = "+" + str(value) + " 护甲"
				"magic_resist":
					stat_text = "+" + str(value) + " 魔法抗性"
				"spell_power":
					stat_text = "+" + str(value) + " 法术强度"
				"move_speed":
					stat_text = "+" + str(value) + " 移动速度"
				"crit_chance":
					stat_text = "+" + str(value) + "% 暴击几率"
				"crit_damage":
					stat_text = "+" + str(value) + "% 暴击伤害"
				"dodge_chance":
					stat_text = "+" + str(value) + "% 闪避几率"
				_:
					stat_text = "+" + str(value) + " " + stat_name

			stat_label.text = stat_text
			stat_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
			stats_list.add_child(stat_label)
	else:
		# 如果没有属性，添加一个"无属性"标签
		var no_stats_label = Label.new()
		no_stats_label.add_theme_font_size_override("font_size", 14)
		no_stats_label.text = "无属性"
		no_stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		stats_list.add_child(no_stats_label)

	# 设置物品价格
	$ItemDetailsPanel/MarginContainer/VBoxContainer/PriceContainer/PriceValueLabel.text = str(item_data.get("cost", 0))

	# 显示详情面板
	item_details_panel.visible = true
	animation_player.play("show_details")

# 隐藏物品详情
func hide_item_details():
	animation_player.play("hide_details")
	animation_player.animation_finished.connect(func(anim_name):
		if anim_name == "hide_details":
			item_details_panel.visible = false
			animation_player.animation_finished.disconnect(animation_player.animation_finished.get_connections()[0]["callable"])
	, CONNECT_ONE_SHOT)

# 购买物品
func _purchase_item(item_data: Dictionary):
	var shop_manager = GameManager.get_manager("ShopManager")
	if not shop_manager:
		return

	var item_type = item_data.get("type", "")
	var item_index = -1

	# 获取物品在商店中的索引
	var shop_items = _get_shop_items()
	for i in range(shop_items.size()):
		if shop_items[i].get("id", "") == item_data.get("id", ""):
			item_index = i
			break

	if item_index == -1:
		return

	# 根据物品类型购买
	var purchased_item = null
	match item_type:
		"chess_piece":
			purchased_item = shop_manager.purchase_chess(item_index)
		"weapon", "armor", "accessory":
			purchased_item = shop_manager.purchase_equipment(item_index)
		"relic":
			purchased_item = shop_manager.purchase_relic(item_index)

	if purchased_item:
		# 购买成功，刷新商店
		refresh_shop()
		# 隐藏详情面板
		hide_item_details()
		# 播放购买成功音效
		# TODO: 添加音效

		# 显示购买成功提示
		GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("购买成功！"))
	else:
		# 购买失败，显示提示
		GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("金币不足或物品已售出！"))

# 信号处理函数
func _on_chess_button_pressed():
	current_shop_type = ShopType.CHESS
	_update_shop_type_display()
	refresh_shop()

func _on_equipment_button_pressed():
	current_shop_type = ShopType.EQUIPMENT
	_update_shop_type_display()
	refresh_shop()

func _on_relic_button_pressed():
	current_shop_type = ShopType.RELIC
	_update_shop_type_display()
	refresh_shop()

func _on_refresh_button_pressed():
	var shop_manager = GameManager.get_manager("ShopManager")
	if shop_manager:
		shop_manager.manual_refresh_shop()
		refresh_shop()

func _on_lock_button_pressed():
	var shop_manager = GameManager.get_manager("ShopManager")
	if shop_manager:
		is_shop_locked = shop_manager.toggle_shop_lock()
		_update_shop_type_display()

func _on_back_button_pressed():
	# 播放关闭动画
	animation_player.play("shop_close")
	animation_player.animation_finished.connect(func(anim_name):
		if anim_name == "shop_close":
			# 返回到上一个场景
			get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")
	, CONNECT_ONE_SHOT)

func _on_rarity_filter_item_selected(index):
	if index == 0:
		current_filter_rarity = -1
	else:
		current_filter_rarity = index - 1
	refresh_shop()

func _on_type_filter_item_selected(index):
	if index == 0:
		current_filter_type = ""
	else:
		match index:
			1: current_filter_type = "weapon"
			2: current_filter_type = "armor"
			3: current_filter_type = "accessory"
	refresh_shop()

func _on_item_clicked(item_data):
	show_item_details(item_data)

func _on_buy_button_pressed():
	_purchase_item(selected_item_data)

func _on_details_close_button_pressed():
	hide_item_details()

# 设置商店类型
func set_shop_type(shop_type: int):
	current_shop_type = shop_type
	_update_shop_type_display()
	refresh_shop()

# 设置折扣率
func set_discount_rate(rate: float):
	current_discount_rate = rate
	_update_shop_type_display()

# 设置为黑市商店
func set_as_black_market():
	current_shop_type = ShopType.BLACK_MARKET
	_update_shop_type_display()
	refresh_shop()

# 设置为神秘商店
func set_as_mystery_shop():
	current_shop_type = ShopType.MYSTERY_SHOP
	_update_shop_type_display()
	refresh_shop()
