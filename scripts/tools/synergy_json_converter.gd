@tool
extends EditorScript
## 羁绊 JSON 转换工具
## 将 synergies.json 中的 effect 字段转换为 effects 数组

# 配置文件路径
const SYNERGIES_JSON_PATH = "res://config/synergies.json"

# 执行工具
func _run():
	print("开始转换 synergies.json 文件...")
	
	# 加载羁绊配置
	var synergies_data = _load_json_file(SYNERGIES_JSON_PATH)
	if synergies_data.is_empty():
		print("无法加载羁绊配置文件")
		return
	
	var modified = false
	
	# 遍历所有羁绊
	for synergy_id in synergies_data:
		var synergy = synergies_data[synergy_id]
		
		# 确保有 thresholds 字段
		if not synergy.has("thresholds") or not synergy.thresholds is Array:
			print("警告: 羁绊 " + synergy_id + " 没有有效的 thresholds 字段")
			continue
		
		# 遍历所有阈值
		for threshold in synergy.thresholds:
			if not threshold is Dictionary:
				continue
			
			# 检查是否有 effect 字段但没有 effects 字段
			if threshold.has("effect") and threshold.effect is Dictionary and not threshold.has("effects"):
				# 将 effect 转换为 effects 数组
				threshold["effects"] = [threshold.effect.duplicate()]
				# 移除原 effect 字段
				threshold.erase("effect")
				modified = true
				print("转换羁绊 " + synergy_id + " 的阈值 " + str(threshold.get("count", "?")) + " 的 effect 字段为 effects 数组")
	
	# 如果有修改，保存文件
	if modified:
		_save_json_file(SYNERGIES_JSON_PATH, synergies_data)
		print("转换完成并保存")
	else:
		print("没有需要转换的内容")

# 加载 JSON 文件
func _load_json_file(file_path: String) -> Dictionary:
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

# 保存 JSON 文件
func _save_json_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("无法打开文件进行写入: " + file_path)
		return false

	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
	print("文件已保存: " + file_path)
	return true
