extends Control
## 地图HUD
## 显示地图界面的HUD元素

# 初始化
func _ready():
	# 更新玩家信息
	_update_player_info()
	
	# 连接信号
	GlobalEventBus.game.add_listener("player_health_changed", _on_player_health_changed)
	EventBus.economy.connect_event("gold_changed", _on_gold_changed)
	GlobalEventBus.game.add_listener("player_level_changed", _on_player_level_changed)
	EventBus.game.connect_event("player_exp_changed", _on_exp_changed)

# 更新玩家信息
func _update_player_info():
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		return
	
	# 更新生命值
	var health_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/HealthContainer/HealthLabel
	health_label.text = str(player.current_health) + "/" + str(player.max_health)
	
	# 更新金币
	var gold_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/GoldContainer/GoldLabel
	gold_label.text = str(player.gold)
	
	# 更新等级
	var level_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/LevelContainer/LevelLabel
	level_label.text = "Lv." + str(player.level)
	
	# 更新经验
	var exp_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/ExpContainer/ExpLabel
	exp_label.text = str(player.exp) + "/" + str(player.get_exp_required_for_next_level())

# 玩家生命值变化事件处理
func _on_player_health_changed(old_value, new_value):
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		return
	
	# 更新生命值
	var health_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/HealthContainer/HealthLabel
	health_label.text = str(new_value) + "/" + str(player.max_health)

# 金币变化事件处理
func _on_gold_changed(old_value, new_value):
	# 更新金币
	var gold_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/GoldContainer/GoldLabel
	gold_label.text = str(new_value)

# 玩家等级变化事件处理
func _on_player_level_changed(old_level, new_level):
	# 更新等级
	var level_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/LevelContainer/LevelLabel
	level_label.text = "Lv." + str(new_level)

# 经验变化事件处理
func _on_exp_changed(old_exp, new_exp):
	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		return
	
	# 更新经验
	var exp_label = $TopPanel/MarginContainer/HBoxContainer/PlayerInfoContainer/ExpContainer/ExpLabel
	exp_label.text = str(new_exp) + "/" + str(player.get_exp_required_for_next_level())

# 棋子按钮点击处理
func _on_chess_button_pressed():
	# 打开棋子管理界面
	GameManager.change_scene("res://scenes/chess/chess_manager_scene.tscn")

# 装备按钮点击处理
func _on_equipment_button_pressed():
	# 打开装备管理界面
	GameManager.change_scene("res://scenes/equipment/equipment_manager_scene.tscn")

# 遗物按钮点击处理
func _on_relic_button_pressed():
	# 打开遗物管理界面
	GameManager.change_scene("res://scenes/relic/relic_manager_scene.tscn")

# 羁绊按钮点击处理
func _on_synergy_button_pressed():
	# 打开羁绊信息界面
	GameManager.change_scene("res://scenes/synergy/synergy_info_scene.tscn")

# 设置按钮点击处理
func _on_settings_button_pressed():
	# 显示设置弹窗
	GameManager.ui_manager.show_popup("settings_popup")
