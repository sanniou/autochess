extends Node
## 配置迁移工具
## 用于将旧的配置系统迁移到新的配置系统

# 旧的配置管理器
var old_config_manager = null

# 新的配置管理器
var new_config_manager = null

# 初始化
func _ready():
	# 获取旧的配置管理器
	old_config_manager = Engine.get_singleton("ConfigManager")
	
	# 创建新的配置管理器
	new_config_manager = load("res://scripts/managers/system/new_config_manager.gd").new()
	
	# 开始迁移
	migrate_configs()

## 迁移配置
func migrate_configs():
	print("开始迁移配置...")
	
	# 迁移配置类型
	migrate_config_types()
	
	# 迁移配置数据
	migrate_config_data()
	
	# 检查迁移结果
	check_migration_result()
	
	print("配置迁移完成")

## 迁移配置类型
func migrate_config_types():
	print("迁移配置类型...")
	
	# 获取所有配置文件
	var config_files = old_config_manager.get_all_config_files()
	
	# 迁移配置类型
	for config_type in config_files:
		var file_path = config_files[config_type]
		var model_class_path = ""
		
		# 获取模型类路径
		if old_config_manager.CONFIG_MODEL_CLASSES.has(config_type):
			model_class_path = old_config_manager.CONFIG_MODEL_CLASSES[config_type]
		
		# 注册配置类型
		new_config_manager.register_config_type(config_type, file_path, model_class_path)
		
		print("- 已迁移配置类型: " + config_type + " -> " + file_path)

## 迁移配置数据
func migrate_config_data():
	print("迁移配置数据...")
	
	# 获取所有配置类型
	var config_types = old_config_manager.get_all_config_types()
	
	# 迁移配置数据
	for config_type in config_types:
		# 获取配置数据
		var config_data = old_config_manager.get_all_config_items(config_type)
		
		# 加载配置
		new_config_manager.load_config(config_type)
		
		print("- 已迁移配置数据: " + config_type + " (" + str(config_data.size()) + " 项)")

## 检查迁移结果
func check_migration_result():
	print("检查迁移结果...")
	
	# 获取所有配置类型
	var old_config_types = old_config_manager.get_all_config_types()
	var new_config_types = new_config_manager.get_all_config_types()
	
	# 检查配置类型数量
	print("- 旧配置类型数量: " + str(old_config_types.size()))
	print("- 新配置类型数量: " + str(new_config_types.size()))
	
	# 检查配置数据
	for config_type in old_config_types:
		var old_data = old_config_manager.get_all_config_items(config_type)
		var new_data = new_config_manager.get_all_config_items(config_type)
		
		print("- " + config_type + ": 旧数据 " + str(old_data.size()) + " 项, 新数据 " + str(new_data.size()) + " 项")
		
		# 检查数据是否一致
		if old_data.size() != new_data.size():
			print("  警告: 数据项数量不一致")
		
		# 检查每个数据项
		for item_id in old_data:
			if not new_data.has(item_id):
				print("  警告: 新数据缺少项 " + item_id)
	
	# 验证所有配置
	if new_config_manager.debug_mode:
		var result = new_config_manager.validate_all_configs()
		print("- 配置验证结果: " + ("通过" if result else "失败"))

## 检查代码使用
func check_code_usage():
	print("检查代码使用...")
	
	# 这里我们只能提供一些建议，因为我们无法自动修改所有代码
	print("建议检查以下文件，确保它们使用新的配置管理器的方法：")
	print("1. 任何直接使用 ConfigManager 的脚本")
	print("2. 任何直接加载 JSON 文件的脚本")
	print("3. 任何直接引用配置路径的脚本")
	
	# 提供一些示例
	print("\n示例代码修改：")
	print("旧代码：")
	print("var config = ConfigManager.get_chess_piece_config(\"warrior_1\")")
	print("新代码：")
	print("var config = ConfigManager.get_chess_piece_config(\"warrior_1\")")
	print("注意：新的配置管理器保持了向后兼容的API，所以大多数代码不需要修改")
	
	print("\n旧代码：")
	print("var config_data = ConfigManager.load_json(\"res://config/custom.json\")")
	print("新代码：")
	print("var config_data = ConfigManager.load_json(\"res://config/custom.json\")")
	
	print("\n旧代码：")
	print("var all_chess = ConfigManager.get_all_chess_pieces()")
	print("新代码：")
	print("var all_chess = ConfigManager.get_all_chess_pieces()")
	
	print("\n如果您需要使用新的API，可以参考以下示例：")
	print("// 注册新的配置类型")
	print("ConfigManager.register_config_type(\"custom\", \"res://config/custom.json\", \"res://scripts/config/models/custom_config.gd\")")
	print("// 加载配置")
	print("ConfigManager.load_config(\"custom\")")
	print("// 获取配置模型")
	print("var model = ConfigManager.get_config_model(\"custom\", \"item_id\")")
	print("// 获取所有配置模型")
	print("var all_models = ConfigManager.get_all_config_models(\"custom\")")
	print("// 设置配置项")
	print("ConfigManager.set_config_item(\"custom\", \"item_id\", {\"name\": \"New Name\"})")
	print("// 保存配置")
	print("ConfigManager.save_config(\"custom\")")

## 替换配置管理器
func replace_config_manager():
	print("替换配置管理器...")
	
	# 这里我们只能提供一些建议，因为我们无法自动替换全局单例
	print("要替换配置管理器，请按照以下步骤操作：")
	print("1. 在 project.godot 文件中，将 ConfigManager 的路径更改为新的配置管理器路径")
	print("   ConfigManager=\"*res://scripts/managers/system/new_config_manager.gd\"")
	print("2. 重命名新的配置管理器文件")
	print("   mv res://scripts/managers/system/new_config_manager.gd res://scripts/managers/system/config_manager.gd")
	print("3. 重命名新的配置模型文件")
	print("   mv res://scripts/config/new_config_model.gd res://scripts/config/config_model.gd")
	print("4. 重启编辑器")
	
	print("注意：这将替换全局单例，可能会影响所有使用 ConfigManager 的代码")
	print("建议先备份项目，然后再进行替换")

## 运行迁移
static func run():
	var migration_tool = load("res://scripts/tools/config_migration.gd").new()
	migration_tool.migrate_configs()
	migration_tool.check_code_usage()
	migration_tool.replace_config_manager()
