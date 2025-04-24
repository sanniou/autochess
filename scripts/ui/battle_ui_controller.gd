extends Control
## 战斗UI控制器
## 负责战斗界面的显示和控制

# 引用
@onready var battle_speed_slider: Slider = $BattleControls/SpeedSlider
@onready var battle_speed_label: Label = $BattleControls/SpeedLabel
@onready var battle_timer: Label = $BattleInfo/TimerLabel
@onready var battle_round: Label = $BattleInfo/RoundLabel
@onready var battle_stats_panel: Panel = $BattleStatsPanel
@onready var stats_container: VBoxContainer = $BattleStatsPanel/StatsContainer

# 战斗管理器引用
var battle_manager: BattleManager

# UI节流器
var ui_throttler: UIThrottler

# 上次显示的时间文本
var _last_time_text: String = ""

# 初始化
func _ready():
	# 创建 UI 节流器
	ui_throttler = UIThrottler.new({
		"default_interval": 0.1,  # 100ms更新一次
		"high_fps_interval": 0.2,  # 高帧率时200ms更新一次
		"low_fps_interval": 0.05   # 低帧率时50ms更新一次
	})

	# 隐藏战斗统计面板
	battle_stats_panel.visible = false

	# 连接信号
	battle_speed_slider.value_changed.connect(_on_speed_slider_changed)
	GlobalEventBus.battle.add_listener("battle_started", _on_battle_started)
	GlobalEventBus.battle.add_listener("battle_ended", _on_battle_ended)
	GlobalEventBus.battle.add_listener("battle_round_started", _on_battle_round_started)

	# 获取战斗管理器引用
	battle_manager = get_node_or_null("/root/GameManager/BattleManager")

# 更新
func _process(delta):
	# 使用节流器控制UI更新频率
	if battle_manager and battle_manager.current_state == battle_manager.BattleState.BATTLE:
		if ui_throttler.should_update("battle_timer", delta):
			_update_battle_timer()

# 更新战斗计时器
func _update_battle_timer() -> void:
	var time_left = battle_manager.timer
	var new_text = "时间: %02d:%02d" % [int(time_left) / 60, int(time_left) % 60]

	# 只有当文本变化时才更新标签
	if new_text != _last_time_text:
		_last_time_text = new_text
		battle_timer.text = new_text

# 速度滑块变化处理
func _on_speed_slider_changed(value: float):
	# 设置战斗速度
	var speed = value

	if battle_manager:
		battle_manager.set_battle_speed(speed)

	# 更新速度标签
	battle_speed_label.text = "速度: %.1fx" % speed

# 战斗开始处理
func _on_battle_started():
	# 显示战斗控制界面
	visible = true

	# 重置速度滑块
	battle_speed_slider.value = 1.0

	# 隐藏战斗统计面板
	battle_stats_panel.visible = false

# 战斗结束处理
func _on_battle_ended(result):
	# 显示战斗统计
	_show_battle_stats(result)

# 关闭按钮处理
func _on_close_button_pressed():
	# 隐藏战斗统计面板
	battle_stats_panel.visible = false

# 战斗回合开始处理
func _on_battle_round_started(round_number):
	# 更新回合标签
	battle_round.text = "回合: %d" % round_number

# 显示战斗统计
func _show_battle_stats(result):
	# 清空统计容器
	for child in stats_container.get_children():
		if child.name != "StatsTitle":
			child.queue_free()

	# 获取战斗统计
	var stats = result.stats
	var is_victory = result.is_victory

	# 设置标题
	var title_label = stats_container.get_node("StatsTitle")
	title_label.text = "战斗结果: %s" % ("胜利" if is_victory else "失败")

	# 添加战斗时间
	_add_stat_row("战斗时间", "%d秒" % stats.battle_duration)

	# 添加伤害统计
	_add_stat_row("玩家造成伤害", "%.0f" % stats.player_damage_dealt)
	_add_stat_row("敌方造成伤害", "%.0f" % stats.enemy_damage_dealt)

	# 添加治疗统计
	_add_stat_row("玩家治疗量", "%.0f" % stats.player_healing)
	_add_stat_row("敌方治疗量", "%.0f" % stats.enemy_healing)

	# 添加击杀统计
	_add_stat_row("玩家击杀数", "%d" % stats.player_kills)
	_add_stat_row("敌方击杀数", "%d" % stats.enemy_kills)

	# 添加技能使用统计
	_add_stat_row("技能使用次数", "%d" % stats.abilities_used)

	# 添加剩余棋子
	_add_stat_row("玩家剩余棋子", "%d" % result.player_pieces_left)
	_add_stat_row("敌方剩余棋子", "%d" % result.enemy_pieces_left)

	# 添加奖励
	if is_victory:
		_add_stat_row("金币奖励", "%d" % result.rewards.gold)
		_add_stat_row("经验奖励", "%d" % result.rewards.exp)

		if result.rewards.has("equipment") and result.rewards.equipment:
			_add_stat_row("装备奖励", "获得%s装备" % result.rewards.equipment_rarity)

		if result.rewards.has("chess_piece") and result.rewards.chess_piece:
			_add_stat_row("棋子奖励", "获得%s棋子" % result.rewards.chess_piece_rarity)

	# 显示统计面板
	battle_stats_panel.visible = true

# 添加统计行
func _add_stat_row(stat_name: String, stat_value: String):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = stat_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	hbox.add_child(name_label)
	hbox.add_child(value_label)
	stats_container.add_child(hbox)
