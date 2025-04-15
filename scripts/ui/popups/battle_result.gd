extends BasePopup
class_name BattleResult
## 战斗结果弹窗
## 用于显示战斗结果和奖励

# 初始化
func _initialize() -> void:
	# 连接按钮信号
	if has_node("ContinueButton"):
		get_node("ContinueButton").pressed.connect(_on_continue_button_pressed)
	
	# 调用父类方法
	super._initialize()

# 更新弹窗
func _update_popup() -> void:
	# 设置标题
	var is_victory = popup_data.get("is_victory", false)
	title = tr("ui.battle.victory_title") if is_victory else tr("ui.battle.defeat_title")
	
	# 设置结果文本
	if has_node("ResultLabel"):
		var result_label = get_node("ResultLabel")
		result_label.text = tr("ui.battle.victory_text") if is_victory else tr("ui.battle.defeat_text")
	
	# 设置奖励
	_update_rewards()
	
	# 播放结果音效
	if is_victory:
		AudioManager.play_sfx("victory.ogg")
	else:
		AudioManager.play_sfx("defeat.ogg")

# 更新奖励
func _update_rewards() -> void:
	# 获取奖励容器
	var rewards_container = get_node_or_null("RewardsContainer")
	if rewards_container == null:
		return
	
	# 清空容器
	for child in rewards_container.get_children():
		child.queue_free()
	
	# 获取奖励
	var rewards = popup_data.get("rewards", {})
	if rewards.is_empty():
		return
	
	# 添加奖励标签
	var rewards_label = Label.new()
	rewards_label.text = tr("ui.battle.rewards")
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_container.add_child(rewards_label)
	
	# 添加金币奖励
	if rewards.has("gold"):
		var gold_label = Label.new()
		gold_label.text = tr("ui.battle.reward_gold", [str(rewards.gold)])
		rewards_container.add_child(gold_label)
	
	# 添加经验奖励
	if rewards.has("exp"):
		var exp_label = Label.new()
		exp_label.text = tr("ui.battle.reward_exp", [str(rewards.exp)])
		rewards_container.add_child(exp_label)
	
	# 添加装备奖励
	if rewards.has("equipment"):
		var equipment_data = rewards.equipment
		
		if equipment_data.has("id"):
			var equipment_id = equipment_data.id
			var equipment_config = config_manager.get_equipment(equipment_id)
			
			if equipment_config:
				var equipment_label = Label.new()
				equipment_label.text = tr("ui.battle.reward_equipment_specific", [tr("equipment." + equipment_id + ".name")])
				rewards_container.add_child(equipment_label)
		elif equipment_data.has("guaranteed") and equipment_data.guaranteed:
			var quality = equipment_data.get("quality", 1)
			var equipment_label = Label.new()
			equipment_label.text = tr("ui.battle.reward_equipment", [str(quality)])
			rewards_container.add_child(equipment_label)
	
	# 添加遗物奖励
	if rewards.has("relic"):
		var relic_data = rewards.relic
		
		if relic_data.has("id"):
			var relic_id = relic_data.id
			var relic_config = config_manager.get_relic(relic_id)
			
			if relic_config:
				var relic_label = Label.new()
				relic_label.text = tr("ui.battle.reward_relic_specific", [tr("relic." + relic_id + ".name")])
				rewards_container.add_child(relic_label)
		elif relic_data.has("guaranteed") and relic_data.guaranteed:
			var rarity = relic_data.get("rarity", 0)
			var relic_label = Label.new()
			relic_label.text = tr("ui.battle.reward_relic", [str(rarity)])
			rewards_container.add_child(relic_label)

# 继续按钮点击处理
func _on_continue_button_pressed() -> void:
	# 播放按钮音效
	play_ui_sound("button_click.ogg")
	
	# 关闭弹窗
	close_popup()
