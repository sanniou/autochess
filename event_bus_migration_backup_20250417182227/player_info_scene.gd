extends Control
## 玩家信息界面
## 显示玩家的属性和状态

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")

# 当前玩家
var current_player = null

# 初始化
func _ready():
	# 获取当前玩家
	current_player = player_manager.get_current_player()
	
	# 更新界面
	_update_ui()
	
	# 连接信号
	EventBus.game.player_health_changed.connect(_on_player_health_changed)
	EventBus.economy.gold_changed.connect(_on_gold_changed)
	EventBus.game.player_level_changed.connect(_on_player_level_changed)
	EventBus.exp_changed.connect(_on_exp_changed)
	EventBus.chess.chess_piece_created.connect(_on_chess_piece_created)
	EventBus.chess.chess_piece_sold.connect(_on_chess_piece_sold)

# 更新界面
func _update_ui():
	if not current_player:
		return
	
	# 更新基本信息
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("NameLabel").text = current_player.player_name
	basic_info.get_node("GridContainer/HealthValue").text = str(current_player.current_health) + "/" + str(current_player.max_health)
	basic_info.get_node("GridContainer/GoldValue").text = str(current_player.gold)
	basic_info.get_node("GridContainer/LevelValue").text = str(current_player.level)
	basic_info.get_node("GridContainer/ExpValue").text = str(current_player.exp) + "/" + str(current_player.get_exp_required_for_next_level())
	basic_info.get_node("GridContainer/PopulationValue").text = str(current_player.get_current_population()) + "/" + str(current_player.get_population_limit())
	
	# 更新战斗统计
	var stats_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/StatsPanel/MarginContainer/VBoxContainer
	stats_info.get_node("GridContainer/WinStreakValue").text = str(current_player.win_streak)
	stats_info.get_node("GridContainer/LoseStreakValue").text = str(current_player.lose_streak)
	stats_info.get_node("GridContainer/TotalWinsValue").text = str(current_player.total_wins)
	stats_info.get_node("GridContainer/TotalLossesValue").text = str(current_player.total_losses)
	
	# 更新升级按钮
	var upgrade_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/UpgradePanel/MarginContainer/VBoxContainer
	var buy_exp_button = upgrade_info.get_node("HBoxContainer/BuyExpButton")
	buy_exp_button.text = "购买经验 (4金币)"
	buy_exp_button.disabled = current_player.gold < 4 or current_player.level >= 9

# 关闭按钮处理
func _on_close_button_pressed():
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 购买经验按钮处理
func _on_buy_exp_button_pressed():
	if not current_player:
		return
	
	# 购买经验
	if current_player.buy_exp(4, 4):
		# 更新界面
		_update_ui()

# 玩家生命值变化事件处理
func _on_player_health_changed(old_value, new_value):
	# 更新生命值显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/HealthValue").text = str(new_value) + "/" + str(current_player.max_health)

# 金币变化事件处理
func _on_gold_changed(old_value, new_value):
	# 更新金币显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/GoldValue").text = str(new_value)
	
	# 更新升级按钮状态
	var upgrade_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/UpgradePanel/MarginContainer/VBoxContainer
	var buy_exp_button = upgrade_info.get_node("HBoxContainer/BuyExpButton")
	buy_exp_button.disabled = new_value < 4 or current_player.level >= 9

# 玩家等级变化事件处理
func _on_player_level_changed(old_level, new_level):
	# 更新等级显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/LevelValue").text = str(new_level)
	
	# 更新人口上限显示
	basic_info.get_node("GridContainer/PopulationValue").text = str(current_player.get_current_population()) + "/" + str(current_player.get_population_limit())
	
	# 更新升级按钮状态
	var upgrade_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/UpgradePanel/MarginContainer/VBoxContainer
	var buy_exp_button = upgrade_info.get_node("HBoxContainer/BuyExpButton")
	buy_exp_button.disabled = current_player.gold < 4 or new_level >= 9

# 经验变化事件处理
func _on_exp_changed(old_exp, new_exp):
	# 更新经验显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/ExpValue").text = str(new_exp) + "/" + str(current_player.get_exp_required_for_next_level())

# 棋子创建事件处理
func _on_chess_piece_created(piece):
	# 更新人口显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/PopulationValue").text = str(current_player.get_current_population()) + "/" + str(current_player.get_population_limit())

# 棋子出售事件处理
func _on_chess_piece_sold(piece):
	# 更新人口显示
	var basic_info = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/BasicInfoPanel/MarginContainer/VBoxContainer
	basic_info.get_node("GridContainer/PopulationValue").text = str(current_player.get_current_population()) + "/" + str(current_player.get_population_limit())
