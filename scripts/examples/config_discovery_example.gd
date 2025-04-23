extends Node
## 配置发现示例
## 展示如何使用配置发现机制

func _ready():
	# 示例 1: 手动发现配置
	print("示例 1: 手动发现配置")
	var discovered_configs = ConfigDiscovery.discover_configs("res://config/")
	print("发现的配置数量: ", discovered_configs.size())
	for config_type in discovered_configs:
		print("- ", config_type, ": ", discovered_configs[config_type])
	
	# 示例 2: 获取模型类路径
	print("\n示例 2: 获取模型类路径")
	var model_paths = {}
	for config_type in discovered_configs:
		var model_path = ConfigDiscovery.get_model_class_path(config_type)
		model_paths[config_type] = model_path
		print("- ", config_type, ": ", model_path)
	
	# 示例 3: 检查模型类是否存在
	print("\n示例 3: 检查模型类是否存在")
	for config_type in model_paths:
		var model_path = model_paths[config_type]
		var exists = ResourceLoader.exists(model_path)
		print("- ", config_type, ": ", exists)
	
	# 示例 4: 使用自动发现的配置
	print("\n示例 4: 使用自动发现的配置")
	var config_types = GameManager.config_manager._config_paths.keys()
	print("已注册的配置类型: ", config_types.size())
	for config_type in config_types:
		print("- ", config_type)
	
	# 示例 5: 查询自动发现的配置
	print("\n示例 5: 查询自动发现的配置")
	for config_type in config_types:
		var config_data = GameManager.config_manager.get_all_config_items(config_type)
		if not config_data.is_empty():
			print("- ", config_type, ": ", config_data.size(), " 个配置项")
	
	# 示例 6: 添加自定义配置
	print("\n示例 6: 添加自定义配置")
	var custom_config = {
		"custom_item": {
			"id": "custom_item",
			"name": "自定义配置项",
			"description": "这是一个通过代码添加的自定义配置项",
			"value": 100
		}
	}
	
	# 注册自定义配置类型
	GameManager.config_manager.register_config_type(
		"custom_config",
		"res://config/custom_config.json"
	)
	
	# 设置配置数据
	GameManager.config_manager._config_cache["custom_config"] = custom_config
	
	# 获取配置数据
	var custom_data = GameManager.config_manager.get_config_item("custom_config", "custom_item")
	print("自定义配置项: ", custom_data)
	
	# 示例 7: 使用配置查询功能
	print("\n示例 7: 使用配置查询功能")
	var rare_relics = GameManager.config_manager.query(ConfigTypes.Type.RELICS, {"rarity": "rare"})
	print("稀有遗物数量: ", rare_relics.size())
	for relic_id in rare_relics:
		var relic = rare_relics[relic_id]
		print("- ", relic.get_value("name", ""), " (", relic_id, ")")
	
	# 示例 8: 使用配置查询数组功能
	print("\n示例 8: 使用配置查询数组功能")
	var warrior_chess = GameManager.config_manager.query_array(ConfigTypes.Type.CHESS_PIECES, {"synergies": ["warrior"]})
	print("战士棋子数量: ", warrior_chess.size())
	for chess in warrior_chess:
		print("- ", chess.get_chess_name())
