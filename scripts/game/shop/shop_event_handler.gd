extends Node
class_name ShopEventHandler
## 商店事件处理器
## 统一处理商店相关事件

# 信号
signal shop_refresh_requested(player_level)
signal battle_round_started(round_number)
signal map_node_selected(node_data)
signal difficulty_changed(old_level, new_level)

# 初始化
func _init():
	# 连接事件总线信号
	_connect_signals()

# 连接信号
func _connect_signals():
	# 连接经济事件
	GlobalEventBus.economy.add_listener("shop_refresh_requested", _on_shop_refresh_requested)
	
	# 连接战斗事件
	GlobalEventBus.battle.add_listener("battle_round_started", _on_battle_round_started)
	
	# 连接地图事件
	GlobalEventBus.map.add_listener("map_node_selected", _on_map_node_selected)
	
	# 连接游戏事件
	GlobalEventBus.game.add_listener("GameEvents.DifficultyChangedEvent", _on_difficulty_changed)

# 商店刷新请求事件处理
func _on_shop_refresh_requested(player_level: int):
	# 转发事件
	shop_refresh_requested.emit(player_level)

# 回合开始事件处理
func _on_battle_round_started(round_number: int):
	# 转发事件
	battle_round_started.emit(round_number)

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary):
	# 转发事件
	map_node_selected.emit(node_data)

# 难度变化事件处理
func _on_difficulty_changed(old_level: int, new_level: int):
	# 转发事件
	difficulty_changed.emit(old_level, new_level)

# 清理
func cleanup():
	# 断开事件总线信号
	GlobalEventBus.economy.remove_listener("shop_refresh_requested", _on_shop_refresh_requested)
	GlobalEventBus.battle.remove_listener("battle_round_started", _on_battle_round_started)
	GlobalEventBus.map.remove_listener("map_node_selected", _on_map_node_selected)
	
	# 断开难度变化事件
	GlobalEventBus.game.remove_listener("GameEvents.DifficultyChangedEvent", _on_difficulty_changed)
