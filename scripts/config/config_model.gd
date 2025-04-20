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
	#if not config_data.has("id"):
		#validation_errors.append("缺少ID字段")
	#elif not config_data.id is String:
		#validation_errors.append("ID必须是字符串")

	# 验证必填字段
	for field in schema:
		if schema[field].get("required", false) and not config_data.has(field):
			validation_errors.append("缺少必填字段: " + field)

	# 验证字段类型
	for field in config_data:
		if schema.has(field):
			var field_type = schema[field].type
			var field_value = config_data[field]

			# 传递父字典、字段键和字段schema，以便验证嵌套结构
			if not _validate_field_type(field_value, schema[field], config_data, field):
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
## 增加了 parent_dict、field_key 和 field_schema 参数，用于在需要时更新原始字典和验证嵌套schema
func _validate_field_type(value, field_schema:Dictionary, parent_dict = null, field_key = null) -> bool:
	var type_name=field_schema.type
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

			var mested_field_schema = field_schema.schema
			if field_schema.has("schema_for_all_field") and field_schema.schema_for_all_field == true:
				# 验证字段类型
				for nested_field in value:
					var nested_field_value = value[nested_field]
					# 递归验证嵌套字段
					for nested_field2 in nested_field_value:
						var nested_field_value2 = nested_field_value[nested_field2]
						if not _validate_field_type(nested_field_value2, mested_field_schema[nested_field2], nested_field_value, nested_field2):
							validation_errors.append("嵌套字典字段错误: " + nested_field)
							return false
				
			else:
				# 验证必填字段
				for nested_field in mested_field_schema:
					if mested_field_schema[nested_field].get("required", false) and not value.has(nested_field):
						validation_errors.append("嵌套字典 " + field_key + " 缺少必填字段: " + nested_field)
						return false
				# 验证字段类型
				for nested_field in value:
					if mested_field_schema.has(nested_field):
						var nested_field_type = mested_field_schema[nested_field].type
						var nested_field_value = value[nested_field]
						# 递归验证嵌套字段
						if not _validate_field_type(nested_field_value, mested_field_schema[nested_field], value, nested_field):
							validation_errors.append("嵌套字典字段类型错误: " + nested_field + "应为 " + nested_field_type)
							return false
				return true
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

				# 如果字典数组
				if element_type in ["dictionary", "dict"]:
					# 如果有 check_schema 字段且为 false，则不验证字典的内容
					if field_schema.has("check_schema") and field_schema.check_schema == false:
						return true
					var nested_schema = field_schema.schema

					# 验证数组中的每个字典
					for i in range(value.size()):
						var item = value[i]
						if not item is Dictionary:
							return false

						# 验证必填字段
						for nested_field in nested_schema:
							if nested_schema[nested_field].get("required", false) and not item.has(nested_field):
								validation_errors.append("\u6570\u7ec4\u5143\u7d20 " + str(i) + " \u7f3a\u5c11\u5fc5\u586b\u5b57\u6bb5: " + nested_field)
								return false

						# 验证字段类型
						for nested_field in item:
							if nested_schema.has(nested_field):
								var nested_field_type = nested_schema[nested_field].type
								var nested_field_value = item[nested_field]

								# 递归验证嵌套字段
								if not _validate_field_type(nested_field_value, nested_schema[nested_field], item, nested_field):
									validation_errors.append("\u6570\u7ec4\u5143\u7d20 " + str(i) + " \u5b57\u6bb5\u7c7b\u578b\u9519\u8bef: " + nested_field + " \u5e94\u4e3a " + nested_field_type)
									return false
					return true
				else:
					# 验证数组元素类型
					for i in range(value.size()):
						if not _validate_field_type(value[i], {'type':element_type}, value, i):
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
					if not _validate_field_type(k, key_type):
						return false

					# 对于值，我们可以修改它
					if not _validate_field_type(value[k], value_type, value, k):
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
