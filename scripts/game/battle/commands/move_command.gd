extends BattleCommand
class_name MoveCommand
## 移动命令
## 用于控制单位移动

# 初始化
func _init(src, tgt, cmd_params: Dictionary = {}):
	super._init(BC.CommandType.MOVE, src, tgt, cmd_params)

# 执行命令
func execute() -> Dictionary:
	if not source or not is_instance_valid(source):
		return {
			"success": false,
			"message": "Invalid source"
		}

	# 检查单位是否可以移动
	if source.is_frozen or source.current_state == source.ChessState.DEAD:
		return {
			"success": false,
			"message": "Unit cannot move"
		}

	# 获取目标位置
	var target_position = params.get("position", Vector2.ZERO)
	if target and is_instance_valid(target):
		target_position = target.global_position

	# 记录起始位置
	var start_position = source.global_position

	# 设置移动目标
	source.set_move_target(target_position)

	# 切换到移动状态
	source.state_machine.change_state("moving")

	return {
		"success": true,
		"message": "Moving to target",
		"start_position": start_position,
		"target_position": target_position
	}

# 撤销命令
func undo() -> Dictionary:
	if not source or not is_instance_valid(source):
		return {
			"success": false,
			"message": "Invalid source"
		}

	# 获取原始位置
	var original_position = params.get("original_position", null)
	if not original_position:
		return {
			"success": false,
			"message": "Original position not available"
		}

	# 直接设置位置
	source.global_position = original_position

	# 清除移动目标
	source.clear_move_target()

	# 切换到空闲状态
	source.state_machine.change_state("idle")

	return {
		"success": true,
		"message": "Move undone"
	}
