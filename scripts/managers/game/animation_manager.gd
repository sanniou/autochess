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

# 动画配置管理器
var animation_config_manager = null

# 动画LOD系统
var animation_lod_system = null

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

	# 初始化动画配置管理器
	_initialize_config_manager()

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

# 初始化动画配置管理器
func _initialize_config_manager() -> void:
	# 创建动画配置管理器
	animation_config_manager = AnimationConfigManager.new()
	add_child(animation_config_manager)

	# 连接配置加载信号
	animation_config_manager.config_loaded.connect(_on_config_loaded)
	animation_config_manager.config_error.connect(_on_config_error)

	# 创建动画LOD系统
	animation_lod_system = AnimationLODSystem.new()
	add_child(animation_lod_system)

	# 连接LOD系统信号
	animation_lod_system.lod_changed.connect(_on_lod_changed)

# 配置加载回调
func _on_config_loaded(config_type: String) -> void:
	_log_info("动画配置已加载: " + config_type)

# 配置错误回调
func _on_config_error(error_message: String) -> void:
	_log_error("加载动画配置错误: " + error_message)

# LOD级别变化回调
func _on_lod_changed(object, old_level: int, new_level: int) -> void:
	# 记录日志
	_log_info("对象LOD级别变化: " + str(object) + ", " + str(old_level) + " -> " + str(new_level))

var battle_animator = null
var ui_animator = null
# 不再使用旧的效果动画器

# 初始化动画控制器
func _initialize_animators() -> void:
	# 创建战斗动画控制器
	battle_animator = BattleAnimator.new()
	battle_animator.name = "BattleAnimator"

	# 创建UI动画控制器
	ui_animator = UIAnimator.new()
	ui_animator.name = "UIAnimator"

	# 不再创建旧的视觉效果动画控制器
	# 现在使用新的 VisualManager 和 GameEffectManager

	# 添加为子节点以便生命周期管理
	add_child(battle_animator)
	add_child(ui_animator)

	# 连接信号
	ui_animator.animation_started.connect(_on_ui_animation_started)
	ui_animator.animation_completed.connect(_on_ui_animation_completed)
	ui_animator.animation_cancelled.connect(_on_ui_animation_cancelled)

	# 不再连接旧的效果动画器信号

# 获取棋子视图组件
func _get_chess_view_component(chess_piece) -> ViewComponent:
	# 检查棋子是否有效
	if not chess_piece or not is_instance_valid(chess_piece):
		return null

	# 获取视图组件
	var view_component = null

	# 使用组件系统获取ViewComponent
	if chess_piece.has_method("get_component"):
		view_component = chess_piece.get_component("ViewComponent")

	if not view_component:
		_log_warning("无法获取棋子的视图组件: " + str(chess_piece))

	return view_component

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

	# 获取棋子视图组件
	var view_component = _get_chess_view_component(chess_piece)
	if not view_component:
		return ""

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"chess_piece": chess_piece,
		"animator": view_component,
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

	# 获取UI动画控制器
	if not ui_animator:
		return ""

	# 直接使用UI动画控制器的play_animation方法
	return ui_animator.play_animation(ui_element, animation_name, params)

# 播放特效动画
func play_effect_animation(position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if effect_name.is_empty():
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.EFFECT, effect_name)

	# 获取特效动画控制器
	var effect_animator = get_effect_animator()
	if not effect_animator:
		_log_error("无法获取视觉效果动画器")
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
	if animation_id.is_empty():
		return false

	# 如果是UI动画，则使用UI动画控制器的cancel_animation方法
	if animation_id.begins_with("ui_"):
		if ui_animator:
			return ui_animator.cancel_animation(animation_id)
		return false

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的取消方法
	var result = false
	if animator is ViewComponent:
		# ViewComponent没有stop_animation方法，但可以通过播放idle动画来停止当前动画
		animator.play_animation("idle")
		result = true
	elif animator is BattleAnimator:
		result = animator.cancel_animation(animation_id)
	elif animator is VisualEffectAnimator:
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
	if animation_id.is_empty():
		return false

	# 如果是UI动画，则使用UI动画控制器的pause_animation方法
	if animation_id.begins_with("ui_"):
		if ui_animator:
			return ui_animator.pause_animation(animation_id)
		return false

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的暂停方法
	var result = false
	if animator is ViewComponent:
		# ViewComponent没有pause_animation方法，但可以通过设置动画速度为0来暂停
		animator.set_animation_speed(0)
		result = true
	elif animator is BattleAnimator:
		result = animator.pause_animation(animation_id)
	elif animator is VisualEffectAnimator:
		result = animator.pause_animation(animation_id)

	if result:
		# 更新动画状态
		animation_data.state = AnimationState.PAUSED

	return result

# 恢复动画
func resume_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty():
		return false

	# 如果是UI动画，则使用UI动画控制器的resume_animation方法
	if animation_id.begins_with("ui_"):
		if ui_animator:
			return ui_animator.resume_animation(animation_id)
		return false

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
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
	if animator is ViewComponent:
		# ViewComponent没有resume_animation方法，但可以通过恢复动画速度来继续播放
		animator.set_animation_speed(animation_data.speed)
		result = true
	elif animator is BattleAnimator:
		result = animator.resume_animation(animation_id)
	elif animator is VisualEffectAnimator:
		result = animator.resume_animation(animation_id)

	if result:
		# 更新动画状态
		animation_data.state = AnimationState.PLAYING

	return result

# 设置动画速度
func set_animation_speed(animation_id: String, speed: float) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty():
		return false

	# 检查速度是否有效
	if speed <= 0:
		return false

	# 如果是UI动画，则使用UI动画控制器的set_animation_speed方法
	if animation_id.begins_with("ui_"):
		if ui_animator:
			return ui_animator.set_animation_speed(animation_id, speed)
		return false

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 获取动画控制器
	var animator = animation_data.animator
	if not animator:
		return false

	# 根据动画类型调用相应的设置速度方法
	var result = false
	if animator is ViewComponent:
		animator.set_animation_speed(speed)
		animation_data.speed = speed
		result = true
	elif animator is BattleAnimator:
		result = animator.set_animation_speed(animation_id, speed)
	elif animator is VisualEffectAnimator:
		result = animator.set_animation_speed(animation_id, speed)

	return result

# 获取动画状态
func get_animation_state(animation_id: String) -> int:
	# 检查动画ID是否有效
	if animation_id.is_empty():
		return AnimationState.IDLE

	# 如果是UI动画，则使用UI动画控制器的get_animation_state方法
	if animation_id.begins_with("ui_"):
		if ui_animator:
			return ui_animator.get_animation_state(animation_id)
		return AnimationState.IDLE

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
		return AnimationState.IDLE

	# 返回动画状态
	return active_animations[animation_id].state

# 是否有活动的动画
func has_active_animations(type: int = -1) -> bool:
	# 如果指定了类型，检查该类型的动画是否有活动的
	if type >= 0 and type < AnimationType.size():
		# 如果是UI动画，还需要检查UI动画控制器
		if type == AnimationType.UI:
			if ui_animator and ui_animator.has_active_animations():
				return true
		return is_playing[type] or not animation_queues[type].is_empty()

	# 如果没有指定类型，检查所有类型
	for t in AnimationType.values():
		if is_playing[t] or not animation_queues[t].is_empty():
			return true

	# 检查UI动画控制器
	if ui_animator and ui_animator.has_active_animations():
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

		# 如果是UI动画，调用UI动画控制器的clear_animations方法
		if type == AnimationType.UI:
			ui_animator.clear_animations()
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

	# 清除UI动画控制器的动画
	ui_animator.clear_animations()

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
		if animator is ViewComponent:
			# 设置动画速度
			animator.set_animation_speed(animation_data.speed)
			# 播放动画
			animator.play_animation(animation_data.animation_name)
			result = true
	elif type == AnimationType.BATTLE:
		# 播放战斗动画
		result = animator.play_animation(
			animation_data.source,
			animation_data.target,
			animation_data.animation_name,
			animation_data.params
		)
	elif type == AnimationType.UI:
		# 直接使用UI动画控制器的play_animation方法
		var animation_id = ui_animator.play_animation(
			animation_data.ui_element,
			animation_data.animation_name,
			animation_data.params
		)
		result = animation_id != ""
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
		if animator is ViewComponent:
			animator.animation_finished.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is BattleAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is UIAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))
		elif animator is VisualEffectAnimator:
			animator.animation_completed.connect(_on_animation_completed.bind(animation_data.id))

# 动画完成处理
func _on_animation_completed(animation_id: String) -> void:
	# 检查动画ID是否有效
	if animation_id.is_empty():
		return

	# 如果是UI动画，则不需要处理，因为已经在_on_ui_animation_completed中处理了
	if animation_id.begins_with("ui_"):
		return

	# 如果不是UI动画，检查是否在活动动画列表中
	if not active_animations.has(animation_id):
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
		if animator is ViewComponent:
			if animator.animation_finished.is_connected(_on_animation_completed):
				animator.animation_finished.disconnect(_on_animation_completed)
		elif animator is BattleAnimator:
			if animator.animation_completed.is_connected(_on_animation_completed):
				animator.animation_completed.disconnect(_on_animation_completed)
		elif animator is VisualEffectAnimator:
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

		# 暂停UI动画
		if ui_animator and ui_animator.has_active_animations():
			# 暂停所有UI动画
			# 注意：这里我们无法获取所有UI动画ID，所以无法暂停它们
			# 这是一个限制，但对于大多数情况来说应该不是问题
			pass
	else:
		# 恢复所有暂停的动画
		for animation_id in active_animations.keys():
			var animation_data = active_animations[animation_id]
			if animation_data.state == AnimationState.PAUSED:
				resume_animation(animation_id)

		# 恢复UI动画
		if ui_animator and ui_animator.has_active_animations():
			# 恢复所有UI动画
			# 注意：这里我们无法获取所有UI动画ID，所以无法恢复它们
			# 这是一个限制，但对于大多数情况来说应该不是问题
			pass

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

# UI动画开始信号处理
func _on_ui_animation_started(animation_id: String) -> void:
	# 发送动画开始信号
	animation_started.emit(animation_id)

# UI动画完成信号处理
func _on_ui_animation_completed(animation_id: String) -> void:
	# 发送动画完成信号
	animation_completed.emit(animation_id)

# UI动画取消信号处理
func _on_ui_animation_cancelled(animation_id: String) -> void:
	# 发送动画取消信号
	animation_cancelled.emit(animation_id)

# 获取视觉效果管理器
func get_visual_manager():
	# 返回新的视觉效果管理器
	if GameManager and GameManager.visual_manager:
		return GameManager.visual_manager

	_log_warning("无法获取VisualManager")
	return null

# 获取动画配置管理器
func get_animation_config_manager() -> AnimationConfigManager:
	return animation_config_manager

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
