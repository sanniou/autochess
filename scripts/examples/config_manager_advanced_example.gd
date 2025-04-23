extends Node
## 配置管理器高级功能示例
## 展示如何使用配置管理器的高级功能

func _ready():
	# 示例 1: 使用查询功能
	print("示例 1: 使用查询功能")
	var rare_relics = GameManager.config_manager.query(ConfigTypes.Type.RELICS, {"rarity": "rare"})
	print("稀有遗物数量: ", rare_relics.size())
	for relic_id in rare_relics:
		var relic = rare_relics[relic_id]
		print("- ", relic.get_value("name", ""), " (", relic_id, ")")
	
	# 示例 2: 使用查询数组功能
	print("\n示例 2: 使用查询数组功能")
	var warrior_chess = GameManager.config_manager.query_array(ConfigTypes.Type.CHESS_PIECES, {"synergies": ["warrior"]})
	print("战士棋子数量: ", warrior_chess.size())
	for chess in warrior_chess:
		print("- ", chess.get_chess_name())
	
	# 示例 3: 启用热重载
	print("\n示例 3: 启用热重载")
	GameManager.config_manager.enable_hot_reload(true)
	print("热重载已启用，修改配置文件后将自动重新加载")
	
	# 示例 4: 监听配置变更信号
	print("\n示例 4: 监听配置变更信号")
	GameManager.config_manager.config_changed.connect(_on_config_changed)
	print("已连接配置变更信号")
	
	# 示例 5: 修改配置并触发变更信号
	print("\n示例 5: 修改配置并触发变更信号")
	var new_chess_data = {
		"id": "custom_chess_2",
		"name": "自定义棋子2",
		"description": "这是一个通过API创建的自定义棋子",
		"cost": 4,
		"health": 120,
		"attack_damage": 25,
		"attack_speed": 1.2,
		"armor": 15,
		"magic_resist": 15,
		"attack_range": 1,
		"move_speed": 320,
		"ability": {
			"name": "自定义技能2",
			"description": "这是一个自定义技能",
			"type": "damage",
			"cooldown": 8.0
		},
		"synergies": ["warrior", "tank"],
		"tier": 3
	}
	var set_result = GameManager.config_manager.set_config_item_enum(
		ConfigTypes.Type.CHESS_PIECES,
		"custom_chess_2",
		new_chess_data
	)
	print("设置配置项结果: ", set_result)
	
	# 示例 6: 使用通用的 get 和 get_item 方法
	print("\n示例 6: 使用通用的 get 和 get_item 方法")
	var all_chess = GameManager.config_manager.get(ConfigTypes.Type.CHESS_PIECES)
	print("棋子总数: ", all_chess.size())
	
	var warrior_1 = GameManager.config_manager.get_item(ConfigTypes.Type.CHESS_PIECES, "warrior_1")
	if warrior_1:
		print("获取到棋子: ", warrior_1.get_chess_name())
	
	# 示例 7: 使用 set_item 方法
	print("\n示例 7: 使用 set_item 方法")
	var new_relic_data = {
		"id": "custom_relic",
		"name": "自定义遗物",
		"description": "这是一个通过API创建的自定义遗物",
		"rarity": "epic",
		"effects": [
			{
				"type": "stat_boost",
				"target": "all",
				"stat": "health",
				"value": 20
			}
		]
	}
	var relic_result = GameManager.config_manager.set_item(
		ConfigTypes.Type.RELICS,
		"custom_relic",
		new_relic_data
	)
	print("设置遗物结果: ", relic_result)
	
	# 示例 8: 删除配置项
	print("\n示例 8: 删除配置项")
	var delete_result = GameManager.config_manager.delete_config_item_enum(
		ConfigTypes.Type.CHESS_PIECES,
		"custom_chess_2"
	)
	print("删除配置项结果: ", delete_result)

# 配置变更回调
func _on_config_changed(config_type: String, config_id: String):
	print("配置已变更: ", config_type, ".", config_id)

# 清理
func _exit_tree():
	# 断开信号连接
	if GameManager and GameManager.config_manager:
		GameManager.config_manager.config_changed.disconnect(_on_config_changed)
