extends Node
## 配置模型测试
## 用于测试配置模型的类型验证功能

# 测试配置模型
func test_config_model():
	print("开始测试配置模型...")
	
	# 创建测试架构
	var test_schema = {
		"id": {
			"type": "string",
			"required": true,
			"description": "配置ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "配置名称"
		},
		"value": {
			"type": "int",
			"required": true,
			"description": "整数值"
		},
		"ratio": {
			"type": "float",
			"required": true,
			"description": "浮点数值"
		},
		"enabled": {
			"type": "bool",
			"required": true,
			"description": "布尔值"
		},
		"tags": {
			"type": "array[string]",
			"required": false,
			"description": "标签数组"
		},
		"properties": {
			"type": "dict[string,any]",
			"required": false,
			"description": "属性字典"
		},
		"int_array": {
			"type": "array[int]",
			"required": false,
			"description": "整数数组"
		}
	}
	
	# 创建配置模型
	var config_model = ConfigModel.new("test", {}, test_schema)
	
	# 测试 JSON 解析的数据
	var json_text = '{
		"id": "test_config",
		"name": "测试配置",
		"value": 42,
		"ratio": 3.14,
		"enabled": true,
		"tags": ["tag1", "tag2", "tag3"],
		"properties": {
			"prop1": "value1",
			"prop2": 123,
			"prop3": true
		},
		"int_array": [1, 2, 3, 4, 5]
	}'
	
	# 解析 JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("JSON 解析错误: " + json.get_error_message())
		return
	
	var config_data = json.get_data()
	
	# 验证配置数据
	print("验证前的数据类型:")
	print("value 类型: ", typeof(config_data.value), " 值: ", config_data.value)
	print("int_array[0] 类型: ", typeof(config_data.int_array[0]), " 值: ", config_data.int_array[0])
	
	var is_valid = config_model.validate(config_data)
	
	print("验证结果: ", is_valid)
	if not is_valid:
		for error_msg in config_model.get_validation_errors():
			print("验证错误: ", error_msg)
	
	print("验证后的数据类型:")
	print("value 类型: ", typeof(config_data.value), " 值: ", config_data.value)
	print("int_array[0] 类型: ", typeof(config_data.int_array[0]), " 值: ", config_data.int_array[0])
	
	# 检查类型是否已转换
	if config_data.value is int:
		print("成功: value 已转换为 int 类型")
	else:
		print("失败: value 仍然是 float 类型")
	
	if config_data.int_array[0] is int:
		print("成功: int_array[0] 已转换为 int 类型")
	else:
		print("失败: int_array[0] 仍然是 float 类型")
	
	print("测试完成")

# 初始化
func _ready():
	# 运行测试
	test_config_model()
	
	# 完成后退出
	get_tree().quit()
