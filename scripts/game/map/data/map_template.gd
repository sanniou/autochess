extends Resource
class_name MapTemplate
## 地图模板
## 定义地图的基本结构和生成规则

# 基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var difficulty: int 

# 结构信息
@export var layers: int = 5
@export var nodes_per_layer: Array = []
@export var node_distribution: Dictionary = {}
@export var fixed_nodes: Array = []
@export var connection_rules: Dictionary = {}

## 从字典创建模板
static func from_dict(dict: Dictionary) -> MapTemplate:
	var template = MapTemplate.new()
	
	# 设置基本信息
	template.id = dict.get("id", "")
	template.name = dict.get("name", "")
	template.description = dict.get("description", "")
	template.difficulty = dict.difficulty
	
	# 设置结构信息
	template.layers = dict.get("layers", 5)
	template.nodes_per_layer = dict.get("nodes_per_layer", []).duplicate()
	template.node_distribution = dict.get("node_distribution", {}).duplicate()
	template.fixed_nodes = dict.get("fixed_nodes", []).duplicate()
	template.connection_rules = dict.get("connection_rules", {}).duplicate()
	
	return template

## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"difficulty": difficulty,
		"layers": layers,
		"nodes_per_layer": nodes_per_layer.duplicate(),
		"node_distribution": node_distribution.duplicate(),
		"fixed_nodes": fixed_nodes.duplicate(),
		"connection_rules": connection_rules.duplicate()
	}

## 获取特定层的节点数
func get_nodes_count_at_layer(layer: int) -> int:
	if layer >= 0 and layer < nodes_per_layer.size():
		return nodes_per_layer[layer]
	return 0

## 获取固定节点
func get_fixed_node_at(layer: int, position: int) -> Dictionary:
	for node in fixed_nodes:
		if node.get("layer", -1) == layer and node.get("position", -1) == position:
			return node
	return {}

## 获取连接规则
func get_min_connections_per_node() -> int:
	return connection_rules.get("min_connections_per_node", 1)

## 获取最大连接数
func get_max_connections_per_node() -> int:
	return connection_rules.get("max_connections_per_node", 3)

## 获取连接密度
func get_connection_density() -> float:
	return connection_rules.get("connection_density", 0.3)

## 是否允许跨层连接
func allows_cross_connections() -> bool:
	return connection_rules.get("allow_cross_connections", false)

## 获取节点类型分布
func get_node_type_weight(type: String) -> float:
	return node_distribution.get(type, 0.0)

## 验证模板是否有效
func is_valid() -> bool:
	if id.is_empty() or name.is_empty():
		return false
	
	if layers <= 0:
		return false
	
	if nodes_per_layer.size() != layers:
		return false
	
	return true
