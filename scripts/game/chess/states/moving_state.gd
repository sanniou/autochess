extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name MovingState
## 棋子移动状态
## 处理棋子在移动时的行为

# 初始化
func _init():
	state_name = "moving"
	state_description = "棋子正在移动向目标"

# 进入状态
func enter() -> void:
	super.enter()

	# 播放移动动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("move")

	# 设置移动目标
	_update_move_target()

# 退出状态
func exit() -> void:
	super.exit()

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 更新移动目标
	_update_move_target()

	# 移动向目标
	if owner and owner.has_method("move_towards_target") and owner.has_method("get_target"):
		var target = owner.get_target()
		if target:
			owner.move_towards_target(target, delta)

# 更新移动目标
func _update_move_target() -> void:
	if not owner or not owner.has_method("get_target") or not owner.has_method("has_target"):
		return

	# 如果没有目标，尝试寻找目标
	if not owner.has_target() and owner.has_method("find_target"):
		owner.find_target()
