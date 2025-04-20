extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name StunnedState
## 棋子眩晕状态
## 处理棋子在眩晕时的行为

# 初始化
func _init():
	state_name = "stunned"
	state_description = "棋子被眩晕，无法行动"

# 进入状态
func enter() -> void:
	super.enter()

	# 设置眩晕数据
	set_state_data("stun_duration", 0.0)  # 将在设置眩晕时设置

	# 播放眩晕动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("stunned")

	# 显示眩晕特效
	if owner and owner.has_method("show_status_effect"):
		owner.show_status_effect("stunned")

# 退出状态
func exit() -> void:
	super.exit()

	# 隐藏眩晕特效
	if owner and owner.has_method("hide_status_effect"):
		owner.hide_status_effect("stunned")

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 获取眩晕持续时间
	var stun_duration = get_state_data_item("stun_duration", 0.0)

	# 眩晕结束后返回空闲状态
	if state_time >= stun_duration:
		# 状态转换会在状态机中处理
		pass

# 设置眩晕持续时间
func set_stun_duration(duration: float) -> void:
	set_state_data("stun_duration", duration)
