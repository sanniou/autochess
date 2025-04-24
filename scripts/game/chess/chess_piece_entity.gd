extends Node2D
class_name ChessPieceEntity
## 棋子实体
## 使用组件系统的棋子实现

# 信号
signal initialized
signal component_added(component)
signal component_removed(component)
signal damaged(amount, source)
signal healed(amount, source)
signal died
signal level_changed(old_level, new_level)

# 基本属性
var id: String = ""  # 棋子ID
var display_name: String = ""  # 显示名称
var description: String = ""  # 描述
var level: int = 1  # 棋子等级
var is_player_piece: bool = true  # 是否是玩家棋子
var is_initialized: bool = false  # 是否已初始化

# 状态属性
var is_invisible: bool = false  # 是否隐身
var is_invulnerable: bool = false  # 是否无敌

# 组件管理器
var component_manager: ComponentManager = null

# 初始化
func _init():
	# 创建组件管理器
	component_manager = ComponentManager.new(self)
	add_child(component_manager)

# 准备完成
func _ready():
	# 如果还没有初始化，进行初始化
	if not is_initialized:
		initialize()

# 处理过程
func _process(delta):
	# 更新所有组件
	if component_manager:
		component_manager.update(delta)

# 初始化棋子
func initialize() -> void:
	# 标记为已初始化
	is_initialized = true

	# 创建基本组件
	_create_basic_components()

	# 发送初始化信号
	initialized.emit()

# 创建基本组件
func _create_basic_components() -> void:
	# 创建属性组件
	var attribute_component = AttributeComponent.new(self)
	add_component(attribute_component)

	# 创建状态机组件
	var state_machine_component = StateMachineComponent.new(self)
	add_component(state_machine_component)

	# 创建目标组件
	var target_component = TargetComponent.new(self)
	add_component(target_component)

	# 创建战斗组件
	var combat_component = CombatComponent.new(self)
	add_component(combat_component)

	# 创建技能组件
	var ability_component = AbilityComponent.new(self)
	add_component(ability_component)

	# 创建视图组件
	var view_component = ViewComponent.new(self)
	add_component(view_component)

	# 创建装备组件
	var equipment_component = EquipmentComponent.new(self)
	add_component(equipment_component)

	# 创建羁绊组件
	var synergy_component = SynergyComponent.new(self)
	add_component(synergy_component)

	# 连接组件信号
	_connect_component_signals()

# 连接组件信号
func _connect_component_signals() -> void:
	# 获取属性组件
	var attribute_component = get_component("AttributeComponent")
	if attribute_component:
		# 连接属性变化信号
		attribute_component.attribute_changed.connect(_on_attribute_changed)

	# 获取状态机组件
	var state_machine_component = get_component("StateMachineComponent")
	if state_machine_component:
		# 连接状态变化信号
		state_machine_component.state_changed.connect(_on_state_changed)

	# 获取战斗组件
	var combat_component = get_component("CombatComponent")
	if combat_component:
		# 连接伤害信号
		combat_component.damage_taken.connect(_on_damage_taken)
		combat_component.healing_received.connect(_on_healing_received)

# 添加组件
func add_component(component: Component) -> Component:
	if not component_manager:
		return null

	var added_component = component_manager.add_component(component)

	# 发送组件添加信号
	component_added.emit(added_component)

	return added_component

# 移除组件
func remove_component(component_id: String) -> bool:
	if not component_manager:
		return false

	var component = component_manager.get_component(component_id)
	if not component:
		return false

	var result = component_manager.remove_component(component_id)

	# 发送组件移除信号
	if result:
		component_removed.emit(component)

	return result

# 获取组件
func get_component(component_name: String) -> Component:
	if not component_manager:
		return null

	return component_manager.get_component_by_name(component_name)

# 获取所有组件
func get_all_components() -> Array:
	if not component_manager:
		return []

	return component_manager.get_all_components()

# 从数据初始化
func initialize_from_data(data: Dictionary) -> void:
	# 设置基本属性
	id = data.get("id", "")
	display_name = data.get("name", "")
	description = data.get("description", "")
	level = data.get("level", 1)
	is_player_piece = data.get("is_player_piece", true)

	# 初始化属性
	var attribute_component = get_component("AttributeComponent")
	if attribute_component and data.has("attributes"):
		attribute_component.initialize_from_dict(data.attributes)

	# 初始化技能
	var ability_component = get_component("AbilityComponent")
	if ability_component and data.has("ability"):
		ability_component.initialize_ability(data.ability)

	# 初始化装备
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component and data.has("equipment"):
		equipment_component.initialize_from_dict(data.equipment)

	# 初始化羁绊
	var synergy_component = get_component("SynergyComponent")
	if synergy_component and data.has("synergies"):
		synergy_component.initialize_from_dict(data.synergies)

	# 标记为已初始化
	is_initialized = true

	# 发送初始化信号
	initialized.emit()

# 获取数据
func get_data() -> Dictionary:
	var data = {
		"id": id,
		"name": display_name,
		"description": description,
		"level": level,
		"is_player_piece": is_player_piece
	}

	# 获取属性数据
	var attribute_component = get_component("AttributeComponent")
	if attribute_component:
		data["attributes"] = attribute_component.get_all_attributes()

	# 获取技能数据
	var ability_component = get_component("AbilityComponent")
	if ability_component:
		data["ability"] = ability_component.get_ability_data()

	# 获取装备数据
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component:
		data["equipment"] = equipment_component.get_equipment_data()

	# 获取羁绊数据
	var synergy_component = get_component("SynergyComponent")
	if synergy_component:
		data["synergies"] = synergy_component.get_synergy_data()

	return data

# 设置目标
func set_target(target) -> void:
	var target_component = get_component("TargetComponent")
	if target_component:
		target_component.set_target(target)

# 清除目标
func clear_target() -> void:
	var target_component = get_component("TargetComponent")
	if target_component:
		target_component.clear_target()

# 获取目标
func get_target():
	var target_component = get_component("TargetComponent")
	if target_component:
		return target_component.get_target()
	return null

# 是否有目标
func has_target() -> bool:
	var target_component = get_component("TargetComponent")
	if target_component:
		return target_component.has_target()
	return false

# 造成伤害
func deal_damage(target, amount: float, damage_type: String = "physical", is_critical: bool = false) -> float:
	var combat_component = get_component("CombatComponent")
	if combat_component:
		return combat_component.deal_damage(target, amount, damage_type, is_critical)
	return 0.0

# 受到伤害
func take_damage(amount: float, damage_type: String = "physical", source = null) -> float:
	# 如果处于无敌状态，不受伤害
	if is_invulnerable:
		return 0.0

	var combat_component = get_component("CombatComponent")
	if combat_component:
		return combat_component.take_damage(source, amount, damage_type, false)
	return 0.0

# 治疗目标
func heal_target(target, amount: float) -> float:
	var combat_component = get_component("CombatComponent")
	if combat_component:
		return combat_component.heal_target(target, amount)
	return 0.0

# 接收治疗
func receive_healing(amount: float, source = null) -> float:
	var combat_component = get_component("CombatComponent")
	if combat_component:
		return combat_component.receive_healing(source, amount)
	return 0.0

# 使用技能
func use_ability() -> bool:
	var ability_component = get_component("AbilityComponent")
	if ability_component:
		return ability_component.cast_ability()
	return false

# 是否可以使用技能
func can_use_ability() -> bool:
	var ability_component = get_component("AbilityComponent")
	if ability_component:
		return ability_component.can_cast()
	return false

# 装备物品
func equip_item(equipment, slot: int) -> bool:
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component:
		return equipment_component.equip_item(equipment, slot)
	return false

# 卸下装备
func unequip_item(slot: int) -> bool:
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component:
		return equipment_component.unequip_item(slot)
	return false

# 获取装备
func get_equipment(slot: int):
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component:
		return equipment_component.get_equipment(slot)
	return null

# 获取所有装备
func get_all_equipment() -> Array:
	var equipment_component = get_component("EquipmentComponent")
	if equipment_component:
		return equipment_component.get_all_equipment()
	return []

# 添加羁绊类型
func add_synergy_type(synergy_type: String) -> void:
	var synergy_component = get_component("SynergyComponent")
	if synergy_component:
		synergy_component.add_synergy_type(synergy_type)

# 设置羁绊等级
func set_synergy_level(synergy_type: String, level: int) -> void:
	var synergy_component = get_component("SynergyComponent")
	if synergy_component:
		synergy_component.set_synergy_level(synergy_type, level)

# 获取羁绊等级
func get_synergy_level(synergy_type: String) -> int:
	var synergy_component = get_component("SynergyComponent")
	if synergy_component:
		return synergy_component.get_synergy_level(synergy_type)
	return 0

# 获取所有羁绊类型
func get_synergy_types() -> Array:
	var synergy_component = get_component("SynergyComponent")
	if synergy_component:
		return synergy_component.get_synergy_types()
	return []

# 设置棋子等级
func set_level(new_level: int) -> void:
	if new_level == level:
		return

	var old_level = level
	level = new_level

	# 更新属性
	var attribute_component = get_component("AttributeComponent")
	if attribute_component:
		# 根据等级调整属性
		var scale_factor = 1.0 + (level - 1) * 0.5  # 每级增加50%

		# 更新基础属性
		var base_attributes = attribute_component.get_all_base_attributes()
		for attribute_name in base_attributes:
			if attribute_name != "current_health" and attribute_name != "current_mana":
				var base_value = base_attributes[attribute_name]
				attribute_component.set_base_attribute(attribute_name, base_value * scale_factor)

		# 更新当前生命值和法力值
		var max_health = attribute_component.get_attribute("max_health")
		var max_mana = attribute_component.get_attribute("max_mana")
		attribute_component.set_health(max_health)
		attribute_component.set_mana(max_mana)

	# 发送等级变化信号
	level_changed.emit(old_level, level)

	# 发送事件
	EventBus.chess.emit_event("chess_piece_level_changed", [self, old_level, level])

# 获取棋子等级
func get_level() -> int:
	return level

# 是否是玩家棋子
func get_is_player_piece() -> bool:
	return is_player_piece

# 设置是否是玩家棋子
func set_is_player_piece(value: bool) -> void:
	is_player_piece = value

# 获取全局位置
#func get_global_position() -> Vector2:
	#return global_position

# 获取ID
func get_id() -> String:
	return id

# 获取显示名称
func get_display_name() -> String:
	return display_name

# 获取描述
func get_description() -> String:
	return description

# 是否死亡
func is_dead() -> bool:
	var attribute_component = get_component("AttributeComponent")
	if attribute_component:
		return attribute_component.is_dead()
	return false

# 重置棋子
func reset() -> void:
	# 重置属性
	var attribute_component = get_component("AttributeComponent")
	if attribute_component:
		attribute_component.reset_attributes()

	# 重置状态
	var state_machine_component = get_component("StateMachineComponent")
	if state_machine_component:
		state_machine_component.reset_state_machine()

	# 清除目标
	var target_component = get_component("TargetComponent")
	if target_component:
		target_component.clear_target()

	# 重置技能冷却
	var ability_component = get_component("AbilityComponent")
	if ability_component:
		ability_component.reset_cooldown()

	# 清除视觉效果
	var view_component = get_component("ViewComponent")
	if view_component:
		view_component.clear_visual_effects()

# 属性变化回调
func _on_attribute_changed(attribute_name: String, old_value, new_value) -> void:
	# 检查是否死亡
	if attribute_name == "current_health" and new_value <= 0:
		# 获取状态机组件
		var state_machine_component = get_component("StateMachineComponent")
		if state_machine_component:
			state_machine_component.change_state(state_machine_component.ChessState.DEAD)

		# 发送死亡信号
		died.emit()

		# 发送事件
		EventBus.chess.emit_event("chess_piece_died", [self])
		GlobalEventBus.battle.dispatch_event(BattleEvents.UnitDiedEvent.new(self))

# 状态变化回调
func _on_state_changed(old_state: int, new_state: int) -> void:
	# 获取状态机组件
	var state_machine_component = get_component("StateMachineComponent")
	if not state_machine_component:
		return

	# 如果进入死亡状态，发送死亡信号
	if new_state == state_machine_component.ChessState.DEAD:
		died.emit()

		# 发送事件
		EventBus.chess.emit_event("chess_piece_died", [self])
		GlobalEventBus.battle.dispatch_event(BattleEvents.UnitDiedEvent.new(self))

# 伤害回调
func _on_damage_taken(source, amount: float, damage_type: String, is_critical: bool) -> void:
	# 发送伤害信号
	damaged.emit(amount, source)

# 治疗回调
func _on_healing_received(source, amount: float) -> void:
	# 发送治疗信号
	healed.emit(amount, source)
