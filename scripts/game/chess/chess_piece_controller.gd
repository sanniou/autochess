extends Node
class_name ChessPieceController
## 棋子控制器
## 协调棋子的数据、逻辑和视图层

# 引用
var data: ChessPieceData = null
var view = null
var state_machine: ChessStateMachine = null
var ability = null

# 配置
var config = {
	"cell_size": Vector2(64, 64),  # 棋盘格子大小
	"attack_range_multiplier": 64, # 攻击范围乘数
	"mana_gain_passive": 5.0,      # 被动法力恢复
	"mana_gain_attack": 10.0,      # 攻击法力恢复
	"mana_gain_damage": 5.0        # 受伤法力恢复
}

# 信号
signal health_changed(old_value, new_value)
signal mana_changed(old_value, new_value)
signal state_changed(old_state, new_state)
signal ability_activated(target)
signal died
signal dodge_successful(attacker)
signal critical_hit(target, damage)
signal elemental_effect_triggered(target, element_type)

# 初始化
func _init():
	# 创建数据对象
	data = ChessPieceData.new()
	
	# 创建状态机
	state_machine = ChessStateMachine.new(self)
	
	# 注册状态
	_register_states()

# 注册状态
func _register_states() -> void:
	state_machine.register_state(IdleState.new())
	state_machine.register_state(MovingState.new())
	state_machine.register_state(AttackingState.new())
	state_machine.register_state(CastingState.new())
	state_machine.register_state(StunnedState.new())
	state_machine.register_state(DeadState.new())

# 设置视图
func set_view(piece_view) -> void:
	view = piece_view
	
	# 连接视图信号
	if view:
		view.animation_finished.connect(_on_animation_finished)

# 初始化棋子
func initialize(piece_data: Dictionary) -> void:
	# 初始化数据
	data.initialize_from_dict(piece_data)
	
	# 初始化视图
	if view:
		view.initialize(data)
	
	# 设置初始状态
	state_machine.set_initial_state("idle")
	
	# 连接状态机信号
	state_machine.state_changed.connect(_on_state_changed)

# 物理更新
func _physics_process(delta: float) -> void:
	# 更新状态机
	if state_machine:
		state_machine.physics_process(delta)
	
	# 更新冷却时间
	if data and data.current_cooldown > 0:
		data.current_cooldown -= delta
		if data.current_cooldown < 0:
			data.current_cooldown = 0

# 播放动画
func play_animation(animation_name: String) -> void:
	if view:
		view.play_animation(animation_name)

# 动画完成回调
func _on_animation_finished(animation_name: String) -> void:
	# 处理动画完成事件
	pass

# 状态变更回调
func _on_state_changed(old_state: String, new_state: String) -> void:
	# 发送状态变更信号
	state_changed.emit(old_state, new_state)
	
	# 更新视图
	if view:
		view.update_state(new_state)

# ===== 状态检查函数 =====

# 检查是否有目标
func has_target() -> bool:
	return data and data.target_id != ""

# 获取目标
func get_target():
	if not has_target():
		return null
	
	# 从游戏管理器获取目标
	return GameManager.board_manager.get_piece_by_id(data.target_id)	

# 设置目标
func set_target(target) -> void:
	if target and data:
		data.target_id = target.get_id()

# 清除目标
func clear_target() -> void:
	if data:
		data.target_id = ""

# 检查目标是否死亡
func is_target_dead(target) -> bool:
	return target and target.is_dead()

# 获取到目标的距离
func get_distance_to_target(target) -> float:
	if not target or not view:
		return 999999.0
	
	return view.global_position.distance_to(target.global_position)

# 获取攻击范围
func get_attack_range() -> float:
	if data:
		return data.attack_range * config.attack_range_multiplier
	return 0.0

# 检查是否被眩晕
func is_stunned() -> bool:
	# 检查效果系统中的眩晕效果
	return GameManager.effect_manager.has_effect(self, "stun")


# 获取眩晕持续时间
func get_stun_duration() -> float:
	# 从效果系统获取眩晕持续时间
	return GameManager.effect_manager.get_effect_duration(self, "stun")

# 清除眩晕
func clear_stun() -> void:
	# 从效果系统清除眩晕效果
	GameManager.effect_manager.remove_effect_by_type(self, "stun")

# 检查是否被冰冻
func is_frozen() -> bool:
	return data and data.is_frozen

# 检查是否被缴械
func is_disarmed() -> bool:
	return data and data.is_disarmed

# 检查是否被嘲讽
func is_taunting() -> bool:
	return data and data.taunted_by != null

# 获取嘲讽源
func get_taunt_source():
	return data and data.taunted_by

# 检查是否死亡
func is_dead() -> bool:
	return data and data.current_health <= 0

# 检查是否被复活
func is_resurrected() -> bool:
	return data and data.current_health > 0 and state_machine.is_in_state("dead")

# ===== 行为函数 =====

# 移动向目标
func move_towards_target(target, delta: float) -> void:
	if not target or not view or not data:
		return
	
	var direction = (target.global_position - view.global_position).normalized()
	view.global_position += direction * data.move_speed * delta

# 执行攻击
func perform_attack() -> void:
	if not has_target():
		return
	
	var target = get_target()
	if not target:
		return
	
	# 计算伤害
	var damage = data.attack_damage
	var is_crit = false
	var trigger_elemental = false
	
	# 检查暴击
	if randf() < data.crit_chance:
		damage *= data.crit_damage
		is_crit = true
	
	# 检查元素效果
	if randf() < data.elemental_effect_chance:
		trigger_elemental = true
	
	# 造成伤害
	var actual_damage = target.take_damage(damage, "physical", self)
	
	# 播放攻击动画
	play_animation("attack")
	
	# 触发攻击效果
	_on_attack(target, actual_damage, is_crit)
	
	# 触发元素效果
	if trigger_elemental:
		_trigger_elemental_effect(target)
	
	# 攻击后获得法力值
	gain_mana(config.mana_gain_attack, "attack")

# 检查是否可以施法
func can_cast_ability() -> bool:
	if not data or not ability:
		return false
	
	return data.current_mana >= data.ability_mana_cost and data.current_cooldown <= 0 and not data.is_silenced

# 激活技能
func activate_ability() -> void:
	if not can_cast_ability():
		return
	
	# 消耗法力值
	spend_mana(data.ability_mana_cost)
	
	# 设置冷却时间
	data.current_cooldown = data.ability_cooldown
	
	# 执行技能
	if ability:
		ability.activate(get_target())
	else:
		# 默认技能：造成伤害
		var target = get_target()
		if target:
			var damage = data.ability_damage + data.spell_power
			target.take_damage(damage, "magical", self)
			
			# 播放技能特效
			_play_ability_effect(target)
	
	# 发送技能激活信号
	ability_activated.emit(get_target())

# 受到伤害
func take_damage(amount: float, damage_type: String = "physical", source = null) -> float:
	if is_dead():
		return 0
	
	# 检查闪避
	if randf() < data.dodge_chance:
		# 触发闪避效果
		_on_dodge(source)
		# 发送闪避成功信号
		dodge_successful.emit(source)
		return 0
	
	# 计算实际伤害
	var actual_damage = amount
	
	# 应用护甲或魔抗
	if damage_type == "physical":
		actual_damage *= (100.0 / (100.0 + data.armor))
	elif damage_type == "magical":
		actual_damage *= (100.0 / (100.0 + data.magic_resist))
	
	# 应用伤害减免效果
	actual_damage *= (1.0 - data.damage_reduction)
	
	# 更新生命值
	var old_health = data.current_health
	data.current_health -= actual_damage
	
	# 检查死亡
	if data.current_health <= 0:
		data.current_health = 0
		die()
	
	# 更新生命值显示
	health_changed.emit(old_health, data.current_health)
	if view:
		view.update_health_bar(data.current_health, data.max_health)
	
	# 受伤获得法力值
	gain_mana(config.mana_gain_damage, "damage")
	
	# 触发受伤效果
	_on_damaged(actual_damage, damage_type, source)
	
	return actual_damage

# 治疗
func heal(amount: float, source = null) -> float:
	if is_dead():
		return 0
	
	var old_health = data.current_health
	data.current_health = min(data.current_health + amount, data.max_health)
	
	# 更新生命值显示
	health_changed.emit(old_health, data.current_health)
	if view:
		view.update_health_bar(data.current_health, data.max_health)
	
	# 触发治疗效果
	_on_healed(amount, source)
	
	return data.current_health - old_health

# 获得法力值
func gain_mana(amount: float, source_type: String = "passive") -> float:
	if is_dead():
		return 0
	
	var old_mana = data.current_mana
	data.current_mana = min(data.current_mana + amount, data.max_mana)
	
	# 更新法力值显示
	mana_changed.emit(old_mana, data.current_mana)
	if view:
		view.update_mana_bar(data.current_mana, data.max_mana)
	
	return data.current_mana - old_mana

# 消耗法力值
func spend_mana(amount: float) -> bool:
	if data.current_mana < amount:
		return false
	
	var old_mana = data.current_mana
	data.current_mana -= amount
	
	# 更新法力值显示
	mana_changed.emit(old_mana, data.current_mana)
	if view:
		view.update_mana_bar(data.current_mana, data.max_mana)
	
	return true

# 死亡
func die() -> void:
	if is_dead() and state_machine.is_in_state("dead"):
		return
	
	# 切换到死亡状态
	state_machine.change_state("dead")
	
	# 发送死亡信号
	died.emit()
	
	# 发送事件
	var EventBus = Engine.get_singleton("EventBus")
	if EventBus:
		var event_definitions = load("res://scripts/events/event_definitions.gd")
		EventBus.battle.emit_event(event_definitions.BattleEvents.UNIT_DIED, [self])

# 处理死亡效果
func process_death() -> void:
	# 触发死亡效果
	_on_death()

# 延迟移除
func queue_free_delayed() -> void:
	if view:
		# 创建淡出动画
		var tween = view.create_tween()
		tween.tween_property(view, "modulate:a", 0.0, 1.0)
		tween.tween_callback(view.queue_free)

# 复活
func resurrect(health_percent: float = 0.3) -> void:
	if not is_dead():
		return
	
	# 恢复生命值
	data.current_health = data.max_health * health_percent
	
	# 重置状态
	state_machine.change_state("idle")
	
	# 更新视觉效果
	if view:
		view.modulate.a = 1.0
		view.update_health_bar(data.current_health, data.max_health)
	
	# 触发复活效果
	_on_resurrect()

# 升级
func upgrade() -> void:
	if data:
		# 记录旧属性
		var old_star_level = data.star_level
		var old_max_health = data.max_health
		var old_attack_damage = data.attack_damage
		var old_ability_damage = data.ability_damage
		
		# 升级数据
		data.upgrade()
		
		# 计算属性增加值
		var stat_increases = {
			"health": data.max_health - old_max_health,
			"attack": data.attack_damage - old_attack_damage,
			"ability": data.ability_damage - old_ability_damage
		}
		
		# 播放升级特效
		_play_upgrade_effect(old_star_level, data.star_level, stat_increases)
		
		# 更新视图
		if view:
			view.update_star_level(data.star_level)
			view.update_health_bar(data.current_health, data.max_health)

# 获取ID
func get_id() -> String:
	return data.id if data else ""

# ===== 效果处理函数 =====

# 攻击效果
func _on_attack(target, damage: float, is_crit: bool) -> void:
	# 处理攻击效果
	if is_crit:
		critical_hit.emit(target, damage)
		
		# 创建视觉特效参数
		var params = {
			"color": GameManager.effect_manager.get_effect_color("physical"),
			"duration": 0.5,
			"damage_type": "physical",
			"damage_amount": damage,
			"is_critical": true
		}
		
		# 使用特效管理器创建特效
		GameManager.effect_manager.create_visual_effect(
			GameManager.effect_manager.VisualEffectType.DAMAGE,
			target,
			params
		)

# 闪避效果
func _on_dodge(attacker = null) -> void:
	# 处理闪避效果
	# 创建视觉特效参数
	var params = {
		"color": GameManager.effect_manager.get_effect_color("dodge"),
		"duration": 0.5,
		"buff_type": "dodge"
	}
	
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(
		GameManager.effect_manager.VisualEffectType.BUFF,
		self,
		params
	)
	
	# 发送元素效果触发信号
	elemental_effect_triggered.emit(attacker, "dodge")

# 受伤效果
func _on_damaged(amount: float, damage_type: String, source) -> void:
	# 处理受伤效果
	pass

# 治疗效果
func _on_healed(amount: float, source) -> void:
	# 处理治疗效果
	pass

# 死亡效果
func _on_death() -> void:
	# 处理死亡效果
	pass

# 复活效果
func _on_resurrect() -> void:
	# 处理复活效果
	pass

# 触发元素效果
func _trigger_elemental_effect(target) -> void:
	# 根据棋子属性触发不同元素效果
	var element_type = "physical"  # 默认物理
	
	# 发送元素效果触发信号
	elemental_effect_triggered.emit(target, element_type)
	
	# 应用元素效果
	match element_type:
		"fire":
			_apply_fire_effect(target)
		"ice":
			_apply_ice_effect(target)
		"lightning":
			_apply_lightning_effect(target)
		"earth":
			_apply_earth_effect(target)

# 应用火元素效果
func _apply_fire_effect(target) -> void:	
	# 创建燃烧效果
	var params = {
		"id": "burning_" + str(randi()),
		"name": "燃烧",
		"description": "每秒受到伤害",
		"duration": 3.0,
		"damage_type": "fire",
		"damage_per_second": data.attack_damage * 0.1,
		"source": self
	}
	
	# 使用特效管理器创建效果
	GameManager.effect_manager.create_effect(
		GameManager.effect_manager.EffectType.DOT,
		self,
		target,
		params
	)
	
	# 播放效果
	_play_elemental_effect(target, Color(0.8, 0.4, 0.0, 0.5))

# 应用冰元素效果
func _apply_ice_effect(target) -> void:
	
	# 创建减速效果
	var params = {
		"id": "slowed_" + str(randi()),
		"name": "减速",
		"description": "移动速度降低",
		"duration": 2.0,
		"stat_type": "move_speed",
		"value": -0.3,  # 减少30%移动速度
		"is_percentage": true,
		"source": self
	}
	
	# 使用特效管理器创建效果
	GameManager.effect_manager.create_effect(
		GameManager.effect_manager.EffectType.STAT,
		self,
		target,
		params
	)
	
	# 播放效果
	_play_elemental_effect(target, Color(0.0, 0.7, 1.0, 0.5))

# 应用雷元素效果
func _apply_lightning_effect(target) -> void:
	
	# 创建眩晕效果
	var params = {
		"id": "stunned_" + str(randi()),
		"name": "眩晕",
		"description": "无法行动",
		"duration": 1.0,
		"control_type": "stun",
		"source": self
	}
	
	# 使用特效管理器创建效果
	GameManager.effect_manager.create_effect(
		GameManager.effect_manager.EffectType.CONTROL,
		self,
		target,
		params
	)
	
	# 播放效果
	_play_elemental_effect(target, Color(0.8, 0.8, 0.0, 0.5))

# 应用土元素效果
func _apply_earth_effect(target) -> void:
	# 创建护甲减少效果
	var params = {
		"id": "armor_reduction_" + str(randi()),
		"name": "护甲减少",
		"description": "护甲降低",
		"duration": 3.0,
		"stat_type": "armor",
		"value": -10.0,  # 减少10点护甲
		"is_percentage": false,
		"source": self
	}
	
	# 使用特效管理器创建效果
	GameManager.effect_manager.create_effect(
		GameManager.effect_manager.EffectType.STAT,
		self,
		target,
		params
	)
	
	# 播放效果
	_play_elemental_effect(target, Color(0.6, 0.4, 0.2, 0.5))

# 播放元素效果
func _play_elemental_effect(target, color: Color) -> void:
	
	# 创建视觉特效参数
	var params = {
		"color": color,
		"duration": 0.8,
		"buff_type": "elemental"
	}
	
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(
		GameManager.effect_manager.VisualEffectType.BUFF,
		target,
		params
	)

# 播放技能特效
func _play_ability_effect(target) -> void:
	# 创建视觉特效参数
	var params = {
		"color": GameManager.effect_manager.get_effect_color("magical"),
		"duration": 0.5,
		"damage_type": "magical",
		"damage_amount": data.ability_damage + data.spell_power
	}
	
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(
		GameManager.effect_manager.VisualEffectType.DAMAGE,
		target,
		params
	)

# 播放升级特效
func _play_upgrade_effect(old_star_level: int, new_star_level: int, stat_increases: Dictionary) -> void:	
	# 创建升级特效容器
	var upgrade_effect = Node2D.new()
	upgrade_effect.name = "UpgradeEffect"
	if view:
		view.add_child(upgrade_effect)
	
	# 创建视觉特效参数
	var params = {
		"color": GameManager.effect_manager.get_effect_color("level_up"),
		"duration": 1.5,
		"buff_type": "level_up"
	}
	
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_visual_effect(
		GameManager.effect_manager.VisualEffectType.LEVEL_UP,
		upgrade_effect,
		params
	)
	
	# 创建星级文本
	var star_text = Label.new()
	star_text.text = str(old_star_level) + " → " + str(new_star_level) + " ★"
	star_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_text.size = Vector2(100, 30)
	star_text.position = Vector2(-50, -80)
	upgrade_effect.add_child(star_text)
	
	# 创建属性提升文本
	var y_offset = -50
	for stat_name in stat_increases:
		var increase = stat_increases[stat_name]
		if increase > 0:
			var stat_label = Label.new()
			var display_name = ""
			match stat_name:
				"health":
					display_name = "生命值"
				"attack":
					display_name = "攻击力"
				"ability":
					display_name = "技能伤害"
				_:
					display_name = stat_name
			
			stat_label.text = display_name + " +" + str(int(increase))
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stat_label.size = Vector2(100, 20)
			stat_label.position = Vector2(-50, y_offset)
			upgrade_effect.add_child(stat_label)
			y_offset += 20
	
	# 创建消失动画
	var tween = view.create_tween() if view else null
	if tween:
		tween.tween_property(star_text, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.3)
		tween.tween_property(upgrade_effect, "modulate", Color(1, 1, 1, 0), 1.0)
		tween.tween_callback(upgrade_effect.queue_free)
	
	# 播放升星音效
	var EventBus = Engine.get_singleton("EventBus")
	if EventBus:
		EventBus.audio.emit_event("play_sound", ["upgrade", view.global_position if view else Vector2.ZERO])
