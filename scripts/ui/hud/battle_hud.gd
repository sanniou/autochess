extends BaseHUD
class_name BattleHUD
## 战斗HUD
## 显示战斗相关信息，如回合数、倒计时、战斗状态等

# 战斗管理器引用
var battle_manager = null

# 回合计时器
var round_timer: Timer = null

# 回合时间
var round_time: float = 30.0

# 当前回合
var current_round: int = 0

# 战斗状态
var battle_state: String = "preparing"  # preparing, fighting, ended

# 初始化
func _initialize() -> void:
	# 获取战斗管理器
	battle_manager = GameManager.battle_manager
	
	# 连接战斗信号
	EventBus.battle.connect_event("battle_started", _on_battle_started)
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
	EventBus.battle.connect_event("battle_round_ended", _on_battle_round_ended)
	EventBus.battle.connect_event("battle_preparing_phase_started", _on_battle_preparing_phase_started)
	EventBus.battle.connect_event("battle_fighting_phase_started", _on_battle_fighting_phase_started)
	
	# 创建回合计时器
	round_timer = Timer.new()
	round_timer.one_shot = true
	round_timer.timeout.connect(_on_round_timer_timeout)
	add_child(round_timer)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	# 更新回合显示
	if has_node("RoundLabel"):
		var round_label = get_node("RoundLabel")
		round_label.text = tr("ui.battle.round", [str(current_round)])
	
	# 更新计时器显示
	if has_node("TimerLabel"):
		var timer_label = get_node("TimerLabel")
		var time_left = round_timer.time_left if round_timer.is_stopped() == false else 0
		timer_label.text = tr("ui.battle.time_left", [str(int(time_left))])
	
	# 更新战斗状态显示
	if has_node("StateLabel"):
		var state_label = get_node("StateLabel")
		var state_text = ""
		
		match battle_state:
			"preparing":
				state_text = tr("ui.battle.state_preparing")
			"fighting":
				state_text = tr("ui.battle.state_fighting")
			"ended":
				state_text = tr("ui.battle.state_ended")
		
		state_label.text = state_text
	
	# 调用父类方法
	super.update_hud()

# 战斗开始处理
func _on_battle_started(battle_data: Dictionary) -> void:
	# 重置回合
	current_round = 0
	
	# 设置战斗状态
	battle_state = "preparing"
	
	# 更新显示
	update_hud()

# 战斗结束处理
func _on_battle_ended(result: Dictionary) -> void:
	# 停止计时器
	round_timer.stop()
	
	# 设置战斗状态
	battle_state = "ended"
	
	# 更新显示
	update_hud()
	
	# 显示战斗结果
	_show_battle_result(result)

# 回合开始处理
func _on_battle_round_started(round_number: int) -> void:
	# 更新当前回合
	current_round = round_number
	
	# 更新显示
	update_hud()

# 回合结束处理
func _on_battle_round_ended(round_number: int) -> void:
	# 停止计时器
	round_timer.stop()
	
	# 更新显示
	update_hud()

# 准备阶段开始处理
func _on_battle_preparing_phase_started() -> void:
	# 设置战斗状态
	battle_state = "preparing"
	
	# 开始计时器
	round_timer.start(round_time)
	
	# 更新显示
	update_hud()

# 战斗阶段开始处理
func _on_battle_fighting_phase_started() -> void:
	# 设置战斗状态
	battle_state = "fighting"
	
	# 停止计时器
	round_timer.stop()
	
	# 更新显示
	update_hud()

# 回合计时器超时处理
func _on_round_timer_timeout() -> void:
	# 通知战斗管理器准备阶段结束
	if battle_manager and battle_state == "preparing":
		battle_manager.end_preparing_phase()

# 显示战斗结果
func _show_battle_result(result: Dictionary) -> void:
	# 创建结果弹窗
	var popup = GameManager.ui_manager.show_popup("battle_result", result)
	
	# 连接弹窗关闭信号
	if popup and popup.has_signal("popup_hide"):
		popup.popup_hide.connect(func(): GameManager.change_state(GameManager.GameState.MAP))

# 游戏暂停处理
func _on_game_paused(paused: bool) -> void:
	# 暂停/恢复计时器
	if round_timer:
		if paused:
			round_timer.paused = true
		else:
			round_timer.paused = false
