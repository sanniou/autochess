extends Node
class_name RelicManager
## 遗物管理器
## 负责遗物的获取、激活和效果触发

# 遗物相关常量
const MAX_RELICS = 6  # 最大遗物数量
const RELIC_SCENE = preload("res://scenes/relic/relic.tscn")  # 遗物场景

# 遗物数据
var player_relics: Array = []  # 玩家拥有的遗物
var available_relics: Array = []  # 可获取的遗物池
var relic_factory = {}  # 遗物工厂，用于创建不同类型的遗物

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

func _ready():
	# 初始化遗物工厂
	_initialize_relic_factory()
	
	# 初始化可获取的遗物池
	_initialize_available_relics()
	
	# 连接信号
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.event_completed.connect(_on_event_completed)
	EventBus.map_node_selected.connect(_on_map_node_selected)

# 初始化遗物工厂
func _initialize_relic_factory() -> void:
	# 加载所有遗物配置
	var relics_config = config_manager.get_all_relics()
	
	# 创建遗物工厂
	for relic_id in relics_config:
		var relic_data = relics_config[relic_id]
		relic_factory[relic_id] = relic_data

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
		EventBus.debug_message.emit("已达到最大遗物数量", 1)
		return null
	
	# 检查遗物是否存在
	if not relic_factory.has(relic_id):
		EventBus.debug_message.emit("遗物不存在: " + relic_id, 2)
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
	EventBus.relic_acquired.emit(relic)
	
	return relic

# 创建遗物实例
func _create_relic(relic_id: String) -> Relic:
	# 检查遗物是否存在
	if not relic_factory.has(relic_id):
		return null
	
	# 获取遗物数据
	var relic_data = relic_factory[relic_id]
	
	# 创建遗物实例
	var relic_instance = RELIC_SCENE.instantiate()
	add_child(relic_instance)
	
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
	return {}

# 战斗结束事件处理
func _on_battle_ended(result: Dictionary) -> void:
	# 如果战斗胜利，触发战斗胜利效果
	if result.is_victory:
		trigger_relic_effect("on_battle_victory", result)
	else:
		trigger_relic_effect("on_battle_defeat", result)
	
	# 触发战斗结束效果
	trigger_relic_effect("on_battle_end", result)

# 事件完成事件处理
func _on_event_completed(event_data: Dictionary, result_data: Dictionary) -> void:
	# 触发事件完成效果
	var context = {
		"event": event_data,
		"result": result_data
	}
	trigger_relic_effect("on_event_completed", context)

# 地图节点选择事件处理
func _on_map_node_selected(node_data: Dictionary) -> void:
	# 如果是宝藏节点，可能会获得遗物
	if node_data.type == "treasure":
		_handle_treasure_node(node_data)
	
	# 触发地图节点选择效果
	trigger_relic_effect("on_map_node_selected", {"node": node_data})

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
