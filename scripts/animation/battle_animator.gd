extends Node
class_name BattleAnimator
## 战斗动画控制器
## 负责控制战斗中的动画效果，如攻击、技能、受伤等

# 信号
signal animation_started(animation_name: String)
signal animation_completed(animation_name: String)
signal animation_cancelled(animation_name: String)

# 动画类型
enum AnimationType {
	ATTACK,    # 攻击动画
	ABILITY,   # 技能动画
	DAMAGE,    # 受伤动画
	DEATH,     # 死亡动画
	MOVEMENT,  # 移动动画
	EFFECT     # 特效动画
}

# 动画状态
enum AnimationState {
	IDLE,     # 空闲状态
	PLAYING,  # 播放中
	PAUSED,   # 暂停
	COMPLETED # 已完成
}

# 战斗管理器引用
var battle_manager = null

# 当前动画
var current_animation = ""

# 动画状态
var animation_state = AnimationState.IDLE

# 动画队列
var animation_queue = []

# 是否正在播放
var is_playing = false

# 初始化
func _init(manager) -> void:
	battle_manager = manager

# 播放攻击动画
func play_attack_animation(attacker, target, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.ATTACK, "attack")

	# 合并默认参数
	var default_params = {
		"duration": 0.5,
		"attack_type": "melee",  # melee, ranged, magic
		"effect_name": "",
		"sound_name": "",
		"move_to_target": true,
		"move_speed": 300.0,
		"return_to_position": true,
		"return_speed": 200.0,
		"scale_during_attack": true,
		"attack_scale": Vector2(1.2, 1.2),
		"show_damage_number": true
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 保存原始位置
	var original_position = attacker.global_position

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"type": AnimationType.ATTACK,
		"attacker": attacker,
		"target": target,
		"original_position": original_position,
		"params": params,
		"state": AnimationState.PLAYING,
		"start_time": Time.get_ticks_msec(),
		"duration": params.duration,
		"effects": []
	}

	# 添加到动画队列
	var result = _add_to_queue(animation_data)

	# 如果添加失败，返回空字符串
	if not result:
		return ""

	# 根据攻击类型创建不同的动画
	match params.attack_type:
		"melee":
			_create_melee_attack_animation(animation_data)
		"ranged":
			_create_ranged_attack_animation(animation_data)
		"magic":
			_create_magic_attack_animation(animation_data)
		_:
			_create_melee_attack_animation(animation_data)

	# 播放攻击音效
	if params.sound_name != "":
		AudioManager.play_sfx(params.sound_name)

	# 发送动画开始信号
	animation_started.emit(animation_id)

	return animation_id

# 创建近战攻击动画
func _create_melee_attack_animation(animation_data: Dictionary) -> void:
	var attacker = animation_data.attacker
	var target = animation_data.target
	var params = animation_data.params
	var original_position = animation_data.original_position

	# 创建动画序列
	var tween = create_tween().set_parallel()

	# 如果需要移动到目标
	if params.move_to_target:
		# 计算移动方向
		var direction = (target.global_position - attacker.global_position).normalized()

		# 计算移动距离，不要完全移动到目标位置
		var distance = attacker.global_position.distance_to(target.global_position) * 0.7

		# 计算目标位置
		var target_position = attacker.global_position + direction * distance

		# 移动到目标
		tween.tween_property(attacker, "global_position", target_position, params.duration * 0.4)

	# 如果需要缩放
	if params.scale_during_attack:
		# 保存原始缩放
		var original_scale = attacker.scale

		# 缩放动画
		tween.tween_property(attacker, "scale", params.attack_scale, params.duration * 0.3)
		tween.tween_property(attacker, "scale", original_scale, params.duration * 0.3).set_delay(params.duration * 0.4)

	# 如果需要返回原位置
	if params.return_to_position:
		tween.tween_property(attacker, "global_position", original_position, params.duration * 0.3).set_delay(params.duration * 0.7)

	# 添加攻击特效
	if params.effect_name != "":
		# 在攻击时间点播放特效
		tween.tween_callback(func():
			# 获取特效管理器
			var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
			if effect_animator:
				# 播放特效
				var effect_id = effect_animator.play_combined_effect(
					target.global_position,
					params.effect_name,
					{"duration": params.duration * 0.5}
				)

				# 添加到特效列表
				animation_data.effects.append(effect_id)
		).set_delay(params.duration * 0.4)

	# 如果需要显示伤害数字
	if params.show_damage_number:
		tween.tween_callback(func():
			# 获取伤害数字管理器
			var damage_number_manager = get_node_or_null("/root/GameManager/DamageNumberManager")
			if damage_number_manager:
				# 显示伤害数字
				damage_number_manager.show_damage(
					target.global_position,
					params.get("damage", 0),
					params.get("damage_type", "physical")
				)
		).set_delay(params.duration * 0.5)

	# 动画完成时回调
	tween.tween_callback(func():
		_on_animation_completed(animation_data.id)
	).set_delay(params.duration)

# 创建远程攻击动画
func _create_ranged_attack_animation(animation_data: Dictionary) -> void:
	var attacker = animation_data.attacker
	var target = animation_data.target
	var params = animation_data.params

	# 创建动画序列
	var tween = create_tween().set_parallel()

	# 如果需要缩放
	if params.scale_during_attack:
		# 保存原始缩放
		var original_scale = attacker.scale

		# 缩放动画
		tween.tween_property(attacker, "scale", params.attack_scale, params.duration * 0.2)
		tween.tween_property(attacker, "scale", original_scale, params.duration * 0.2).set_delay(params.duration * 0.2)

	# 创建投射物
	var projectile = Sprite2D.new()
	projectile.texture = load("res://assets/images/vfx/projectile.png")  # 默认投射物纹理
	projectile.global_position = attacker.global_position
	get_tree().root.add_child(projectile)

	# 投射物移动动画
	var projectile_tween = create_tween()
	projectile_tween.tween_property(projectile, "global_position", target.global_position, params.duration * 0.6)
	projectile_tween.tween_callback(func():
		# 移除投射物
		projectile.queue_free()

		# 添加攻击特效
		if params.effect_name != "":
			# 获取特效管理器
			var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
			if effect_animator:
				# 播放特效
				var effect_id = effect_animator.play_combined_effect(
					target.global_position,
					params.effect_name,
					{"duration": params.duration * 0.4}
				)

				# 添加到特效列表
				animation_data.effects.append(effect_id)

		# 如果需要显示伤害数字
		if params.show_damage_number:
			# 获取伤害数字管理器
			var damage_number_manager = get_node_or_null("/root/GameManager/DamageNumberManager")
			if damage_number_manager:
				# 显示伤害数字
				damage_number_manager.show_damage(
					target.global_position,
					params.get("damage", 0),
					params.get("damage_type", "physical")
				)
	)

	# 动画完成时回调
	tween.tween_callback(func():
		_on_animation_completed(animation_data.id)
	).set_delay(params.duration)

# 创建魔法攻击动画
func _create_magic_attack_animation(animation_data: Dictionary) -> void:
	var attacker = animation_data.attacker
	var target = animation_data.target
	var params = animation_data.params

	# 创建动画序列
	var tween = create_tween().set_parallel()

	# 如果需要缩放
	if params.scale_during_attack:
		# 保存原始缩放
		var original_scale = attacker.scale

		# 缩放动画
		tween.tween_property(attacker, "scale", params.attack_scale, params.duration * 0.3)
		tween.tween_property(attacker, "scale", original_scale, params.duration * 0.3).set_delay(params.duration * 0.3)

	# 创建施法特效
	var cast_effect = Sprite2D.new()
	cast_effect.texture = load("res://assets/images/vfx/magic_cast.png")  # 默认施法特效纹理
	cast_effect.global_position = attacker.global_position
	cast_effect.modulate = Color(1, 1, 1, 0)  # 初始透明
	get_tree().root.add_child(cast_effect)

	# 施法特效动画
	var cast_tween = create_tween()
	cast_tween.tween_property(cast_effect, "modulate", Color(1, 1, 1, 1), params.duration * 0.3)
	cast_tween.tween_property(cast_effect, "modulate", Color(1, 1, 1, 0), params.duration * 0.2)
	cast_tween.tween_callback(func():
		# 移除施法特效
		cast_effect.queue_free()

		# 添加攻击特效
		if params.effect_name != "":
			# 获取特效管理器
			var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
			if effect_animator:
				# 播放特效
				var effect_id = effect_animator.play_combined_effect(
					target.global_position,
					params.effect_name,
					{"duration": params.duration * 0.5}
				)

				# 添加到特效列表
				animation_data.effects.append(effect_id)

		# 如果需要显示伤害数字
		if params.show_damage_number:
			# 获取伤害数字管理器
			var damage_number_manager = get_node_or_null("/root/GameManager/DamageNumberManager")
			if damage_number_manager:
				# 显示伤害数字
				damage_number_manager.show_damage(
					target.global_position,
					params.get("damage", 0),
					params.get("damage_type", "physical")
				)
	)

	# 动画完成时回调
	tween.tween_callback(func():
		_on_animation_completed(animation_data.id)
	).set_delay(params.duration)

# 播放技能动画
func play_ability_animation(caster, targets: Array, ability_name: String, params: Dictionary = {}) -> String:
	# 将在后续实现
	return ""

# 播放受伤动画
func play_damage_animation(target, damage_amount: float, damage_type: String, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not is_instance_valid(target):
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.DAMAGE, "damage")

	# 合并默认参数
	var default_params = {
		"duration": 0.5,
		"effect_name": "",
		"sound_name": "",
		"flash": true,
		"flash_color": Color(1, 0, 0, 0.5),  # 默认闪烁颜色
		"shake": true,
		"shake_amount": 5.0,
		"show_damage_number": true,
		"critical": false
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 根据伤害类型调整参数
	match damage_type:
		"physical":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "physical_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "hit.ogg"
		"magical":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "magical_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "magic_hit.ogg"
			params.flash_color = Color(0.5, 0, 1, 0.5)  # 魔法伤害闪烁颜色
		"fire":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "fire_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "fire.ogg"
			params.flash_color = Color(1, 0.5, 0, 0.5)  # 火焰伤害闪烁颜色
		"ice":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "ice_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "ice.ogg"
			params.flash_color = Color(0, 0.8, 1, 0.5)  # 冰冻伤害闪烁颜色
		"lightning":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "lightning_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "lightning.ogg"
			params.flash_color = Color(1, 1, 0, 0.5)  # 闪电伤害闪烁颜色
		"poison":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "poison_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "poison.ogg"
			params.flash_color = Color(0, 1, 0, 0.5)  # 毒素伤害闪烁颜色
		"true":
			if not params.has("effect_name") or params.effect_name.is_empty():
				params.effect_name = "true_hit"
			if not params.has("sound_name") or params.sound_name.is_empty():
				params.sound_name = "true_damage.ogg"
			params.flash_color = Color(1, 1, 1, 0.5)  # 真实伤害闪烁颜色

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"type": AnimationType.DAMAGE,
		"target": target,
		"damage_amount": damage_amount,
		"damage_type": damage_type,
		"params": params,
		"state": AnimationState.PLAYING,
		"start_time": Time.get_ticks_msec(),
		"duration": params.duration,
		"effects": []
	}

	# 添加到动画队列
	var result = _add_to_queue(animation_data)

	# 如果添加失败，返回空字符串
	if not result:
		return ""

	# 创建动画序列
	var tween = create_tween().set_parallel()

	# 保存原始颜色
	var original_modulate = target.modulate

	# 保存原始位置
	var original_position = target.global_position

	# 如果需要闪烁
	if params.flash:
		# 闪烁动画
		tween.tween_property(target, "modulate", params.flash_color, params.duration * 0.2)
		tween.tween_property(target, "modulate", original_modulate, params.duration * 0.3).set_delay(params.duration * 0.2)

	# 如果需要抖动
	if params.shake:
		# 抖动动画
		for i in range(5):
			var offset = Vector2(
				randf_range(-params.shake_amount, params.shake_amount),
				randf_range(-params.shake_amount, params.shake_amount)
			)
			tween.tween_property(target, "global_position", original_position + offset, params.duration * 0.1)

		# 恢复原始位置
		tween.tween_property(target, "global_position", original_position, params.duration * 0.1).set_delay(params.duration * 0.5)

	# 添加受伤特效
	if params.effect_name != "":
		# 获取特效管理器
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			# 播放特效
			var effect_id = effect_animator.play_combined_effect(
				target.global_position,
				params.effect_name,
				{"duration": params.duration * 0.5}
			)

			# 添加到特效列表
			animation_data.effects.append(effect_id)

	# 如果需要显示伤害数字
	if params.show_damage_number:
		# 获取伤害数字管理器
		var damage_number_manager = get_node_or_null("/root/GameManager/DamageNumberManager")
		if damage_number_manager:
			# 显示伤害数字
			damage_number_manager.show_damage(
				target.global_position,
				damage_amount,
				damage_type,
				params.critical
			)

	# 播放受伤音效
	if params.sound_name != "":
		AudioManager.play_sfx(params.sound_name)

	# 动画完成时回调
	tween.tween_callback(func():
		_on_animation_completed(animation_data.id)
	).set_delay(params.duration)

	# 发送动画开始信号
	animation_started.emit(animation_id)

	return animation_id

# 播放死亡动画
func play_death_animation(target, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not is_instance_valid(target):
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.DEATH, "death")

	# 合并默认参数
	var default_params = {
		"duration": 1.0,
		"effect_name": "death_effect",
		"sound_name": "death.ogg",
		"fade_out": true,
		"scale_out": true,
		"rotate": true,
		"particles": true,
		"remove_after_animation": true
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"type": AnimationType.DEATH,
		"target": target,
		"params": params,
		"state": AnimationState.PLAYING,
		"start_time": Time.get_ticks_msec(),
		"duration": params.duration,
		"effects": []
	}

	# 添加到动画队列
	var result = _add_to_queue(animation_data)

	# 如果添加失败，返回空字符串
	if not result:
		return ""

	# 创建动画序列
	var tween = create_tween().set_parallel()

	# 如果需要淡出
	if params.fade_out:
		tween.tween_property(target, "modulate:a", 0.0, params.duration)

	# 如果需要缩放
	if params.scale_out:
		tween.tween_property(target, "scale", Vector2(0.1, 0.1), params.duration)

	# 如果需要旋转
	if params.rotate:
		tween.tween_property(target, "rotation", PI, params.duration)

	# 如果需要粒子效果
	if params.particles:
		# 获取特效管理器
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			# 播放粒子特效
			var effect_id = effect_animator.play_particle_effect(
				target.global_position,
				"death_particles",
				params.duration,
				{
					"amount": 30,
					"lifetime": params.duration * 0.8,
					"speed": 50.0,
					"color": Color(0.5, 0.5, 0.5, 0.8),
					"scale": Vector2(1.5, 1.5),
					"emission_shape": 1,  # 圆形
					"emission_radius": 20.0,
					"direction": Vector2(0, -1),
					"spread": 180.0,
					"gravity": Vector2(0, 20)
				}
			)

			# 添加到特效列表
			animation_data.effects.append(effect_id)

	# 添加死亡特效
	if params.effect_name != "":
		# 获取特效管理器
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			# 播放特效
			var effect_id = effect_animator.play_combined_effect(
				target.global_position,
				params.effect_name,
				{"duration": params.duration}
			)

			# 添加到特效列表
			animation_data.effects.append(effect_id)

	# 播放死亡音效
	if params.sound_name != "":
		AudioManager.play_sfx(params.sound_name)

	# 动画完成时回调
	tween.tween_callback(func():
		# 如果需要移除目标
		if params.remove_after_animation and is_instance_valid(target):
			target.queue_free()

		# 完成动画
		_on_animation_completed(animation_data.id)
	).set_delay(params.duration)

	# 发送动画开始信号
	animation_started.emit(animation_id)

	return animation_id

# 播放移动动画
func play_movement_animation(piece, start_pos: Vector2, end_pos: Vector2, params: Dictionary = {}) -> String:
	# 检查参数有效性
	if not is_instance_valid(piece):
		return ""

	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.MOVEMENT, "movement")

	# 合并默认参数
	var default_params = {
		"duration": 0.5,
		"effect_name": "",
		"sound_name": "move.ogg",
		"path_type": "linear",  # linear, arc, bezier
		"arc_height": 50.0,
		"control_point": Vector2.ZERO,
		"bounce": false,
		"bounce_height": 10.0,
		"trail": false,
		"trail_color": Color(0.5, 0.5, 0.5, 0.5),
		"face_direction": true
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"type": AnimationType.MOVEMENT,
		"piece": piece,
		"start_pos": start_pos,
		"end_pos": end_pos,
		"params": params,
		"state": AnimationState.PLAYING,
		"start_time": Time.get_ticks_msec(),
		"duration": params.duration,
		"effects": []
	}

	# 添加到动画队列
	var result = _add_to_queue(animation_data)

	# 如果添加失败，返回空字符串
	if not result:
		return ""

	# 创建动画序列
	var tween = create_tween()

	# 保存原始方向
	var original_scale = piece.scale

	# 如果需要面向移动方向
	if params.face_direction:
		# 计算移动方向
		var direction = end_pos - start_pos

		# 如果向右移动，保持原始方向
		# 如果向左移动，翻转方向
		if direction.x < 0:
			tween.tween_property(piece, "scale:x", -abs(original_scale.x), 0.1)
		else:
			tween.tween_property(piece, "scale:x", abs(original_scale.x), 0.1)

	# 根据路径类型创建不同的移动动画
	match params.path_type:
		"linear":
			# 线性移动
			tween.tween_property(piece, "global_position", end_pos, params.duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		"arc":
			# 创建弧形路径
			_create_arc_movement(tween, piece, start_pos, end_pos, params.arc_height, params.duration)
		"bezier":
			# 创建贝塞尔曲线路径
			_create_bezier_movement(tween, piece, start_pos, end_pos, params.control_point, params.duration)
		_:
			# 默认线性移动
			tween.tween_property(piece, "global_position", end_pos, params.duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 如果需要弹跳
	if params.bounce:
		# 到达目标位置后添加弹跳效果
		tween.tween_callback(func():
			# 创建弹跳动画
			var bounce_tween = create_tween()
			bounce_tween.tween_property(piece, "global_position:y", end_pos.y - params.bounce_height, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			bounce_tween.tween_property(piece, "global_position:y", end_pos.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		)

	# 如果需要拖尾效果
	if params.trail:
		# 获取特效管理器
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			# 创建拖尾特效
			var trail = Line2D.new()
			trail.width = 5.0
			trail.default_color = params.trail_color
			get_tree().root.add_child(trail)

			# 添加起点
			trail.add_point(start_pos)

			# 创建定时器更新拖尾
			var timer = Timer.new()
			timer.wait_time = 0.05
			timer.one_shot = false
			timer.timeout.connect(func():
				trail.add_point(piece.global_position)

				# 限制点数
				if trail.get_point_count() > 20:
					trail.remove_point(0)
			)
			get_tree().root.add_child(timer)
			timer.start()

			# 移动结束后渐隐拖尾
			tween.tween_callback(func():
				timer.stop()
				timer.queue_free()

				# 渐隐拖尾
				var fade_tween = create_tween()
				fade_tween.tween_property(trail, "modulate:a", 0.0, 0.3)
				fade_tween.tween_callback(func(): trail.queue_free())
			).set_delay(params.duration)

	# 添加移动特效
	if params.effect_name != "":
		# 获取特效管理器
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			# 播放特效
			var effect_id = effect_animator.play_combined_effect(
				piece.global_position,
				params.effect_name,
				{"duration": params.duration}
			)

			# 添加到特效列表
			animation_data.effects.append(effect_id)

	# 播放移动音效
	if params.sound_name != "":
		AudioManager.play_sfx(params.sound_name)

	# 动画完成时回调
	tween.tween_callback(func():
		# 恢复原始方向
		if params.face_direction:
			piece.scale = original_scale

		# 完成动画
		_on_animation_completed(animation_data.id)
	).set_delay(0.3 if params.bounce else 0.0)

	# 发送动画开始信号
	animation_started.emit(animation_id)

	return animation_id

# 创建弧形移动
func _create_arc_movement(tween: Tween, piece, start_pos: Vector2, end_pos: Vector2, arc_height: float, duration: float) -> void:
	# 计算路径中点
	var mid_point = (start_pos + end_pos) / 2

	# 计算弧形顶点
	var arc_top = mid_point + Vector2(0, -arc_height)

	# 创建路径点
	var path_points = []
	path_points.append(start_pos)
	path_points.append(arc_top)
	path_points.append(end_pos)

	# 创建路径跟随器
	var path_follow = PathFollow2D.new()
	var path = Path2D.new()

	# 设置路径曲线
	var curve = Curve2D.new()
	for point in path_points:
		curve.add_point(point)

	path.curve = curve
	path.add_child(path_follow)
	get_tree().root.add_child(path)

	# 设置路径跟随器初始位置
	path_follow.progress_ratio = 0.0

	# 创建路径跟随动画
	tween.tween_property(path_follow, "progress_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 更新棋子位置
	tween.tween_method(func(progress: float):
		if is_instance_valid(piece) and is_instance_valid(path_follow):
			piece.global_position = path_follow.global_position
	, 0.0, 1.0, duration)

	# 动画完成后清理路径
	tween.tween_callback(func():
		path.queue_free()
	).set_delay(duration)

# 创建贝塞尔曲线移动
func _create_bezier_movement(tween: Tween, piece, start_pos: Vector2, end_pos: Vector2, control_point: Vector2, duration: float) -> void:
	# 如果控制点为零，使用默认控制点
	if control_point == Vector2.ZERO:
		# 计算默认控制点
		var mid_point = (start_pos + end_pos) / 2
		var direction = (end_pos - start_pos).normalized()
		var perpendicular = Vector2(-direction.y, direction.x) * 100.0
		control_point = mid_point + perpendicular

	# 创建路径点
	var path_points = []
	path_points.append(start_pos)
	path_points.append(control_point)
	path_points.append(end_pos)

	# 创建路径跟随器
	var path_follow = PathFollow2D.new()
	var path = Path2D.new()

	# 设置路径曲线
	var curve = Curve2D.new()
	curve.add_point(start_pos, Vector2.ZERO, control_point - start_pos)
	curve.add_point(end_pos, end_pos - control_point, Vector2.ZERO)

	path.curve = curve
	path.add_child(path_follow)
	get_tree().root.add_child(path)

	# 设置路径跟随器初始位置
	path_follow.progress_ratio = 0.0

	# 创建路径跟随动画
	tween.tween_property(path_follow, "progress_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 更新棋子位置
	tween.tween_method(func(progress: float):
		if is_instance_valid(piece) and is_instance_valid(path_follow):
			piece.global_position = path_follow.global_position
	, 0.0, 1.0, duration)

	# 动画完成后清理路径
	tween.tween_callback(func():
		path.queue_free()
	).set_delay(duration)

# 播放特效动画
func play_effect_animation(position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 创建动画ID
	var animation_id = _create_animation_id(AnimationType.EFFECT, effect_name)

	# 合并默认参数
	var default_params = {
		"duration": 1.0,
		"sound_name": "",
		"scale": Vector2(1, 1),
		"rotation": 0.0,
		"z_index": 0
	}

	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]

	# 创建动画数据
	var animation_data = {
		"id": animation_id,
		"type": AnimationType.EFFECT,
		"position": position,
		"effect_name": effect_name,
		"params": params,
		"state": AnimationState.PLAYING,
		"start_time": Time.get_ticks_msec(),
		"duration": params.duration,
		"effects": []
	}

	# 添加到动画队列
	var result = _add_to_queue(animation_data)

	# 如果添加失败，返回空字符串
	if not result:
		return ""

	# 获取特效管理器
	var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
	if effect_animator:
		# 播放特效
		var effect_id = effect_animator.play_combined_effect(
			position,
			effect_name,
			{
				"duration": params.duration,
				"scale": params.scale,
				"rotation": params.rotation,
				"z_index": params.z_index
			}
		)

		# 添加到特效列表
		animation_data.effects.append(effect_id)

	# 播放特效音效
	if params.sound_name != "":
		AudioManager.play_sfx(params.sound_name)

	# 创建定时器完成动画
	var timer = get_tree().create_timer(params.duration)
	timer.timeout.connect(func(): _on_animation_completed(animation_data.id))

	# 发送动画开始信号
	animation_started.emit(animation_id)

	return animation_id

# 取消动画
func cancel_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 取消相关特效
	if animation_data.has("effects"):
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			for effect_id in animation_data.effects:
				effect_animator.cancel_effect(effect_id)

	# 清理动画资源
	_cleanup_animation(animation_id)

	# 发送动画取消信号
	animation_cancelled.emit(animation_id)

	# 从活动动画中移除
	active_animations.erase(animation_id)

	return true

# 暂停动画
func pause_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 如果动画已经暂停或完成，则返回
	if animation_data.state == AnimationState.PAUSED or animation_data.state == AnimationState.COMPLETED:
		return false

	# 暂停相关特效
	if animation_data.has("effects"):
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			for effect_id in animation_data.effects:
				effect_animator.pause_effect(effect_id)

	# 更新动画状态
	animation_data.state = AnimationState.PAUSED

	# 记录暂停时间
	animation_data.paused_time = Time.get_ticks_msec() - animation_data.start_time

	# 发送动画暂停信号
	animation_paused.emit(animation_id)

	return true

# 恢复动画
func resume_animation(animation_id: String) -> bool:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return false

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 如果动画没有暂停，则返回
	if animation_data.state != AnimationState.PAUSED:
		return false

	# 恢复相关特效
	if animation_data.has("effects"):
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			for effect_id in animation_data.effects:
				effect_animator.resume_effect(effect_id)

	# 更新动画状态
	animation_data.state = AnimationState.PLAYING

	# 更新开始时间
	animation_data.start_time = Time.get_ticks_msec() - animation_data.paused_time

	# 发送动画恢复信号
	animation_resumed.emit(animation_id)

	return true

# 获取动画状态
func get_animation_state(animation_id: String) -> int:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return AnimationState.IDLE

	# 返回动画状态
	return active_animations[animation_id].state

# 是否有活动的动画
func has_active_animations() -> bool:
	# 检查是否有活动的动画
	for animation_id in active_animations:
		var animation_data = active_animations[animation_id]
		if animation_data.state == AnimationState.PLAYING or animation_data.state == AnimationState.PAUSED:
			return true

	return false

# 清除所有动画
func clear_animations() -> void:
	# 复制活动动画列表，因为我们将在遍历过程中修改它
	var animations_to_clear = active_animations.keys()

	# 取消所有动画
	for animation_id in animations_to_clear:
		cancel_animation(animation_id)

	# 清空动画队列
	animation_queue.clear()

# 创建动画ID
func _create_animation_id(type: int, name: String) -> String:
	# 生成唯一ID
	var timestamp = Time.get_ticks_msec()
	var random_part = randi() % 10000

	# 根据动画类型生成前缀
	var prefix = ""
	match type:
		AnimationType.ATTACK: prefix = "attack"
		AnimationType.DAMAGE: prefix = "damage"
		AnimationType.DEATH: prefix = "death"
		AnimationType.MOVEMENT: prefix = "movement"
		AnimationType.EFFECT: prefix = "effect"
		AnimationType.ABILITY: prefix = "ability"
		_: prefix = "animation"

	# 组合ID
	return prefix + "_" + name + "_" + str(timestamp) + "_" + str(random_part)

# 添加动画到队列
func _add_to_queue(animation_data: Dictionary) -> bool:
	# 检查动画数据是否有效
	if not animation_data.has("id") or animation_data.id.is_empty():
		return false

	# 添加到队列
	animation_queue.append(animation_data)

	# 处理队列
	_process_queue()

	return true

# 处理动画队列
func _process_queue() -> void:
	# 如果队列为空，则返回
	if animation_queue.is_empty():
		return

	# 获取下一个动画
	var animation_data = animation_queue.pop_front()

	# 添加到活动动画
	active_animations[animation_data.id] = animation_data

# 动画完成处理
func _on_animation_completed(animation_id: String) -> void:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 清理动画资源
	_cleanup_animation(animation_id)

	# 更新动画状态
	animation_data.state = AnimationState.COMPLETED

	# 发送动画完成信号
	animation_completed.emit(animation_id)

	# 从活动动画中移除
	active_animations.erase(animation_id)

# 清理动画资源
func _cleanup_animation(animation_id: String) -> void:
	# 检查动画ID是否有效
	if animation_id.is_empty() or not active_animations.has(animation_id):
		return

	# 获取动画数据
	var animation_data = active_animations[animation_id]

	# 清理相关特效
	if animation_data.has("effects"):
		var effect_animator = get_node_or_null("/root/GameManager/EffectAnimator")
		if effect_animator:
			for effect_id in animation_data.effects:
				effect_animator.cancel_effect(effect_id)
