extends "res://scripts/game/chess/states/chess_state.gd"
class_name IdleState
## 棋子空闲状态
## 处理棋子在空闲时的行为

# 状态名称
func _init():
	state_name = "idle"

# 进入状态
func enter() -> void:
	# 重置攻击计时器
	if owner.data:
		owner.data.attack_timer = 0.0
	
	# 播放空闲动画
	owner.play_animation("idle")

# 物理更新
func physics_process(delta: float) -> void:
	# 自动回蓝
	if owner.data:
		owner.gain_mana(delta * 5.0, "passive")  # 每秒回复5点法力值
	
	# 检查状态转换
	var next_state = check_transitions()
	if next_state != "":
		owner.state_machine.change_state(next_state)

# 检查状态转换
func check_transitions() -> String:
	# 如果被眩晕，切换到眩晕状态
	if owner.is_stunned():
		return "stunned"
	
	# 如果死亡，切换到死亡状态
	if owner.is_dead():
		return "dead"
	
	# 如果有目标，切换到移动或攻击状态
	if owner.has_target():
		var target = owner.get_target()
		if target:
			var distance = owner.get_distance_to_target(target)
			if distance <= owner.get_attack_range():
				return "attacking"
			else:
				return "moving"
	
	return ""
