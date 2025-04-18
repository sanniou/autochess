extends "res://scripts/game/chess/states/chess_state.gd"
class_name DeadState
## 棋子死亡状态
## 处理棋子在死亡时的行为

# 状态名称
func _init():
	state_name = "dead"

# 死亡动画持续时间
var death_animation_duration: float = 1.0
var death_timer: float = 0.0
var death_processed: bool = false

# 进入状态
func enter() -> void:
	# 重置死亡计时器
	death_timer = 0.0
	death_processed = false
	
	# 播放死亡动画
	owner.play_animation("death")
	
	# 清除目标
	owner.clear_target()
	
	# 处理死亡效果
	if not death_processed:
		death_processed = true
		owner.process_death()

# 退出状态
func exit() -> void:
	pass

# 物理更新
func physics_process(delta: float) -> void:
	# 更新死亡计时器
	death_timer += delta
	
	# 死亡动画结束后移除棋子
	if death_timer >= death_animation_duration:
		owner.queue_free_delayed()

# 检查状态转换
func check_transitions() -> String:
	# 如果被复活，切换到空闲状态
	if owner.is_resurrected():
		return "idle"
	
	return ""
