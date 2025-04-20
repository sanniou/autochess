extends Node
## 配置管理器使用示例
## 展示如何正确使用 ConfigManager

func _ready():
	# 示例 1: 获取所有棋子配置
	print("示例 1: 获取所有棋子配置")
	var all_chess_pieces = ConfigManager.get_all_chess_pieces()
	print("棋子数量: ", all_chess_pieces.size())
	
	# 示例 2: 获取特定棋子配置
	print("\n示例 2: 获取特定棋子配置")
	var warrior = ConfigManager.get_chess_piece_config("warrior_1")
	if not warrior.is_empty():
		print("棋子名称: ", warrior.name)
		print("棋子描述: ", warrior.description)
		print("棋子生命值: ", warrior.health)
		print("棋子攻击力: ", warrior.attack_damage)
	
	# 示例 3: 获取所有遗物配置
	print("\n示例 3: 获取所有遗物配置")
	var all_relics = ConfigManager.get_all_relics()
	print("遗物数量: ", all_relics.size())
	
	# 示例 4: 获取特定遗物配置
	print("\n示例 4: 获取特定遗物配置")
	var lucky_coin = ConfigManager.get_relic_config("lucky_coin")
	if not lucky_coin.is_empty():
		print("遗物名称: ", lucky_coin.name)
		print("遗物描述: ", lucky_coin.description)
		print("遗物稀有度: ", lucky_coin.rarity)
	
	# 示例 5: 获取所有事件配置
	print("\n示例 5: 获取所有事件配置")
	var all_events = ConfigManager.get_all_events()
	print("事件数量: ", all_events.size())
	
	# 示例 6: 获取特定事件配置
	print("\n示例 6: 获取特定事件配置")
	var treasure_chest = ConfigManager.get_event_config("treasure_chest")
	if not treasure_chest.is_empty():
		print("事件标题: ", treasure_chest.title)
		print("事件描述: ", treasure_chest.description)
		print("事件类型: ", treasure_chest.event_type)
	
	# 示例 7: 使用通用方法获取配置
	print("\n示例 7: 使用通用方法获取配置")
	var chess_config = ConfigManager.get_config("chess_pieces")
	print("棋子数量: ", chess_config.size())
	
	# 示例 8: 加载任意配置文件
	print("\n示例 8: 加载任意配置文件")
	var custom_config = ConfigManager.load_json("res://config/chess_pieces.json")
	print("自定义配置数据大小: ", custom_config.size())
	
	# 示例 9: 获取所有配置文件
	print("\n示例 9: 获取所有配置文件")
	var all_configs = ConfigManager.get_all_config_files()
	print("配置文件数量: ", all_configs.size())
	for config_name in all_configs:
		print("- ", config_name, ": ", all_configs[config_name])
	
	# 示例 10: 验证配置文件
	print("\n示例 10: 验证配置文件")
	if ConfigManager.debug_mode:
		ConfigManager.validate_all_configs()
		print("配置验证完成，请查看控制台输出")
	else:
		print("配置验证仅在调试模式下可用")
