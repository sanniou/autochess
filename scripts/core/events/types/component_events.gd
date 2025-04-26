extends RefCounted
class_name ComponentEvents
## 组件事件类型
## 定义与组件系统相关的事件

## 组件添加事件
class ComponentAddedEvent extends BusEvent:
	## 实体
	var entity
	
	## 组件
	var component: Component
	
	## 初始化
	func _init(p_entity, p_component: Component):
		entity = p_entity
		component = p_component
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.added"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ComponentAddedEvent[entity=%s, component=%s]" % [entity, component.get_component_name()]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = ComponentAddedEvent.new(entity, component)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 组件移除事件
class ComponentRemovedEvent extends BusEvent:
	## 实体
	var entity
	
	## 组件
	var component: Component
	
	## 初始化
	func _init(p_entity, p_component: Component):
		entity = p_entity
		component = p_component
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.removed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ComponentRemovedEvent[entity=%s, component=%s]" % [entity, component.get_component_name()]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = ComponentRemovedEvent.new(entity, component)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 组件启用事件
class ComponentEnabledEvent extends BusEvent:
	## 实体
	var entity
	
	## 组件
	var component: Component
	
	## 初始化
	func _init(p_entity, p_component: Component):
		entity = p_entity
		component = p_component
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.enabled"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ComponentEnabledEvent[entity=%s, component=%s]" % [entity, component.get_component_name()]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = ComponentEnabledEvent.new(entity, component)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 组件禁用事件
class ComponentDisabledEvent extends BusEvent:
	## 实体
	var entity
	
	## 组件
	var component: Component
	
	## 初始化
	func _init(p_entity, p_component: Component):
		entity = p_entity
		component = p_component
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.disabled"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ComponentDisabledEvent[entity=%s, component=%s]" % [entity, component.get_component_name()]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = ComponentDisabledEvent.new(entity, component)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 属性变化事件
class AttributeChangedEvent extends BusEvent:
	## 实体
	var entity
	
	## 属性名称
	var attribute_name: String
	
	## 旧值
	var old_value: Variant
	
	## 新值
	var new_value: Variant
	
	## 初始化
	func _init(p_entity, p_attribute_name: String, p_old_value: Variant, p_new_value: Variant):
		entity = p_entity
		attribute_name = p_attribute_name
		old_value = p_old_value
		new_value = p_new_value
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.attribute_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AttributeChangedEvent[entity=%s, attribute=%s, old=%s, new=%s]" % [
			entity, attribute_name, old_value, new_value
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AttributeChangedEvent.new(entity, attribute_name, old_value, new_value)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 状态变化事件
class StateChangedEvent extends BusEvent:
	## 实体
	var entity
	
	## 旧状态
	var old_state: int
	
	## 新状态
	var new_state: int
	
	## 状态名称映射
	var state_names: Dictionary
	
	## 初始化
	func _init(p_entity, p_old_state: int, p_new_state: int, p_state_names: Dictionary = {}):
		entity = p_entity
		old_state = p_old_state
		new_state = p_new_state
		state_names = p_state_names
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.state_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		var old_state_name = state_names.get(old_state, str(old_state))
		var new_state_name = state_names.get(new_state, str(new_state))
		return "StateChangedEvent[entity=%s, old_state=%s, new_state=%s]" % [
			entity, old_state_name, new_state_name
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = StateChangedEvent.new(entity, old_state, new_state, state_names.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 目标变化事件
class TargetChangedEvent extends BusEvent:
	## 实体
	var entity
	
	## 旧目标
	var old_target
	
	## 新目标
	var new_target
	
	## 初始化
	func _init(p_entity, p_old_target, p_new_target):
		entity = p_entity
		old_target = p_old_target
		new_target = p_new_target
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.target_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TargetChangedEvent[entity=%s, old_target=%s, new_target=%s]" % [
			entity, old_target, new_target
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = TargetChangedEvent.new(entity, old_target, new_target)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 伤害事件
class DamageEvent extends BusEvent:
	## 伤害来源
	var source_entity
	
	## 伤害目标
	var target_entity
	
	## 伤害数值
	var amount: float
	
	## 伤害类型
	var damage_type: String
	
	## 是否暴击
	var is_critical: bool
	
	## 初始化
	func _init(p_source_entity, p_target_entity, p_amount: float, p_damage_type: String, p_is_critical: bool = false):
		source_entity = p_source_entity
		target_entity = p_target_entity
		amount = p_amount
		damage_type = p_damage_type
		is_critical = p_is_critical
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.damage"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "DamageEvent[source=%s, target=%s, amount=%.1f, type=%s, critical=%s]" % [
			source_entity, target_entity, amount, damage_type, is_critical
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = DamageEvent.new(source_entity, target_entity, amount, damage_type, is_critical)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 治疗事件
class HealEvent extends BusEvent:
	## 治疗来源
	var source_entity
	
	## 治疗目标
	var target_entity
	
	## 治疗数值
	var amount: float
	
	## 初始化
	func _init(p_source_entity, p_target_entity, p_amount: float):
		source_entity = p_source_entity
		target_entity = p_target_entity
		amount = p_amount
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.heal"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "HealEvent[source=%s, target=%s, amount=%.1f]" % [
			source_entity, target_entity, amount
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = HealEvent.new(source_entity, target_entity, amount)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 技能使用事件
class AbilityUsedEvent extends BusEvent:
	## 施法者
	var caster
	
	## 技能ID
	var ability_id: String
	
	## 技能名称
	var ability_name: String
	
	## 目标
	var target
	
	## 技能数据
	var ability_data: Dictionary
	
	## 初始化
	func _init(p_caster, p_ability_id: String, p_ability_name: String, p_target, p_ability_data: Dictionary = {}):
		caster = p_caster
		ability_id = p_ability_id
		ability_name = p_ability_name
		target = p_target
		ability_data = p_ability_data
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.ability_used"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AbilityUsedEvent[caster=%s, ability=%s, target=%s]" % [
			caster, ability_name, target
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AbilityUsedEvent.new(caster, ability_id, ability_name, target, ability_data.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 装备事件
class EquipmentEvent extends BusEvent:
	## 实体
	var entity
	
	## 装备
	var equipment
	
	## 槽位
	var slot: int
	
	## 初始化
	func _init(p_entity, p_equipment, p_slot: int):
		entity = p_entity
		equipment = p_equipment
		slot = p_slot
	
	## 获取事件类型
	static func get_type() -> String:
		return "component.equipment_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentEvent[entity=%s, equipment=%s, slot=%d]" % [
			entity, equipment, slot
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = EquipmentEvent.new(entity, equipment, slot)
		event.timestamp = timestamp
		event.canceled = canceled

		return event
