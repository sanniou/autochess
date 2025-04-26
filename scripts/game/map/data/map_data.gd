extends Resource
class_name MapData
## 地图数据
## 包含地图的所有信息，包括节点、连接和元数据

# 地图基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var difficulty: int = 1
@export var seed_value: int = 0

# 地图元数据
@export var generation_time: int = 0
@export var template_id: String = ""
@export var layers: int = 0

# 地图结构 - 仍然保留数组以便序列化
@export var nodes: Array[MapNode] = []
@export var connections: Array[MapConnection] = []

# 优化的数据结构 - 使用字典提高查询效率
var _nodes_by_id: Dictionary = {}  # 通过ID快速访问节点
var _nodes_by_layer: Dictionary = {}  # 通过层级快速访问节点
var _nodes_by_type: Dictionary = {}  # 通过类型快速访问节点
var _connections_by_id: Dictionary = {}  # 通过ID快速访问连接
var _connections_from_node: Dictionary = {}  # 从节点出发的连接
var _connections_to_node: Dictionary = {}  # 到达节点的连接

## 初始化地图数据
## 设置地图的基本信息
func initialize(template_id: String, seed_val: int) -> void:
	id = "map_" + str(seed_val)
	self.template_id = template_id
	seed_value = seed_val
	generation_time = Time.get_unix_time_from_system()

	# 初始化索引结构
	_clear_indices()

## 清除索引结构
func _clear_indices() -> void:
	_nodes_by_id.clear()
	_nodes_by_layer.clear()
	_nodes_by_type.clear()
	_connections_by_id.clear()
	_connections_from_node.clear()
	_connections_to_node.clear()

## 重建索引
## 在加载地图或大量修改后调用，以确保索引是最新的
func rebuild_indices() -> void:
	# 清除现有索引
	_clear_indices()

	# 重建节点索引
	for node in nodes:
		_add_node_to_indices(node)

	# 重建连接索引
	for connection in connections:
		_add_connection_to_indices(connection)

## 添加节点到索引
func _add_node_to_indices(node: MapNode) -> void:
	# 添加到ID索引
	_nodes_by_id[node.id] = node

	# 添加到层级索引
	if not _nodes_by_layer.has(node.layer):
		_nodes_by_layer[node.layer] = []
	_nodes_by_layer[node.layer].append(node)

	# 添加到类型索引
	if not _nodes_by_type.has(node.type):
		_nodes_by_type[node.type] = []
	_nodes_by_type[node.type].append(node)

## 添加连接到索引
func _add_connection_to_indices(connection: MapConnection) -> void:
	# 添加到ID索引
	_connections_by_id[connection.id] = connection

	# 添加到出发节点索引
	if not _connections_from_node.has(connection.from_node_id):
		_connections_from_node[connection.from_node_id] = []
	_connections_from_node[connection.from_node_id].append(connection)

	# 添加到到达节点索引
	if not _connections_to_node.has(connection.to_node_id):
		_connections_to_node[connection.to_node_id] = []
	_connections_to_node[connection.to_node_id].append(connection)

## 添加节点
## 将节点添加到地图并更新索引
func add_node(node: MapNode) -> void:
	nodes.append(node)
	_add_node_to_indices(node)

## 添加连接
## 将连接添加到地图并更新索引
func add_connection(connection: MapConnection) -> void:
	connections.append(connection)
	_add_connection_to_indices(connection)

	# 更新节点的连接信息
	var from_node = get_node_by_id(connection.from_node_id)
	var to_node = get_node_by_id(connection.to_node_id)

	if from_node:
		from_node.add_connection_to(connection.to_node_id)

	if to_node:
		to_node.add_connection_from(connection.from_node_id)

## 移除节点
## 从地图中移除节点并更新索引
func remove_node(node_id: String) -> bool:
	var node = get_node_by_id(node_id)
	if not node:
		return false

	# 移除与该节点相关的所有连接
	var connections_to_remove = []

	for connection in connections:
		if connection.from_node_id == node_id or connection.to_node_id == node_id:
			connections_to_remove.append(connection.id)

	for connection_id in connections_to_remove:
		remove_connection(connection_id)

	# 从数组中移除节点
	for i in range(nodes.size()):
		if nodes[i].id == node_id:
			nodes.remove_at(i)
			break

	# 从索引中移除节点
	_nodes_by_id.erase(node_id)

	if _nodes_by_layer.has(node.layer):
		_nodes_by_layer[node.layer].erase(node)
		if _nodes_by_layer[node.layer].is_empty():
			_nodes_by_layer.erase(node.layer)

	if _nodes_by_type.has(node.type):
		_nodes_by_type[node.type].erase(node)
		if _nodes_by_type[node.type].is_empty():
			_nodes_by_type.erase(node.type)

	return true

## 移除连接
## 从地图中移除连接并更新索引
func remove_connection(connection_id: String) -> bool:
	var connection = get_connection_by_id(connection_id)
	if not connection:
		return false

	# 从数组中移除连接
	for i in range(connections.size()):
		if connections[i].id == connection_id:
			connections.remove_at(i)
			break

	# 从索引中移除连接
	_connections_by_id.erase(connection_id)

	if _connections_from_node.has(connection.from_node_id):
		_connections_from_node[connection.from_node_id].erase(connection)
		if _connections_from_node[connection.from_node_id].is_empty():
			_connections_from_node.erase(connection.from_node_id)

	if _connections_to_node.has(connection.to_node_id):
		_connections_to_node[connection.to_node_id].erase(connection)
		if _connections_to_node[connection.to_node_id].is_empty():
			_connections_to_node.erase(connection.to_node_id)

	# 更新节点的连接信息
	var from_node = get_node_by_id(connection.from_node_id)
	var to_node = get_node_by_id(connection.to_node_id)

	if from_node:
		from_node.remove_connection_to(connection.to_node_id)

	if to_node:
		to_node.remove_connection_from(connection.from_node_id)

	return true

## 获取指定层的节点
## 返回指定层的所有节点
func get_nodes_by_layer(layer: int) -> Array[MapNode]:
	if _nodes_by_layer.has(layer):
		var newarray: Array[MapNode] = []
		newarray.assign(_nodes_by_layer[layer].duplicate())
		return newarray
	return []

## 获取指定类型的节点
## 返回指定类型的所有节点
func get_nodes_by_type(type: String) -> Array[MapNode]:
	if _nodes_by_type.has(type):
		var newarray: Array[MapNode] = []
		newarray.assign(_nodes_by_type[type].duplicate())
		return newarray
	return []

## 获取指定ID的节点
## 返回指定ID的节点，如果不存在则返回null
func get_node_by_id(node_id: String) -> MapNode:
	return _nodes_by_id.get(node_id)

## 获取指定ID的连接
## 返回指定ID的连接，如果不存在则返回null
func get_connection_by_id(connection_id: String) -> MapConnection:
	return _connections_by_id.get(connection_id)

## 获取从指定节点出发的连接
## 返回从指定节点出发的所有连接
func get_connections_from_node(node_id: String) -> Array[MapConnection]:
	if _connections_from_node.has(node_id):
		var newarray: Array[MapConnection] = []
		newarray.assign(_connections_from_node[node_id].duplicate())
		return newarray
	return []

## 获取到达指定节点的连接
## 返回到达指定节点的所有连接
func get_connections_to_node(node_id: String) -> Array[MapConnection]:
	if _connections_to_node.has(node_id):
		var newarray: Array[MapConnection] = []
		newarray.assign(_connections_to_node[node_id].duplicate())
		return newarray
	return []

## 获取可到达的节点
## 返回从指定节点可到达的所有节点
func get_reachable_nodes(from_node_id: String) -> Array[MapNode]:
	var result: Array[MapNode] = []
	var from_connections = get_connections_from_node(from_node_id)

	for connection in from_connections:
		if connection.traversable:
			var to_node = get_node_by_id(connection.to_node_id)
			if to_node:
				result.append(to_node)

	return result

## 获取可从其到达的节点
## 返回可到达指定节点的所有节点
func get_nodes_that_can_reach(to_node_id: String) -> Array[MapNode]:
	var result: Array[MapNode] = []
	var to_connections = get_connections_to_node(to_node_id)

	for connection in to_connections:
		if connection.traversable:
			var from_node = get_node_by_id(connection.from_node_id)
			if from_node:
				result.append(from_node)

	return result

## 获取两个节点之间的连接
## 返回连接两个节点的连接，如果不存在则返回null
func get_connection_between_nodes(from_node_id: String, to_node_id: String) -> MapConnection:
	var from_connections = get_connections_from_node(from_node_id)

	for connection in from_connections:
		if connection.to_node_id == to_node_id:
			return connection

	return null

## 检查两个节点之间是否有连接
## 返回两个节点之间是否有连接
func has_connection_between_nodes(from_node_id: String, to_node_id: String) -> bool:
	return get_connection_between_nodes(from_node_id, to_node_id) != null

## 获取所有节点
## 返回地图中的所有节点
func get_all_nodes() -> Array[MapNode]:
	return nodes.duplicate()

## 获取所有连接
## 返回地图中的所有连接
func get_all_connections() -> Array[MapConnection]:
	return connections.duplicate()

## 获取节点数量
## 返回地图中的节点数量
func get_node_count() -> int:
	return nodes.size()

## 获取连接数量
## 返回地图中的连接数量
func get_connection_count() -> int:
	return connections.size()

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
	map_data.difficulty = dict.get("difficulty", 1)
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
