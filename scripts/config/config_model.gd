extends Resource
class_name ConfigModel
## 配置数据模型基类
## 为配置数据提供类型安全的访问和验证

# 配置ID
var id: String = ""

# 配置类型
var config_type: String = ""

# 配置数据
var data: Dictionary = {}

# 配置架构
var schema: Dictionary = {}

# 验证错误
var validation_errors: Array = []

# 初始化
func _init(config_id: String = "", config_data: Dictionary = {}, config_schema: Dictionary = {}):
	id = config_id
	config_type = _get_config_type()

	if not config_schema.is_empty():
		schema = config_schema
	else:
		schema = _get_default_schema()

	if not config_data.is_empty():
		set_data(config_data)

## 设置配置数据
func set_data(config_data: Dictionary) -> bool:
	# 验证数据
	if not validate(config_data):
		return false

	# 设置数据
	data = config_data.duplicate(true)

	# 设置ID
	if data.has("id"):
		id = data.id

	return true

## 获取配置数据
func get_data() -> Dictionary:
	return data.duplicate(true)

## 获取配置ID
func get_id() -> String:
	return id

## 获取配置类型
func get_config_type() -> String:
	return config_type

## 获取配置架构
func get_schema() -> Dictionary:
	return schema.duplicate(true)

## 获取配置字段
func get(field_name: String, default_value = null):
	if data.has(field_name):
		return data[field_name]
	return default_value

## 设置配置字段
func set(field_name: String, value) -> bool:
	# 检查字段是否在架构中
	if not schema.has(field_name):
		validation_errors.append("字段不在架构中: " + field_name)
		return false

	# 验证字段类型
	var field_schema = schema[field_name]
	if not _validate_field_type(value, field_schema, null, null):
		validation_errors.append("字段类型错误: " + field_name)
		return false

	# 设置字段
	data[field_name] = value
	return true

## 检查字段是否存在
func has(field_name: String) -> bool:
	return data.has(field_name)

## 是否为空
func is_empty() -> bool:
	return data.is_empty()

## 验证配置数据
func validate(config_data: Dictionary) -> bool:
	# 清空验证错误
	validation_errors.clear()

	# 验证必填字段
	for field in schema:
		if schema[field].get("required", false) and not config_data.has(field):
			validation_errors.append("缺少必填字段: " + field)

	# 验证字段类型
	for field in config_data:
		if schema.has(field):
			var field_schema = schema[field]
			var field_value = config_data[field]

			# 传递父字典、字段键和字段schema，以便验证嵌套结构
			if not _validate_field_type(field_value, field_schema, config_data, field):
				validation_errors.append("字段类型错误: " + field + " 应为 " + field_schema.type)

	# 验证自定义规则
	_validate_custom_rules(config_data)

	return validation_errors.is_empty()

## 获取验证错误
func get_validation_errors() -> Array:
	return validation_errors.duplicate()

## 获取配置类型
func _get_config_type() -> String:
	return "base"

## 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "配置ID"
		}
	}

## 验证字段类型
## 增加了 parent_dict、field_key 和 field_schema 参数，用于在需要时更新原始字典和验证嵌套schema
func _validate_field_type(value, field_schema, parent_dict = null, field_key = null) -> bool:
	# 如果field_schema是字符串，则转换为字典
	if field_schema is String:
		field_schema = {"type": field_schema}
	
	var type_name = field_schema.type
	
	match type_name:
		"string":
			return value is String
		"int":
			# 处理 JSON 解析将整数解析为浮点数的情况
			if value is float and value == floor(value):
				# 如果提供了父字典和字段键，更新值为整数
				if parent_dict != null and field_key != null:
					parent_dict[field_key] = int(value)
				return true
			return value is int
		"float":
			return value is float
		"bool":
			return value is bool
		"array":
			return value is Array
		"dictionary", "dict":
			 # 如果有 check_schema 字段且为 false，则不验证字典的内容
			if field_schema.has("check_schema") and field_schema.check_schema == false:
				return value is Dictionary
			
			# 如果有 schema 字段，则验证字典的内容
			if field_schema.has("schema") and value is Dictionary:
				var nested_schema = field_schema.schema
				
				# 验证必填字段
				for nested_field in nested_schema:
					if nested_schema[nested_field].get("required", false) and not value.has(nested_field):
						validation_errors.append("缺少必填字段: " + field_key + "." + nested_field)
						return false
				
				# 验证字段类型
				for nested_field in value:
					if nested_schema.has(nested_field):
						var nested_field_schema = nested_schema[nested_field]
						if not _validate_field_type(value[nested_field], nested_field_schema, value, nested_field):
							validation_errors.append("字段类型错误: " + field_key + "." + nested_field)
							return false
			
			return value is Dictionary
		"vector2":
			if value is Vector2:
				return true
			if value is Dictionary and value.has("x") and value.has("y"):
				if parent_dict != null and field_key != null:
					parent_dict[field_key] = Vector2(value.x, value.y)
				return true
			return false
		"vector3":
			if value is Vector3:
				return true
			if value is Dictionary and value.has("x") and value.has("y") and value.has("z"):
				if parent_dict != null and field_key != null:
					parent_dict[field_key] = Vector3(value.x, value.y, value.z)
				return true
			return false
		"color":
			if value is Color:
				return true
			if value is String and value.begins_with("#"):
				if parent_dict != null and field_key != null:
					parent_dict[field_key] = Color.from_string(value, Color.WHITE)
				return true
			return false
		"resource":
			return value is Resource
		"object":
			return value is Object
		"any":
			return true
		_:
			# 自定义类型或复合类型
			if type_name.begins_with("array["):
				var element_type = type_name.substr(6, type_name.length() - 7)
				if not value is Array:
					return false

				# 如果字典数组
				if element_type in ["dictionary", "dict"]:
					# 如果有 check_schema 字段且为 false，则不验证字典的内容
					if field_schema.has("check_schema") and field_schema.check_schema == false:
						return true
					
					# 如果有 schema 字段，则验证数组中每个字典的内容
					if field_schema.has("schema"):
						var nested_schema = field_schema.schema
						
						for i in range(value.size()):
							var item = value[i]
							if not item is Dictionary:
								validation_errors.append("数组项类型错误: 应为字典")
								return false
							
							# 验证必填字段
							for nested_field in nested_schema:
								if nested_schema[nested_field].get("required", false) and not item.has(nested_field):
									validation_errors.append("缺少必填字段: " + field_key + "[" + str(i) + "]." + nested_field)
									return false
							
							# 验证字段类型
							for nested_field in item:
								if nested_schema.has(nested_field):
									var nested_field_schema = nested_schema[nested_field]
									if not _validate_field_type(item[nested_field], nested_field_schema, item, nested_field):
										validation_errors.append("字段类型错误: " + field_key + "[" + str(i) + "]." + nested_field)
										return false
					
					return true
				
				# 验证数组中的每个元素
				for i in range(value.size()):
					if not _validate_field_type(value[i], {"type": element_type}, value, i):
						return false
				
				return true
			elif type_name.begins_with("dict["):
				var key_value_types = type_name.substr(5, type_name.length() - 6).split(",")
				if key_value_types.size() != 2 or not value is Dictionary:
					return false

				var key_type = key_value_types[0].strip_edges()
				var value_type = key_value_types[1].strip_edges()

				# 验证字典键值类型
				for k in value:
					# 对于键，我们不能修改它，所以不传递父字典和字段键
					if not _validate_field_type(k, {"type": key_type}):
						return false

					# 对于值，我们可以修改它
					if not _validate_field_type(value[k], {"type": value_type}, value, k):
						return false

				return true
			
			# 检查是否是枚举类型
			if field_schema.has("enum"):
				var enum_values = field_schema.enum
				return value in enum_values
			
			return false

## 验证自定义规则
func _validate_custom_rules(_config_data: Dictionary) -> void:
	# 子类可以重写此方法实现自定义验证规则
	pass

## 转换为字符串
func _to_string() -> String:
	return config_type + ":" + id
