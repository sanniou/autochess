extends Node
class_name ComponentManager
## 组件管理器
## 管理实体的所有组件

# 信号
signal component_added(component)
signal component_removed(component)
signal component_enabled(component)
signal component_disabled(component)

# 组件列表
var components: Dictionary = {}  # 组件字典 {组件ID: 组件}
var components_by_name: Dictionary = {}  # 按名称组织的组件字典 {组件名称: [组件列表]}
var components_by_type: Dictionary = {}  # 按类型组织的组件字典 {组件类型: [组件列表]}
var update_order: Array = []  # 更新顺序

# 所有者
var component_owner = null

# 更新系统
var update_system: ComponentUpdateSystem = null

# 初始化
func _init(p_owner = null):
	component_owner = p_owner

	# 创建更新系统
	update_system = ComponentUpdateSystem.new()
	add_child(update_system)

# 添加组件
func add_component(component: Component) -> Component:
	# 设置组件所有者
	component.set_owner(owner)

	# 初始化组件
	component.initialize()

	# 添加到组件字典
	components[component.get_id()] = component

	# 添加到名称字典
	var name = component.get_component_name()
	if not components_by_name.has(name):
		components_by_name[name] = []
	components_by_name[name].append(component)

	# 添加到类型字典
	var type = component.get_script().resource_path.get_file().get_basename()
	if not components_by_type.has(type):
		components_by_type[type] = []
	components_by_type[type].append(component)

	# 更新排序
	_update_sort_order()

	# 连接信号
	component.enabled.connect(_on_component_enabled.bind(component))
	component.disabled.connect(_on_component_disabled.bind(component))

	# 注册到更新系统
	var update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_FRAME

	# 根据组件类型设置更新频率
	match type:
		"AttributeComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_SECOND
		"ViewComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_FRAME
		"CombatComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_PHYSICS
		"AbilityComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_PHYSICS
		"TargetComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_PHYSICS
		"StateMachineComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_PHYSICS
		"EquipmentComponent":
			update_frequency = ComponentUpdateSystem.UpdateFrequency.ON_DEMAND

	update_system.register_component(component, update_frequency)

	# 发送信号
	component_added.emit(component)

	# 发送组件添加事件
	if GlobalEventBus:
		var event = ComponentEvents.ComponentAddedEvent.new(component_owner, component)
		GlobalEventBus.get_group("component").dispatch_event(event)

	return component

# 移除组件
func remove_component(component_id: String) -> bool:
	if not components.has(component_id):
		return false

	var component = components[component_id]

	# 从更新系统取消注册
	update_system.unregister_component(component)

	# 从组件字典移除
	components.erase(component_id)

	# 从名称字典移除
	var name = component.get_component_name()
	if components_by_name.has(name):
		components_by_name[name].erase(component)
		if components_by_name[name].is_empty():
			components_by_name.erase(name)

	# 从类型字典移除
	var type = component.get_script().resource_path.get_file().get_basename()
	if components_by_type.has(type):
		components_by_type[type].erase(component)
		if components_by_type[type].is_empty():
			components_by_type.erase(type)

	# 更新排序
	_update_sort_order()

	# 断开信号
	if component.enabled.is_connected(_on_component_enabled):
		component.enabled.disconnect(_on_component_enabled)
	if component.disabled.is_connected(_on_component_disabled):
		component.disabled.disconnect(_on_component_disabled)

	# 发送组件移除事件
	if GlobalEventBus:
		var event = ComponentEvents.ComponentRemovedEvent.new(component_owner, component)
		GlobalEventBus.get_group("component").dispatch_event(event)

	# 销毁组件
	component.destroy()

	# 发送信号
	component_removed.emit(component)

	return true

# 获取组件
func get_component(component_id: String) -> Component:
	return components.get(component_id)

# 获取组件（按名称）
func get_component_by_name(_name: String) -> Component:
	if components_by_name.has(_name) and not components_by_name[_name].is_empty():
		return components_by_name[_name][0]
	return null

# 获取所有组件（按名称）
func get_components_by_name(_name: String) -> Array:
	if components_by_name.has(_name):
		return components_by_name[_name].duplicate()
	return []

# 获取所有组件（按类型）
func get_components_by_type(type: String) -> Array:
	if components_by_type.has(type):
		return components_by_type[type].duplicate()
	return []

# 获取所有组件
func get_all_components() -> Array:
	return components.values()

# 更新所有组件
func update(delta: float) -> void:
	# 注意：此方法保留用于向后兼容
	# 实际更新由ComponentUpdateSystem处理
	pass

# 启用所有组件
func enable_all() -> void:
	for component in components.values():
		component.enable()

# 禁用所有组件
func disable_all() -> void:
	for component in components.values():
		component.disable()

# 清空所有组件
func clear() -> void:
	# 禁用所有组件
	disable_all()

	# 断开所有信号并从更新系统取消注册
	for component in components.values():
		# 从更新系统取消注册
		update_system.unregister_component(component)

		# 断开信号
		if component.enabled.is_connected(_on_component_enabled):
			component.enabled.disconnect(_on_component_enabled)
		if component.disabled.is_connected(_on_component_disabled):
			component.disabled.disconnect(_on_component_disabled)

		# 发送组件移除事件
		if GlobalEventBus:
			var event = ComponentEvents.ComponentRemovedEvent.new(component_owner, component)
			GlobalEventBus.get_group("component").dispatch_event(event)

		# 销毁组件
		component.destroy()

	# 清空字典
	components.clear()
	components_by_name.clear()
	components_by_type.clear()
	update_order.clear()

# 更新排序顺序
func _update_sort_order() -> void:
	# 创建临时数组
	var temp_array = []

	# 添加所有组件
	for component_id in components:
		temp_array.append({
			"id": component_id,
			"priority": components[component_id].get_priority()
		})

	# 按优先级排序
	temp_array.sort_custom(func(a, b): return a.priority > b.priority)

	# 更新排序顺序
	update_order.clear()
	for item in temp_array:
		update_order.append(item.id)

# 组件启用回调
func _on_component_enabled(component: Component) -> void:
	component_enabled.emit(component)

	# 发送组件启用事件
	if GlobalEventBus:
		var event = ComponentEvents.ComponentEnabledEvent.new(component_owner, component)
		GlobalEventBus.get_group("component").dispatch_event(event)

# 组件禁用回调
func _on_component_disabled(component: Component) -> void:
	component_disabled.emit(component)

	# 发送组件禁用事件
	if GlobalEventBus:
		var event = ComponentEvents.ComponentDisabledEvent.new(component_owner, component)
		GlobalEventBus.get_group("component").dispatch_event(event)
