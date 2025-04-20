extends Panel
## 商店物品卡片
## 用于在商店中显示可购买的物品

# 信号
signal item_purchased(item_data, item_type, price)
signal item_selected(item_card)

# 物品数据
var item_data: Dictionary = {}
var item_type: String = ""
var item_price: int = 0
var item_index: int = -1

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")

const TYPE_INDICATORS = {
	"chess": "C",
	"equipment": "E",
	"relic": "R"
}

# 初始化
func _ready():
	# 加载金币图标
	var coin_icon = load("res://assets/images/ui/coin_icon.png")
	if coin_icon:
		$VBoxContainer/PriceContainer/CoinIcon.texture = coin_icon

	# 设置工具提示面板
	$TooltipPanel.visible = false

	# 设置工具提示位置
	_update_tooltip_position()

# 初始化物品数据
func initialize(data: Dictionary, type: String, price: int, index: int = -1) -> void:
	item_data = data
	item_type = type
	item_price = price
	item_index = index

	# 更新显示
	_update_display()

# 更新显示
func _update_display() -> void:
	# 设置物品名称
	var item_name = ""
	if item_type == "chess":
		# 使用本地化系统获取名称，并提供回退数据
		var tr_key = "game.chess." + item_data.id
		item_name = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "equipment":
		# 使用本地化系统获取名称，并提供回退数据
		var tr_key = "game.equipment." + item_data.id
		item_name = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "relic":
		item_name = item_data.name

	$VBoxContainer/NameLabel.text = item_name

	# 设置物品价格
	$VBoxContainer/PriceContainer/PriceLabel.text = str(item_price)

	# 设置物品图标
	var icon_path = ""
	if item_type == "chess":
		icon_path = "res://assets/images/chess/" + item_data.icon
	elif item_type == "equipment":
		icon_path = "res://assets/images/equipment/" + item_data.icon
	elif item_type == "relic":
		icon_path = item_data.icon_path

	if ResourceLoader.exists(icon_path):
		$VBoxContainer/MarginContainer/IconPanel/IconTexture.texture = load(icon_path)

	# 设置稀有度指示器
	var rarity = GameConsts.Rarity.COMMON
	if item_type == "chess":
		# 1-5费对应0-4稀有度
		var cost_rarity = item_data.cost - 1
		rarity = clamp(cost_rarity, GameConsts.Rarity.COMMON, GameConsts.Rarity.LEGENDARY)
	elif item_type == "equipment" or item_type == "relic":
		rarity = item_data.rarity if item_data.has("rarity") else GameConsts.Rarity.COMMON

	$VBoxContainer/MarginContainer/IconPanel/RarityIndicator.color = GameConsts.get_rarity_color(rarity)

	# 设置类型指示器
	$VBoxContainer/MarginContainer/IconPanel/TypeIndicator.text = TYPE_INDICATORS.get(item_type, "?")

	# 设置边框颜色
	var style = get_theme_stylebox("panel").duplicate()
	style.border_color = GameConsts.get_rarity_color(rarity)
	add_theme_stylebox_override("panel", style)

	# 更新工具提示内容
	_update_tooltip_content()

# 更新工具提示内容
func _update_tooltip_content() -> void:
	# 设置标题
	var title = ""
	if item_type == "chess":
		# 使用本地化系统获取名称，并提供回退数据
		var tr_key = "game.chess." + item_data.id
		title = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "equipment":
		# 使用本地化系统获取名称，并提供回退数据
		var tr_key = "game.equipment." + item_data.id
		title = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "relic":
		title = item_data.name

	$TooltipPanel/VBoxContainer/TitleLabel.text = title

	# 设置描述
	var description = ""
	if item_type == "chess":
		# 使用本地化系统获取描述，并提供回退数据
		var tr_key = "game.chess." + item_data.id + ".description"
		description = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "equipment":
		# 使用本地化系统获取描述，并提供回退数据
		var tr_key = "game.equipment." + item_data.id + ".description"
		description = LocalizationManager.translate(tr_key, [], item_data)
	elif item_type == "relic":
		description = item_data.description

	$TooltipPanel/VBoxContainer/DescriptionLabel.text = description

	# 设置属性
	var stats_text = ""
	if item_type == "chess":
		stats_text = "费用: " + str(item_data.cost) + "\n"
		if item_data.has("health"):
			stats_text += "生命: " + str(item_data.health) + "\n"
		if item_data.has("attack"):
			stats_text += "攻击: " + str(item_data.attack) + "\n"
		if item_data.has("synergies"):
			var synergies_str = ", ".join(PackedStringArray(item_data.synergies))
			stats_text += "羁绊: " + synergies_str
	elif item_type == "equipment":
		if item_data.has("stats"):
			for stat in item_data.stats:
				stats_text += stat + ": " + str(item_data.stats[stat]) + "\n"
	elif item_type == "relic":
		if item_data.has("effects"):
			for effect in item_data.effects:
				if effect.has("description"):
					stats_text += effect.description + "\n"

	$TooltipPanel/VBoxContainer/StatsLabel.text = stats_text

# 更新工具提示位置
func _update_tooltip_position() -> void:
	var tooltip = $TooltipPanel
	var global_pos = get_global_position()
	var viewport_size = get_viewport_rect().size

	# 默认显示在右侧
	var pos_x = global_pos.x + size.x + 10
	var pos_y = global_pos.y

	# 如果右侧空间不足，显示在左侧
	if pos_x + tooltip.size.x > viewport_size.x:
		pos_x = global_pos.x - tooltip.size.x - 10

	# 如果底部空间不足，向上调整
	if pos_y + tooltip.size.y > viewport_size.y:
		pos_y = viewport_size.y - tooltip.size.y - 10

	tooltip.global_position = Vector2(pos_x, pos_y)

# 设置可购买状态
func set_purchasable(can_purchase: bool) -> void:
	$VBoxContainer/BuyButton.disabled = !can_purchase

	if can_purchase:
		$VBoxContainer/BuyButton.text = "购买"
	else:
		$VBoxContainer/BuyButton.text = "金币不足"

# 购买按钮点击事件
func _on_buy_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	item_purchased.emit(item_data, item_type, item_price)

# 鼠标进入事件
func _on_mouse_entered() -> void:
	# 显示工具提示
	_update_tooltip_position()
	$TooltipPanel.visible = true

	# 高亮显示
	modulate = Color(1.2, 1.2, 1.2)

# 鼠标离开事件
func _on_mouse_exited() -> void:
	# 隐藏工具提示
	$TooltipPanel.visible = false

	# 恢复正常显示
	modulate = Color(1, 1, 1)

# 鼠标输入事件
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_selected.emit(self)
