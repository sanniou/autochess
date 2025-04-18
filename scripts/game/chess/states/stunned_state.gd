extends "res://scripts/game/chess/states/chess_state.gd"
class_name StunnedState
## 棋子眩晕状态
## 处理棋子在眩晕时的行为

# 状态名称
func _init():
	state_name = "stunned"

# 眩晕持续时间
var stun_duration: float = 0.0
var stun_timer: float = 0.0

# 进入状态
func enter() -> void:
	# 获取眩晕持续时间
	stun_duration = owner.get_stun_duration()
	stun_timer = 0.0
	
	# 播放眩晕动画
	owner.play_animation("stunned")

# 退出状态
func exit() -> void:
	pass

# 物理更新
func physics_process(delta: float) -> void:
	# 更新眩晕计时器
	stun_timer += delta
	
	# 眩晕结束后返回空闲状态
	if stun_timer >= stun_duration:
		owner.clear_stun()
		owner.state_machine.change_state("idle")
	
	# 检查状态转换
	var next_state = check_transitions()
	if next_state != "":
		owner.state_machine.change_state(next_state)

# 检查状态转换
func check_transitions() -> String:
	# 如果死亡，切换到死亡状态
	if owner.is_dead():
		return "dead"
	
	return ""
