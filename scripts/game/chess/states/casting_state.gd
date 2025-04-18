extends "res://scripts/game/chess/states/chess_state.gd"
class_name CastingState
## 棋子施法状态
## 处理棋子在施法时的行为

# 状态名称
func _init():
	state_name = "casting"

# 施法持续时间
var cast_duration: float = 0.5
var cast_timer: float = 0.0
var ability_activated: bool = false

# 进入状态
func enter() -> void:
	# 重置施法计时器
	cast_timer = 0.0
	ability_activated = false
	
	# 播放施法动画
	owner.play_animation("cast")

# 退出状态
func exit() -> void:
	pass

# 物理更新
func physics_process(delta: float) -> void:
	# 更新施法计时器
	cast_timer += delta
	
	# 在施法中间点激活技能
	if not ability_activated and cast_timer >= cast_duration / 2:
		ability_activated = true
		owner.activate_ability()
	
	# 施法完成后返回攻击或空闲状态
	if cast_timer >= cast_duration:
		if owner.has_target():
			var target = owner.get_target()
			if target and not owner.is_target_dead(target):
				var distance = owner.get_distance_to_target(target)
				if distance <= owner.get_attack_range():
					owner.state_machine.change_state("attacking")
				else:
					owner.state_machine.change_state("moving")
			else:
				owner.state_machine.change_state("idle")
		else:
			owner.state_machine.change_state("idle")
	
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
	
	return ""
