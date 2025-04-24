extends RefCounted
class_name BusEvent
## 事件基类
## 所有事件类型都应继承自此类

## 事件时间戳
var timestamp: int = Time.get_unix_time_from_system()

## 事件是否已取消
var canceled: bool = false

## 事件源对象（可选）
var source: Object = null

## 获取事件类型名称
## 默认实现会根据类名自动推断事件类型
## 子类可以重写此方法以返回特定的事件类型
func get_type() -> String:
	# 获取类名
	var clazz_name = get_script().get_path().get_file().get_basename()
	if clazz_name == "event":
		return "Event"

	# 如果是内部类，使用对象的类名
	if clazz_name.find("@") >= 0 or clazz_name == "":
		clazz_name = get_class()

	# 从类名中提取事件组和事件名
	var event_group = ""
	var event_name = ""

	# 尝试从类名中提取事件组
	# 例如：GameEvents.PlayerDiedEvent -> game
	if clazz_name.find("Events") >= 0:
		event_group = clazz_name.split("Events")[0].to_lower()
	else:
		# 尝试从父脚本路径中提取事件组
		var script_path = get_script().get_path()
		if script_path.find("types/") >= 0:
			var type_dir = script_path.split("types/")[1].split("/")[0]
			if type_dir.ends_with("_events"):
				event_group = type_dir.split("_events")[0]

	# 如果无法从类名或路径中提取事件组，使用默认组
	if event_group == "":
		event_group = "event"

	# 从类名中提取事件名
	# 例如：PlayerDiedEvent -> player_died
	event_name = clazz_name.replace("Event", "")

	# 将驼峰命名转换为蛇形命名
	var snake_case_name = ""
	for i in range(event_name.length()):
		var c = event_name[i]
		if c == c.to_upper() and i > 0:
			snake_case_name += "_" + c.to_lower()
		else:
			snake_case_name += c.to_lower()

	# 返回完整的事件类型
	return event_group + "." + snake_case_name

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
		event.source = source
		return event

	# 创建相同类型的新事件
	var event = script.new()

	# 复制基本属性
	event.timestamp = timestamp
	event.canceled = canceled
	event.source = source

	# 获取所有属性
	var properties = get_property_list()

	# 复制所有自定义属性
	for prop in properties:
		var name = prop.name
		# 跳过内置属性和方法
		if name in ["script", "Script Variables", "timestamp", "canceled", "source"] or name.begins_with("_"):
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
		event.set(name, value)

	return event
