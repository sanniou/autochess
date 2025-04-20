extends Resource
class_name ConnectionType
## 连接类型
## 定义地图节点之间的连接类型和属性

# 基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var color: String = "#ffffff"

# 连接属性
@export var properties: Dictionary = {}

## 从字典创建连接类型
static func from_dict(dict: Dictionary) -> ConnectionType:
	var connection_type = ConnectionType.new()
	
	# 设置基本信息
	connection_type.id = dict.get("id", "")
	connection_type.name = dict.get("name", "")
	connection_type.description = dict.get("description", "")
	connection_type.color = dict.get("color", "#ffffff")
	
	# 设置属性
	connection_type.properties = dict.get("properties", {}).duplicate()
	
	return connection_type

## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"color": color,
		"properties": properties.duplicate()
	}

## 获取属性值
func get_property(property_name: String, default_value = null):
	return properties.get(property_name, default_value)

## 设置属性值
func set_property(property_name: String, value) -> void:
	properties[property_name] = value

## 检查是否有特定属性
func has_property(property_name: String) -> bool:
	return properties.has(property_name)

## 获取颜色对象
func get_color_object() -> Color:
	return Color.from_string(color, Color.WHITE)

## 是否是双向连接
func is_bidirectional() -> bool:
	return get_property("is_bidirectional", false)

## 获取通行成本
func get_traversal_cost() -> int:
	return get_property("traversal_cost", 1)

## 是否是隐藏连接
func is_hidden() -> bool:
	return get_property("is_hidden", false)

## 验证连接类型是否有效
func is_valid() -> bool:
	if id.is_empty() or name.is_empty():
		return false
	
	return true
