extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name AttackingState
## 棋子攻击状态
## 处理棋子在攻击时的行为

# 初始化
func _init():
	state_name = "attacking"
	state_description = "棋子正在攻击目标"

# 进入状态
func enter() -> void:
	super.enter()

	# 重置攻击计时器
	set_state_data("attack_timer", 0.0)
	set_state_data("attack_executed", false)

	# 播放攻击动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("attack")

# 退出状态
func exit() -> void:
	super.exit()

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 更新攻击计时器
	var attack_timer = get_state_data_item("attack_timer", 0.0)
	attack_timer += delta
	set_state_data("attack_timer", attack_timer)

	# 检查是否已执行攻击
	var attack_executed = get_state_data_item("attack_executed", false)

	# 在攻击动画中间点执行攻击
	if not attack_executed and attack_timer >= 0.5:  # 假设攻击动画持续1秒，中间点在0.5秒
		set_state_data("attack_executed", true)
		_perform_attack()

	# 攻击动画结束后返回空闲状态
	if attack_timer >= 1.0:  # 假设攻击动画持续1秒
		# 状态转换会在状态机中处理
		pass

# 执行攻击
func _perform_attack() -> void:
	if owner and owner.has_method("perform_attack"):
		owner.perform_attack()
