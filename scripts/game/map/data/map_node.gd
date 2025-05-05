extends Resource
class_name MapNode
## 地图节点
## 表示地图上的一个节点，如战斗、商店、事件等

# 节点基本信息
@export var id: String = ""
@export var type: String = ""
@export var layer: int = 0
@export var position: int = 0
@export var position_x: int = 0
@export var position_y: int = 0
@export var visited: bool = false

# 节点属性
@export var properties: Dictionary = {}

# 节点奖励
@export var rewards: Dictionary = {}

# 节点连接 - 使用字符串数组以提高类型安全性
@export var connections_to: Array[String] = []
@export var connections_from: Array[String] = []

## 初始化节点
## 设置节点的基本信息
func initialize(node_id: String, node_type: String, node_layer: int, node_position: int) -> void:
	id = node_id
	type = node_type
	layer = node_layer
	position = node_position

## 设置节点属性
## 添加或更新指定键的属性值
func set_property(key: String, value) -> void:
	properties[key] = value

## 获取节点属性
## 如果属性不存在，返回默认值
func get_property(key: String, default_value = null):
	return properties.get(key, default_value)

## 检查节点是否有指定属性
func has_property(key: String) -> bool:
	return properties.has(key)

## 添加奖励
## 设置指定类型的奖励值
func add_reward(reward_type: String, reward_value) -> void:
	rewards[reward_type] = reward_value

## 获取奖励
## 如果奖励不存在，返回默认值
func get_reward(reward_type: String, default_value = null):
	return rewards.get(reward_type, default_value)

## 检查节点是否有指定奖励
func has_reward(reward_type: String) -> bool:
	return rewards.has(reward_type)

## 添加到其他节点的连接
## 如果连接已存在，则不重复添加
func add_connection_to(node_id: String) -> void:
	if not connections_to.has(node_id):
		connections_to.append(node_id)

## 添加来自其他节点的连接
## 如果连接已存在，则不重复添加
func add_connection_from(node_id: String) -> void:
	if not connections_from.has(node_id):
		connections_from.append(node_id)

## 移除到其他节点的连接
func remove_connection_to(node_id: String) -> void:
	connections_to.erase(node_id)

## 移除来自其他节点的连接
func remove_connection_from(node_id: String) -> void:
	connections_from.erase(node_id)

## 检查是否可以到达指定节点
func can_reach(node_id: String) -> bool:
	return connections_to.has(node_id)

## 检查是否可以从指定节点到达
func can_be_reached_from(node_id: String) -> bool:
	return connections_from.has(node_id)

## 获取所有可到达的节点ID
func get_reachable_nodes() -> Array[String]:
	return connections_to.duplicate()

## 获取所有可从其到达的节点ID
func get_nodes_that_can_reach() -> Array[String]:
	return connections_from.duplicate()

## 将节点数据转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"layer": layer,
		"position": position,
		"visited": visited,
		"properties": properties.duplicate(),
		"rewards": rewards.duplicate(),
		"connections_to": connections_to.duplicate(),
		"connections_from": connections_from.duplicate()
	}

## 从字典创建节点数据
static func from_dict(dict: Dictionary) -> MapNode:
	var node = MapNode.new()

	# 设置基本信息
	node.id = dict.get("id", "")
	node.type = dict.get("type", "")
	node.layer = dict.get("layer", 0)
	node.position = dict.get("position", 0)
	node.visited = dict.get("visited", false)

	# 设置属性和奖励
	node.properties = dict.get("properties", {}).duplicate()
	node.rewards = dict.get("rewards", {}).duplicate()

	# 设置连接
	var connections_to_array = dict.get("connections_to", [])
	for connection in connections_to_array:
		node.connections_to.append(connection)

	var connections_from_array = dict.get("connections_from", [])
	for connection in connections_from_array:
		node.connections_from.append(connection)

	return node
