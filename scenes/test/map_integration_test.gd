extends Control
## 地图集成测试场景
## 用于测试地图生成和节点交互

# 导入配置类型枚举
const ConfigTypes = preload("res://scripts/config/config_types.gd")

# 地图管理器
var map_manager:MapManager = null

# 地图控制器
var map_controller:MapController = null

# 地图渲染器
var map_renderer:MapRenderer = null

# 当前地图数据
var current_map:MapData = null

# 当前选中的节点
var selected_node:MapNode = null

# 初始化
func _ready():
	# 获取管理器引用
	map_manager = GameManager.map_manager

	# 初始化UI
	_initialize_ui()

	# 初始化地图模板选择器
	_initialize_template_selector()

	# 创建地图渲染器
	_create_map_renderer()

# 初始化UI
func _initialize_ui() -> void:
	# 更新按钮状态
	_update_buttons()

# 初始化地图模板选择器
func _initialize_template_selector() -> void:
	# 加载所有可用地图模板
	var config_manager = GameManager.config_manager
	if config_manager:
		var map_configs = config_manager.get_config_enum(ConfigTypes.Type.MAP_CONFIG)
		if map_configs and map_configs.has("map_config") and map_configs.map_config.has("templates"):
			var templates = map_configs.map_config.templates

			# 填充模板选择下拉菜单
			var template_dropdown = $ControlPanel/TemplateSelector/TemplateDropdown

			if template_dropdown:
				for template_id in templates.keys():
					var template_data = templates[template_id]
					var template_name = template_data.get("name", template_id)
					var display_name = template_name + " (难度: " + str(template_data.get("difficulty", 1)) + ")"

					# 添加项目并存储ID
					var item_index = template_dropdown.item_count
					template_dropdown.add_item(display_name)
					template_dropdown.set_item_metadata(item_index, template_id)

# 初始化地图渲染器
func _create_map_renderer() -> void:
	# 获取场景中已有的渲染器
	map_renderer = $MapContainer/MapRenderer2D

	if map_renderer and map_manager:
		# 连接信号
		map_renderer.node_clicked.connect(_on_map_node_clicked)
		map_renderer.node_hovered.connect(_on_map_node_hovered)
		map_renderer.node_unhovered.connect(_on_map_node_unhovered)

		# 将渲染器提供给MapManager
		map_manager.set_renderer(map_renderer)

		print("地图渲染器初始化完成")

# 更新按钮状态
func _update_buttons() -> void:
	if has_node("ControlPanel/ButtonContainer"):
		# 获取按钮引用
		var clear_button = $ControlPanel/ButtonContainer/ClearButton
		var save_button = $ControlPanel/ButtonContainer/SaveButton

		# 根据当前状态更新按钮
		clear_button.disabled = current_map == null
		save_button.disabled = current_map == null

		# 更新节点操作按钮
		if has_node("NodePanel/ButtonContainer"):
			var activate_button = $NodePanel/ButtonContainer/ActivateButton
			var complete_button = $NodePanel/ButtonContainer/CompleteButton

			activate_button.disabled = selected_node == null
			complete_button.disabled = selected_node == null

# 生成地图
func _generate_map() -> void:
	# 获取选择的模板
	var template_id = "standard"
	if has_node("ControlPanel/TemplateSelector/TemplateDropdown"):
		var dropdown = $ControlPanel/TemplateSelector/TemplateDropdown
		var selected_idx = dropdown.selected

		if selected_idx >= 0:
			var metadata = dropdown.get_item_metadata(selected_idx)
			if metadata != null:
				# 使用元数据作为模板ID
				template_id = str(metadata)

	# 获取难度
	var difficulty = 1
	if has_node("ControlPanel/DifficultySelector/DifficultySpinBox"):
		difficulty = $ControlPanel/DifficultySelector/DifficultySpinBox.value

	# 获取种子
	var seed_value = -1
	if has_node("ControlPanel/SeedSelector/SeedSpinBox"):
		seed_value = $ControlPanel/SeedSelector/SeedSpinBox.value
		if seed_value == 0:  # 0表示随机种子
			seed_value = -1

	# 生成地图
	if map_manager:
		map_manager.initialize_map(template_id, difficulty, seed_value)
		current_map = map_manager.current_map

		# 更新地图渲染器
		map_manager.load_map(current_map)

		# 更新按钮状态
		_update_buttons()

		# 更新地图信息
		_update_map_info()

# 清除地图
func _clear_map() -> void:
	# 使用MapManager清除地图
	if map_manager:
		map_manager.clear_map()

	current_map = null
	selected_node = null

	# 更新按钮状态
	_update_buttons()

	# 清除地图信息
	if has_node("InfoPanel/MapInfo"):
		$InfoPanel/MapInfo.text = "未生成地图"

	# 清除节点信息
	if has_node("NodePanel"):
		$NodePanel.visible = false

	# 注意：不需要手动清理渲染器，MapManager.clear_map() 已经处理了这部分工作
	# 渲染器会保留在场景中，但其内容已被清除

# 更新地图信息
func _update_map_info() -> void:
	if current_map and has_node("InfoPanel/MapInfo"):
		var info_text = "地图信息：\n"
		info_text += "模板：" + current_map.template_id + "\n"
		info_text += "难度：" + str(current_map.difficulty) + "\n"
		info_text += "层数：" + str(current_map.layers) + "\n"
		info_text += "节点总数：" + str(current_map.nodes.size()) + "\n"
		#info_text += "已访问节点：" + str(current_map.visited_nodes.size()) + "\n"
		#info_text += "可访问节点：" + str(current_map.available_nodes.size()) + "\n"

		$InfoPanel/MapInfo.text = info_text

# 更新节点信息
func _update_node_info() -> void:
	if selected_node and has_node("NodePanel"):
		$NodePanel.visible = true

		if has_node("NodePanel/NodeInfo"):
			var info_text = "节点信息：\n"
			info_text += "ID：" + selected_node.id + "\n"
			info_text += "类型：" + selected_node.type + "\n"
			info_text += "层级：" + str(selected_node.layer) + "\n"
			info_text += "位置：" + str(selected_node.position) + "\n"
			info_text += "状态：" + ("已访问" if selected_node.visited else "未访问") + "\n"
			#info_text += "可访问：" + ("是" if selected_node.available else "否") + "\n"

			# 添加节点特定属性
			if selected_node.properties:
				info_text += "\n节点数据：\n"
				for key in selected_node.properties.keys():
					info_text += key + ": " + str(selected_node.properties[key]) + "\n"

			$NodePanel/NodeInfo.text = info_text
	else:
		if has_node("NodePanel"):
			$NodePanel.visible = false

# 激活节点
func _activate_node() -> void:
	if selected_node and map_manager:
		# 激活节点
		map_manager.activate_node(selected_node.id)

		# 更新地图信息
		_update_map_info()

		# 更新节点信息
		_update_node_info()

		# 更新地图渲染器
		if map_renderer:
			map_renderer.update_nodes()

		# 显示消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "已激活节点：" + selected_node.id
			$MessageLabel.visible = true

			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 完成节点
func _complete_node() -> void:
	if selected_node and map_manager:
		# 完成节点
		map_manager.complete_node(selected_node.id)

		# 更新地图信息
		_update_map_info()

		# 更新节点信息
		_update_node_info()

		# 更新地图渲染器
		if map_renderer:
			map_renderer.update_nodes()

		# 显示消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "已完成节点：" + selected_node.id
			$MessageLabel.visible = true

			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 保存地图
func _save_map() -> void:
	if current_map:
		# 构建保存数据
		var save_data = {
			"template_id": current_map.template_id,
			"difficulty": current_map.difficulty,
			"seed": current_map.seed_value,
			"visited_nodes": [],
			"available_nodes": []
		}

		# 保存已访问节点
		for node_id in current_map.visited_nodes:
			save_data.visited_nodes.append(node_id)

		# 保存可访问节点
		for node_id in current_map.available_nodes:
			save_data.available_nodes.append(node_id)

		# 保存到文件
		var save_path = "user://map_test_save.json"
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(save_data, "  "))
			file.close()

			# 显示消息
			if has_node("MessageLabel"):
				$MessageLabel.text = "地图已保存"
				$MessageLabel.visible = true

				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)

# 加载地图
func _load_map() -> void:
	# 加载保存文件
	var load_path = "user://map_test_save.json"
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()

			var json_result = JSON.parse_string(json_text)
			if json_result:
				# 生成地图
				if map_manager:
					map_manager.initialize_map(
						json_result.template_id,
						json_result.difficulty,
						json_result.seed
					)
					current_map = map_manager.current_map

					# 设置已访问节点
					for node_id in json_result.visited_nodes:
						map_manager.mark_node_visited(node_id)

					# 设置可访问节点
					for node_id in json_result.available_nodes:
						map_manager.mark_node_available(node_id)

					# 地图已通过MapManager加载，不需要额外更新渲染器

					# 更新按钮状态
					_update_buttons()

					# 更新地图信息
					_update_map_info()

					# 显示消息
					if has_node("MessageLabel"):
						$MessageLabel.text = "地图已加载"
						$MessageLabel.visible = true

						# 3秒后隐藏消息
						var timer = get_tree().create_timer(3.0)
						timer.timeout.connect(func(): $MessageLabel.visible = false)
	else:
		# 显示错误消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "错误：保存文件不存在"
			$MessageLabel.visible = true

			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 地图节点点击处理
func _on_map_node_clicked(node_data) -> void:
	# 设置选中节点
	selected_node = node_data

	# 更新节点信息
	_update_node_info()

	# 更新按钮状态
	_update_buttons()

# 地图节点悬停处理
func _on_map_node_hovered(node_data) -> void:
	# 显示节点提示
	if has_node("TooltipLabel"):
		$TooltipLabel.text = node_data.type.capitalize() + " 节点"
		$TooltipLabel.visible = true

# 地图节点离开处理
func _on_map_node_unhovered(_node_data) -> void:
	# 隐藏节点提示
	if has_node("TooltipLabel"):
		$TooltipLabel.visible = false

# 生成按钮处理
func _on_generate_button_pressed() -> void:
	# 生成地图
	_generate_map()

# 清除按钮处理
func _on_clear_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 清除地图
	_clear_map()

# 保存按钮处理
func _on_save_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 保存地图
	_save_map()

# 加载按钮处理
func _on_load_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 加载地图
	_load_map()

# 激活节点按钮处理
func _on_activate_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 激活节点
	_activate_node()

# 完成节点按钮处理
func _on_complete_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 完成节点
	_complete_node()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 清理资源
	_cleanup_resources()

	# 返回测试中心
	get_tree().change_scene_to_file("res://scenes/test/test_hub.tscn")

# 清理资源
func _cleanup_resources() -> void:
	# 断开渲染器与MapManager的连接
	if map_manager and map_manager.get_active_renderer() == map_renderer:
		# 设置为null会让MapManager清理引用但不销毁渲染器
		map_manager.set_renderer(null)

	# 清理渲染器
	if map_renderer:
		# 断开信号连接
		if map_renderer.node_clicked.is_connected(_on_map_node_clicked):
			map_renderer.node_clicked.disconnect(_on_map_node_clicked)
		if map_renderer.node_hovered.is_connected(_on_map_node_hovered):
			map_renderer.node_hovered.disconnect(_on_map_node_hovered)
		if map_renderer.node_unhovered.is_connected(_on_map_node_unhovered):
			map_renderer.node_unhovered.disconnect(_on_map_node_unhovered)

		# 清理渲染器
		map_renderer.clear_map()

		# 注意：不需要销毁渲染器，因为它是场景的一部分
		# 场景退出时会自动销毁所有子节点
