extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name DeadState
## 棋子死亡状态
## 处理棋子在死亡时的行为

# 初始化
func _init():
	state_name = "dead"
	state_description = "棋子已死亡"

# 进入状态
func enter() -> void:
	super.enter()

	# 设置死亡数据
	set_state_data("death_processed", false)
	set_state_data("death_animation_duration", 1.0)

	# 播放死亡动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("death")

	# 处理死亡效果
	_process_death()

# 退出状态
func exit() -> void:
	super.exit()

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 获取死亡动画持续时间
	var death_animation_duration = get_state_data_item("death_animation_duration", 1.0)

	# 死亡动画结束后移除棋子
	if state_time >= death_animation_duration:
		_remove_chess_piece()

# 处理死亡效果
func _process_death() -> void:
	# 检查是否已处理死亡
	if get_state_data_item("death_processed", false):
		return

	# 标记为已处理死亡
	set_state_data("death_processed", true)

	# 清除目标
	if owner and owner.has_method("clear_target"):
		owner.clear_target()

	# 发送死亡事件
	if owner:
		# 发送死亡信号
		if owner.has_signal("died"):
			owner.died.emit()

		# 发送事件
		EventBus.chess.emit_event("chess_piece_died", [owner])
		GlobalEventBus.battle.dispatch_event(BattleEvents.UnitDiedEvent.new(owner))

		# 处理死亡效果
		if owner.has_method("process_death"):
			owner.process_death()

# 移除棋子
func _remove_chess_piece() -> void:
	if owner and owner.has_method("queue_free_delayed"):
		owner.queue_free_delayed()
