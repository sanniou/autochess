extends Object
class_name BaseConstants
## 常量基类
## 为所有常量类提供基础功能和结构

## 将枚举值转换为字符串映射
static func enum_to_string_map(enum_dict: Dictionary) -> Dictionary:
	var result = {}
	for key in enum_dict:
		result[enum_dict[key]] = key.to_lower()
	return result

## 获取枚举的所有值
static func get_enum_values(enum_dict: Dictionary) -> Array:
	var values = []
	for key in enum_dict:
		values.append(enum_dict[key])
	return values

## 获取枚举的所有名称
static func get_enum_names(enum_dict: Dictionary) -> Array:
	var names = []
	for key in enum_dict:
		names.append(key)
	return names

## 检查值是否在枚举中
static func is_valid_enum_value(enum_dict: Dictionary, value) -> bool:
	return get_enum_values(enum_dict).has(value)

## 检查名称是否在枚举中
static func is_valid_enum_name(enum_dict: Dictionary, name: String) -> bool:
	return get_enum_names(enum_dict).has(name)

## 根据值获取枚举名称
static func get_enum_name_by_value(enum_dict: Dictionary, value) -> String:
	for key in enum_dict:
		if enum_dict[key] == value:
			return key
	return ""

## 根据名称获取枚举值
static func get_enum_value_by_name(enum_dict: Dictionary, name: String) -> int:
	if enum_dict.has(name):
		return enum_dict[name]
	return -1
