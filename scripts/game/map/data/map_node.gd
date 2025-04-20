extends Resource
class_name MapNode
## 地图节点
## 表示地图上的一个节点，如战斗、商店、事件等

# 节点基本信息
@export var id: String = ""
@export var type: String = ""
@export var layer: int = 0
@export var position: int = 0
@export var visited: bool = false

# 节点属性
@export var properties: Dictionary = {}

# 节点奖励
@export var rewards: Dictionary = {}

# 节点连接
@export var connections_to: Array = []
@export var connections_from: Array = []

## 初始化节点
func initialize(node_id: String, node_type: String, node_layer: int, node_position: int) -> void:
    self.id = node_id
    self.type = node_type
    self.layer = node_layer
    self.position = node_position

## 设置节点属性
func set_property(key: String, value) -> void:
    properties[key] = value

## 获取节点属性
func get_property(key: String, default_value = null):
    return properties.get(key, default_value)

## 添加奖励
func add_reward(reward_type: String, reward_value) -> void:
    rewards[reward_type] = reward_value

## 获取奖励
func get_reward(reward_type: String, default_value = null):
    return rewards.get(reward_type, default_value)

## 添加到其他节点的连接
func add_connection_to(node_id: String) -> void:
    if not connections_to.has(node_id):
        connections_to.append(node_id)

## 添加来自其他节点的连接
func add_connection_from(node_id: String) -> void:
    if not connections_from.has(node_id):
        connections_from.append(node_id)

## 检查是否可以到达指定节点
func can_reach(node_id: String) -> bool:
    return connections_to.has(node_id)

## 检查是否可以从指定节点到达
func can_be_reached_from(node_id: String) -> bool:
    return connections_from.has(node_id)

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
    node.connections_to = dict.get("connections_to", []).duplicate()
    node.connections_from = dict.get("connections_from", []).duplicate()
    
    return node
