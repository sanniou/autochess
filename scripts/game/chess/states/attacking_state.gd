extends "res://scripts/game/chess/states/chess_state.gd"
class_name AttackingState
## 棋子攻击状态
## 处理棋子在攻击时的行为

# 状态名称
func _init():
	state_name = "attacking"

# 进入状态
func enter() -> void:
	# 重置攻击计时器
	if owner.data:
		owner.data.attack_timer = 0.0
	
	# 播放攻击动画
	owner.play_animation("attack")

# 退出状态
func exit() -> void:
	pass

# 物理更新
func physics_process(delta: float) -> void:
	# 自动回蓝
	if owner.data:
		owner.gain_mana(delta * 5.0, "passive")  # 每秒回复5点法力值
	
	# 如果没有目标，返回空闲状态
	if not owner.has_target():
		owner.state_machine.change_state("idle")
		return
	
	# 获取目标
	var target = owner.get_target()
	if not target or owner.is_target_dead(target):
		owner.clear_target()
		owner.state_machine.change_state("idle")
		return
	
	# 检查是否被嘲讽
	if owner.is_taunting():
		# 如果被嘲讽，强制将嘲讽源设为目标
		var taunt_source = owner.get_taunt_source()
		if taunt_source and taunt_source != target:
			owner.set_target(taunt_source)
			target = taunt_source
			
			# 检查是否超出攻击范围
			var taunt_distance = owner.get_distance_to_target(taunt_source)
			if taunt_distance > owner.get_attack_range():
				owner.state_machine.change_state("moving")
				return
	
	# 检查是否超出攻击范围
	var distance = owner.get_distance_to_target(target)
	if distance > owner.get_attack_range():
		owner.state_machine.change_state("moving")
		return
	
	# 检查是否可以施法
	if owner.can_cast_ability():
		owner.state_machine.change_state("casting")
		return
	
	# 更新攻击计时器
	if not owner.is_disarmed() and owner.data:
		owner.data.attack_timer += delta
		if owner.data.attack_timer >= 1.0 / owner.data.attack_speed:
			owner.data.attack_timer = 0.0
			owner.perform_attack()
	
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
