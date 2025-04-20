extends BattleCommand
class_name AbilityCommand
## 技能命令
## 用于控制单位使用技能

# 初始化
func _init(src, tgt, cmd_params: Dictionary = {}):
	super._init(BC.CommandType.ABILITY, src, tgt, cmd_params)

# 执行命令
func execute() -> Dictionary:
	if not source or not is_instance_valid(source):
		return {
			"success": false,
			"message": "Invalid source"
		}

	# 检查单位是否可以使用技能
	if source.is_silenced or source.current_state == source.ChessState.DEAD:
		return {
			"success": false,
			"message": "Unit cannot use ability"
		}

	# 检查法力值是否足够
	if source.current_mana < source.ability_cost:
		return {
			"success": false,
			"message": "Not enough mana"
		}

	# 获取技能ID
	var ability_id = params.get("ability_id", "")
	if ability_id.is_empty() and source.ability:
		ability_id = source.ability.id

	# 获取技能目标
	var ability_targets = params.get("targets", [])
	if ability_targets.is_empty() and target:
		ability_targets = [target]

	# 切换到施法状态
	source.state_machine.change_state("casting")

	# 使用技能
	var ability_result = source.use_ability(ability_id, ability_targets)

	return {
		"success": ability_result.success,
		"message": ability_result.message,
		"ability_id": ability_id,
		"targets": ability_targets,
		"ability_result": ability_result
	}

# 撤销命令
func undo() -> Dictionary:
	# 技能命令无法撤销，因为已经产生了效果
	return {
		"success": false,
		"message": "Ability cannot be undone"
	}
