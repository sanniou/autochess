extends RefCounted
class_name BusEvent
## 事件基类
## 所有事件类型都应继承自此类

## 事件时间戳
var timestamp: int = Time.get_unix_time_from_system()

## 事件是否已取消
var canceled: bool = false

## 获取事件类型名称
## 默认实现会根据类名自动推断事件类型
## 子类可以重写此方法以返回特定的事件类型
static func get_type() -> String:
	return "root"


## 取消事件
## 被取消的事件可能不会被某些监听器处理
func cancel() -> void:
	canceled = true

## 检查事件是否已取消
func is_canceled() -> bool:
	return canceled

## 获取事件的字符串表示
## 默认实现会显示事件类型和所有自定义属性
func _to_string() -> String:
	# 获取事件类名
	var clazz_name = get_class()

	# 获取所有属性
	var properties = get_property_list()
	var props_str = ""

	# 添加所有自定义属性
	for prop in properties:
		var name = prop.name
		# 跳过内置属性和方法
		if name in ["script", "Script Variables", "timestamp", "canceled", "source"] or name.begins_with("_"):
			continue

		# 获取属性值
		var value = get(name)

		# 添加属性到字符串
		if props_str != "":
			props_str += ", "
		props_str += name + "=" + str(value)

	# 如果有自定义属性，添加它们
	if props_str != "":
		return clazz_name + "[" + props_str + "]"
	else:
		# 否则使用基本格式
		return clazz_name + "[type=" + get_type() + ", canceled=" + str(canceled) + "]"

func get_custom_property_names(child_obj: Object, parent_class: Object) -> Array:
	var child_props = child_obj.get_property_list()
	var parent_props = parent_class.new().get_property_list() if parent_class else []
	
	var parent_prop_names = []
	for prop in parent_props:
		parent_prop_names.append(prop["name"])
	
	var custom_props = []
	for prop in child_props:
		var name = prop["name"]
		if name not in parent_prop_names and name not in ["Built-in script","script", "reference"]:
			custom_props.append(name)
	
	return custom_props
## 克隆事件（用于事件记录和重放）
## 默认实现会尝试自动克隆事件对象
## 子类可以重写此方法以自定义克隆行为
func clone() -> BusEvent:
	# 获取当前对象的类
	var script = get_script()
	if script == null:
		# 如果没有脚本，返回基本事件
		var event = BusEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

	# 获取所有属性
	var properties = get_custom_property_names(self,BusEvent)

	var newValues = []
	# 复制所有自定义属性
	for name in properties:
		# 跳过内置属性和方法
		if name in ["script", "Script Variables", "timestamp", "canceled"] or name.begins_with("_"):
			continue

		# 获取属性值
		var value = get(name)

		# 如果是引用类型，尝试复制
		if typeof(value) == TYPE_OBJECT:
			# 如果对象有 duplicate 方法，调用它
			if value != null and value.has_method("duplicate"):
				value = value.duplicate()
		elif typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_DICTIONARY:
			# 深度复制数组和字典
			value = value.duplicate(true)

		# 设置属性值
		newValues.append(value)
		#event.set(name, value)
		# 创建相同类型的新事件
	var event
	if newValues.size() == 0:
		event = script.call("new")
	else:
		event = script.callv("new",newValues)
		
	assert(not event == null)
	
	# 复制基本属性
	event.timestamp = timestamp
	event.canceled = canceled
	return event
