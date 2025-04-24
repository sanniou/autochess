extends RefCounted
class_name ConfigQuery
## 配置查询构建器
## 提供链式调用API，简化配置查询

# 配置管理器引用
var _config_manager: ConfigManager

# 查询参数
var _config_type: int
var _conditions: Dictionary = {}
var _as_model: bool = true

## 初始化查询构建器
func _init(config_manager: ConfigManager, config_type: int):
	_config_manager = config_manager
	_config_type = config_type

## 添加查询条件
## 可以链式调用
func where(field: String, value) -> ConfigQuery:
	_conditions[field] = value
	return self

## 添加多个查询条件
## 可以链式调用
func where_many(conditions: Dictionary) -> ConfigQuery:
	for field in conditions:
		_conditions[field] = conditions[field]
	return self

## 设置是否返回模型对象
## 可以链式调用
func as_model(value: bool = true) -> ConfigQuery:
	_as_model = value
	return self

## 获取查询结果（字典形式）
func get() -> Dictionary:
	return _config_manager.query(_config_type, _conditions, _as_model)

## 获取查询结果（数组形式）
func get_array() -> Array:
	return _config_manager.query_array(_config_type, _conditions, _as_model)

## 获取第一个匹配的结果
func first():
	var results = get_array()
	if results.is_empty():
		return null
	return results[0]

## 获取结果数量
func count() -> int:
	return get().size()

## 检查是否有匹配结果
func has_results() -> bool:
	return count() > 0
