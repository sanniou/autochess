extends Node
## 组件系统初始化器
## 负责初始化组件系统

## 组件系统管理器
var component_system_manager: ComponentSystemManager = null

## 初始化
func _ready() -> void:
	# 创建组件系统管理器
	component_system_manager = ComponentSystemManager.new()
	component_system_manager.name = "ComponentSystemManager"
	add_child(component_system_manager)
	
	# 注册到游戏管理器
	if GameManager:
		GameManager.register_manager("ComponentSystemManager", component_system_manager)
	
	# 注册现有的组件管理器
	_register_existing_component_managers()
	
	print("[ComponentSystemInitializer] 组件系统初始化完成")

## 注册现有的组件管理器
func _register_existing_component_managers() -> void:
	# 查找场景中的所有组件管理器
	var component_managers = get_tree().get_nodes_in_group("component_managers")
	
	for manager in component_managers:
		if manager is ComponentManager:
			component_system_manager.register_component_manager(manager)
	
	print("[ComponentSystemInitializer] 已注册 %d 个组件管理器" % component_managers.size())
