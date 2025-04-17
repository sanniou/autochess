extends Node
## 配置迁移工具
## 用于将现有配置文件迁移到标准结构

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

# 迁移状态
var migration_results = {}

func _ready():
	# 连接信号
	EventBus.debug.connect_event("debug_message", _on_debug_message)
	
	# 开始迁移
	migrate_all_configs()

## 迁移所有配置文件
func migrate_all_configs() -> void:
	print("开始迁移所有配置文件...")
	
	# 获取所有配置文件
	var config_files = config_manager.get_all_config_files()
	
	# 迁移每个配置文件
	for config_name in config_files:
		var config_path = config_files[config_name]
		migrate_config(config_name, config_path)
	
	# 打印迁移结果
	print("迁移完成，结果如下：")
	for config_name in migration_results:
		var result = migration_results[config_name]
		print("- " + config_name + ": " + result.status + (result.message.is_empty() ? "" : " (" + result.message + ")"))

## 迁移配置文件
func migrate_config(config_name: String, config_path: String) -> void:
	print("迁移配置文件: " + config_name)
	
	# 加载配置文件
	var config_data = config_manager.load_json(config_path)
	if config_data.is_empty():
		migration_results[config_name] = {
			"status": "失败",
			"message": "配置文件为空或不存在"
		}
		return
	
	# 根据配置类型进行迁移
	var migrated_data = {}
	var migration_status = "成功"
	var migration_message = ""
	
	if config_name == "events":
		migrated_data = migrate_events_config(config_data)
	elif config_name == "events/events":
		# 已经是标准结构，不需要迁移
		migrated_data = config_data
	elif config_name == "relics":
		migrated_data = migrate_relics_config(config_data)
	elif config_name == "relics/relics":
		# 已经是标准结构，不需要迁移
		migrated_data = config_data
	elif config_name == "chess_pieces":
		migrated_data = migrate_chess_pieces_config(config_data)
	elif config_name == "equipment":
		migrated_data = migrate_equipment_config(config_data)
	elif config_name == "synergies":
		migrated_data = migrate_synergies_config(config_data)
	elif config_name == "map_nodes":
		migrated_data = migrate_map_nodes_config(config_data)
	elif config_name == "difficulty":
		migrated_data = migrate_difficulty_config(config_data)
	elif config_name == "achievements":
		migrated_data = migrate_achievements_config(config_data)
	elif config_name == "skins":
		migrated_data = migrate_skins_config(config_data)
	else:
		migration_status = "跳过"
		migration_message = "未知的配置类型"
		migrated_data = config_data
	
	# 保存迁移后的配置文件
	if migration_status == "成功":
		var save_result = config_manager.save_json(config_path, migrated_data)
		if not save_result:
			migration_status = "失败"
			migration_message = "保存配置文件失败"
	
	# 记录迁移结果
	migration_results[config_name] = {
		"status": migration_status,
		"message": migration_message
	}

## 迁移事件配置
func migrate_events_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for event_id in config_data:
		var event = config_data[event_id]
		var migrated_event = {
			"id": event_id,
			"title": event.get("name", "未命名事件"),
			"description": event.get("description", ""),
			"image_path": "res://assets/images/events/" + event.get("image", "default.png"),
			"event_type": "normal",
			"weight": 100,
			"is_one_time": false,
			"choices": []
		}
		
		# 迁移选项
		if event.has("choices"):
			for choice in event.choices:
				var migrated_choice = {
					"text": choice.get("text", ""),
					"requirements": choice.get("requirements", {}),
					"effects": []
				}
				
				# 迁移效果
				if choice.has("effects"):
					for effect in choice.effects:
						var migrated_effect = {}
						
						if effect.has("type"):
							migrated_effect["type"] = effect.type
						
						if effect.has("amount"):
							migrated_effect["operation"] = effect.amount < 0 ? "subtract" : "add"
							migrated_effect["value"] = abs(effect.amount)
						
						if effect.has("rarity"):
							migrated_effect["rarity"] = effect.rarity
						
						if effect.has("count"):
							migrated_effect["count"] = effect.count
						
						if effect.has("options"):
							migrated_effect["options"] = effect.options
						
						if effect.has("chance"):
							migrated_effect["chance"] = effect.chance
						
						migrated_choice.effects.append(migrated_effect)
				
				migrated_event.choices.append(migrated_choice)
		
		migrated_data[event_id] = migrated_event
	
	return migrated_data

## 迁移遗物配置
func migrate_relics_config(config_data: Dictionary) -> Dictionary:
	# 遗物配置已经是标准结构，不需要迁移
	return config_data

## 迁移棋子配置
func migrate_chess_pieces_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for piece_id in config_data:
		var piece = config_data[piece_id]
		var migrated_piece = piece.duplicate()
		
		# 确保有 id 字段
		if not migrated_piece.has("id"):
			migrated_piece["id"] = piece_id
		
		# 确保图标路径是完整路径
		if migrated_piece.has("icon") and not migrated_piece.icon.begins_with("res://"):
			migrated_piece["icon"] = "res://assets/images/chess/" + migrated_piece.icon
		
		# 确保模型路径是完整路径
		if migrated_piece.has("model") and not migrated_piece.model.begins_with("res://"):
			migrated_piece["model"] = "res://assets/models/chess/" + migrated_piece.model
		
		migrated_data[piece_id] = migrated_piece
	
	return migrated_data

## 迁移装备配置
func migrate_equipment_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for equip_id in config_data:
		var equip = config_data[equip_id]
		var migrated_equip = equip.duplicate()
		
		# 确保有 id 字段
		if not migrated_equip.has("id"):
			migrated_equip["id"] = equip_id
		
		# 确保图标路径是完整路径
		if migrated_equip.has("icon") and not migrated_equip.icon.begins_with("res://"):
			migrated_equip["icon_path"] = "res://assets/images/equipment/" + migrated_equip.icon
			migrated_equip.erase("icon")
		
		migrated_data[equip_id] = migrated_equip
	
	return migrated_data

## 迁移羁绊配置
func migrate_synergies_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for synergy_id in config_data:
		var synergy = config_data[synergy_id]
		var migrated_synergy = synergy.duplicate()
		
		# 确保有 id 字段
		if not migrated_synergy.has("id"):
			migrated_synergy["id"] = synergy_id
		
		# 确保图标路径是完整路径
		if migrated_synergy.has("icon") and not migrated_synergy.icon.begins_with("res://"):
			migrated_synergy["icon_path"] = "res://assets/images/synergies/" + migrated_synergy.icon
			migrated_synergy.erase("icon")
		
		migrated_data[synergy_id] = migrated_synergy
	
	return migrated_data

## 迁移地图节点配置
func migrate_map_nodes_config(config_data: Dictionary) -> Dictionary:
	# 地图节点配置结构较为特殊，需要确保有 map_templates 和 node_types 字段
	var migrated_data = config_data.duplicate()
	
	if not migrated_data.has("map_templates"):
		migrated_data["map_templates"] = {}
	
	if not migrated_data.has("node_types"):
		migrated_data["node_types"] = {}
	
	# 确保节点类型的图标路径是完整路径
	for node_type in migrated_data.node_types:
		var type_data = migrated_data.node_types[node_type]
		if type_data.has("icon") and not type_data.icon.begins_with("res://"):
			type_data["icon_path"] = "res://assets/images/map/" + type_data.icon
			type_data.erase("icon")
	
	return migrated_data

## 迁移难度配置
func migrate_difficulty_config(config_data: Dictionary) -> Dictionary:
	# 难度配置结构较为简单，不需要特殊处理
	return config_data

## 迁移成就配置
func migrate_achievements_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for achievement_id in config_data:
		var achievement = config_data[achievement_id]
		var migrated_achievement = achievement.duplicate()
		
		# 确保有 id 字段
		if not migrated_achievement.has("id"):
			migrated_achievement["id"] = achievement_id
		
		# 确保图标路径是完整路径
		if migrated_achievement.has("icon") and not migrated_achievement.icon.begins_with("res://"):
			migrated_achievement["icon_path"] = "res://assets/images/achievements/" + migrated_achievement.icon
			migrated_achievement.erase("icon")
		
		migrated_data[achievement_id] = migrated_achievement
	
	return migrated_data

## 迁移皮肤配置
func migrate_skins_config(config_data: Dictionary) -> Dictionary:
	var migrated_data = {}
	
	for skin_id in config_data:
		var skin = config_data[skin_id]
		var migrated_skin = skin.duplicate()
		
		# 确保有 id 字段
		if not migrated_skin.has("id"):
			migrated_skin["id"] = skin_id
		
		# 确保预览图路径是完整路径
		if migrated_skin.has("preview") and not migrated_skin.preview.begins_with("res://"):
			migrated_skin["preview_path"] = "res://assets/images/skins/" + migrated_skin.preview
			migrated_skin.erase("preview")
		
		migrated_data[skin_id] = migrated_skin
	
	return migrated_data

## 调试消息处理
func _on_debug_message(message: String, level: int) -> void:
	if level >= 2:  # 错误级别
		print("错误: " + message)
	elif level == 1:  # 警告级别
		print("警告: " + message)
	else:  # 信息级别
		print("信息: " + message)
