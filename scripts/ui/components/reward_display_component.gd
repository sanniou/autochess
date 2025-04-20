extends Control
class_name RewardDisplayComponent
## 奖励显示组件
## 用于显示游戏奖励内容

# 节点引用
@onready var rewards_container = $RewardsContainer if has_node("RewardsContainer") else null

# 奖励数据
var rewards: Dictionary = {}

# 初始化
func _ready() -> void:
	# 清空奖励容器
	clear_rewards()

# 设置奖励数据
func set_rewards(reward_data: Dictionary) -> void:
	rewards = reward_data
	update_rewards()

# 更新奖励显示
func update_rewards() -> void:
	# 清空奖励容器
	clear_rewards()
	
	if rewards_container == null:
		return
	
	# 添加金币奖励
	if rewards.has("gold") and rewards.gold > 0:
		var gold_label = Label.new()
		gold_label.text = tr("ui.reward.gold", [str(rewards.gold)])
		rewards_container.add_child(gold_label)
	
	# 添加经验奖励
	if rewards.has("experience") and rewards.experience > 0:
		var exp_label = Label.new()
		exp_label.text = tr("ui.reward.experience", [str(rewards.experience)])
		rewards_container.add_child(exp_label)
	
	# 添加物品奖励
	if rewards.has("items") and rewards.items.size() > 0:
		for item_data in rewards.items:
			var item_label = Label.new()
			
			if item_data.has("id") and item_data.has("name"):
				item_label.text = tr("ui.reward.item_specific", [item_data.name])
			else:
				item_label.text = tr("ui.reward.item")
				
			rewards_container.add_child(item_label)
	
	# 添加遗物奖励
	if rewards.has("relic"):
		var relic_data = rewards.relic
		
		if relic_data.has("id"):
			var relic_id = relic_data.id
			var relic_config = ConfigManager.get_relic(relic_id)
			
			if relic_config:
				var relic_label = Label.new()
				relic_label.text = tr("ui.reward.relic_specific", [tr("relic." + relic_id + ".name")])
				rewards_container.add_child(relic_label)
		elif relic_data.has("guaranteed") and relic_data.guaranteed:
			var rarity = relic_data.get("rarity", 0)
			var relic_label = Label.new()
			relic_label.text = tr("ui.reward.relic", [str(rarity)])
			rewards_container.add_child(relic_label)
	
	# 添加棋子奖励
	if rewards.has("chess"):
		var chess_data = rewards.chess
		
		if chess_data.has("id"):
			var chess_id = chess_data.id
			var chess_config = ConfigManager.get_chess(chess_id)
			
			if chess_config:
				var chess_label = Label.new()
				chess_label.text = tr("ui.reward.chess_specific", [tr("chess." + chess_id + ".name")])
				rewards_container.add_child(chess_label)
	
	# 如果没有奖励，显示无奖励信息
	if rewards_container.get_child_count() == 0:
		var no_reward_label = Label.new()
		no_reward_label.text = tr("ui.reward.no_reward")
		rewards_container.add_child(no_reward_label)

# 清空奖励容器
func clear_rewards() -> void:
	if rewards_container == null:
		return
		
	# 移除所有子节点
	for child in rewards_container.get_children():
		rewards_container.remove_child(child)
		child.queue_free()
