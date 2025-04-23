extends Node
## 配置管理器枚举API使用示例
## 展示如何使用枚举API访问配置

func _ready():
	# 示例 1: 使用枚举获取所有棋子配置
	print("示例 1: 使用枚举获取所有棋子配置")
	var all_chess_pieces = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)
	print("棋子数量: ", all_chess_pieces.size())
	
	# 示例 2: 使用枚举获取特定棋子配置
	print("\n示例 2: 使用枚举获取特定棋子配置")
	var warrior = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.CHESS_PIECES, "warrior_1")
	if warrior:
		print("棋子名称: ", warrior.get_chess_name())
		print("棋子描述: ", warrior.get_description())
		print("棋子生命值: ", warrior.get_health())
		print("棋子攻击力: ", warrior.get_attack_damage())
	
	# 示例 3: 使用枚举获取所有遗物配置
	print("\n示例 3: 使用枚举获取所有遗物配置")
	var all_relics = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.RELICS)
	print("遗物数量: ", all_relics.size())
	
	# 示例 4: 使用枚举获取特定遗物配置
	print("\n示例 4: 使用枚举获取特定遗物配置")
	var lucky_coin = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.RELICS, "lucky_coin")
	if lucky_coin:
		print("遗物名称: ", lucky_coin.get_value("name", ""))
		print("遗物描述: ", lucky_coin.get_value("description", ""))
		print("遗物稀有度: ", lucky_coin.get_value("rarity", ""))
	
	# 示例 5: 使用枚举获取所有事件配置
	print("\n示例 5: 使用枚举获取所有事件配置")
	var all_events = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.EVENTS)
	print("事件数量: ", all_events.size())
	
	# 示例 6: 使用枚举获取特定事件配置
	print("\n示例 6: 使用枚举获取特定事件配置")
	var treasure_chest = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.EVENTS, "treasure_chest")
	if treasure_chest:
		print("事件标题: ", treasure_chest.get_value("title", ""))
		print("事件描述: ", treasure_chest.get_value("description", ""))
		print("事件类型: ", treasure_chest.get_value("event_type", ""))
	
	# 示例 7: 使用通用方法获取配置
	print("\n示例 7: 使用通用方法获取配置")
	var chess_config = GameManager.config_manager.get_config_enum(ConfigTypes.Type.CHESS_PIECES)
	print("棋子数量: ", chess_config.size())
	
	# 示例 8: 使用枚举注册新的配置类型
	print("\n示例 8: 使用枚举注册新的配置类型")
	GameManager.config_manager.register_config_type_enum(
		ConfigTypes.Type.BOARD_SKINS,
		"res://config/skins/custom_board_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)
	print("注册成功!")
	
	# 示例 9: 使用枚举重新加载配置
	print("\n示例 9: 使用枚举重新加载配置")
	var result = GameManager.config_manager.reload_config_enum(ConfigTypes.Type.CHESS_PIECES)
	print("重新加载结果: ", result)
	
	# 示例 10: 使用枚举设置配置项
	print("\n示例 10: 使用枚举设置配置项")
	var new_chess_data = {
		"id": "custom_chess",
		"name": "自定义棋子",
		"description": "这是一个通过API创建的自定义棋子",
		"cost": 3,
		"health": 100,
		"attack_damage": 20,
		"attack_speed": 1.0,
		"armor": 10,
		"magic_resist": 10,
		"attack_range": 1,
		"move_speed": 300,
		"ability": {
			"name": "自定义技能",
			"description": "这是一个自定义技能",
			"type": "damage",
			"cooldown": 10.0
		},
		"synergies": ["warrior", "mage"],
		"tier": 2
	}
	var set_result = GameManager.config_manager.set_config_item_enum(
		ConfigTypes.Type.CHESS_PIECES,
		"custom_chess",
		new_chess_data
	)
	print("设置配置项结果: ", set_result)
	
	# 示例 11: 使用枚举获取刚刚设置的配置项
	print("\n示例 11: 使用枚举获取刚刚设置的配置项")
	var custom_chess = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.CHESS_PIECES, "custom_chess")
	if custom_chess:
		print("自定义棋子名称: ", custom_chess.get_chess_name())
		print("自定义棋子描述: ", custom_chess.get_description())
		print("自定义棋子生命值: ", custom_chess.get_health())
