extends BaseHUD
class_name MapHUD
## 地图HUD
## 显示地图相关信息，如当前层数、节点信息等

# 地图管理器引用
var map_manager = null

# 当前选中的节点
var selected_node = null

# 初始化
func _initialize() -> void:
	# 获取地图管理器
	map_manager = GameManager.map_manager

	# 连接地图信号
	GlobalEventBus.map.add_listener("map_node_selected", _on_map_node_selected)
	GlobalEventBus.map.add_listener("map_node_hovered", _on_map_node_hovered)
	GlobalEventBus.map.add_listener("map_completed", _on_map_completed)

	# 更新显示
	update_hud()

	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	if map_manager == null:
		return

	# 获取当前地图数据
	var map_data = map_manager.get_current_map()
	var current_node = map_manager.get_current_node()

	# 更新层数显示
	if has_node("LayerLabel") and current_node:
		var layer_label = get_node("LayerLabel")
		layer_label.text = tr("ui.map.layer")+ str(current_node.layer + 1)+ str(map_data.layers)

	# 更新节点信息显示
	_update_node_info(selected_node if selected_node else current_node)

	# 调用父类方法
	super.update_hud()

# 更新节点信息
func _update_node_info(node) -> void:
	if node == null:
		return

	# 更新节点类型显示
	if has_node("NodeTypeLabel"):
		var node_type_label = get_node("NodeTypeLabel")
		node_type_label.text = node.get_type_name()

	# 更新节点描述显示
	if has_node("NodeDescriptionLabel"):
		var node_desc_label = get_node("NodeDescriptionLabel")
		node_desc_label.text = node.get_description()

	# 更新节点奖励显示
	if has_node("NodeRewardsLabel"):
		var node_rewards_label = get_node("NodeRewardsLabel")
		node_rewards_label.text = node.get_rewards_description()

	# 更新节点难度显示
	if has_node("NodeDifficultyLabel"):
		var node_difficulty_label = get_node("NodeDifficultyLabel")
		node_difficulty_label.text = node.get_difficulty_description()

# 地图节点选择处理
func _on_map_node_selected(node_data: MapNode) -> void:
	# 更新选中节点
	selected_node = node_data

	# 更新显示
	update_hud()

# 地图节点悬停处理
func _on_map_node_hovered(node_data: MapNode) -> void:
	# 更新悬停节点信息
	var node = node_data
	_update_node_info(node)

# 地图完成处理
func _on_map_completed() -> void:
	# 显示地图完成提示
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo",tr("ui.map.completed")))

	# 播放完成音效
	AudioManager.play_sfx("map_completed.ogg")

# 显示节点详情
func show_node_details(node) -> void:
	if node == null:
		return

	# 创建节点详情弹窗
	var popup_data = {
		"node": node
	}

	GameManager.ui_manager.show_popup("node_details", popup_data)
