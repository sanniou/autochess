extends BattleCommand
class_name AttackCommand
## 攻击命令
## 用于控制单位攻击

# 初始化
func _init(src, tgt, cmd_params: Dictionary = {}):
	super._init(BC.CommandType.ATTACK, src, tgt, cmd_params)

# 执行命令
func execute() -> Dictionary:
	if not source or not is_instance_valid(source):
		return {
			"success": false,
			"message": "Invalid source"
		}

	if not target or not is_instance_valid(target):
		return {
			"success": false,
			"message": "Invalid target"
		}

	# 检查单位是否可以攻击
	if source.is_disarmed or source.current_state == source.ChessState.DEAD:
		return {
			"success": false,
			"message": "Unit cannot attack"
		}

	# 检查目标是否可以被攻击
	if target.current_state == target.ChessState.DEAD:
		return {
			"success": false,
			"message": "Target cannot be attacked"
		}

	# 检查攻击范围
	var distance = source.global_position.distance_to(target.global_position)
	if distance > source.attack_range * 64:  # 假设一个格子是64像素
		return {
			"success": false,
			"message": "Target out of range"
		}

	# 设置攻击目标
	source.set_target(target)

	# 切换到攻击状态
	source.state_machine.change_state("attacking")

	# 执行攻击
	var attack_result = source.perform_attack()

	return {
		"success": true,
		"message": "Attack performed",
		"attack_result": attack_result
	}

# 撤销命令
func undo() -> Dictionary:
	# 攻击命令无法撤销，因为已经造成了伤害
	return {
		"success": false,
		"message": "Attack cannot be undone"
	}
