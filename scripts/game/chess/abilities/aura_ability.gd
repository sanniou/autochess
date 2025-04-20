extends Ability
class_name AuraAbility
## 光环技能
## 为周围友军提供增益效果

# 光环类型
var aura_type: String = "attack"  # 光环类型(attack/defense/speed/health)
var aura_value: float = 0.0       # 光环值
var aura_radius: float = 2.0      # 光环半径（格子数）
var affected_pieces: Array = []   # 受影响的棋子

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置光环类型和值
	aura_type = ability_data.get("aura_type", "attack")
	aura_value = ability_data.get("aura_value", 0.0)
	aura_radius = ability_data.get("aura_radius", 2.0)

	# 设置目标类型
	target_type = "self"

	# 连接信号
	owner.died.connect(_on_owner_died)

	# 设置持续时间为无限
	duration = -1

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 创建光环效果
	_create_aura_effect()

	# 应用光环效果
	_apply_aura_effect()

	# 播放技能特效
	_play_aura_effect()

	# 设置定时器定期更新光环效果
	_setup_aura_timer()

# 创建光环效果
func _create_aura_effect() -> void:
	# 创建光环视觉效果
	var aura = ColorRect.new()
	aura.name = "AuraEffect"
	aura.color = _get_aura_color()

	# 获取棋盘管理器
	var board_manager = GameManager.board_manager
	if board_manager:
		# 计算光环大小
		var aura_size = aura_radius * 2 * board_manager.cell_size.x
		aura.size = Vector2(aura_size, aura_size)
		aura.position = Vector2(-aura_size/2, -aura_size/2)
	else:
		# 默认大小
		aura.size = Vector2(200, 200)
		aura.position = Vector2(-100, -100)

	# 设置透明度
	aura.modulate.a = 0.2

	# 添加到所有者
	owner.add_child(aura)

	# 创建呼吸动画
	var tween = owner.create_tween()
	tween.set_loops()
	tween.tween_property(aura, "modulate:a", 0.1, 1.0)
	tween.tween_property(aura, "modulate:a", 0.2, 1.0)

# 应用光环效果
func _apply_aura_effect() -> void:
	# 获取棋盘管理器
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 清除之前的效果
	_remove_aura_effect()

	# 获取范围内的所有友军
	var allies = []
	var all_pieces = board_manager.pieces

	for piece in all_pieces:
		if piece != owner and piece.is_player_piece == owner.is_player_piece and piece.current_state != ChessPiece.ChessState.DEAD:
			# 计算距离
			var distance = owner.board_position.distance_to(piece.board_position)
			if distance <= aura_radius:
				allies.append(piece)

	# 为范围内的所有友军应用效果
	for ally in allies:
		# 创建效果数据
		var effect_data = {
			"id": id + "_aura_effect",
			"duration": -1,  # 持续到光环消失
			"stats": {}
		}

		# 根据光环类型设置效果
		match aura_type:
			"attack":
				effect_data.stats["attack_damage"] = aura_value
			"defense":
				effect_data.stats["armor"] = aura_value
			"speed":
				effect_data.stats["attack_speed"] = aura_value
			"health":
				effect_data.stats["health"] = aura_value

		# 应用效果
		ally.add_effect(effect_data)

		# 添加到受影响列表
		affected_pieces.append(ally)

		# 播放效果特效
		_play_effect(ally)

# 移除光环效果
func _remove_aura_effect() -> void:
	# 移除所有受影响棋子的效果
	for piece in affected_pieces:
		if is_instance_valid(piece):
			piece.remove_effect(id + "_aura_effect")

	# 清空受影响列表
	affected_pieces.clear()

# 设置光环定时器
func _setup_aura_timer() -> void:
	# 创建定时器定期更新光环效果
	var timer = Timer.new()
	timer.name = "AuraTimer"
	timer.wait_time = 1.0  # 每秒更新一次
	timer.autostart = true
	timer.timeout.connect(_on_aura_timer_timeout)

	# 添加到所有者
	owner.add_child(timer)

# 光环定时器超时处理
func _on_aura_timer_timeout() -> void:
	# 更新光环效果
	_apply_aura_effect()

# 所有者死亡处理
func _on_owner_died() -> void:
	# 移除光环效果
	_remove_aura_effect()

	# 移除光环视觉效果
	if owner.has_node("AuraEffect"):
		owner.get_node("AuraEffect").queue_free()

	# 移除光环定时器
	if owner.has_node("AuraTimer"):
		owner.get_node("AuraTimer").queue_free()

# 获取光环颜色
func _get_aura_color() -> Color:
	match aura_type:
		"attack":
			return Color(0.8, 0.2, 0.2, 0.2)  # 红色
		"defense":
			return Color(0.2, 0.2, 0.8, 0.2)  # 蓝色
		"speed":
			return Color(0.2, 0.8, 0.2, 0.2)  # 绿色
		"health":
			return Color(0.2, 0.8, 0.8, 0.2)  # 青色
		_:
			return Color(0.8, 0.8, 0.2, 0.2)  # 黄色

# 播放光环特效
func _play_aura_effect() -> void:
	# 创建增益特效
	var params = {
		"buff_type": aura_type,
		"radius": aura_radius * GameManager.board_manager.cell_size.x  # 转换为像素单位
	}

	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(GameManager.effect_manager.VisualEffectType.BUFF, owner, params)

# 播放单体特效
func _play_effect(target: ChessPiece) -> void:
	# 创建增益特效
	var params = {
		"buff_type": aura_type
	}

	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(GameManager.effect_manager.VisualEffectType.BUFF, target, params)
