extends Node
class_name AbilityConfigLoader
## 技能配置加载器
## 负责加载和管理技能配置

# 配置目录
const ABILITY_CONFIG_DIR = "res://config/abilities/"

# 技能配置缓存
var _ability_configs = {}

# 初始化
func _init() -> void:
	# 加载所有技能配置
	_load_all_ability_configs()

# 加载所有技能配置
func _load_all_ability_configs() -> void:
	# 获取配置目录
	var dir = DirAccess.open(ABILITY_CONFIG_DIR)
	if not dir:
		push_error("无法打开技能配置目录: " + ABILITY_CONFIG_DIR)
		return
	
	# 扫描配置文件
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = ABILITY_CONFIG_DIR + file_name
			var ability_id = file_name.get_basename()
			_load_ability_config(ability_id, file_path)
		elif dir.current_is_dir() and file_name != "." and file_name != "..":
			# 扫描子目录
			var subdir_path = ABILITY_CONFIG_DIR + file_name + "/"
			var subdir = DirAccess.open(subdir_path)
			if subdir:
				subdir.list_dir_begin()
				var subfile_name = subdir.get_next()
				while subfile_name != "":
					if not subdir.current_is_dir() and subfile_name.ends_with(".json"):
						var file_path = subdir_path + subfile_name
						var ability_id = subfile_name.get_basename()
						_load_ability_config(ability_id, file_path)
					subfile_name = subdir.get_next()
				subdir.list_dir_end()
		file_name = dir.get_next()
	dir.list_dir_end()

# 加载技能配置
func _load_ability_config(ability_id: String, file_path: String) -> void:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("技能配置文件不存在: " + file_path)
		return
	
	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("无法打开技能配置文件: " + file_path)
		return
	
	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("解析技能配置文件失败: " + file_path + ", 行 " + str(json.get_error_line()) + ": " + json.get_error_message())
		return
	
	# 获取配置数据
	var config_data = json.get_data()
	
	# 缓存配置
	_ability_configs[ability_id] = config_data

# 获取技能配置
func get_ability_config(ability_id: String) -> Dictionary:
	if _ability_configs.has(ability_id):
		return _ability_configs[ability_id]
	return {}

# 获取所有技能配置
func get_all_ability_configs() -> Dictionary:
	return _ability_configs

# 重新加载技能配置
func reload_ability_configs() -> void:
	_ability_configs.clear()
	_load_all_ability_configs()
