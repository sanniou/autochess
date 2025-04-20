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
var owner = null

# 初始化
func _init(p_owner = null):
	owner = p_owner

# 添加组件
func add_component(component: Component) -> Component:
	# 设置组件所有者
	component.set_owner(owner)
	
	# 初始化组件
	component.initialize()
	
	# 添加到组件字典
	components[component.get_id()] = component
	
	# 添加到名称字典
	var name = component.get_name()
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
	
	# 发送信号
	component_added.emit(component)
	
	return component

# 移除组件
func remove_component(component_id: String) -> bool:
	if not components.has(component_id):
		return false
	
	var component = components[component_id]
	
	# 从组件字典移除
	components.erase(component_id)
	
	# 从名称字典移除
	var name = component.get_name()
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
	
	# 销毁组件
	component.destroy()
	
	# 发送信号
	component_removed.emit(component)
	
	return true

# 获取组件
func get_component(component_id: String) -> Component:
	return components.get(component_id)

# 获取组件（按名称）
func get_component_by_name(name: String) -> Component:
	if components_by_name.has(name) and not components_by_name[name].is_empty():
		return components_by_name[name][0]
	return null

# 获取所有组件（按名称）
func get_components_by_name(name: String) -> Array:
	if components_by_name.has(name):
		return components_by_name[name].duplicate()
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
	for component_id in update_order:
		if components.has(component_id):
			var component = components[component_id]
			if component.is_enabled:
				component.update(delta)

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
	
	# 断开所有信号
	for component in components.values():
		if component.enabled.is_connected(_on_component_enabled):
			component.enabled.disconnect(_on_component_enabled)
		if component.disabled.is_connected(_on_component_disabled):
			component.disabled.disconnect(_on_component_disabled)
		
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

# 组件禁用回调
func _on_component_disabled(component: Component) -> void:
	component_disabled.emit(component)
