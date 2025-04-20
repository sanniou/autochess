extends "res://scripts/managers/core/base_manager.gd"
class_name AnimationManager
## 动画管理器
## 负责管理游戏中的所有动画效果，包括棋子动画、战斗动画和UI动画

# 信号
signal animation_started(animation_id: String)
signal animation_completed(animation_id: String)
signal animation_cancelled(animation_id: String)

# 动画类型
enum AnimationType {
	CHESS,    # 棋子动画
	BATTLE,   # 战斗动画
	UI,       # UI动画
	EFFECT    # 特效动画
}

# 动画状态
enum AnimationState {
	IDLE,     # 空闲状态
	PLAYING,  # 播放中
	PAUSED,   # 暂停
	COMPLETED # 已完成
}

# 当前活动的动画
var active_animations = {}

# 动画队列
var animation_queues = {
	AnimationType.CHESS: [],
	AnimationType.BATTLE: [],
	AnimationType.UI: [],
	AnimationType.EFFECT: []
}

# 是否正在播放动画
var is_playing = {
	AnimationType.CHESS: false,
	AnimationType.BATTLE: false,
	AnimationType.UI: false,
	AnimationType.EFFECT: false
}

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "AnimationManager"

	# 原 _ready 函数的内容
	# 连接信号
		EventBus.game.connect_event("game_paused", _on_game_paused)

		# 初始化动画控制器
		_initialize_animators()

		# 添加到处理列表
		set_process(true)

	# 处理函数，用于更新动画队列和状态
func _process(delta: float) -> void:
	# 处理各类型的动画队列
	for type in animation_queues.keys():
		if not is_playing[type] and not animation_queues[type].is_empty():
			_process_queue(type)

# 初始化动画控制器
func _initialize_animators() -> void:
	# 创建棋子动画控制器字典
	var chess_animators = {}

	# 创建战斗动画控制器
	var battle_animator = BattleAnimator.new(self)
	battle_animator.name = "BattleAnimator"

	# 创建UI动画控制器
	var ui_animator = UIAnimator.new(self)
	ui_animator.name = "UIAnimator"

	# 创建特效动画控制器
	var effect_animator = EffectAnimator.new(get_tree().get_root())
	effect_animator.name = "EffectAnimator"

	# 添加为子节点以便生命周期管理
	add_child(battle_animator)
	add_child(ui_animator)
	add_child(effect_animator)

# 获取棋子动画控制器
func _get_chess_animator(chess_piece) -> ChessAnimator:
	# 检查棋子是否有效
	if not chess_piece or not is_instance_valid(chess_piece):
		return null

	# 检查棋子是否已经有动画控制器
	if chess_piece.has_node("ChessAnimator"):
		return chess_piece.get_node("ChessAnimator")

	# 创建新的棋子动画控制器
	var animator = ChessAnimator.new(chess_piece)
	animator.name = "ChessAnimator"
	chess_piece.add_child(animator)

	return animator

# 播放棋子动画
func play_chess_animation(chess_piece, animation_name: String, speed: float = 1.0, loop: bool = false) -> String:
	# 检查参数有效性
	if not chess_piece or animation_name.is_empty():
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.CHESS, animation_name)

	# 检查是否已经有相同的动画在播放
	if active_animations.has(animation_id):
		return animation_id

	# 获取或创建棋子动画控制器
	var animator = _get_chess_animator(chess_piece)
	if not animator:
		return ""

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"chess_piece": chess_piece,
		"animator": animator,
		"animation_name": animation_name,
		"speed": speed,
		"loop": loop,
		"state": AnimationState.IDLE
	}

	# 添加到队列
	return _add_to_queue(AnimationType.CHESS, animation_data)

# 播放战斗动画
func play_battle_animation(source, target, animation_name: String, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not source or animation_name.is_empty():
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.BATTLE, animation_name)

	# 检查是否已经有相同的动画在播放
	if active_animations.has(animation_id):
		return animation_id

	# 获取战斗动画控制器
	var battle_animator = get_node_or_null("BattleAnimator")
	if not battle_animator:
		return ""

	# 合并默认参数
	var default_params = {
		"speed": 1.0,
		"loop": false,
		"delay": 0.0
	}
	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"source": source,
		"target": target,
		"animator": battle_animator,
		"animation_name": animation_name,
		"params": params,
		"state": AnimationState.IDLE
	}

	# 添加到队列
	return _add_to_queue(AnimationType.BATTLE, animation_data)

# 播放UI动画
func play_ui_animation(ui_element, animation_name: String, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not ui_element or animation_name.is_empty():
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.UI, animation_name)

	# 检查是否已经有相同的动画在播放
	if active_animations.has(animation_id):
		return animation_id

	# 获取UI动画控制器
	var ui_animator = get_node_or_null("UIAnimator")
	if not ui_animator:
		return ""

	# 合并默认参数
	var default_params = {
		"duration": 0.5,
		"delay": 0.0,
		"ease": Tween.EASE_IN_OUT,
		"trans": Tween.TRANS_LINEAR
	}
	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"ui_element": ui_element,
		"animator": ui_animator,
		"animation_name": animation_name,
		"params": params,
		"state": AnimationState.IDLE
	}

	# 添加到队列
	return _add_to_queue(AnimationType.UI, animation_data)

# 播放特效动画
func play_effect_animation(position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if effect_name.is_empty():
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.EFFECT, effect_name)

	# 获取特效动画控制器
	var effect_animator = get_node_or_null("EffectAnimator")
	if not effect_animator:
		return ""

	# 合并默认参数
	var default_params = {
		"duration": 1.0,
		"scale": Vector2(1, 1),
		"rotation": 0.0,
		"color": Color.WHITE,
		"delay": 0.0,
		"auto_remove": true
	}
	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"position": position,
		"animator": effect_animator,
		"effect_name": effect_name,
		"params": params,
		"state": AnimationState.IDLE
	}

	# 添加到队列
	return _add_to_queue(AnimationType.EFFECT, animation_data)

# 取消动画
func cancel_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的取消方法
	var result = false
	if animator is ChessAnimator:
		result = animator.stop_animation()
	elif animator is BattleAnimator:
		result = animator.cancel_animation(animation_id)
	elif animator is UIAnimator:
		result = animator.cancel_animation(animation_id)
	elif animator is EffectAnimator:
		result = animator.cancel_animation(animation_id)

	if result:
		# 更新动画状态
		animation_data.state = AnimationState.COMPLETED

		# 从活动动画列表中移除
		active_animations.erase(animation_id)

		# 发送取消信号
		animation_cancelled.emit(animation_id)

	return result

# 暂停动画
func pause_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的暂停方法
	var result = false
	if animator is ChessAnimator:
		result = animator.pause_animation()
	elif animator is BattleAnimator:
		result = animator.pause_animation(animation_id)
	elif animator is UIAnimator:
		result = animator.pause_animation(animation_id)
	elif animator is EffectAnimator:
		result = animator.pause_animation(animation_id)

	if result:
		# 更新动画状态
		animation_data.state = AnimationState.PAUSED

	return result

# 恢复动画
func resume_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 检查动画是否处于暂停状态
	if animation_data.state != AnimationState.PAUSED:
		return false

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的恢复方法
	var result = false
	if animator is ChessAnimator:
		result = animator.resume_animation()
	elif animator is BattleAnimator:
		result = animator.resume_animation(animation_id)
	elif animator is UIAnimator:
		result = animator.resume_animation(animation_id)
	elif animator is EffectAnimator:
		result = animator.resume_animation(animation_id)

	if result:
		# 更新动画状态
		animation_data.state = AnimationState.PLAYING

	return result

# 设置动画速度
func set_animation_speed(animation_id: String, speed: float) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 检查速度是否有效
	if speed <= 0:
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的设置速度方法
	var result = false
	if animator is ChessAnimator:
		result = animator.set_animation_speed(speed)
		if result:
			animation_data.speed = speed
	elif animator is BattleAnimator:
		result = animator.set_animation_speed(animation_id, speed)
	elif animator is UIAnimator:
		result = animator.set_animation_speed(animation_id, speed)
	elif animator is EffectAnimator:
		result = animator.set_animation_speed(animation_id, speed)

	return result

# 获取动画状态
func get_animation_state(animation_id: String) -> int:
	# 检查动画ID是否有效
	if animation_id.is_empty():
		return AnimationState.IDLE

	# 检查动画是否存在
	if not active_animations.has(animation_id):
		return AnimationState.IDLE

	# 返回动画状态
	return active_animations[animation_id].state

# 是否有活动的动画
func has_active_animations(type: int = -1) -> bool:
	# 如果指定了类型，检查该类型的动画是否有活动的
	if type >= 0 and type < AnimationType.size():
		return is_playing[type] or not animation_queues[type].is_empty()

	# 如果没有指定类型，检查所有类型
	for t in AnimationType.values():
		if is_playing[t] or not animation_queues[t].is_empty():
			return true

	return not active_animations.is_empty()

# 清除所有动画
func clear_animations(type: int = -1) -> void:
	# 如果指定了类型，只清除该类型的动画
	if type >= 0 and type < AnimationType.size():
		# 清除队列
		animation_queues[type].clear()

		# 清除活动动画
		var to_remove = []
		for id in active_animations.keys():
			if id.begins_with(str(type) + "_"):
				# 取消动画
				cancel_animation(id)
				to_remove.append(id)

		# 移除动画
		for id in to_remove:
			active_animations.erase(id)

		# 重置播放状态
		is_playing[type] = false
		return

	# 如果没有指定类型，清除所有动画
	for t in AnimationType.values():
		# 清除队列
		animation_queues[t].clear()
		# 重置播放状态
		is_playing[t] = false

	# 取消所有活动动画
	for id in active_animations.keys():
		cancel_animation(id)

	# 清除活动动画列表
	active_animations.clear()

# 创建动画ID
func _create_animation_id(type: int, name: String) -> String:
	# 生成唯一的动画ID，格式：类型_名称_时间戳
	var timestamp = Time.get_unix_time_from_system()
	var unique_id = "%d_%s_%d" % [type, name, timestamp]
	return unique_id

# 添加动画到队列
func _add_to_queue(type: int, animation_data: Dictionary) -> String:
	# 检查类型是否有效
	if type < 0 or type >= AnimationType.size():
		return ""

	# 检查动画数据是否有效
	if not animation_data.has("id") or animation_data.id.is_empty():
		return ""

	# 添加到队列
	animation_queues[type].append(animation_data)

	# 如果当前没有正在播放的动画，则开始处理队列
	if not is_playing[type]:
		_process_queue(type)

	return animation_data.id

# 处理动画队列
func _process_queue(type: int) -> void:
	# 检查类型是否有效
	if type < 0 or type >= AnimationType.size():
		return

	# 检查队列是否为空
	if animation_queues[type].is_empty():
		is_playing[type] = false
		return

	# 获取下一个要播放的动画
	var animation_data = animation_queues[type].pop_front()

	# 标记为正在播放
	is_playing[type] = true

	# 添加到活动动画列表
	active_animations[animation_data.id] = animation_data

	# 更新动画状态
	animation_data.state = AnimationState.PLAYING

	# 发送动画开始信号
	animation_started.emit(animation_data.id)

	# 根据动画类型调用相应的播放方法
	var animator = animation_data.animator
	var result = false

	if type == AnimationType.CHESS:
		# 播放棋子动画
		result = animator.play_animation(
			animation_data.animation_name,
			animation_data.speed,
			animation_data.loop
		)
	elif type == AnimationType.BATTLE:
		# 播放战斗动画
		result = animator.play_animation(
			animation_data.source,
			animation_data.target,
			animation_data.animation_name,
			animation_data.params
		)
	elif type == AnimationType.UI:
		# 播放UI动画
		result = animator.play_animation(
			animation_data.ui_element,
			animation_data.animation_name,
			animation_data.params
		)
	elif type == AnimationType.EFFECT:
		# 播放特效动画
		result = animator.play_animation(
			animation_data.position,
			animation_data.effect_name,
			animation_data.params
		)

	# 如果播放失败，则处理下一个动画
	if not result:
		# 从活动动画列表中移除
		active_animations.erase(animation_data.id)

		# 发送动画完成信号
		animation_completed.emit(animation_data.id)

		# 继续处理队列
		_process_queue(type)
	else:
		# 连接动画完成信号
		if animator is ChessAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is BattleAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is UIAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is EffectAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))

# 动画完成处理
func _on_animation_completed(animation_id: String) -> void:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画类型
	var type = -1
	for t in AnimationType.values():
		if animation_id.begins_with(str(t) + "_"):
			type = t
			break

	# 断开信号连接
	var animator = animation_data.animator
	if animator:
		if animator is ChessAnimator:
			if animator.animation_completed.is_connected(_on_animation_completed):
				animator.animation_completed.disconnect(_on_animation_completed)
		elif animator is BattleAnimator:
			if animator.animation_completed.is_connected(_on_animation_completed):
				animator.animation_completed.disconnect(_on_animation_completed)
		elif animator is UIAnimator:
			if animator.animation_completed.is_connected(_on_animation_completed):
				animator.animation_completed.disconnect(_on_animation_completed)
		elif animator is EffectAnimator:
			if animator.animation_completed.is_connected(_on_animation_completed):
				animator.animation_completed.disconnect(_on_animation_completed)

	# 更新动画状态
	animation_data.state = AnimationState.COMPLETED

	# 从活动动画列表中移除
	active_animations.erase(animation_id)

	# 发送动画完成信号
	animation_completed.emit(animation_id)

	# 如果类型有效，处理下一个动画
	if type >= 0 and type < AnimationType.size():
		# 重置播放状态
		is_playing[type] = false

		# 如果队列不为空，处理下一个动画
		if not animation_queues[type].is_empty():
			_process_queue(type)

# 游戏暂停处理
func _on_game_paused(paused: bool) -> void:
	# 如果游戏暂停，暂停所有活动的动画
	if paused:
		# 暂停所有活动的动画
		for animation_id in active_animations.keys():
			pause_animation(animation_id)
	else:
		# 恢复所有暂停的动画
		for animation_id in active_animations.keys():
			var animation_data = active_animations[animation_id]
			if animation_data.state == AnimationState.PAUSED:
				resume_animation(animation_id)

	# 更新处理状态
	set_process(!paused)

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写重置方法
func _do_reset() -> void:
	# 清除所有动画
	clear_animations()

	# 重置动画队列
	for type in animation_queues.keys():
		animation_queues[type].clear()
		is_playing[type] = false

	_log_info("动画管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.game.disconnect_event("game_paused", _on_game_paused)

	# 清除所有动画
	clear_animations()

	# 清空数据
	active_animations.clear()
	for type in animation_queues.keys():
		animation_queues[type].clear()
		is_playing[type] = false

	_log_info("动画管理器清理完成")