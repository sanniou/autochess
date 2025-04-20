extends "res://scripts/game/chess/states/base_chess_state.gd"
class_name IdleState
## 棋子空闲状态
## 处理棋子在空闲时的行为

# 初始化
func _init():
	state_name = "idle"
	state_description = "棋子处于空闲状态，会自动回复法力值并寻找目标"

# 进入状态
func enter() -> void:
	super.enter()

	# 重置攻击计时器
	set_state_data("attack_timer", 0.0)

	# 播放空闲动画
	if owner and owner.has_method("play_animation"):
		owner.play_animation("idle")

# 退出状态
func exit() -> void:
	super.exit()

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 自动回蓝
	if owner and owner.has_method("gain_mana"):
		owner.gain_mana(delta * 5.0, "passive")  # 每秒回复5点法力值

	# 更新攻击计时器
	var attack_timer = get_state_data_item("attack_timer", 0.0)
	attack_timer += delta
	set_state_data("attack_timer", attack_timer)

	# 检查是否可以攻击
	if owner and owner.has_method("get_attribute") and owner.has_method("has_target"):
		if owner.has_target():
			var attack_speed = owner.get_attribute("attack_speed")
			if attack_speed <= 0:
				attack_speed = 0.1  # 防止除以零

			if attack_timer >= 1.0 / attack_speed:
				set_state_data("attack_timer", 0.0)
				_perform_attack()

# 执行攻击
func _perform_attack() -> void:
	if owner and owner.has_method("perform_attack"):
		owner.perform_attack()
