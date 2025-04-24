extends Node
class_name ComponentSystemManager
## 组件系统管理器
## 管理组件系统的全局状态和配置

## 组件更新系统
var update_system: ComponentUpdateSystem = null

## 组件管理器列表
var component_managers: Array = []

## 调试模式
var debug_mode: bool = false

## 初始化
func _ready() -> void:
	# 创建组件更新系统
	update_system = ComponentUpdateSystem.new()
	add_child(update_system)
	
	# 设置调试模式
	debug_mode = OS.is_debug_build()
	update_system.set_collect_stats(debug_mode)
	
	# 注册事件监听器
	if GlobalEventBus:
		GlobalEventBus.get_group("component").add_listener("added", _on_component_added)
		GlobalEventBus.get_group("component").add_listener("removed", _on_component_removed)
		GlobalEventBus.get_group("component").add_listener("enabled", _on_component_enabled)
		GlobalEventBus.get_group("component").add_listener("disabled", _on_component_disabled)

## 注册组件管理器
## @param manager 组件管理器
func register_component_manager(manager: ComponentManager) -> void:
	if not component_managers.has(manager):
		component_managers.append(manager)
		
		# 注册现有组件
		for component in manager.components.values():
			_register_component(component)

## 取消注册组件管理器
## @param manager 组件管理器
func unregister_component_manager(manager: ComponentManager) -> void:
	if component_managers.has(manager):
		component_managers.erase(manager)
		
		# 取消注册组件
		for component in manager.components.values():
			_unregister_component(component)

## 注册组件
## @param component 组件
func _register_component(component: Component) -> void:
	# 根据组件类型设置更新频率
	var component_type = component.get_script().resource_path.get_file().get_basename()
	var update_frequency = ComponentUpdateSystem.UpdateFrequency.EVERY_FRAME
	
	# 根据组件类型设置更新频率
	match component_type:
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
	
	# 注册到更新系统
	update_system.register_component(component, update_frequency)

## 取消注册组件
## @param component 组件
func _unregister_component(component: Component) -> void:
	update_system.unregister_component(component)

## 组件添加事件处理
## @param event 组件添加事件
func _on_component_added(event: ComponentEvents.ComponentAddedEvent) -> void:
	_register_component(event.component)

## 组件移除事件处理
## @param event 组件移除事件
func _on_component_removed(event: ComponentEvents.ComponentRemovedEvent) -> void:
	_unregister_component(event.component)

## 组件启用事件处理
## @param event 组件启用事件
func _on_component_enabled(event: ComponentEvents.ComponentEnabledEvent) -> void:
	# 可以在这里添加额外的启用逻辑
	pass

## 组件禁用事件处理
## @param event 组件禁用事件
func _on_component_disabled(event: ComponentEvents.ComponentDisabledEvent) -> void:
	# 可以在这里添加额外的禁用逻辑
	pass

## 获取性能统计
## @return 性能统计字典
func get_performance_stats() -> Dictionary:
	return update_system.get_performance_stats()

## 获取昂贵的组件
## @param threshold_ms 阈值（毫秒）
## @return 昂贵组件列表
func get_expensive_components(threshold_ms: float = 1.0) -> Array:
	return update_system.get_expensive_components(threshold_ms)

## 清除性能统计
func clear_performance_stats() -> void:
	update_system.clear_performance_stats()

## 获取组件数量
## @return 组件数量字典
func get_component_counts() -> Dictionary:
	return update_system.get_component_counts()

## 设置是否收集性能统计
## @param collect 是否收集
func set_collect_stats(collect: bool) -> void:
	update_system.set_collect_stats(collect)
