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

## 初始化连接
func initialize(connection_id: String, from_id: String, to_id: String) -> void:
	self.id = connection_id
	self.from_node_id = from_id
	self.to_node_id = to_id

## 设置连接属性
func set_property(key: String, value) -> void:
	properties[key] = value

## 获取连接属性
func get_property(key: String, default_value = null):
	return properties.get(key, default_value)

## 检查是否有指定属性
func has_property(key: String) -> bool:
	return properties.has(key)

## 设置连接是否可通行
func set_traversable(can_traverse: bool) -> void:
	traversable = can_traverse

## 将连接数据转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"from_node_id": from_node_id,
		"to_node_id": to_node_id,
		"traversable": traversable,
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

	# 设置属性
	connection.properties = dict.get("properties", {}).duplicate()

	return connection
