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

	# 清除现有的效果
	if has_node("GlowEffect"):
		get_node("GlowEffect").queue_free()
	if has_node("PulseEffect"):
		get_node("PulseEffect").queue_free()
	if has_node("ParticleEffect"):
		get_node("ParticleEffect").queue_free()
	if has_node("NodeMarker"):
		get_node("NodeMarker").queue_free()

	if is_current:
		# 当前节点
		modulate = Color(1, 1, 0)  # 黄色
		scale = Vector2(1.2, 1.2)  # 稍微放大

		# 添加光晕效果
		var glow_effect = ColorRect.new()
		glow_effect.name = "GlowEffect"
		glow_effect.color = Color(1, 1, 0.5, 0.3)
		glow_effect.size = Vector2(100, 100)
		glow_effect.position = Vector2(-50, -50)
		glow_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(glow_effect)

		# 创建光晕动画
		var tween = create_tween().set_loops()
		tween.tween_property(glow_effect, "modulate:a", 0.7, 0.5)
		tween.tween_property(glow_effect, "modulate:a", 0.3, 0.5)

		# 添加当前节点标记
		var marker = Label.new()
		marker.name = "NodeMarker"
		marker.text = "当前"
		marker.position = Vector2(-20, -40)
		marker.add_theme_color_override("font_color", Color(1, 1, 0))
		add_child(marker)

		# 添加粒子效果
		_add_particle_effect(Color(1, 1, 0.5, 0.7))
	elif is_visited:
		# 已访问节点
		modulate = Color(0.5, 0.5, 0.5, 0.7)  # 灰色半透明

		# 添加已访问标记
		var marker = Label.new()
		marker.name = "NodeMarker"
		marker.text = "已访问"
		marker.position = Vector2(-20, -40)
		marker.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(marker)

		# 添加已访问效果
		var visited_effect = ColorRect.new()
		visited_effect.name = "GlowEffect"
		visited_effect.color = Color(0.5, 0.5, 0.5, 0.2)
		visited_effect.size = Vector2(80, 80)
		visited_effect.position = Vector2(-40, -40)
		visited_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(visited_effect)
	elif is_selectable:
		# 可选节点
		modulate = _get_node_color(node_data.type)
		$Button.disabled = false

		# 添加脉动效果
		var pulse_effect = ColorRect.new()
		pulse_effect.name = "PulseEffect"
		pulse_effect.color = _get_node_color(node_data.type) * 1.2  # 稍微亮一点
		pulse_effect.color.a = 0.3
		pulse_effect.size = Vector2(80, 80)
		pulse_effect.position = Vector2(-40, -40)
		pulse_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pulse_effect)

		# 创建脉动动画
		var tween = create_tween().set_loops()
		tween.tween_property(pulse_effect, "scale", Vector2(1.2, 1.2), 0.8)
		tween.parallel().tween_property(pulse_effect, "modulate:a", 0.1, 0.8)
		tween.tween_property(pulse_effect, "scale", Vector2(1.0, 1.0), 0.8)
		tween.parallel().tween_property(pulse_effect, "modulate:a", 0.5, 0.8)

		# 添加可选标记
		var marker = Label.new()
		marker.name = "NodeMarker"
		marker.text = "可选"
		marker.position = Vector2(-20, -40)
		marker.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		add_child(marker)

		# 添加粒子效果
		_add_particle_effect(_get_node_color(node_data.type))
	else:
		# 不可选节点
		modulate = Color(0.3, 0.3, 0.3, 0.5)  # 半透明灰色

		# 添加不可选标记
		var marker = Label.new()
		marker.name = "NodeMarker"
		marker.text = "锁定"
		marker.position = Vector2(-20, -40)
		marker.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(marker)

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

		# 创建悬停效果
		var hover_effect = ColorRect.new()
		hover_effect.name = "HoverEffect"
		hover_effect.color = Color(1, 1, 1, 0.2)
		hover_effect.size = Vector2(70, 70)
		hover_effect.position = Vector2(-35, -35)
		hover_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hover_effect)

		# 显示节点提示
		_show_node_tooltip()

		# 发送悬停信号
		EventBus.map.map_node_hovered.emit(node_data)

## 鼠标离开处理
func _on_mouse_exited() -> void:
	if not $Button.disabled:
		# 恢复原始大小
		scale = Vector2(1.0, 1.0)

		# 移除悬停效果
		if has_node("HoverEffect"):
			get_node("HoverEffect").queue_free()

		# 隐藏提示
		_hide_node_tooltip()

		# 发送节点离开信号
		EventBus.map_node_unhovered.emit()

## 显示节点提示
func _show_node_tooltip() -> void:
	# 创建提示面板
	var tooltip = Control.new()
	tooltip.name = "NodeTooltip"
	tooltip.size = Vector2(200, 150)
	tooltip.position = Vector2(40, -75)  # 在节点右侧显示
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建背景面板
	var panel = Panel.new()
	panel.size = tooltip.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_child(panel)

	# 创建内容容器
	var container = VBoxContainer.new()
	container.size = Vector2(180, 130)
	container.position = Vector2(10, 10)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_child(container)

	# 添加标题
	var title = Label.new()
	title.text = _get_node_type_name(node_data.type)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", _get_node_color(node_data.type))
	container.add_child(title)

	# 添加分隔线
	var separator = HSeparator.new()
	container.add_child(separator)

	# 添加描述
	var description = Label.new()
	description.text = _get_node_description(node_data.type)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(description)

	# 添加奖励信息（如果有）
	if node_data.has("rewards") and not node_data.rewards.is_empty():
		var rewards_title = Label.new()
		rewards_title.text = "可能的奖励:"
		rewards_title.add_theme_font_size_override("font_size", 14)
		container.add_child(rewards_title)

		var rewards_text = _get_rewards_text(node_data.rewards)
		var rewards_label = Label.new()
		rewards_label.text = rewards_text
		rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(rewards_label)

	add_child(tooltip)

## 隐藏节点提示
func _hide_node_tooltip() -> void:
	if has_node("NodeTooltip"):
		get_node("NodeTooltip").queue_free()

## 获取节点描述
func _get_node_description(node_type: String) -> String:
	var descriptions = {
		"battle": "与普通敌人战斗。可能获得金币和装备。",
		"elite_battle": "与精英敌人战斗。挑战难度更高，但奖励更丰厚。",
		"boss": "与Boss战斗。非常危险，但有特殊奖励。",
		"shop": "商店节点。可以购买棋子、装备和道具。",
		"event": "随机事件。可能有好处也可能有坏处。",
		"treasure": "宝藏节点。必定获得特殊奖励。",
		"rest": "休息节点。恢复生命值并可能获得额外效果。"
	}

	return descriptions.get(node_type, "未知节点类型")

## 获取奖励文本
func _get_rewards_text(rewards: Dictionary) -> String:
	var text = ""

	if rewards.has("gold"):
		text += "金币: " + str(rewards.gold) + "\n"

	if rewards.has("exp"):
		text += "经验: " + str(rewards.exp) + "\n"

	if rewards.has("equipment_chance"):
		var chance = int(rewards.equipment_chance * 100)
		text += "装备概率: " + str(chance) + "%\n"

	if rewards.has("equipment") and rewards.equipment.has("guaranteed") and rewards.equipment.guaranteed:
		text += "保证装备\n"

	if rewards.has("relic_chance"):
		var chance = int(rewards.relic_chance * 100)
		text += "遗物概率: " + str(chance) + "%\n"

	if rewards.has("relic") and rewards.relic.has("guaranteed") and rewards.relic.guaranteed:
		text += "保证遗物\n"

	if rewards.has("heal"):
		text += "治疗: " + str(rewards.heal) + "\n"

	return text

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

			tooltip += LocalizationManager.tr("ui.map.difficulty").format({"difficulty": difficulty_text, "level": str(node_data.get("enemy_level", 1))}) + "\n"

			# 添加奖励信息
			var rewards = node_data.get("rewards", {})
			if rewards.has("gold"):
				tooltip += LocalizationManager.tr("ui.map.reward_gold").format({"amount": str(rewards.gold)}) + "\n"
			if rewards.has("exp"):
				tooltip += LocalizationManager.tr("ui.map.reward_exp").format({"amount": str(rewards.exp)}) + "\n"
		"shop":
			# 添加商店信息
			if node_data.get("discount", false):
				tooltip += LocalizationManager.tr("ui.shop.discount").format({"percent": "20%"}) + "\n"
		"treasure":
			# 添加宝藏信息
			var rewards = node_data.get("rewards", {})
			if rewards.has("gold"):
				tooltip += LocalizationManager.tr("ui.map.reward_gold").format({"amount": str(rewards.gold)}) + "\n"
			if rewards.has("equipment") and rewards.equipment.has("guaranteed") and rewards.equipment.guaranteed:
				var quality = rewards.equipment.get("quality", 1)
				tooltip += LocalizationManager.tr("ui.map.reward_equipment").format({"quality": str(quality)}) + "\n"
			if rewards.has("relic") and rewards.relic.has("guaranteed") and rewards.relic.guaranteed:
				var rarity = rewards.relic.get("rarity", 0)
				tooltip += LocalizationManager.tr("ui.map.reward_relic").format({"rarity": str(rarity)}) + "\n"
		"rest":
			# 添加休息信息
			var heal_amount = node_data.get("heal_amount", 0)
			tooltip += LocalizationManager.tr("ui.map.reward_heal").format({"amount": str(heal_amount)}) + "\n"
		"event":
			# 添加事件信息
			tooltip += LocalizationManager.tr("ui.event.random_event") + "\n"

	return tooltip.strip_edges()



## 添加粒子效果
func _add_particle_effect(color: Color) -> void:
	# 创建粒子容器
	var particle_container = Node2D.new()
	particle_container.name = "ParticleEffect"
	add_child(particle_container)

	# 创建多个粒子
	for i in range(5):
		# 创建粒子
		var particle = ColorRect.new()
		particle.color = color
		particle.size = Vector2(4, 4)
		particle.position = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		particle_container.add_child(particle)

		# 创建粒子动画
		var tween = create_tween().set_loops()
		tween.tween_property(particle, "position",
			particle.position + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			randf_range(0.5, 1.5))
		tween.tween_property(particle, "position",
			particle.position,
			randf_range(0.5, 1.5))

		# 创建透明度动画
		var alpha_tween = create_tween().set_loops()
		alpha_tween.tween_property(particle, "modulate:a", 0.3, randf_range(0.5, 1.0))
		alpha_tween.tween_property(particle, "modulate:a", 1.0, randf_range(0.5, 1.0))
