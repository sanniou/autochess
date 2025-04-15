extends Node
## 配置管理器测试脚本
## 用于测试配置管理器是否能正确加载配置文件

func _ready():
	# 获取配置管理器
	var config_manager = get_node("/root/ConfigManager")
	
	# 测试加载所有配置文件
	print("测试加载所有配置文件...")
	
	# 测试棋子配置
	var chess_pieces = config_manager.get_all_chess_pieces()
	print("棋子配置数量: ", chess_pieces.size())
	
	# 测试装备配置
	var equipment = config_manager.get_all_equipment()
	print("装备配置数量: ", equipment.size())
	
	# 测试遗物配置
	var relics = config_manager.get_all_relics()
	print("遗物配置数量: ", relics.size())
	
	# 测试事件配置
	var events = config_manager.get_all_events()
	print("事件配置数量: ", events.size())
	
	# 测试羁绊配置
	var synergies = config_manager.get_all_synergies()
	print("羁绊配置数量: ", synergies.size())
	
	# 测试难度配置
	var difficulty = config_manager.get_difficulty_config(1)
	print("难度配置: ", difficulty)
	
	# 测试成就配置
	var achievements = config_manager.get_all_achievements()
	print("成就配置数量: ", achievements.size())
	
	# 测试皮肤配置
	var skins = config_manager.get_all_skins()
	print("皮肤配置数量: ", skins.size())
	
	# 测试获取所有配置文件
	var all_configs = config_manager.get_all_config_files()
	print("所有配置文件: ", all_configs)
	
	# 测试加载任意配置文件
	var test_config = config_manager.load_json("res://config/chess_pieces.json")
	print("测试加载棋子配置: ", test_config.size())
	
	print("配置管理器测试完成!")
