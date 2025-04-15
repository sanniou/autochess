extends SceneTree
## 完整的配置文件迁移工具
## 确保所有配置文件都符合标准结构

# 配置文件路径
const CONFIG_PATHS = {
	"chess_pieces": "res://config/chess_pieces.json",
	"equipment": "res://config/equipment.json",
	"map_nodes": "res://config/map_nodes.json",
	"relics": "res://config/relics/relics.json",
	"synergies": "res://config/synergies.json",
	"events": "res://config/events/events.json",
	"difficulty": "res://config/difficulty.json",
	"achievements": "res://config/achievements.json",
	"skins": "res://config/skins.json"
}

# 配置文件标准结构
const CONFIG_SCHEMAS = {
	"chess_pieces": {
		"required_fields": ["id", "name", "description", "cost", "health", "attack_damage", "attack_speed", "armor", "magic_resist", "attack_range", "move_speed"],
		"path_fields": ["icon", "model"],
		"path_prefixes": {
			"icon": "res://assets/images/chess/",
			"model": "res://assets/models/chess/"
		}
	},
	"equipment": {
		"required_fields": ["id", "name", "description", "rarity"],
		"path_fields": ["icon"],
		"path_prefixes": {
			"icon": "res://assets/images/equipment/"
		},
		"rename_fields": {
			"icon": "icon_path"
		}
	},
	"relics": {
		"required_fields": ["id", "name", "description", "rarity", "is_passive"],
		"path_fields": ["icon_path"],
		"path_prefixes": {
			"icon_path": "res://assets/images/relics/"
		}
	},
	"synergies": {
		"required_fields": ["id", "name", "description", "thresholds"],
		"path_fields": ["icon"],
		"path_prefixes": {
			"icon": "res://assets/images/synergies/"
		},
		"rename_fields": {
			"icon": "icon_path"
		}
	},
	"events": {
		"required_fields": ["id", "title", "description", "choices"],
		"path_fields": ["image_path"],
		"path_prefixes": {
			"image_path": "res://assets/images/events/"
		},
		"rename_fields": {
			"name": "title",
			"image": "image_path"
		}
	},
	"difficulty": {
		"required_fields": ["name", "description"]
	},
	"achievements": {
		"required_fields": ["id", "name", "description", "requirements"],
		"path_fields": ["icon"],
		"path_prefixes": {
			"icon": "res://assets/images/achievements/"
		},
		"rename_fields": {
			"icon": "icon_path"
		}
	},
	"skins": {
		"required_fields": ["id", "name", "description", "type"],
		"path_fields": ["preview", "path"],
		"path_prefixes": {
			"preview": "res://assets/images/skins/",
			"path": "res://assets/skins/"
		},
		"rename_fields": {
			"preview": "preview_path"
		}
	}
}

func _init():
	print("开始全面迁移配置文件...")
	
	# 迁移所有配置文件
	for config_name in CONFIG_PATHS:
		migrate_config_file(config_name, CONFIG_PATHS[config_name])
	
	print("配置文件迁移完成！")
	quit()

## 迁移配置文件
func migrate_config_file(config_name: String, config_path: String):
	print("迁移配置文件: " + config_name + " (" + config_path + ")")
	
	# 检查文件是否存在
	if not FileAccess.file_exists(config_path):
		print("配置文件不存在: " + config_path)
		return
	
	# 加载配置文件
	var config_data = load_json_file(config_path)
	if config_data.is_empty():
		print("配置文件为空: " + config_path)
		return
	
	# 获取配置文件的标准结构
	var schema = CONFIG_SCHEMAS.get(config_name, {})
	if schema.is_empty():
		print("未找到配置文件的标准结构: " + config_name)
		return
	
	# 迁移配置数据
	var migrated_data = {}
	var migrated_count = 0
	
	for item_id in config_data:
		var item = config_data[item_id]
		var migrated_item = item.duplicate()
		var item_migrated = false
		
		# 确保有 id 字段
		if not migrated_item.has("id"):
			migrated_item["id"] = item_id
			item_migrated = true
		
		# 添加必要字段
		for field in schema.get("required_fields", []):
			if not migrated_item.has(field):
				if field == "id":
					migrated_item[field] = item_id
				elif field == "name" and migrated_item.has("title"):
					migrated_item[field] = migrated_item["title"]
				elif field == "title" and migrated_item.has("name"):
					migrated_item[field] = migrated_item["name"]
				elif field == "description":
					migrated_item[field] = "No description"
				elif field == "is_passive":
					migrated_item[field] = false
				elif field == "rarity":
					migrated_item[field] = 0
				elif field == "cost":
					migrated_item[field] = 1
				elif field == "health" or field == "attack_damage" or field == "armor" or field == "magic_resist":
					migrated_item[field] = 100
				elif field == "attack_speed":
					migrated_item[field] = 1.0
				elif field == "attack_range":
					migrated_item[field] = 1
				elif field == "move_speed":
					migrated_item[field] = 300
				elif field == "choices":
					migrated_item[field] = []
				elif field == "thresholds":
					migrated_item[field] = []
				elif field == "requirements":
					migrated_item[field] = {"type": "none", "count": 1}
				elif field == "type":
					migrated_item[field] = "normal"
				else:
					migrated_item[field] = ""
				item_migrated = true
		
		# 重命名字段
		for old_field in schema.get("rename_fields", {}):
			var new_field = schema.rename_fields[old_field]
			if migrated_item.has(old_field) and not migrated_item.has(new_field):
				migrated_item[new_field] = migrated_item[old_field]
				migrated_item.erase(old_field)
				item_migrated = true
		
		# 确保路径字段使用完整路径
		for field in schema.get("path_fields", []):
			var actual_field = schema.get("rename_fields", {}).get(field, field)
			if migrated_item.has(actual_field) and not migrated_item[actual_field].begins_with("res://"):
				var prefix = schema.get("path_prefixes", {}).get(field, "res://assets/")
				migrated_item[actual_field] = prefix + migrated_item[actual_field]
				item_migrated = true
		
		# 添加到迁移后的数据
		migrated_data[item_id] = migrated_item
		
		if item_migrated:
			migrated_count += 1
	
	# 保存迁移后的配置文件
	if migrated_count > 0:
		save_json_file(config_path, migrated_data)
		print("已迁移 " + str(migrated_count) + " 个项目")
	else:
		print("配置文件已符合标准结构，无需迁移")

## 加载 JSON 文件
func load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("文件不存在: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("无法打开文件: " + file_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("解析 JSON 失败: " + file_path + ", 行 " + str(json.get_error_line()) + ": " + json.get_error_message())
		return {}
	
	return json.get_data()

## 保存 JSON 文件
func save_json_file(file_path: String, data: Dictionary) -> bool:
	# 确保目录存在
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("无法打开文件进行写入: " + file_path)
		return false
	
	var json_text = JSON.stringify(data, "  ")
	file.store_string(json_text)
	file.close()
	
	print("文件已保存: " + file_path)
	return true
