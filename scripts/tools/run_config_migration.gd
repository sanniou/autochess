extends SceneTree
## 运行配置迁移工具
## 用于迁移配置文件并确保所有代码都使用 ConfigManager 的方法

func _init():
	print("开始配置迁移和代码检查...")

	# 迁移配置文件
	migrate_configs()

	# 检查代码使用
	check_code_usage()

	print("配置迁移和代码检查完成！")

## 迁移配置文件
func migrate_configs():
	print("迁移配置文件...")

	# 获取配置管理器
	var config_manager = get_node("/root/ConfigManager")

	# 获取所有配置文件
	var config_files = config_manager.get_all_config_files()
	print("找到 " + str(config_files.size()) + " 个配置文件")

	# 迁移事件配置
	migrate_events_config(config_manager)

	# 迁移其他配置文件
	for config_name in config_files:
		var config_path = config_files[config_name]
		print("检查配置文件: " + config_name + " (" + config_path + ")")

		# 加载配置文件
		var config_data = config_manager.load_json(config_path)
		if config_data.is_empty():
			print("配置文件为空: " + config_path)
			continue

		# 根据配置类型进行迁移
		var migrated = false

		if config_name == "chess_pieces":
			migrated = migrate_chess_pieces_config(config_manager, config_path, config_data)
		elif config_name == "equipment":
			migrated = migrate_equipment_config(config_manager, config_path, config_data)
		elif config_name == "synergies":
			migrated = migrate_synergies_config(config_manager, config_path, config_data)
		elif config_name == "relics/relics":
			migrated = migrate_relics_config(config_manager, config_path, config_data)

		if migrated:
			print("配置文件已迁移: " + config_path)
		else:
			print("配置文件无需迁移: " + config_path)

	print("配置文件迁移完成")

## 迁移事件配置
func migrate_events_config(config_manager):
	print("迁移事件配置...")

	# 检查是否存在旧的事件配置
	var old_events_path = "res://config/events.json"
	var new_events_path = "res://config/events/events.json"

	if FileAccess.file_exists(old_events_path):
		print("找到旧的事件配置文件，开始迁移...")

		# 加载旧的事件配置
		var old_events = config_manager.load_json(old_events_path)
		if old_events.is_empty():
			print("旧的事件配置为空，跳过迁移")
			return false

		# 加载新的事件配置
		var new_events = {}
		if FileAccess.file_exists(new_events_path):
			new_events = config_manager.load_json(new_events_path)

		# 迁移事件配置
		for event_id in old_events:
			var old_event = old_events[event_id]

			# 如果新配置中已存在该事件，跳过
			if new_events.has(event_id):
				print("事件 " + event_id + " 已存在于新配置中，跳过")
				continue

			# 创建新的事件配置
			var new_event = {
				"id": event_id,
				"title": old_event.get("name", "未命名事件"),
				"description": old_event.get("description", ""),
				"image_path": "res://assets/images/events/" + old_event.get("image", "default.png"),
				"event_type": "normal",
				"weight": 100,
				"is_one_time": false,
				"choices": []
			}

			# 迁移选项
			if old_event.has("choices"):
				for choice in old_event.choices:
					var new_choice = {
						"text": choice.get("text", ""),
						"requirements": choice.get("requirements", {}),
						"effects": []
					}

					# 迁移效果
					if choice.has("effects"):
						for effect in choice.effects:
							var new_effect = {}

							if effect.has("type"):
								new_effect["type"] = effect.type

							if effect.has("amount"):
								if effect.amount < 0:
									new_effect["operation"] = "subtract"
								else:
									new_effect["operation"] = "add"
								new_effect["value"] = abs(effect.amount)

							if effect.has("rarity"):
								new_effect["rarity"] = effect.rarity

							if effect.has("count"):
								new_effect["count"] = effect.count

							if effect.has("options"):
								new_effect["options"] = effect.options

							if effect.has("chance"):
								new_effect["chance"] = effect.chance

							new_choice.effects.append(new_effect)

					new_event.choices.append(new_choice)

			# 添加到新配置
			new_events[event_id] = new_event

		# 保存新的事件配置
		config_manager.save_json(new_events_path, new_events)
		print("事件配置迁移完成")
		return true
	else:
		print("未找到旧的事件配置文件，跳过迁移")
		return false

## 迁移棋子配置
func migrate_chess_pieces_config(config_manager, config_path, config_data):
	var migrated = false
	var migrated_data = {}

	for piece_id in config_data:
		var piece = config_data[piece_id]
		var migrated_piece = piece.duplicate()

		# 确保有 id 字段
		if not migrated_piece.has("id"):
			migrated_piece["id"] = piece_id
			migrated = true

		# 确保图标路径是完整路径
		if migrated_piece.has("icon") and not migrated_piece.icon.begins_with("res://"):
			migrated_piece["icon"] = "res://assets/images/chess/" + migrated_piece.icon
			migrated = true

		# 确保模型路径是完整路径
		if migrated_piece.has("model") and not migrated_piece.model.begins_with("res://"):
			migrated_piece["model"] = "res://assets/models/chess/" + migrated_piece.model
			migrated = true

		migrated_data[piece_id] = migrated_piece

	if migrated:
		config_manager.save_json(config_path, migrated_data)

	return migrated

## 迁移装备配置
func migrate_equipment_config(config_manager, config_path, config_data):
	var migrated = false
	var migrated_data = {}

	for equip_id in config_data:
		var equip = config_data[equip_id]
		var migrated_equip = equip.duplicate()

		# 确保有 id 字段
		if not migrated_equip.has("id"):
			migrated_equip["id"] = equip_id
			migrated = true

		# 确保图标路径是完整路径
		if migrated_equip.has("icon") and not migrated_equip.icon.begins_with("res://"):
			migrated_equip["icon_path"] = "res://assets/images/equipment/" + migrated_equip.icon
			migrated_equip.erase("icon")
			migrated = true

		migrated_data[equip_id] = migrated_equip

	if migrated:
		config_manager.save_json(config_path, migrated_data)

	return migrated

## 迁移羁绊配置
func migrate_synergies_config(config_manager, config_path, config_data):
	var migrated = false
	var migrated_data = {}

	for synergy_id in config_data:
		var synergy = config_data[synergy_id]
		var migrated_synergy = synergy.duplicate()

		# 确保有 id 字段
		if not migrated_synergy.has("id"):
			migrated_synergy["id"] = synergy_id
			migrated = true

		# 确保图标路径是完整路径
		if migrated_synergy.has("icon") and not migrated_synergy.icon.begins_with("res://"):
			migrated_synergy["icon_path"] = "res://assets/images/synergies/" + migrated_synergy.icon
			migrated_synergy.erase("icon")
			migrated = true

		migrated_data[synergy_id] = migrated_synergy

	if migrated:
		config_manager.save_json(config_path, migrated_data)

	return migrated

## 迁移遗物配置
func migrate_relics_config(config_manager, config_path, config_data):
	var migrated = false
	var migrated_data = {}

	for relic_id in config_data:
		var relic = config_data[relic_id]
		var migrated_relic = relic.duplicate()

		# 确保有 id 字段
		if not migrated_relic.has("id"):
			migrated_relic["id"] = relic_id
			migrated = true

		# 确保图标路径是完整路径
		if migrated_relic.has("icon") and not migrated_relic.icon_path.begins_with("res://"):
			migrated_relic["icon_path"] = "res://assets/images/relics/" + migrated_relic.icon_path
			migrated = true

		migrated_data[relic_id] = migrated_relic

	if migrated:
		config_manager.save_json(config_path, migrated_data)

	return migrated

## 检查代码使用
func check_code_usage():
	print("检查代码使用...")

	# 这里我们只能提供一些建议，因为我们无法自动修改所有代码
	print("建议检查以下文件，确保它们使用 ConfigManager 的方法：")
	print("1. scripts/ui/skin_system.gd - 已修改，现在使用 get_all_skins()")
	print("2. 任何直接加载 JSON 文件的脚本")
	print("3. 任何直接引用配置路径的脚本")

	print("代码检查完成，请手动检查其他可能的问题")

	# 退出脚本
	quit()
