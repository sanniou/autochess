extends Resource
class_name MapConnection
## 地图连接
## 表示地图上两个节点之间的连接

# 连接基本信息
@export var id: String = ""
@export var from_node_id: String = ""
@export var to_node_id: String = ""
@export var traversable: bool = true

# 连接属性
@export var properties: Dictionary = {}

# 连接类型 - 可用于表示不同类型的路径（如普通路径、精英路径等）
@export var connection_type: String = "normal"

## 初始化连接
## 设置连接的基本信息
func initialize(connection_id: String, from_id: String, to_id: String, type: String = "normal") -> void:
	id = connection_id
	from_node_id = from_id
	to_node_id = to_id
	connection_type = type

## 设置连接属性
## 添加或更新指定键的属性值
func set_property(key: String, value) -> void:
	properties[key] = value

## 获取连接属性
## 如果属性不存在，返回默认值
func get_property(key: String, default_value = null):
	return properties.get(key, default_value)

## 检查是否有指定属性
func has_property(key: String) -> bool:
	return properties.has(key)

## 设置连接是否可通行
func set_traversable(can_traverse: bool) -> void:
	traversable = can_traverse

## 检查连接是否可通行
func is_traversable() -> bool:
	return traversable

## 设置连接类型
func set_connection_type(type: String) -> void:
	connection_type = type

## 获取连接类型
func get_connection_type() -> String:
	return connection_type

## 检查连接是否连接指定节点
func connects_nodes(node1_id: String, node2_id: String) -> bool:
	return (from_node_id == node1_id and to_node_id == node2_id) or \
		   (from_node_id == node2_id and to_node_id == node1_id)

## 将连接数据转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"from_node_id": from_node_id,
		"to_node_id": to_node_id,
		"traversable": traversable,
		"connection_type": connection_type,
		"properties": properties.duplicate()
	}

## 从字典创建连接数据
static func from_dict(dict: Dictionary) -> MapConnection:
	var connection = MapConnection.new()

	# 设置基本信息
	connection.id = dict.get("id", "")
	connection.from_node_id = dict.get("from_node_id", "")
	connection.to_node_id = dict.get("to_node_id", "")
	connection.traversable = dict.get("traversable", true)
	connection.connection_type = dict.get("connection_type", "normal")

	# 设置属性
	connection.properties = dict.get("properties", {}).duplicate()

	return connection
