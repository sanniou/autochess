extends Object
class_name ConfigDiscovery
## 配置发现工具
## 用于自动发现和注册配置类型

## 扫描配置目录，发现所有配置文件
## @param config_dir 配置目录路径
## @return 发现的配置类型字典 {配置类型: 配置文件路径}
static func discover_configs(config_dir: String) -> Dictionary:
	var result = {}
	
	# 确保目录路径以斜杠结尾
	if not config_dir.ends_with("/"):
		config_dir += "/"
	
	# 扫描配置目录
	var dir = DirAccess.open(config_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# 检查是否是目录
			if dir.current_is_dir():
				# 递归扫描子目录
				var sub_dir = config_dir + file_name + "/"
				var sub_configs = discover_configs(sub_dir)
				
				# 合并结果
				for config_type in sub_configs:
					result[config_type] = sub_configs[config_type]
			else:
				# 检查是否是 JSON 文件
				if file_name.ends_with(".json"):
					# 获取配置类型
					var config_type = _get_config_type_from_file_name(file_name)
					
					# 添加到结果
					result[config_type] = config_dir + file_name
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return result

## 从文件名获取配置类型
## @param file_name 文件名
## @return 配置类型
static func _get_config_type_from_file_name(file_name: String) -> String:
	# 移除扩展名
	var config_type = file_name.get_basename()
	
	# 转换为蛇形命名
	config_type = config_type.to_snake_case()
	
	return config_type

## 从配置类型获取模型类路径
## @param config_type 配置类型
## @return 模型类路径
static func get_model_class_path(config_type: String) -> String:
	# 转换为驼峰命名
	var class_name_str = ""
	var parts = config_type.split("_")
	
	for part in parts:
		if not part.is_empty():
			class_name_str += part.capitalize()
	
	# 添加 Config 后缀
	class_name_str += "Config"
	
	# 构建路径
	return "res://scripts/config/models/" + config_type + "_config.gd"

## 扫描并注册所有配置类型
## @param config_manager 配置管理器实例
## @param config_dir 配置目录路径
static func register_all_configs(config_manager, config_dir: String) -> void:
	# 发现所有配置
	var configs = discover_configs(config_dir)
	
	# 注册所有配置
	for config_type in configs:
		var file_path = configs[config_type]
		var model_class_path = get_model_class_path(config_type)
		
		# 检查模型类是否存在
		if ResourceLoader.exists(model_class_path):
			config_manager.register_config_type(config_type, file_path, model_class_path)
		else:
			# 使用默认模型类
			config_manager.register_config_type(config_type, file_path)
