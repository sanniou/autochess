extends Control
## 战斗HUD
## 显示战斗界面的HUD元素

# 初始化
func _ready():
	# 更新玩家信息
	_update_player_info()
	
	# 更新战斗信息
	_update_battle_info()
	
	# 连接信号
	GlobalEventBus.game.add_listener("player_health_changed", _on_player_health_changed)
	GlobalEventBus.economy.add_listener("gold_changed", _on_gold_changed)
	GlobalEventBus.battle.add_listener("battle_started", _on_battle_started)
	GlobalEventBus.battle.add_listener("battle_ended", _on_battle_ended)

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

# 更新战斗信息
func _update_battle_info():
	# 获取战斗信息
	var round_label = $TopPanel/MarginContainer/HBoxContainer/BattleInfoContainer/RoundLabel
	round_label.text = "回合: " + str(GameManager.battle_manager.current_round)
	
	var timer_label = $TopPanel/MarginContainer/HBoxContainer/BattleInfoContainer/TimerLabel
	timer_label.text = "时间: " + str(int(GameManager.battle_manager.timer))
	
	var state_label = $TopPanel/MarginContainer/HBoxContainer/BattleInfoContainer/StateLabel
	match GameManager.battle_manager.current_state:
		GameManager.battle_manager.BattleState.PREPARE:
			state_label.text = "状态: 准备阶段"
		GameManager.battle_manager.BattleState.BATTLE:
			state_label.text = "状态: 战斗阶段"
		GameManager.battle_manager.BattleState.RESULT:
			state_label.text = "状态: 结算阶段"

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

# 战斗开始事件处理
func _on_battle_started():
	# 更新战斗信息
	_update_battle_info()
	
	# 更新底部信息
	var info_label = $BottomPanel/MarginContainer/HBoxContainer/InfoLabel
	info_label.text = "战斗开始！"

# 战斗结束事件处理
func _on_battle_ended(result):
	# 更新战斗信息
	_update_battle_info()
	
	# 更新底部信息
	var info_label = $BottomPanel/MarginContainer/HBoxContainer/InfoLabel
	if result.is_victory:
		info_label.text = "战斗胜利！"
	else:
		info_label.text = "战斗失败！"

# 羁绊按钮点击处理
func _on_synergy_button_pressed():
	# 打开羁绊信息界面
	GameManager.change_scene("res://scenes/synergy/synergy_info_scene.tscn")

# 设置按钮点击处理
func _on_settings_button_pressed():
	# 显示设置弹窗
	GameManager.ui_manager.show_popup("settings_popup")

# 处理输入
func _process(delta):
	# 更新战斗信息
	_update_battle_info()
