extends Control
class_name AchievementItem
## 成就项
## 显示单个成就的信息和状态

# 成就数据
var achievement_id: String = ""
var achievement_data: Dictionary = {}
var is_unlocked: bool = false

# 引用
@onready var icon = $HBoxContainer/Icon
@onready var lock_icon = $HBoxContainer/Icon/LockIcon
@onready var name_label = $HBoxContainer/VBoxContainer/NameLabel
@onready var description_label = $HBoxContainer/VBoxContainer/DescriptionLabel
@onready var progress_bar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var progress_label = $HBoxContainer/VBoxContainer/ProgressLabel
@onready var reward_container = $HBoxContainer/VBoxContainer/RewardContainer
@onready var tooltip = $Tooltip

# 初始化
func _ready() -> void:
	# 更新UI
	_update_ui()
	
	# 连接信号
	_connect_signals()

# 连接信号
func _connect_signals() -> void:
	# 连接鼠标进入和退出信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# 设置成就数据
func set_achievement_data(id: String, data: Dictionary) -> void:
	achievement_id = id
	achievement_data = data
	
	# 如果已经准备好，更新UI
	if is_inside_tree():
		_update_ui()

# 设置解锁状态
func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked
	
	# 如果已经准备好，更新UI
	if is_inside_tree():
		_update_ui()

# 设置进度
func set_progress(progress: float, max_progress: float) -> void:
	# 计算进度百分比
	var progress_percentage = progress / max_progress if max_progress > 0 else 0.0
	
	# 更新进度条
	if progress_bar:
		progress_bar.value = progress_percentage * 100
	
	# 更新进度文本
	if progress_label:
		progress_label.text = tr("ui.achievement.progress_value").format({
			"current": int(progress),
			"max": int(max_progress)
		})
	
	# 如果已经解锁，隐藏进度显示
	if is_unlocked:
		if progress_bar:
			progress_bar.visible = false
		if progress_label:
			progress_label.visible = false

# 更新UI
func _update_ui() -> void:
	# 设置成就图标
	var icon_path = achievement_data.get("icon_path", "")
	if icon_path != "" and icon:
		var texture = load(icon_path)
		if texture:
			icon.texture = texture
	
	# 设置锁定图标
	if lock_icon:
		lock_icon.visible = not is_unlocked
	
	# 设置成就名称
	if name_label:
		name_label.text = achievement_data.get("name", "")
	
	# 设置成就描述
	if description_label:
		description_label.text = achievement_data.get("description", "")
	
	# 设置解锁状态样式
	if is_unlocked:
		# 已解锁样式
		modulate = Color(1, 1, 1, 1)
		if name_label:
			name_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
		if description_label:
			description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		
		# 隐藏进度显示
		if progress_bar:
			progress_bar.visible = false
		if progress_label:
			progress_label.visible = false
	else:
		# 未解锁样式
		modulate = Color(0.7, 0.7, 0.7, 1)
		if name_label:
			name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		if description_label:
			description_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		
		# 显示进度显示
		if progress_bar:
			progress_bar.visible = true
		if progress_label:
			progress_label.visible = true
	
	# 设置奖励显示
	_update_reward_display()
	
	# 设置工具提示
	_update_tooltip()

# 更新奖励显示
func _update_reward_display() -> void:
	# 清空奖励容器
	if reward_container:
		for child in reward_container.get_children():
			child.queue_free()
		
		# 获取成就奖励
		var rewards = achievement_data.get("rewards", {})
		
		# 添加金币奖励
		if rewards.has("gold") and rewards.gold > 0:
			var gold_label = Label.new()
			gold_label.text = tr("ui.achievement.reward_gold").format({"amount": rewards.gold})
			gold_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
			reward_container.add_child(gold_label)
		
		# 添加经验奖励
		if rewards.has("exp") and rewards.exp > 0:
			var exp_label = Label.new()
			exp_label.text = tr("ui.achievement.reward_exp").format({"amount": rewards.exp})
			exp_label.add_theme_color_override("font_color", Color(0, 0.8, 1, 1))
			reward_container.add_child(exp_label)
		
		# 添加解锁物品奖励
		if rewards.has("unlock_item") and rewards.unlock_item != "":
			var item_label = Label.new()
			item_label.text = tr("ui.achievement.reward_unlock")
			item_label.add_theme_color_override("font_color", Color(0, 1, 0.5, 1))
			reward_container.add_child(item_label)

# 更新工具提示
func _update_tooltip() -> void:
	if tooltip:
		# 设置工具提示内容
		var tooltip_text = ""
		
		# 添加成就名称
		tooltip_text += "[b]" + achievement_data.get("name", "") + "[/b]\n\n"
		
		# 添加成就描述
		tooltip_text += achievement_data.get("description", "") + "\n\n"
		
		# 添加解锁状态
		if is_unlocked:
			tooltip_text += tr("ui.achievement.unlocked") + "\n"
		else:
			tooltip_text += tr("ui.achievement.locked") + "\n"
		
		# 添加奖励信息
		var rewards = achievement_data.get("rewards", {})
		if not rewards.is_empty():
			tooltip_text += "\n" + tr("ui.achievement.rewards") + ":\n"
			
			# 添加金币奖励
			if rewards.has("gold") and rewards.gold > 0:
				tooltip_text += "- " + tr("ui.achievement.reward_gold").format({"amount": rewards.gold}) + "\n"
			
			# 添加经验奖励
			if rewards.has("exp") and rewards.exp > 0:
				tooltip_text += "- " + tr("ui.achievement.reward_exp").format({"amount": rewards.exp}) + "\n"
			
			# 添加解锁物品奖励
			if rewards.has("unlock_item") and rewards.unlock_item != "":
				tooltip_text += "- " + tr("ui.achievement.reward_unlock") + "\n"
		
		# 设置工具提示文本
		tooltip.tooltip_text = tooltip_text

# 鼠标进入处理
func _on_mouse_entered() -> void:
	# 显示高亮效果
	modulate = Color(1, 1, 1, 1)
	
	# 显示工具提示
	if tooltip:
		tooltip.visible = true

# 鼠标退出处理
func _on_mouse_exited() -> void:
	# 恢复正常效果
	if not is_unlocked:
		modulate = Color(0.7, 0.7, 0.7, 1)
	
	# 隐藏工具提示
	if tooltip:
		tooltip.visible = false
