extends Control
## 地图节点
## 表示地图上的一个节点，可以是战斗、商店、事件等

# 节点数据
var node_data = {}

# 节点选择信号
signal node_selected(node_data)

func _ready():
	# 初始化节点
	$Button.mouse_entered.connect(_on_mouse_entered)
	$Button.mouse_exited.connect(_on_mouse_exited)

## 设置节点数据
func setup(data: Dictionary) -> void:
	node_data = data

	# 设置节点图标
	var icon_path = _get_icon_path(data.type)
	var icon = load(icon_path)
	if icon:
		$Icon.texture = icon

	# 设置节点标签
	$Label.text = _get_node_type_name(data.type)

	# 设置节点颜色
	var color = _get_node_color(data.type)
	modulate = color

## 设置节点状态
func set_state(is_current: bool, is_selectable: bool, is_visited: bool) -> void:
	# 重置效果
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(1, 1)
	$Button.disabled = true

	if is_current:
		# 当前节点
		modulate = Color(1, 1, 0)  # 黄色
		scale = Vector2(1.2, 1.2)  # 稍微放大

		# 添加光晕效果
		var tween = create_tween().set_loops()
		tween.tween_property(self, "modulate", Color(1, 1, 0.5, 1), 0.5)
		tween.tween_property(self, "modulate", Color(1, 1, 0, 1), 0.5)
	elif is_visited:
		# 已访问节点
		modulate = Color(0.5, 0.5, 0.5, 0.7)  # 灰色半透明
	elif is_selectable:
		# 可选节点
		modulate = _get_node_color(node_data.type)
		$Button.disabled = false

		# 添加轻微的呼吸效果
		var tween = create_tween().set_loops()
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.8)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.8)
	else:
		# 不可选节点
		modulate = Color(0.3, 0.3, 0.3, 0.5)  # 半透明灰色

## 获取节点ID
func get_node_id() -> String:
	return node_data.id

## 获取节点图标路径
func _get_icon_path(node_type: String) -> String:
	var node_types = ConfigManager.map_nodes_config.node_types
	if node_types.has(node_type):
		return "res://assets/images/map/" + node_types[node_type].icon

	return "res://assets/images/map/node_battle.png"  # 默认图标

## 获取节点类型名称
func _get_node_type_name(node_type: String) -> String:
	var tr_key = "ui.map.node_" + node_type
	return LocalizationManager.tr(tr_key)

## 获取节点颜色
func _get_node_color(node_type: String) -> Color:
	var node_types = ConfigManager.map_nodes_config.node_types
	if node_types.has(node_type):
		return Color(node_types[node_type].color)

	return Color(1, 1, 1)  # 默认白色

## 按钮点击处理
func _on_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")
	node_selected.emit(node_data)

## 鼠标进入处理
func _on_mouse_entered() -> void:
	if not $Button.disabled:
		# 鼠标悬停效果
		scale = Vector2(1.1, 1.1)  # 缩放效果

		# 显示节点提示
		var tooltip_text = _get_node_tooltip()
		if not tooltip_text.is_empty():
			# 这里可以实现显示提示框，暂时使用事件总线
			EventBus.show_toast.emit(tooltip_text, 2.0)

		# 发送悬停信号
		EventBus.map_node_hovered.emit(node_data)

## 获取节点提示文本
func _get_node_tooltip() -> String:
	var tooltip = _get_node_type_name(node_data.type) + "\n"

	# 根据节点类型添加不同的提示信息
	match node_data.type:
		"battle", "elite_battle", "boss":
			# 添加难度信息
			var difficulty_text = ""
			var difficulty = node_data.get("difficulty", 1.0)

			if difficulty < 1.2:
				difficulty_text = LocalizationManager.tr("ui.map.difficulty_easy")
			elif difficulty < 1.5:
				difficulty_text = LocalizationManager.tr("ui.map.difficulty_normal")
			elif difficulty < 2.0:
				difficulty_text = LocalizationManager.tr("ui.map.difficulty_hard")
			else:
				difficulty_text = LocalizationManager.tr("ui.map.difficulty_extreme")

			tooltip += LocalizationManager.tr("ui.map.difficulty", [difficulty_text, str(node_data.get("enemy_level", 1))]) + "\n"

			# 添加奖励信息
			var rewards = node_data.get("rewards", {})
			if rewards.has("gold"):
				tooltip += LocalizationManager.tr("ui.map.reward_gold", [str(rewards.gold)]) + "\n"
			if rewards.has("exp"):
				tooltip += LocalizationManager.tr("ui.map.reward_exp", [str(rewards.exp)]) + "\n"
		"shop":
			# 添加商店信息
			if node_data.get("discount", false):
				tooltip += LocalizationManager.tr("ui.shop.discount", ["20%"]) + "\n"
		"treasure":
			# 添加宝藏信息
			var rewards = node_data.get("rewards", {})
			if rewards.has("gold"):
				tooltip += LocalizationManager.tr("ui.map.reward_gold", [str(rewards.gold)]) + "\n"
			if rewards.has("equipment") and rewards.equipment.has("guaranteed") and rewards.equipment.guaranteed:
				var quality = rewards.equipment.get("quality", 1)
				tooltip += LocalizationManager.tr("ui.map.reward_equipment", [str(quality)]) + "\n"
			if rewards.has("relic") and rewards.relic.has("guaranteed") and rewards.relic.guaranteed:
				var rarity = rewards.relic.get("rarity", 0)
				tooltip += LocalizationManager.tr("ui.map.reward_relic", [str(rarity)]) + "\n"
		"rest":
			# 添加休息信息
			var heal_amount = node_data.get("heal_amount", 0)
			tooltip += LocalizationManager.tr("ui.map.reward_heal", [str(heal_amount)]) + "\n"
		"event":
			# 添加事件信息
			tooltip += LocalizationManager.tr("ui.event.random_event") + "\n"

	return tooltip.strip_edges()

## 鼠标离开处理
func _on_mouse_exited() -> void:
	# 恢复原始大小
	scale = Vector2(1.0, 1.0)
