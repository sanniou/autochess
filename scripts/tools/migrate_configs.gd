extends SceneTree
## 配置迁移脚本
## 用于将现有配置文件迁移到标准结构

func _init():
	print("开始迁移配置文件...")

	# 迁移事件配置
	migrate_events_config()

	# 迁移其他配置文件
	migrate_other_configs()

	print("配置文件迁移完成！")
	quit()

## 迁移事件配置
func migrate_events_config():
	print("迁移事件配置...")

	# 检查是否存在旧的事件配置
	var old_events_path = "res://config/events.json"
	var new_events_path = "res://config/events/events.json"

	if FileAccess.file_exists(old_events_path):
		print("找到旧的事件配置文件，开始迁移...")

		# 加载旧的事件配置
		var old_events = load_json_file(old_events_path)
		if old_events.is_empty():
			print("旧的事件配置为空，跳过迁移")
			return

		# 加载新的事件配置
		var new_events = {}
		if FileAccess.file_exists(new_events_path):
			new_events = load_json_file(new_events_path)

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
		save_json_file(new_events_path, new_events)
		print("事件配置迁移完成")
	else:
		print("未找到旧的事件配置文件，跳过迁移")

## 迁移其他配置文件
func migrate_other_configs():
	print("迁移其他配置文件...")

	# 迁移棋子配置
	migrate_config_file("res://config/chess_pieces.json", func(data):
		var migrated_data = {}

		for piece_id in data:
			var piece = data[piece_id]
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
	)

	# 迁移装备配置
	migrate_config_file("res://config/equipment.json", func(data):
		var migrated_data = {}

		for equip_id in data:
			var equip = data[equip_id]
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
	)

	# 迁移羁绊配置
	migrate_config_file("res://config/synergies.json", func(data):
		var migrated_data = {}

		for synergy_id in data:
			var synergy = data[synergy_id]
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
	)

	# 迁移遗物配置
	migrate_config_file("res://config/relics/relics.json", func(data):
		# 遗物配置已经是标准结构，不需要迁移
		return data
	)

	print("其他配置文件迁移完成")

## 迁移配置文件
func migrate_config_file(file_path: String, migration_func: Callable):
	print("迁移配置文件: " + file_path)

	if not FileAccess.file_exists(file_path):
		print("配置文件不存在: " + file_path)
		return

	# 加载配置文件
	var data = load_json_file(file_path)
	if data.is_empty():
		print("配置文件为空: " + file_path)
		return

	# 迁移配置数据
	var migrated_data = migration_func.call(data)

	# 保存迁移后的配置文件
	save_json_file(file_path, migrated_data)
	print("配置文件迁移完成: " + file_path)

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
