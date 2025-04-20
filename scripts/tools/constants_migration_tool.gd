@tool
extends EditorScript
## 常量迁移工具
## 用于更新现有代码中的常量引用

# 文件路径
const SCRIPTS_DIR = "res://scripts"
const CONSTANTS_DIR = "res://scripts/constants"

# 旧常量文件
const OLD_CONSTANTS = {
	"relic_constants.gd": "RelicConstants",
	"effect_constants.gd": "EffectConstants",
	"rarity.gd": "RarityConstants"
}

# 新常量文件
const NEW_CONSTANTS = {
	"game_constants.gd": "GameConstants",
	"effect_constants_new.gd": "EffectConstants",
	"relic_constants_new.gd": "RelicConstants"
}

# 常量映射
const CONSTANT_MAPPING = {
	# 稀有度映射
	"RarityConstants.COMMON": "GameConstants.Rarity.COMMON",
	"RarityConstants.UNCOMMON": "GameConstants.Rarity.UNCOMMON",
	"RarityConstants.RARE": "GameConstants.Rarity.RARE",
	"RarityConstants.EPIC": "GameConstants.Rarity.EPIC",
	"RarityConstants.LEGENDARY": "GameConstants.Rarity.LEGENDARY",
	
	# 方法映射
	"RarityConstants.get_rarity_name": "GameConstants.get_rarity_name",
	"RarityConstants.get_rarity_color": "GameConstants.get_rarity_color",
	"RarityConstants.get_rarities_by_level": "GameConstants.get_rarities_by_level",
	
	# RelicConstants 方法映射
	"RelicConstants.get_valid_triggers": "EffectConstants.get_trigger_type_names",
	"RelicConstants.get_valid_effect_types": "EffectConstants.get_effect_type_names",
	"RelicConstants.get_valid_condition_types": "EffectConstants.get_condition_type_names",
	
	# EffectConstants 方法映射
	"EffectConstants.get_all_effect_type_names": "EffectConstants.get_effect_type_names",
	"EffectConstants.get_all_trigger_type_names": "EffectConstants.get_trigger_type_names",
	"EffectConstants.get_all_condition_type_names": "EffectConstants.get_condition_type_names"
}

# 执行工具
func _run():
	print("开始迁移常量引用...")
	
	# 获取所有脚本文件
	var script_files = _get_all_script_files(SCRIPTS_DIR)
	
	# 更新常量引用
	var updated_count = 0
	for script_file in script_files:
		if _update_constants_in_file(script_file):
			updated_count += 1
	
	print("迁移完成，共更新 " + str(updated_count) + " 个文件")

# 获取所有脚本文件
func _get_all_script_files(dir_path: String) -> Array:
	var files = []
	var dir = DirAccess.open(dir_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = dir_path + "/" + file_name
			
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				# 递归处理子目录
				files.append_array(_get_all_script_files(full_path))
			elif file_name.ends_with(".gd"):
				# 添加脚本文件
				files.append(full_path)
			
			file_name = dir.get_next()
	
	return files

# 更新文件中的常量引用
func _update_constants_in_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	
	# 跳过新的常量文件
	for const_file in NEW_CONSTANTS.keys():
		if file_path.ends_with(const_file):
			return false
	
	# 跳过迁移工具本身
	if file_path.ends_with("constants_migration_tool.gd"):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var original_content = content
	
	# 更新常量引用
	for old_const in CONSTANT_MAPPING:
		var new_const = CONSTANT_MAPPING[old_const]
		content = content.replace(old_const, new_const)
	
	# 更新 preload 语句
	for old_file in OLD_CONSTANTS:
		var old_class = OLD_CONSTANTS[old_file]
		var old_preload = 'preload("res://scripts/constants/' + old_file + '")'
		
		for new_file in NEW_CONSTANTS:
			var new_class = NEW_CONSTANTS[new_file]
			if old_class == new_class:
				var new_preload = 'preload("res://scripts/constants/' + new_file + '")'
				content = content.replace(old_preload, new_preload)
	
	# 如果内容有变化，保存文件
	if content != original_content:
		file = FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			return false
		
		file.store_string(content)
		file.close()
		
		print("更新文件: " + file_path)
		return true
	
	return false
