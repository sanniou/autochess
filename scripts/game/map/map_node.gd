extends Resource
class_name MapNode
## 地图节点
## 表示地图上的一个节点，可以是战斗、商店、事件等

# 节点基本属性
@export var id: String = ""
@export var layer: int = 0
@export var position: int = 0
@export var type: String = "battle"
@export var visited: bool = false

# 节点特定属性
@export var difficulty: float = 1.0
@export var enemy_level: int = 1
@export var event_id: String = ""
@export var discount: bool = false
@export var heal_amount: int = 0
@export var boss_id: String = ""
@export var challenge_type: String = ""
@export var altar_type: String = ""
@export var blacksmith_service: String = ""

# 节点奖励
@export var rewards: Dictionary = {}

# 节点连接
@export var connections_to: Array = []
@export var connections_from: Array = []

# 节点视觉属性
@export var icon_path: String = ""
@export var color: Color = Color.WHITE

## 初始化节点
func initialize(node_data: Dictionary) -> void:
	# 设置基本属性
	id = node_data.get("id", "")
	layer = node_data.get("layer", 0)
	position = node_data.get("position", 0)
	type = node_data.get("type", "battle")
	visited = node_data.get("visited", false)

	# 设置特定属性
	difficulty = node_data.get("difficulty", 1.0)
	enemy_level = node_data.get("enemy_level", 1)
	event_id = node_data.get("event_id", "")
	discount = node_data.get("discount", false)
	heal_amount = node_data.get("heal_amount", 0)
	boss_id = node_data.get("boss_id", "")
	challenge_type = node_data.get("challenge_type", "")
	altar_type = node_data.get("altar_type", "")
	blacksmith_service = node_data.get("blacksmith_service", "")

	# 设置奖励
	rewards = node_data.get("rewards", {})

	# 设置视觉属性
	_set_visual_properties()

## 设置视觉属性
func _set_visual_properties() -> void:
	var node_types = ConfigManager.map_nodes_config.node_types
	if node_types.has(type):
		var node_type_data = node_types[type]
		icon_path = "res://assets/images/map/" + node_type_data.get("icon", "node_battle.png")
		color = Color(node_type_data.get("color", "#ffffff"))

## 添加连接到其他节点
func add_connection_to(node_id: String) -> void:
	if not connections_to.has(node_id):
		connections_to.append(node_id)

## 添加来自其他节点的连接
func add_connection_from(node_id: String) -> void:
	if not connections_from.has(node_id):
		connections_from.append(node_id)

## 获取节点类型名称
func get_type_name() -> String:
	var tr_key = "ui.map.node_" + type
	return LocalizationManager.tr(tr_key)

## 获取节点描述
func get_description() -> String:
	var tr_key = "ui.map.node_" + type + "_desc"
	return LocalizationManager.tr(tr_key)

## 获取节点奖励描述
func get_rewards_description() -> String:
	var desc = ""

	if rewards.has("gold"):
		desc += LocalizationManager.tr("ui.map.reward_gold", [str(rewards.gold)]) + "\n"

	if rewards.has("exp"):
		desc += LocalizationManager.tr("ui.map.reward_exp", [str(rewards.exp)]) + "\n"

	if rewards.has("equipment") and rewards.equipment.has("guaranteed") and rewards.equipment.guaranteed:
		var quality = rewards.equipment.get("quality", 1)
		desc += LocalizationManager.tr("ui.map.reward_equipment", [str(quality)]) + "\n"

	if rewards.has("relic") and rewards.relic.has("guaranteed") and rewards.relic.guaranteed:
		var rarity = rewards.relic.get("rarity", 0)
		desc += LocalizationManager.tr("ui.map.reward_relic", [str(rarity)]) + "\n"

	if rewards.has("heal"):
		desc += LocalizationManager.tr("ui.map.reward_heal", [str(rewards.heal)]) + "\n"

	return desc.strip_edges()

## 获取节点难度描述
func get_difficulty_description() -> String:
	if type == "battle" or type == "elite_battle" or type == "boss" or type == "challenge":
		var difficulty_text = ""

		if difficulty < 1.2:
			difficulty_text = LocalizationManager.tr("ui.map.difficulty_easy")
		elif difficulty < 1.5:
			difficulty_text = LocalizationManager.tr("ui.map.difficulty_normal")
		elif difficulty < 2.0:
			difficulty_text = LocalizationManager.tr("ui.map.difficulty_hard")
		else:
			difficulty_text = LocalizationManager.tr("ui.map.difficulty_extreme")

		var desc = LocalizationManager.tr("ui.map.difficulty", [difficulty_text, str(enemy_level)])

		# 挑战节点显示挑战类型
		if type == "challenge" and not challenge_type.is_empty():
			desc += "\n" + LocalizationManager.tr("ui.map.challenge_type", [LocalizationManager.tr("ui.challenge." + challenge_type)])

		return desc

	# 祭坛节点显示祭坛类型
	if type == "altar" and not altar_type.is_empty():
		return LocalizationManager.tr("ui.map.altar_type", [LocalizationManager.tr("ui.altar." + altar_type)])

	# 铁匠铺节点显示服务类型
	if type == "blacksmith" and not blacksmith_service.is_empty():
		return LocalizationManager.tr("ui.map.blacksmith_service", [LocalizationManager.tr("ui.blacksmith." + blacksmith_service)])

	return ""

## 获取节点数据
func get_data() -> Dictionary:
	var data = {
		"id": id,
		"layer": layer,
		"position": position,
		"type": type,
		"visited": visited,
		"rewards": rewards.duplicate()
	}

	# 添加特定属性
	match type:
		"battle", "elite_battle":
			data["difficulty"] = difficulty
			data["enemy_level"] = enemy_level
		"event":
			data["event_id"] = event_id
		"shop":
			data["discount"] = discount
		"rest":
			data["heal_amount"] = heal_amount
		"boss":
			data["boss_id"] = boss_id
		"challenge":
			data["difficulty"] = difficulty
			data["enemy_level"] = enemy_level
			data["challenge_type"] = challenge_type
		"altar":
			data["altar_type"] = altar_type
		"blacksmith":
			data["discount"] = discount
			data["blacksmith_service"] = blacksmith_service
		"mystery":
			# 神秘节点不需要额外属性
			pass

	return data

## 标记为已访问
func mark_as_visited() -> void:
	visited = true

## 检查是否可以访问
func is_accessible(current_layer: int, current_node_id: String) -> bool:
	# 如果不是下一层，不可访问
	if layer != current_layer + 1:
		return false

	# 检查是否有从当前节点到此节点的连接
	for connection in connections_from:
		if connection == current_node_id:
			return true

	return false
