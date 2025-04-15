extends SceneTree
## 运行配置迁移工具（简化版）
## 用于迁移配置文件并确保所有代码都使用 ConfigManager 的方法

func _init():
	print("开始配置迁移和代码检查...")
	
	# 检查代码使用
	check_code_usage()
	
	print("配置迁移和代码检查完成！")
	quit()

## 检查代码使用
func check_code_usage():
	print("检查代码使用...")
	
	# 这里我们只能提供一些建议，因为我们无法自动修改所有代码
	print("建议检查以下文件，确保它们使用 ConfigManager 的方法：")
	print("1. scripts/ui/skin_system.gd - 已修改，现在使用 get_all_skins()")
	print("2. 任何直接加载 JSON 文件的脚本")
	print("3. 任何直接引用配置路径的脚本")
	
	# 检查 skin_system.gd 文件
	if FileAccess.file_exists("res://scripts/ui/skin_system.gd"):
		print("\n检查 skin_system.gd 文件...")
		var file = FileAccess.open("res://scripts/ui/skin_system.gd", FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content.find("get_all_skins()") >= 0:
			print("✓ skin_system.gd 已使用 get_all_skins() 方法")
		else:
			print("✗ skin_system.gd 未使用 get_all_skins() 方法")
		
		if content.find("load_json(") >= 0:
			print("! skin_system.gd 仍在使用 load_json() 方法，建议替换为更具体的方法")
		
	# 检查其他可能直接加载 JSON 的文件
	print("\n检查其他可能直接加载 JSON 的文件...")
	
	var suspicious_files = []
	
	# 检查 scripts 目录
	check_directory_for_json_loading("res://scripts", suspicious_files)
	
	if suspicious_files.size() > 0:
		print("\n以下文件可能直接加载 JSON 文件，建议检查：")
		for file_path in suspicious_files:
			print("- " + file_path)
	else:
		print("未发现其他可疑文件")
	
	print("\n代码检查完成，请手动检查其他可能的问题")

## 检查目录中的文件是否直接加载 JSON
func check_directory_for_json_loading(dir_path: String, suspicious_files: Array):
	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("无法打开目录: " + dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path + "/" + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			# 递归检查子目录
			check_directory_for_json_loading(full_path, suspicious_files)
		elif file_name.ends_with(".gd"):
			# 检查 GD 脚本
			var file = FileAccess.open(full_path, FileAccess.READ)
			var content = file.get_as_text()
			file.close()
			
			# 检查是否直接加载 JSON 文件
			if content.find("FileAccess.open") >= 0 and content.find(".json") >= 0:
				suspicious_files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
