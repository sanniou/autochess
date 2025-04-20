extends Resource
class_name MapData
## 地图数据
## 包含地图的所有信息，包括节点、连接和元数据

# 地图基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var difficulty: int
@export var seed_value: int = 0

# 地图结构
@export var nodes: Array = []  # MapNode 对象数组
@export var connections: Array = []  # MapConnection 对象数组

# 地图元数据
@export var generation_time: int = 0
@export var template_id: String = ""
@export var layers: int = 0

## 初始化地图数据
func initialize(template_id: String, seed_val: int) -> void:
	self.id = "map_" + str(seed_val)
	self.template_id = template_id
	self.seed_value = seed_val
	self.generation_time = Time.get_unix_time_from_system()

## 添加节点
func add_node(node: MapNode) -> void:
	nodes.append(node)

## 添加连接
func add_connection(connection: MapConnection) -> void:
	connections.append(connection)

## 获取指定层的节点
func get_nodes_by_layer(layer: int) -> Array:
	var result = []
	for node in nodes:
		if node.layer == layer:
			result.append(node)
	return result

## 获取指定类型的节点
func get_nodes_by_type(type: String) -> Array:
	var result = []
	for node in nodes:
		if node.type == type:
			result.append(node)
	return result

## 获取指定ID的节点
func get_node_by_id(node_id: String) -> MapNode:
	for node in nodes:
		if node.id == node_id:
			return node
	return null

## 获取从指定节点出发的连接
func get_connections_from_node(node_id: String) -> Array:
	var result = []
	for connection in connections:
		if connection.from_node_id == node_id:
			result.append(connection)
	return result

## 获取到达指定节点的连接
func get_connections_to_node(node_id: String) -> Array:
	var result = []
	for connection in connections:
		if connection.to_node_id == node_id:
			result.append(connection)
	return result

## 获取可到达的节点
func get_reachable_nodes(from_node_id: String) -> Array:
	var result = []
	var from_connections = get_connections_from_node(from_node_id)
	
	for connection in from_connections:
		if connection.traversable:
			var to_node = get_node_by_id(connection.to_node_id)
			if to_node:
				result.append(to_node)
	
	return result

## 获取可从其到达的节点
func get_nodes_that_can_reach(to_node_id: String) -> Array:
	var result = []
	var to_connections = get_connections_to_node(to_node_id)
	
	for connection in to_connections:
		if connection.traversable:
			var from_node = get_node_by_id(connection.from_node_id)
			if from_node:
				result.append(from_node)
	
	return result

## 将地图数据转换为字典
func to_dict() -> Dictionary:
	var dict = {
		"id": id,
		"name": name,
		"description": description,
		"difficulty": difficulty,
		"seed_value": seed_value,
		"template_id": template_id,
		"generation_time": generation_time,
		"layers": layers,
		"nodes": [],
		"connections": []
	}
	
	# 添加节点数据
	for node in nodes:
		dict.nodes.append(node.to_dict())
	
	# 添加连接数据
	for connection in connections:
		dict.connections.append(connection.to_dict())
	
	return dict

## 从字典创建地图数据
static func from_dict(dict: Dictionary) -> MapData:
	var map_data = MapData.new()
	
	# 设置基本信息
	map_data.id = dict.get("id", "")
	map_data.name = dict.get("name", "")
	map_data.description = dict.get("description", "")
	map_data.difficulty = dict.get("difficulty", "normal")
	map_data.seed_value = dict.get("seed_value", 0)
	map_data.template_id = dict.get("template_id", "")
	map_data.generation_time = dict.get("generation_time", 0)
	map_data.layers = dict.get("layers", 0)
	
	# 创建节点
	for node_dict in dict.get("nodes", []):
		var node = MapNode.from_dict(node_dict)
		map_data.add_node(node)
	
	# 创建连接
	for connection_dict in dict.get("connections", []):
		var connection = MapConnection.from_dict(connection_dict)
		map_data.add_connection(connection)
	
	return map_data
