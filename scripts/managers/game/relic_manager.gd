extends "res://scripts/managers/core/base_manager.gd"
class_name RelicManager
## 遗物管理器
## 负责遗物的获取、激活和效果触发

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")
const RelicConsts = preload("res://scripts/constants/relic_constants.gd")

# 遗物相关常量
const MAX_RELICS = 6  # 最大遗物数量
const RELIC_SCENE = preload("res://scenes/relic/relic.tscn")  # 遗物场景

# 遗物数据
var player_relics: Array = []  # 玩家拥有的遗物
var available_relics: Array = []  # 可获取的遗物池
var relic_factory = {}  # 遗物工厂，用于创建不同类型的遗物

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "RelicManager"
	# 添加依赖
	add_dependency("ConfigManager")

	# 原 _ready 函数的内容
	# 初始化遗物工厂
	_initialize_relic_factory()

	# 初始化可获取的遗物池
	_initialize_available_relics()

	# 连接信号
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)
	EventBus.event.connect_event("event_completed", _on_event_completed)
	EventBus.map.connect_event("map_node_selected", _on_map_node_selected)

	# 初始化遗物工厂
func _initialize_relic_factory() -> void:
	# 加载所有遗物配置
	var relics_config = ConfigManager.get_all_relics()

	# 创建遗物工厂
	for relic_id in relics_config:
		var relic_model = relics_config[relic_id] as RelicConfig
		if relic_model:
			# 获取完整数据
			var relic_data = relic_model.get_data()

			# 确保触发条件字段存在
			if not relic_data.has("trigger_conditions"):
				relic_data["trigger_conditions"] = {}

			# 存储到工厂
			relic_factory[relic_id] = relic_data
		else:
			_log_warning("无法加载遗物配置: " + relic_id)

# 初始化可获取的遗物池
func _initialize_available_relics() -> void:
	available_relics.clear()

	# 添加所有遗物到可获取池
	for relic_id in relic_factory:
		available_relics.append(relic_id)

# 获取遗物
func acquire_relic(relic_id: String, player = null) -> Relic:
	# 检查是否已达到最大遗物数量
	if player_relics.size() >= MAX_RELICS:
		EventBus.debug.emit_event("debug_message", ["已达到最大遗物数量", 1])
		return null

	# 检查遗物是否存在
	if not relic_factory.has(relic_id):
		EventBus.debug.emit_event("debug_message", ["遗物不存在: " + relic_id, 2])
		return null

	# 创建遗物实例
	var relic = _create_relic(relic_id)
	if not relic:
		return null

	# 设置遗物拥有者
	relic.owner_player = player

	# 添加到玩家遗物列表
	player_relics.append(relic)

	# 如果是被动遗物，立即激活
	if relic.is_passive:
		relic.activate()

	# 发送遗物获取信号
	EventBus.relic.emit_event("relic_acquired", [relic])

	return relic

# 创建遗物实例
func _create_relic(relic_id: String) -> Relic:
	# 检查遗物是否存在
	if not relic_factory.has(relic_id):
		return null

	# 获取遗物数据
	var relic_data = relic_factory[relic_id].duplicate(true) # 深度复制以避免修改原始数据

	# 创建遗物实例
	var relic_instance = RELIC_SCENE.instantiate()
	add_child(relic_instance)

	# 确保触发条件字段存在
	if not relic_data.has("trigger_conditions"):
		relic_data["trigger_conditions"] = {}

	# 初始化遗物
	relic_instance.initialize(relic_data)

	return relic_instance

# 激活遗物
func activate_relic(relic_id: String) -> bool:
	# 查找遗物
	var relic = _find_relic(relic_id)
	if not relic:
		return false

	# 激活遗物
	return relic.activate()

# 触发遗物效果
func trigger_relic_effect(trigger_type: String, context: Dictionary = {}) -> void:
	# 遍历所有遗物，触发对应类型的效果
	for relic in player_relics:
		if relic.is_active:
			relic.trigger_effect(trigger_type, context)

# 更新遗物状态
func update(delta: float) -> void:
	# 更新所有遗物状态
	for relic in player_relics:
		relic.update(delta)

# 移除遗物
func remove_relic(relic_id: String) -> bool:
	# 查找遗物
	var relic = _find_relic(relic_id)
	if not relic:
		return false

	# 停用遗物
	relic.deactivate()

	# 从列表中移除
	player_relics.erase(relic)

	# 销毁遗物
	relic.queue_free()

	return true

# 查找遗物
func _find_relic(relic_id: String) -> Relic:
	for relic in player_relics:
		if relic.id == relic_id:
			return relic
	return null

# 获取随机遗物
func get_random_relic(rarity_filter: int = -1, exclude_ids: Array = []) -> String:
	var filtered_relics = []

	# 过滤遗物
	for relic_id in available_relics:
		# 排除已有遗物
		if exclude_ids.has(relic_id):
			continue

		# 应用稀有度过滤
		if rarity_filter >= 0:
			var relic_data = relic_factory[relic_id]
			if relic_data.rarity != rarity_filter:
				continue

		filtered_relics.append(relic_id)

	# 如果没有符合条件的遗物，返回空
	if filtered_relics.is_empty():
		return ""

	# 随机选择一个遗物
	return filtered_relics[randi() % filtered_relics.size()]

# 获取多个随机遗物
func get_random_relics(count: int, rarity_filter: int = -1, exclude_ids: Array = []) -> Array:
	var result = []
	var remaining_relics = available_relics.duplicate()

	# 移除排除的遗物
	for exclude_id in exclude_ids:
		remaining_relics.erase(exclude_id)

	# 应用稀有度过滤
	if rarity_filter >= 0:
		for i in range(remaining_relics.size() - 1, -1, -1):
			var relic_id = remaining_relics[i]
			var relic_data = relic_factory[relic_id]
			if relic_data.rarity != rarity_filter:
				remaining_relics.remove_at(i)

	# 随机选择指定数量的遗物
	for _i in range(count):
		if remaining_relics.is_empty():
			break

		var index = randi() % remaining_relics.size()
		result.append(remaining_relics[index])
		remaining_relics.remove_at(index)

	return result

# 获取玩家所有遗物
func get_player_relics() -> Array:
	return player_relics.duplicate()

# 获取遗物数据
func get_relic_data(relic_id: String) -> Dictionary:
	if relic_factory.has(relic_id):
		return relic_factory[relic_id].duplicate()
	else:
		# 尝试从配置管理器获取
		var relic_model = ConfigManager.get_relic_config(relic_id)
		if relic_model:
			return relic_model.get_data()
	return {}

# 战斗结束事件处理
func _on_battle_ended(result: Dictionary) -> void:
	# 如果战斗胜利，触发战斗胜利效果
	if result.is_victory:
		trigger_relic_effect(EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_BATTLE_VICTORY], result)
	else:
		trigger_relic_effect(EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_BATTLE_DEFEAT], result)

	# 触发战斗结束效果
	trigger_relic_effect(EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_BATTLE_END], result)

# 事件完成事件处理
func _on_event_completed(event_data: Dictionary, result_data: Dictionary) -> void:
	# 触发事件完成效果
	var context = {
		"event": event_data,
		"result": result_data
	}
	trigger_relic_effect(EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_EVENT_COMPLETED], context)

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 如果是宝藏节点，可能会获得遗物
	if node_data.type == "treasure":
		_handle_treasure_node(node_data)

	# 触发地图节点选择效果
	trigger_relic_effect(EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_MAP_NODE_SELECTED], {"node": node_data})

# 处理宝藏节点
func _handle_treasure_node(node_data: Dictionary) -> void:
	# 检查是否包含遗物奖励
	if node_data.has("rewards") and node_data.rewards.has("relic"):
		var relic_data = node_data.rewards.relic

		# 如果指定了具体遗物ID
		if relic_data.has("id"):
			acquire_relic(relic_data.id)
		# 如果指定了稀有度
		elif relic_data.has("rarity"):
			var relic_id = get_random_relic(relic_data.rarity)
			if not relic_id.is_empty():
				acquire_relic(relic_id)
		# 随机遗物
		else:
			var relic_id = get_random_relic()
			if not relic_id.is_empty():
				acquire_relic(relic_id)

# 清理所有遗物
func clear_all_relics() -> void:
	# 停用并移除所有遗物
	for relic in player_relics:
		relic.deactivate()
		relic.queue_free()

	player_relics.clear()

# 保存遗物状态
func save_relics_state() -> Array:
	var save_data = []

	for relic in player_relics:
		save_data.append({
			"id": relic.id,
			"is_active": relic.is_active,
			"charges": relic.charges,
			"current_cooldown": relic.current_cooldown
		})

	return save_data

# 加载遗物状态
func load_relics_state(save_data: Array, player = null) -> void:
	# 清理现有遗物
	clear_all_relics()

	# 加载遗物
	for relic_data in save_data:
		var relic = acquire_relic(relic_data.id, player)
		if relic:
			relic.is_active = relic_data.is_active
			relic.charges = relic_data.charges
			relic.current_cooldown = relic_data.current_cooldown

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.battle.disconnect_event("battle_ended", _on_battle_ended)
			EventBus.event.disconnect_event("event_completed", _on_event_completed)
			EventBus.map.disconnect_event("map_node_selected", _on_map_node_selected)

	# 清理遗物
	clear_all_relics()

	# 清理遗物工厂和可获取池
	relic_factory.clear()
	available_relics.clear()

	_log_info("遗物管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 清理遗物
	clear_all_relics()

	# 重新初始化可获取的遗物池
	_initialize_available_relics()

	_log_info("遗物管理器重置完成")
