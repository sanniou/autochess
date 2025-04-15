extends BasePopup
class_name NodeDetails
## 节点详情弹窗
## 用于显示地图节点的详细信息

# 初始化
func _initialize() -> void:
	# 连接按钮信号
	if has_node("CloseButton"):
		get_node("CloseButton").pressed.connect(_on_close_button_pressed)
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 获取节点
	var node = popup_data.get("node")
	if node == null:
		close_popup()
		return
	
	# 设置标题
	title = node.get_type_name()
	
	# 设置图标
	if has_node("NodeIcon"):
		var node_icon = get_node("NodeIcon")
		node_icon.texture = load(node.icon_path)
	
	# 设置描述
	if has_node("DescriptionLabel"):
		var description_label = get_node("DescriptionLabel")
		description_label.text = node.get_description()
	
	# 设置难度
	if has_node("DifficultyLabel"):
		var difficulty_label = get_node("DifficultyLabel")
		difficulty_label.text = node.get_difficulty_description()
	
	# 设置奖励
	if has_node("RewardsLabel"):
		var rewards_label = get_node("RewardsLabel")
		rewards_label.text = node.get_rewards_description()

# 关闭按钮点击处理
func _on_close_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
