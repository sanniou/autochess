extends Component
class_name StateMachineComponent
## 状态机组件
## 管理棋子的状态和状态转换

# 信号
signal state_changed(old_state, new_state)

# 状态枚举
enum ChessState {
	IDLE,       # 空闲状态
	MOVING,     # 移动状态
	ATTACKING,  # 攻击状态
	CASTING,    # 施法状态
	STUNNED,    # 眩晕状态
	DEAD        # 死亡状态
}

# 状态机
var state_machine: FiniteStateMachine = null

# 状态控制
var is_silenced: bool = false  # 是否被沉默
var is_disarmed: bool = false  # 是否被缴械
var is_frozen: bool = false    # 是否被冰冻
var is_stunned: bool = false   # 是否被眩晕
var taunted_by = null          # 嘲讽来源

# 初始化
func _init(p_owner = null, p_name: String = "StateMachineComponent"):
	super._init(p_owner, p_name)
	priority = 90  # 高优先级，确保状态在属性之后更新

# 初始化组件
func initialize() -> void:
	super.initialize()

	# 创建状态机
	state_machine = FiniteStateMachine.new(owner)

	# 将状态机添加为棋子的子节点
	if owner and owner is Node:
		owner.add_child(state_machine)

	# 连接状态机信号
	state_machine.state_changed.connect(_on_state_changed)

	# 注册状态
	_register_states()

	# 注册状态转换
	_register_transitions()

	# 设置初始状态
	state_machine.set_initial_state("idle")

# 注册状态
func _register_states() -> void:
	# 注册空闲状态
	state_machine.register_state("idle", IdleState.new())

	# 注册移动状态
	state_machine.register_state("moving", MovingState.new())

	# 注册攻击状态
	state_machine.register_state("attacking", AttackingState.new())

	# 注册施法状态
	state_machine.register_state("casting", CastingState.new())

	# 注册眩晕状态
	state_machine.register_state("stunned", StunnedState.new())

	# 注册死亡状态
	state_machine.register_state("dead", DeadState.new())

# 注册状态转换
func _register_transitions() -> void:
	# 从空闲状态的转换
	state_machine.register_transition("idle", "moving", func():
		# 如果有目标且不在攻击范围内，切换到移动状态
		var target_component = owner.get_component("TargetComponent")
		if target_component and target_component.has_target():
			var target = target_component.get_target()
			var attribute_component = owner.get_component("AttributeComponent")
			if attribute_component:
				var attack_range = attribute_component.get_attribute("attack_range")
				var distance = target_component.get_distance_to_target(target)
				return distance > attack_range
		return false
	)

	state_machine.register_transition("idle", "attacking", func():
		# 如果有目标且在攻击范围内，切换到攻击状态
		var target_component = owner.get_component("TargetComponent")
		if target_component and target_component.has_target():
			var target = target_component.get_target()
			var attribute_component = owner.get_component("AttributeComponent")
			if attribute_component:
				var attack_range = attribute_component.get_attribute("attack_range")
				var distance = target_component.get_distance_to_target(target)
				return distance <= attack_range and not is_disarmed
		return false
	)

	state_machine.register_transition("idle", "casting", func():
		# 如果有可用技能且法力值足够，切换到施法状态
		var ability_component = owner.get_component("AbilityComponent")
		return ability_component and ability_component.can_cast_ability() and not is_silenced
	)

	state_machine.register_transition("idle", "stunned", func():
		# 如果被眩晕，切换到眩晕状态
		return is_stunned
	)

	state_machine.register_transition("idle", "dead", func():
		# 如果死亡，切换到死亡状态
		var attribute_component = owner.get_component("AttributeComponent")
		return attribute_component and attribute_component.is_dead()
	)

	# 从移动状态的转换
	state_machine.register_transition("moving", "idle", func():
		# 如果没有目标，切换到空闲状态
		var target_component = owner.get_component("TargetComponent")
		return not target_component or not target_component.has_target()
	)

	state_machine.register_transition("moving", "attacking", func():
		# 如果有目标且在攻击范围内，切换到攻击状态
		var target_component = owner.get_component("TargetComponent")
		if target_component and target_component.has_target():
			var target = target_component.get_target()
			var attribute_component = owner.get_component("AttributeComponent")
			if attribute_component:
				var attack_range = attribute_component.get_attribute("attack_range")
				var distance = target_component.get_distance_to_target(target)
				return distance <= attack_range and not is_disarmed
		return false
	)

	state_machine.register_transition("moving", "casting", func():
		# 如果有可用技能且法力值足够，切换到施法状态
		var ability_component = owner.get_component("AbilityComponent")
		return ability_component and ability_component.can_cast_ability() and not is_silenced
	)

	state_machine.register_transition("moving", "stunned", func():
		# 如果被眩晕，切换到眩晕状态
		return is_stunned
	)

	state_machine.register_transition("moving", "dead", func():
		# 如果死亡，切换到死亡状态
		var attribute_component = owner.get_component("AttributeComponent")
		return attribute_component and attribute_component.is_dead()
	)

	# 从攻击状态的转换
	state_machine.register_transition("attacking", "idle", func():
		# 攻击完成后，切换到空闲状态
		var attacking_state = state_machine.states["attacking"] as AttackingState
		return attacking_state.state_time >= 1.0  # 假设攻击动画持续1秒
	)

	state_machine.register_transition("attacking", "stunned", func():
		# 如果被眩晕，切换到眩晕状态
		return is_stunned
	)

	state_machine.register_transition("attacking", "dead", func():
		# 如果死亡，切换到死亡状态
		var attribute_component = owner.get_component("AttributeComponent")
		return attribute_component and attribute_component.is_dead()
	)

	# 从施法状态的转换
	state_machine.register_transition("casting", "idle", func():
		# 施法完成后，切换到空闲状态
		var casting_state = state_machine.states["casting"] as CastingState
		var cast_time = casting_state.get_state_data_item("cast_time", 1.0)
		return casting_state.state_time >= cast_time + 0.5  # 施法完成后等待0.5秒
	)

	state_machine.register_transition("casting", "stunned", func():
		# 如果被眩晕，切换到眩晕状态
		return is_stunned
	)

	state_machine.register_transition("casting", "dead", func():
		# 如果死亡，切换到死亡状态
		var attribute_component = owner.get_component("AttributeComponent")
		return attribute_component and attribute_component.is_dead()
	)

	# 从眩晕状态的转换
	state_machine.register_transition("stunned", "idle", func():
		# 眩晕结束后，切换到空闲状态
		var stunned_state = state_machine.states["stunned"] as StunnedState
		var stun_duration = stunned_state.get_state_data_item("stun_duration", 0.0)
		return stunned_state.state_time >= stun_duration and not is_stunned
	)

	state_machine.register_transition("stunned", "dead", func():
		# 如果死亡，切换到死亡状态
		var attribute_component = owner.get_component("AttributeComponent")
		return attribute_component and attribute_component.is_dead()
	)

# 更新组件
func update(delta: float) -> void:
	super.update(delta)

	# 状态机更新由引擎自动调用_physics_process

# 获取当前状态
func get_current_state() -> String:
	return state_machine.get_current_state_name()

# 获取当前状态枚举
func get_current_state_enum() -> int:
	var state_name = get_current_state()

	match state_name:
		"idle":
			return ChessState.IDLE
		"moving":
			return ChessState.MOVING
		"attacking":
			return ChessState.ATTACKING
		"casting":
			return ChessState.CASTING
		"stunned":
			return ChessState.STUNNED
		"dead":
			return ChessState.DEAD
		_:
			return ChessState.IDLE

# 改变状态
func change_state(state: int) -> void:
	var state_name = ""

	match state:
		ChessState.IDLE:
			state_name = "idle"
		ChessState.MOVING:
			state_name = "moving"
		ChessState.ATTACKING:
			state_name = "attacking"
		ChessState.CASTING:
			state_name = "casting"
		ChessState.STUNNED:
			state_name = "stunned"
		ChessState.DEAD:
			state_name = "dead"

	if not state_name.is_empty():
		state_machine.change_state(state_name)

# 改变状态（字符串版本）
func change_state_by_name(state_name: String) -> void:
	state_machine.change_state(state_name)

# 是否处于指定状态
func is_in_state(state: int) -> bool:
	var state_name = ""

	match state:
		ChessState.IDLE:
			state_name = "idle"
		ChessState.MOVING:
			state_name = "moving"
		ChessState.ATTACKING:
			state_name = "attacking"
		ChessState.CASTING:
			state_name = "casting"
		ChessState.STUNNED:
			state_name = "stunned"
		ChessState.DEAD:
			state_name = "dead"

	return state_machine.is_in_state(state_name)

# 是否处于指定状态（字符串版本）
func is_in_state_by_name(state_name: String) -> bool:
	return state_machine.is_in_state(state_name)

# 设置沉默状态
func set_silenced(silenced: bool) -> void:
	is_silenced = silenced

# 设置缴械状态
func set_disarmed(disarmed: bool) -> void:
	is_disarmed = disarmed

# 设置冰冻状态
func set_frozen(frozen: bool) -> void:
	is_frozen = frozen

# 设置眩晕状态
func set_stunned(stunned: bool, duration: float = 2.0) -> void:
	is_stunned = stunned

	# 如果被眩晕，强制进入眩晕状态
	if stunned:
		var stunned_state = state_machine.states["stunned"] as StunnedState
		if stunned_state:
			stunned_state.set_stun_duration(duration)

		change_state_by_name("stunned")

# 设置嘲讽来源
func set_taunted_by(source) -> void:
	taunted_by = source

	# 如果被嘲讽，更新目标
	if taunted_by and is_instance_valid(taunted_by):
		var target_component = owner.get_component("TargetComponent")
		if target_component:
			target_component.set_target(taunted_by)

# 清除嘲讽来源
func clear_taunted_by() -> void:
	taunted_by = null

# 开始施法
func start_casting(ability_id: String, cast_time: float = 1.0) -> void:
	var casting_state = state_machine.states["casting"] as CastingState
	if casting_state:
		casting_state.start_casting(ability_id, cast_time)

	change_state_by_name("casting")

# 重置状态
func reset_state_machine() -> void:
	# 清除所有状态标志
	is_silenced = false
	is_disarmed = false
	is_frozen = false
	is_stunned = false
	taunted_by = null

	# 切换到空闲状态
	change_state_by_name("idle")

# 状态变化事件处理
func _on_state_changed(old_state: String, new_state: String) -> void:
	# 转换为枚举
	var old_state_enum = ChessState.IDLE
	var new_state_enum = ChessState.IDLE

	match old_state:
		"idle":
			old_state_enum = ChessState.IDLE
		"moving":
			old_state_enum = ChessState.MOVING
		"attacking":
			old_state_enum = ChessState.ATTACKING
		"casting":
			old_state_enum = ChessState.CASTING
		"stunned":
			old_state_enum = ChessState.STUNNED
		"dead":
			old_state_enum = ChessState.DEAD

	match new_state:
		"idle":
			new_state_enum = ChessState.IDLE
		"moving":
			new_state_enum = ChessState.MOVING
		"attacking":
			new_state_enum = ChessState.ATTACKING
		"casting":
			new_state_enum = ChessState.CASTING
		"stunned":
			new_state_enum = ChessState.STUNNED
		"dead":
			new_state_enum = ChessState.DEAD

	# 发送状态变化信号
	state_changed.emit(old_state_enum, new_state_enum)

	# 如果进入死亡状态，发送死亡信号
	if new_state == "dead" and owner.has_signal("died"):
		owner.died.emit()

		# 发送事件
		EventBus.chess.emit_event("chess_piece_died", [owner])
		GlobalEventBus.battle.dispatch_event(BattleEvents.UnitDiedEvent.new(owner))
