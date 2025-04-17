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

## 验证配置数据
func validate(config_data: Dictionary) -> bool:
	# 清空验证错误
	validation_errors.clear()
	
	# 验证ID
	if not config_data.has("id"):
		validation_errors.append("缺少ID字段")
	elif not config_data.id is String:
		validation_errors.append("ID必须是字符串")
	
	# 验证必填字段
	for field in schema:
		if schema[field].get("required", false) and not config_data.has(field):
			validation_errors.append("缺少必填字段: " + field)
	
	# 验证字段类型
	for field in config_data:
		if schema.has(field):
			var field_type = schema[field].type
			var field_value = config_data[field]
			
			if not _validate_field_type(field_value, field_type):
				validation_errors.append("字段类型错误: " + field + " 应为 " + field_type)
	
	# 验证自定义规则
	_validate_custom_rules(config_data)
	
	return validation_errors.is_empty()

## 获取验证错误
func get_validation_errors() -> Array:
	return validation_errors

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
func _validate_field_type(value, type_name: String) -> bool:
	match type_name:
		"string":
			return value is String
		"int":
			return value is int
		"float":
			return value is float
		"bool":
			return value is bool
		"array":
			return value is Array
		"dictionary", "dict":
			return value is Dictionary
		"vector2":
			return value is Vector2
		"vector3":
			return value is Vector3
		"color":
			return value is Color
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
				
				# 验证数组元素类型
				for element in value:
					if not _validate_field_type(element, element_type):
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
					if not _validate_field_type(k, key_type) or not _validate_field_type(value[k], value_type):
						return false
				
				return true
			
			return false

## 验证自定义规则
func _validate_custom_rules(_config_data: Dictionary) -> void:
	# 子类可以重写此方法实现自定义验证规则
	pass

## 转换为字符串
func _to_string() -> String:
	return config_type + ":" + id
