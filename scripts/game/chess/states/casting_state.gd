extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name CastingState
## 棋子施法状态
## 处理棋子在施法时的行为

# 初始化
func _init():
	state_name = "casting"
	state_description = "棋子正在施放技能"

# 进入状态
func enter() -> void:
	super.enter()

	# 设置施法数据
	set_state_data("ability_id", "")  # 将在开始施法时设置
	set_state_data("ability_executed", false)
	set_state_data("cast_time", 1.0)  # 默认施法时间

	# 播放施法动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("cast")

# 退出状态
func exit() -> void:
	super.exit()

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 获取施法数据
	var ability_executed = get_state_data_item("ability_executed", false)
	var cast_time = get_state_data_item("cast_time", 1.0)

	# 在施法完成时执行技能
	if not ability_executed and state_time >= cast_time:
		set_state_data("ability_executed", true)
		_perform_ability()

	# 施法动画结束后返回空闲状态
	if state_time >= cast_time + 0.5:  # 施法完成后等待0.5秒
		# 状态转换会在状态机中处理
		pass

# 开始施法
func start_casting(ability_id: String, cast_time: float = 1.0) -> void:
	set_state_data("ability_id", ability_id)
	set_state_data("cast_time", cast_time)
	set_state_data("ability_executed", false)

# 执行技能
func _perform_ability() -> void:
	if not owner or not owner.has_method("cast_ability"):
		return

	var ability_id = get_state_data_item("ability_id", "")
	if ability_id.is_empty():
		return

	owner.cast_ability(ability_id)
