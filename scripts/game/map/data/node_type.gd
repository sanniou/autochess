extends Resource
class_name NodeType
## 节点类型
## 定义地图节点的类型和属性

# 基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var color: String = "#ffffff"

# 节点属性
@export var properties: Dictionary = {}

## 从字典创建节点类型
static func from_dict(dict: Dictionary) -> NodeType:
	var node_type = NodeType.new()
	
	# 设置基本信息
	node_type.id = dict.get("id", "")
	node_type.name = dict.get("name", "")
	node_type.description = dict.get("description", "")
	node_type.icon = dict.get("icon", "")
	node_type.color = dict.get("color", "#ffffff")
	
	# 设置属性
	node_type.properties = dict.get("properties", {}).duplicate()
	
	return node_type

## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"icon": icon,
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

## 是否是战斗节点
func is_battle_node() -> bool:
	return get_property("is_battle", false)

## 是否是入口节点
func is_entry_node() -> bool:
	return get_property("is_entry", false)

## 是否是出口节点
func is_exit_node() -> bool:
	return get_property("is_exit", false)

## 获取战斗类型
func get_battle_type() -> String:
	return get_property("battle_type", "normal")

## 验证节点类型是否有效
func is_valid() -> bool:
	if id.is_empty() or name.is_empty():
		return false
	
	return true
