extends "res://scripts/managers/core/base_manager.gd"
class_name EventManager
## 事件管理器
## 负责事件的触发、选择和结果处理

# 事件相关常量
const EVENT_SCENE = preload("res://scenes/event/event.tscn")  # 事件场景

# 事件数据
var event_factory = {}  # 事件工厂，用于创建不同类型的事件
var current_event: Event = null  # 当前事件
var completed_events: Array = []  # 已完成的事件ID列表
var event_history: Array = []  # 事件历史记录


# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EventManager"
	# 添加依赖
	add_dependency("ConfigManager")

	# 原 _ready 函数的内容
	# 初始化事件工厂
	_initialize_event_factory()

	# 连接信号
	GlobalEventBus.map.add_listener("map_node_selected", _on_map_node_selected)

	# Add listeners for GameFlowEvents
	GlobalEventBus.gameflow.add_class_listener(GameFlowEvents.EventStateEnteredEvent, _on_event_state_entered)
	GlobalEventBus.gameflow.add_class_listener(GameFlowEvents.EventStateExitedEvent, _on_event_state_exited)

# 初始化事件工厂
func _initialize_event_factory() -> void:
	# 加载所有事件配置
	var events_config = GameManager.config_manager.get_all_events()

	# 创建事件工厂
	for event_id in events_config:
		var event_model = events_config[event_id] as EventConfig
		event_factory[event_id] = event_model.get_data()

# 触发事件
func trigger_event(event_id: String) -> bool:
	# 检查事件是否存在
	if not event_factory.has(event_id):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("事件不存在: " + event_id, 2))
		return false

	# 检查是否已有正在进行的事件
	if current_event != null:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("已有正在进行的事件", 1))
		return false

	# 创建事件实例
	var event = _create_event(event_id)
	if not event:
		return false

	# 设置为当前事件
	current_event = event

	# 开始事件
	event.start()

	# 记录事件历史
	_record_event(event_id)

	return true

# 创建事件实例
func _create_event(event_id: String) -> Event:
	# 检查事件是否存在
	if not event_factory.has(event_id):
		return null

	# 获取事件数据
	var event_data = event_factory[event_id]

	# 创建事件实例
	var event_instance = EVENT_SCENE.instantiate()
	add_child(event_instance)

	# 初始化事件
	event_instance.initialize(event_data)

	# 连接信号
	event_instance.event_completed.connect(_on_event_completed)

	return event_instance

# 随机触发事件
func trigger_random_event(context: Dictionary = {}, event_type: String = "") -> bool:
	# 获取符合条件的事件列表
	var eligible_events = _get_eligible_events(context, event_type)

	# 如果没有符合条件的事件，返回失败
	if eligible_events.is_empty():
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("没有符合条件的事件可触发", 1))
		return false

	# 根据权重随机选择一个事件
	var selected_event = _weighted_random_selection(eligible_events)

	# 触发选中的事件
	return trigger_event(selected_event)

# 获取符合条件的事件列表
func _get_eligible_events(context: Dictionary = {}, event_type: String = "") -> Array:
	var eligible_events = []

	for event_id in event_factory:
		var event_data = event_factory[event_id]

		# 检查事件类型
		if not event_type.is_empty() and event_data.event_type != event_type:
			continue

		# 检查是否为一次性事件且已完成
		if event_data.get("is_one_time", false) and completed_events.has(event_id):
			continue

		# 创建临时事件实例检查条件
		var temp_event = Event.new()
		temp_event.initialize(event_data)

		# 检查是否满足触发条件
		if temp_event.check_requirements(context):
			eligible_events.append({
				"id": event_id,
				"weight": event_data.get("weight", 100)
			})

		# 清理临时实例
		temp_event.queue_free()

	return eligible_events

# 根据权重随机选择事件
func _weighted_random_selection(events: Array) -> String:
	var total_weight = 0

	# 计算总权重
	for event in events:
		total_weight += event.weight

	# 随机选择
	var random_value = randi() % total_weight
	var current_weight = 0

	for event in events:
		current_weight += event.weight
		if random_value < current_weight:
			return event.id

	# 默认返回第一个事件
	return events[0].id if not events.is_empty() else ""

# 记录事件历史
func _record_event(event_id: String) -> void:
	event_history.append({
		"id": event_id,
		"timestamp": Time.get_unix_time_from_system()
	})

# 清理当前事件
func clear_current_event() -> void:
	if current_event:
		current_event.queue_free()
		current_event = null

# 事件完成事件处理
func _on_event_completed(result: Dictionary) -> void:
	# 记录已完成事件
	if current_event and current_event.is_one_time:
		completed_events.append(current_event.id)

	# 清理当前事件
	clear_current_event()

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 如果是事件节点，触发事件
	if node_data.type == "event":
		_handle_event_node(node_data)

# 处理事件节点
func _handle_event_node(node_data: Dictionary) -> void:
	# 如果指定了具体事件ID
	if node_data.has("event_id"):
		trigger_event(node_data.event_id)
	# 如果指定了事件类型
	elif node_data.has("event_type"):
		trigger_random_event({}, node_data.event_type)
	# 随机事件
	else:
		trigger_random_event()

# 获取事件数据
func get_event_data(event_id: String) -> Dictionary:
	if event_factory.has(event_id):
		return event_factory[event_id].duplicate()
	else:
		# 尝试从配置管理器获取
		var event_model = GameManager.config_manager.get_event_config(event_id)
		if event_model:
			return event_model.get_data()
	return {}

# 获取已完成事件列表
func get_completed_events() -> Array:
	return completed_events.duplicate()

# 获取事件历史记录
func get_event_history() -> Array:
	return event_history.duplicate()

# 保存事件状态
func save_events_state() -> Dictionary:
	return {
		"completed_events": completed_events.duplicate(),
		"event_history": event_history.duplicate()
	}

# 加载事件状态
func load_events_state(save_data: Dictionary) -> void:
	if save_data.has("completed_events"):
		completed_events = save_data.completed_events.duplicate()

	if save_data.has("event_history"):
		event_history = save_data.event_history.duplicate()

# 重置事件状态
func reset_events() -> void:
	completed_events.clear()
	event_history.clear()
	clear_current_event()

# 修改事件权重
func modify_event_weight(event_id: String, weight_modifier: float) -> void:
	# 检查事件是否存在
	if not event_factory.has(event_id):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("事件不存在: " + event_id, 2))
		return

	# 获取当前权重
	var current_weight = event_factory[event_id].weight

	# 计算新权重
	var new_weight = max(1, current_weight + weight_modifier)

	# 更新权重
	event_factory[event_id].weight = new_weight

	# 发送事件权重修改信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("事件权重修改: " + event_id + ", " + str(current_weight) + " -> " + str(new_weight), 0))

# 获取事件权重
func get_event_weight(event_id: String) -> int:
	if event_factory.has(event_id):
		return event_factory[event_id].weight
	return 0

# 创建随机事件
func create_random_event() -> Event:
	# 获取所有事件配置
	var all_events = event_factory.keys()

	# 按类型分类事件
	var events_by_type = {}
	for event_id in all_events:
		var event_data = event_factory[event_id]
		var event_type = event_data.get("event_type", "general")

		if not events_by_type.has(event_type):
			events_by_type[event_type] = []
		events_by_type[event_type].append(event_id)

	# 随机选择事件类型
	var event_types = events_by_type.keys()
	var random_type = event_types[randi() % event_types.size()]

	# 从选中类型中随机选择事件
	var type_events = events_by_type[random_type]
	var random_event_id = type_events[randi() % type_events.size()]

	# 创建事件
	return _create_event(random_event_id)

# 创建指定类型的随机事件
func create_random_event_by_type(event_type: String) -> Event:
	# 获取所有事件配置
	var all_events = event_factory.keys()

	# 筛选指定类型的事件
	var type_events = []
	for event_id in all_events:
		var event_data = event_factory[event_id]
		if event_data.get("event_type", "general") == event_type:
			type_events.append(event_id)

	# 如果没有指定类型的事件，返回随机事件
	if type_events.is_empty():
		return create_random_event()

	# 随机选择事件
	var random_event_id = type_events[randi() % type_events.size()]

	# 创建事件
	return _create_event(random_event_id)

# 创建指定难度的随机事件
func create_random_event_by_difficulty(difficulty: String) -> Event:
	# 获取所有事件配置
	var all_events = event_factory.keys()

	# 筛选指定难度的事件
	var difficulty_events = []
	for event_id in all_events:
		var event_data = event_factory[event_id]
		if event_data.get("difficulty", "normal") == difficulty:
			difficulty_events.append(event_id)

	# 如果没有指定难度的事件，返回随机事件
	if difficulty_events.is_empty():
		return create_random_event()

	# 随机选择事件
	var random_event_id = difficulty_events[randi() % difficulty_events.size()]

	# 创建事件
	return _create_event(random_event_id)

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	GlobalEventBus.map.remove_listener("map_node_selected", _on_map_node_selected)

	# Remove listeners for GameFlowEvents
	GlobalEventBus.gameflow.remove_class_listener(GameFlowEvents.EventStateEnteredEvent, _on_event_state_entered)
	GlobalEventBus.gameflow.remove_class_listener(GameFlowEvents.EventStateExitedEvent, _on_event_state_exited)

	# 清理当前事件
	clear_current_event()

	# 清理事件工厂和历史记录
	event_factory.clear()
	completed_events.clear()
	event_history.clear()

	_log_info("事件管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 重置事件状态
	reset_events()

	_log_info("事件管理器重置完成")


# GameFlow Event Handlers
func _on_event_state_entered(event: GameFlowEvents.EventStateEnteredEvent) -> void:
	_log_info("EventStateEnteredEvent received, triggering event...")
	if event.params and event.params.has("event_id"):
		var event_id = event.params.get("event_id")
		if not event_id.is_empty():
			trigger_event(event_id)
		else:
			_log_warning("EventStateEnteredEvent: 'event_id' in params is empty. Triggering random event.")
			trigger_random_event(event.params.get("context", {}), event.params.get("event_type", ""))
	elif event.params and event.params.has("event_type"):
		_log_info("EventStateEnteredEvent: 'event_type' found in params. Triggering random event of type: " + event.params.event_type)
		trigger_random_event(event.params.get("context", {}), event.params.event_type)
	else:
		_log_warning("EventStateEnteredEvent: No 'event_id' or 'event_type' in params. Triggering a completely random event.")
		trigger_random_event() # Fallback to a completely random event if no specific id or type is provided

func _on_event_state_exited(_event: GameFlowEvents.EventStateExitedEvent) -> void:
	_log_info("EventStateExitedEvent received, clearing current event...")
	clear_current_event()
