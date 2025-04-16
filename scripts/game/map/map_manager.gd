extends Node
class_name MapManager
## 地图管理器
## 管理地图生成、节点选择和地图进度

# 信号
signal map_initialized(map_data)
signal node_selected(node_data)
signal map_completed

# 地图数据
var map_data: Dictionary = {}
var nodes: Dictionary = {}  # 节点ID到MapNode对象的映射
var current_layer: int = 0
var current_node: MapNode = null
var selectable_nodes: Array = []
var completed: bool = false

# 地图生成器
var map_generator: MapGenerator

# 难度相关
var difficulty_level: int = 1
var map_template: String = "standard"

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var game_manager = get_node("/root/GameManager")

func _ready():
	# 创建地图生成器
	map_generator = MapGenerator.new()
	add_child(map_generator)

	# 连接信号
	map_generator.map_generated.connect(_on_map_generated)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.event_completed.connect(_on_event_completed)
	EventBus.shop_exited.connect(_on_shop_exited)

## 初始化地图
func initialize_map(template: String = "standard", difficulty: int = 1, seed_value: int = -1) -> void:
	# 设置难度和模板
	difficulty_level = difficulty
	map_template = template

	# 根据难度选择地图模板
	if difficulty > 2:
		map_template = "hard"
	elif difficulty < 1:
		map_template = "easy"

	# 生成地图
	map_data = map_generator.generate_map(map_template, seed_value)

	# 初始化节点
	_initialize_nodes()

	# 设置初始节点
	current_layer = 0
	current_node = _get_node_by_id(map_data.nodes[0][0].id)
	current_node.mark_as_visited()

	# 更新可选节点
	_update_selectable_nodes()

	# 发送地图初始化信号
	map_initialized.emit(map_data)

## 初始化节点
func _initialize_nodes() -> void:
	nodes.clear()

	# 创建所有节点
	for layer_nodes in map_data.nodes:
		for node_data in layer_nodes:
			var node = MapNode.new()
			node.initialize(node_data)
			nodes[node.id] = node

	# 设置节点连接
	for layer_idx in range(map_data.connections.size()):
		var layer_connections = map_data.connections[layer_idx]

		for connection in layer_connections:
			var from_node = nodes[connection.from]

			for to_node_id in connection.to:
				from_node.add_connection_to(to_node_id)
				var to_node = nodes[to_node_id]
				to_node.add_connection_from(connection.from)

## 选择节点
func select_node(node_id: String) -> bool:
	# 检查是否是可选节点
	var is_selectable = false
	for node in selectable_nodes:
		if node.id == node_id:
			is_selectable = true
			break

	if not is_selectable:
		return false

	# 更新当前节点
	var selected_node = nodes[node_id]
	current_node = selected_node
	current_layer = selected_node.layer
	selected_node.mark_as_visited()

	# 更新可选节点
	_update_selectable_nodes()

	# 检查是否完成地图
	if current_layer == map_data.layers - 1:
		completed = true
		map_completed.emit()

	# 发送节点选择信号
	node_selected.emit(selected_node.get_data())
	EventBus.map_node_selected.emit(selected_node.get_data())

	# 触发节点事件
	_trigger_node_event(selected_node)

	return true

## 更新可选节点
func _update_selectable_nodes() -> void:
	selectable_nodes.clear()

	if current_layer >= map_data.layers - 1 or completed:
		return

	# 查找当前节点的连接
	for node_id in current_node.connections_to:
		var node = nodes[node_id]
		selectable_nodes.append(node)

## 获取所有节点
func get_all_nodes() -> Dictionary:
	return nodes

## 触发节点事件
func _trigger_node_event(node: MapNode) -> void:
	# 根据节点类型触发不同事件
	match node.type:
		"battle":
			_start_battle(node)
		"elite_battle":
			_start_elite_battle(node)
		"shop":
			_open_shop(node)
		"event":
			_trigger_event(node)
		"treasure":
			_open_treasure(node)
		"rest":
			_rest_at_node(node)
		"boss":
			_start_boss_battle(node)
		"mystery":
			_trigger_mystery_node(node)
		"challenge":
			_start_challenge(node)
		"altar":
			_open_altar(node)
		"blacksmith":
			_open_blacksmith(node)

## 开始普通战斗
func _start_battle(node: MapNode) -> void:
	# 设置战斗参数
	var battle_params = {
		"difficulty": node.difficulty,
		"enemy_level": node.enemy_level,
		"is_elite": false,
		"is_boss": false,
		"rewards": node.rewards
	}

	# 存储战斗参数
	game_manager.battle_params = battle_params

	# 切换到战斗状态
	game_manager.change_state(GameManager.GameState.BATTLE)

## 开始精英战斗
func _start_elite_battle(node: MapNode) -> void:
	# 设置战斗参数
	var battle_params = {
		"difficulty": node.difficulty,
		"enemy_level": node.enemy_level,
		"is_elite": true,
		"is_boss": false,
		"rewards": node.rewards
	}

	# 存储战斗参数
	game_manager.battle_params = battle_params

	# 切换到战斗状态
	game_manager.change_state(GameManager.GameState.BATTLE)

## 开始Boss战斗
func _start_boss_battle(node: MapNode) -> void:
	# 设置战斗参数
	var battle_params = {
		"difficulty": node.difficulty,
		"enemy_level": node.enemy_level,
		"is_elite": false,
		"is_boss": true,
		"boss_id": node.boss_id,
		"rewards": node.rewards
	}

	# 存储战斗参数
	game_manager.battle_params = battle_params

	# 切换到战斗状态
	game_manager.change_state(GameManager.GameState.BATTLE)

## 打开商店
func _open_shop(node: MapNode) -> void:
	# 设置商店参数
	var shop_params = {
		"discount": node.discount,
		"layer": node.layer
	}

	# 存储商店参数
	game_manager.shop_params = shop_params

	# 切换到商店状态
	game_manager.change_state(GameManager.GameState.SHOP)

## 触发事件
func _trigger_event(node: MapNode) -> void:
	# 设置事件参数
	var event_params = {
		"event_id": node.event_id,
		"layer": node.layer
	}

	# 存储事件参数
	game_manager.event_params = event_params

	# 切换到事件状态
	game_manager.change_state(GameManager.GameState.EVENT)

## 打开宝藏
func _open_treasure(node: MapNode) -> void:
	# 处理宝藏奖励
	_process_rewards(node.rewards)

	# 显示宝藏获取UI
	# 这里应该显示一个UI，展示获得的奖励
	# 暂时直接返回地图
	EventBus.treasure_collected.emit(node.rewards)

## 在节点休息
func _rest_at_node(node: MapNode) -> void:
	# 处理休息效果
	var player_manager = get_node("/root/GameManager/PlayerManager")
	if player_manager:
		player_manager.heal_player(node.heal_amount)

	# 显示休息UI
	# 这里应该显示一个UI，展示休息效果
	# 暂时直接返回地图
	EventBus.rest_completed.emit(node.heal_amount)

## 处理奖励
func _process_rewards(rewards: Dictionary) -> void:
	var player_manager = get_node("/root/GameManager/PlayerManager")
	var equipment_manager = get_node("/root/GameManager/EquipmentManager")
	var relic_manager = get_node("/root/GameManager/RelicManager")

	# 处理金币奖励
	if rewards.has("gold") and player_manager:
		player_manager.add_gold(rewards.gold)

	# 处理经验奖励
	if rewards.has("exp") and player_manager:
		player_manager.add_exp(rewards.exp)

	# 处理装备奖励
	if rewards.has("equipment") and equipment_manager:
		var equipment_data = rewards.equipment

		if equipment_data.has("guaranteed") and equipment_data.guaranteed:
			var quality = equipment_data.get("quality", 1)
			equipment_manager.create_random_equipment(quality)
		elif rewards.has("equipment_chance"):
			if randf() < rewards.equipment_chance:
				equipment_manager.create_random_equipment()

	# 处理遗物奖励
	if rewards.has("relic") and relic_manager:
		var relic_data = rewards.relic

		if relic_data.has("guaranteed") and relic_data.guaranteed:
			var rarity = relic_data.get("rarity", 0)
			var relic_id = relic_manager.get_random_relic(rarity)
			if not relic_id.is_empty():
				relic_manager.acquire_relic(relic_id)
		elif rewards.has("relic_chance"):
			if randf() < rewards.relic_chance:
				var relic_id = relic_manager.get_random_relic()
				if not relic_id.is_empty():
					relic_manager.acquire_relic(relic_id)

## 获取节点通过ID
func _get_node_by_id(node_id: String) -> MapNode:
	if nodes.has(node_id):
		return nodes[node_id]
	return null

## 获取当前地图数据
func get_map_data() -> Dictionary:
	return map_data

## 获取当前节点
func get_current_node() -> MapNode:
	return current_node

## 获取可选节点
func get_selectable_nodes() -> Array:
	return selectable_nodes



## 获取地图完成状态
func is_map_completed() -> bool:
	return completed

## 获取两个节点之间的路径
func get_path_between_nodes(from_node_id: String, to_node_id: String) -> Array:
	# 如果节点不存在，返回空数组
	if not nodes.has(from_node_id) or not nodes.has(to_node_id):
		return []

	# 获取节点
	var from_node = nodes[from_node_id]
	var to_node = nodes[to_node_id]

	# 如果节点层级不相邻，返回空数组
	if to_node.layer != from_node.layer + 1:
		return []

	# 检查直接连接
	if from_node.connections_to.has(to_node_id):
		return [from_node_id, to_node_id]

	# 如果没有直接连接，返回空数组
	return []

## 获取到目标节点的最佳路径
func get_best_path_to_node(target_node_id: String) -> Array:
	# 如果没有当前节点或目标节点不存在，返回空数组
	if not current_node or not nodes.has(target_node_id):
		return []

	# 获取目标节点
	var target_node = nodes[target_node_id]

	# 如果目标节点层级不在地图的最后一层，返回空数组
	if target_node.layer != map_data.layers - 1:
		return []

	# 使用广度优先搜索找到目标节点的路径
	return _find_path_bfs(current_node.id, target_node_id)

## 使用广度优先搜索找到目标节点的路径
func _find_path_bfs(start_node_id: String, target_node_id: String) -> Array:
	# 初始化队列和访问记录
	var queue = []
	var visited = {}
	var parent = {}

	# 将起点加入队列
	queue.push_back(start_node_id)
	visited[start_node_id] = true

	# BFS遍历
	while not queue.is_empty():
		var current_id = queue.pop_front()

		# 如果到达目标，重建路径
		if current_id == target_node_id:
			return _reconstruct_path(parent, start_node_id, target_node_id)

		# 获取当前节点
		var current_node = nodes[current_id]

		# 遍历所有连接
		for next_id in current_node.connections_to:
			if not visited.has(next_id):
				queue.push_back(next_id)
				visited[next_id] = true
				parent[next_id] = current_id

	# 如果没有找到路径，返回空数组
	return []

## 重建路径
func _reconstruct_path(parent: Dictionary, start_node_id: String, target_node_id: String) -> Array:
	var path = [target_node_id]
	var current_id = target_node_id

	while current_id != start_node_id:
		current_id = parent[current_id]
		path.push_front(current_id)

	return path

## 战斗结束事件处理
func _on_battle_ended(result: Dictionary) -> void:
	# 如果战斗失败，不处理奖励
	if not result.is_victory:
		return

	# 处理战斗奖励
	if result.has("rewards"):
		_process_rewards(result.rewards)

## 事件完成事件处理
func _on_event_completed(event, result: Dictionary) -> void:
	# 处理事件奖励
	if result.has("rewards"):
		_process_rewards(result.rewards)

## 商店退出事件处理
func _on_shop_exited() -> void:
	# 商店退出后的处理
	pass

## 地图生成事件处理
func _on_map_generated(data: Dictionary) -> void:
	map_data = data

## 触发神秘节点
func _trigger_mystery_node(node: MapNode) -> void:
	# 随机决定节点类型
	var possible_types = ["battle", "shop", "event", "treasure", "rest"]
	var random_type = possible_types[randi() % possible_types.size()]

	# 创建一个新的节点数据
	var mystery_node = MapNode.new()
	mystery_node.initialize({
		"id": node.id,
		"layer": node.layer,
		"position": node.position,
		"type": random_type,
		"visited": true
	})

	# 根据随机类型设置额外属性
	match random_type:
		"battle":
			mystery_node.difficulty = _calculate_battle_difficulty(node.layer, false)
			mystery_node.enemy_level = _calculate_enemy_level(node.layer)
		"event":
			mystery_node.event_id = _select_event_for_node(node.layer)
		"shop":
			mystery_node.discount = true  # 神秘商店总是有折扣
		"treasure":
			mystery_node.rewards = _generate_better_rewards(node.layer)
		"rest":
			mystery_node.heal_amount = 30 + node.layer * 5  # 神秘休息点治疗量更高

	# 显示提示
	EventBus.show_toast.emit(LocalizationManager.tr("ui.map.mystery_revealed").format({"type": LocalizationManager.tr("ui.map.node_" + random_type)}))

	# 触发对应类型的节点事件
	_trigger_node_event(mystery_node)

## 开始挑战
func _start_challenge(node: MapNode) -> void:
	# 设置挑战参数
	var challenge_params = {
		"difficulty": node.difficulty * 1.2,  # 挑战难度更高
		"enemy_level": node.enemy_level,
		"is_elite": false,
		"is_boss": false,
		"is_challenge": true,
		"challenge_type": _select_challenge_type(),
		"rewards": _generate_better_rewards(node.layer)
	}

	# 存储战斗参数
	game_manager.battle_params = challenge_params

	# 切换到战斗状态
	game_manager.change_state(GameManager.GameState.BATTLE)

## 打开祭坛
func _open_altar(node: MapNode) -> void:
	# 设置祭坛参数
	var altar_params = {
		"layer": node.layer,
		"altar_type": _select_altar_type()
	}

	# 存储祭坛参数
	game_manager.altar_params = altar_params

	# 切换到祭坛状态
	game_manager.change_state(GameManager.GameState.ALTAR)

## 打开铁匠铺
func _open_blacksmith(node: MapNode) -> void:
	# 设置铁匠铺参数
	var blacksmith_params = {
		"layer": node.layer,
		"discount": randf() < 0.3  # 30%概率有折扣
	}

	# 存储铁匠铺参数
	game_manager.blacksmith_params = blacksmith_params

	# 切换到铁匠铺状态
	game_manager.change_state(GameManager.GameState.BLACKSMITH)

## 计算战斗难度
func _calculate_battle_difficulty(layer: int, is_elite: bool) -> float:
	var base_difficulty = 1.0 + (layer * 0.2)  # 每层增加20%难度
	if is_elite:
		base_difficulty *= 1.5  # 精英战斗难度提高50%
	return base_difficulty

## 计算敌人等级
func _calculate_enemy_level(layer: int) -> int:
	return 1 + layer  # 敌人等级 = 层数 + 1

## 选择节点事件
func _select_event_for_node(layer: int) -> String:
	# 这里应该根据层数选择适合的事件
	# 暂时返回随机事件
	var event_ids = ["mysterious_merchant", "abandoned_armory", "ancient_shrine", "wandering_trainer", "gambling_goblin"]
	return event_ids[randi() % event_ids.size()]

## 选择挑战类型
func _select_challenge_type() -> String:
	# 这里应该返回不同类型的挑战
	var challenge_types = ["time_limit", "no_abilities", "limited_mana", "elite_enemies", "restricted_movement"]
	return challenge_types[randi() % challenge_types.size()]

## 选择祭坛类型
func _select_altar_type() -> String:
	# 这里应该返回不同类型的祭坛
	var altar_types = ["health", "attack", "defense", "ability", "gold"]
	return altar_types[randi() % altar_types.size()]

## 生成更好的奖励
func _generate_better_rewards(layer: int) -> Dictionary:
	# 生成更好的奖励
	var rewards = {
		"gold": 20 + layer * 10,
		"exp": 10 + layer * 5,
		"equipment": {
			"guaranteed": true,
			"quality": min(3, 1 + layer / 3)  # 最高品质为3
		},
		"relic": {
			"guaranteed": layer > 3,  # 第4层以后必定有遗物
			"rarity": min(2, layer / 4)  # 最高稀有度为2
		},
		"relic_chance": min(0.5, 0.1 + layer * 0.05)  # 最高概率50%
	}
	return rewards
