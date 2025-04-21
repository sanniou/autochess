extends "res://scripts/managers/core/base_manager.gd"
class_name MapManager
## 地图管理器
## 管理地图生成、节点选择和地图进度

# 地图信号
signal map_loaded(map_data)
signal map_cleared
signal node_selected(node_data)
signal node_visited(node_data)
signal node_hovered(node_data)
signal node_unhovered(node_data)
signal map_completed(map_data)

# 地图组件
var map_controller: MapController
var map_config: MapConfig = MapConfig.new()

# 当前地图状态
var current_map: MapData = null
var current_node: MapNode = null
var visited_nodes = {}
var available_nodes = {}

# 地图生成器
var map_generator: ProceduralMapGenerator

# 地图渲染器场景
const MAP_RENDERER_SCENE = preload("res://scenes/game/map/map_renderer_2d.tscn")

# 难度相关
var difficulty_level: int = 1
var map_template: String = "standard"

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "MapManager"
	# 添加依赖
	add_dependency("ConfigManager")

	# 创建地图渲染器
	var map_renderer = MAP_RENDERER_SCENE.instantiate()
	add_child(map_renderer)

	# 创建地图控制器
	map_controller = MapController.new()
	map_controller.renderer = map_renderer
	add_child(map_controller)

	# 创建地图生成器
	map_generator = ProceduralMapGenerator.new()
	map_controller.generator = map_generator
	add_child(map_generator)

	# 连接信号
	map_controller.map_loaded.connect(_on_map_loaded)
	map_controller.map_cleared.connect(_on_map_cleared)
	map_controller.node_selected.connect(_on_node_selected)
	map_controller.node_visited.connect(_on_node_visited)
	map_controller.node_hovered.connect(_on_node_hovered)
	map_controller.node_unhovered.connect(_on_node_unhovered)

	# 连接事件总线信号
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)
	EventBus.event.connect_event("event_completed", _on_event_completed)
	EventBus.economy.connect_event("shop_closed", _on_shop_exited)

	# 加载地图配置
	_load_map_config()

	_log_info("地图管理器初始化完成")

## 加载地图配置
func _load_map_config() -> void:
	# 使用ConfigManager获取地图配置
	var config_model = ConfigManager.get_map_config()
	if config_model:
		# 复制配置数据
		map_config.set_data(config_model.get_data())
	else:
		_log_warning("无法加载地图配置")

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
	var map_data = map_generator.generate_map(map_template, seed_value)

	if map_data:
		# 加载生成的地图
		load_map(map_data)
	else:
		_log_error("生成地图失败")

## 加载地图
func load_map(map_data: MapData) -> void:
	# 清除当前地图
	clear_map()

	# 设置当前地图
	current_map = map_data

	# 重置状态
	visited_nodes = {}
	available_nodes = {}

	# 找到起始节点
	var start_nodes = current_map.get_nodes_by_type("start")
	if not start_nodes.is_empty():
		current_node = start_nodes[0]
		visited_nodes[current_node.id] = true

		# 更新可用节点
		_update_available_nodes()

	# 使用控制器加载地图
	map_controller.load_map_data(current_map)

	# 发送信号
	map_loaded.emit(current_map)

## 加载地图文件
func load_map_file(file_path: String) -> void:
	map_controller.load_map_file(file_path)

## 保存地图文件
func save_map_file(file_path: String) -> void:
	map_controller.save_map_file(file_path)

## 清除地图
func clear_map() -> void:
	# 清除状态
	current_map = null
	current_node = null
	visited_nodes = {}
	available_nodes = {}

	# 使用控制器清除地图
	map_controller.clear_map()

	# 发送信号
	map_cleared.emit()

## 选择节点
func select_node(node_id: String) -> bool:
	if not current_map:
		return false

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return false

	# 检查节点是否可用
	if not available_nodes.has(node_id):
		return false

	# 使用控制器选择节点
	map_controller.select_node(node_id)

	# 更新当前节点
	current_node = node

	# 触发节点事件
	_trigger_node_event(node)

	return true

## 访问节点
func visit_node(node_id: String) -> bool:
	if not current_map:
		return false

	var node = current_map.get_node_by_id(node_id)
	if not node:
		return false

	# 检查节点是否可用
	if not available_nodes.has(node_id):
		return false

	# 更新当前节点
	current_node = node

	# 标记为已访问
	visited_nodes[node_id] = true
	node.visited = true

	# 更新可用节点
	_update_available_nodes()

	# 使用控制器访问节点
	map_controller.visit_node(node_id)

	# 检查地图是否完成
	if _is_map_completed():
		map_completed.emit(current_map)

	return true

## 更新可用节点
func _update_available_nodes() -> void:
	if not current_map or not current_node:
		return

	# 清除当前可用节点
	available_nodes = {}

	# 获取当前节点可到达的节点
	var reachable_nodes = current_map.get_reachable_nodes(current_node.id)

	# 添加到可用节点
	for node in reachable_nodes:
		available_nodes[node.id] = true

## 检查地图是否完成
func _is_map_completed() -> bool:
	if not current_map or not current_node:
		return false

	# 检查当前节点是否是出口节点
	return current_node.get_property("is_exit", false)



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
	GameManager.battle_params = battle_params

	# 切换到战斗状态
	GameManager.change_state(GameManager.GameState.BATTLE)

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
	GameManager.battle_params = battle_params

	# 切换到战斗状态
	GameManager.change_state(GameManager.GameState.BATTLE)

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
	GameManager.battle_params = battle_params

	# 切换到战斗状态
	GameManager.change_state(GameManager.GameState.BATTLE)

## 打开商店
func _open_shop(node: MapNode) -> void:
	# 设置商店参数
	var shop_params = {
		"discount": node.discount,
		"layer": node.layer
	}

	# 存储商店参数
	GameManager.shop_params = shop_params

	# 切换到商店状态
	GameManager.change_state(GameManager.GameState.SHOP)

## 触发事件
func _trigger_event(node: MapNode) -> void:
	# 设置事件参数
	var event_params = {
		"event_id": node.event_id,
		"layer": node.layer
	}

	# 存储事件参数
	GameManager.event_params = event_params

	# 切换到事件状态
	GameManager.change_state(GameManager.GameState.EVENT)

## 打开宝藏
func _open_treasure(node: MapNode) -> void:
	# 处理宝藏奖励
	_process_rewards(node.rewards)

	# 显示宝藏获取UI
	# 这里应该显示一个UI，展示获得的奖励
	# 暂时直接返回地图
	EventBus.map.emit_event("treasure_collected", [node.rewards])

## 在节点休息
func _rest_at_node(node: MapNode) -> void:
	# 处理休息效果
	var player_manager = GameManager.play_manager
	if player_manager:
		player_manager.heal_player(node.heal_amount)

	# 显示休息UI
	# 这里应该显示一个UI，展示休息效果
	# 暂时直接返回地图
	EventBus.map.emit_event("rest_completed", [node.heal_amount])

## 处理奖励
func _process_rewards(rewards: Dictionary) -> void:
	var player_manager = GameManager.player_manager
	var equipment_manager = GameManager.equipment_manager
	var relic_manager = GameManager.relic_manager

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







## 获取地图完成状态
func is_map_completed() -> bool:
	return _is_map_completed()

## 获取两个节点之间的路径
func get_path_between_nodes(from_node_id: String, to_node_id: String) -> Array:
	if not current_map:
		return []

	# 获取节点
	var from_node = current_map.get_node_by_id(from_node_id)
	var to_node = current_map.get_node_by_id(to_node_id)

	if not from_node or not to_node:
		return []

	# 获取从起始节点可达的节点
	var reachable_nodes = current_map.get_reachable_nodes(from_node_id)

	# 检查目标节点是否可达
	for node in reachable_nodes:
		if node.id == to_node_id:
			return [from_node_id, to_node_id]

	# 如果没有直接连接，返回空数组
	return []

## 获取到目标节点的最佳路径
func get_best_path_to_node(target_node_id: String) -> Array:
	# 如果没有当前节点或当前地图，返回空数组
	if not current_node or not current_map:
		return []

	# 获取目标节点
	var target_node = current_map.get_node_by_id(target_node_id)
	if not target_node:
		return []

	# 使用广度优先搜索找到目标节点的路径
	return _find_path_bfs(current_node.id, target_node_id)

## 使用广度优先搜索找到目标节点的路径
func _find_path_bfs(start_node_id: String, target_node_id: String) -> Array:
	if not current_map:
		return []

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
		var current_node = current_map.get_node_by_id(current_id)
		if not current_node:
			continue

		# 获取可达节点
		var reachable_nodes = current_map.get_reachable_nodes(current_id)

		# 遍历所有可达节点
		for next_node in reachable_nodes:
			if not visited.has(next_node.id):
				queue.push_back(next_node.id)
				visited[next_node.id] = true
				parent[next_node.id] = current_id

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

## 地图加载事件处理
func _on_map_loaded(map_data: MapData) -> void:
	map_loaded.emit(map_data)

## 地图清除事件处理
func _on_map_cleared() -> void:
	map_cleared.emit()

## 节点选择事件处理
func _on_node_selected(node: MapNode) -> void:
	node_selected.emit(node)

## 节点访问事件处理
func _on_node_visited(node: MapNode) -> void:
	node_visited.emit(node)

## 节点悬停事件处理
func _on_node_hovered(node: MapNode) -> void:
	node_hovered.emit(node)

## 节点取消悬停事件处理
func _on_node_unhovered(node: MapNode) -> void:
	node_unhovered.emit(node)

## 战斗结束事件处理
func _on_battle_ended(result: Dictionary) -> void:
	# 如果战斗失败，不处理奖励
	if not result.is_victory:
		return

	# 处理战斗奖励
	if result.has("rewards"):
		_process_rewards(result.rewards)

## 事件完成事件处理
func _on_event_completed(_event, result: Dictionary) -> void:
	# 处理事件奖励
	if result.has("rewards"):
		_process_rewards(result.rewards)

## 商店退出事件处理
func _on_shop_exited() -> void:
	# 商店退出后的处理
	pass

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.battle.disconnect_event("battle_ended", _on_battle_ended)
	EventBus.event.disconnect_event("event_completed", _on_event_completed)
	EventBus.economy.disconnect_event("shop_closed", _on_shop_exited)

	# 清理地图控制器
	if map_controller:
		map_controller.queue_free()
		map_controller = null

	# 清理地图生成器
	if map_generator:
		map_generator.queue_free()
		map_generator = null

	# 清理地图数据
	current_map = null
	current_node = null
	visited_nodes = {}
	available_nodes = {}

	_log_info("地图管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 清理地图数据
	current_map = null
	current_node = null
	visited_nodes = {}
	available_nodes = {}

	_log_info("地图管理器重置完成")

## 获取当前地图数据
func get_current_map() -> MapData:
	return current_map

## 获取当前节点
func get_current_node() -> MapNode:
	return current_node

## 获取可选节点
func get_selectable_nodes() -> Array:
	var nodes_array = []
	for node_id in available_nodes:
		var node = current_map.get_node_by_id(node_id)
		if node:
			nodes_array.append(node)
	return nodes_array

## 触发神秘节点
func _trigger_mystery_node(node: MapNode) -> void:
	# 随机决定节点类型
	var possible_types = ["battle", "shop", "event", "treasure", "rest"]
	var random_type = possible_types[randi() % possible_types.size()]

	# 创建一个新的节点数据
	var mystery_node = MapNode.new()
	mystery_node.initialize(node.id, random_type, node.layer, node.position)

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
	EventBus.ui.emit_event("show_toast", [LocalizationManager.tr("ui.map.mystery_revealed").format({"type": LocalizationManager.tr("ui.map.node_" + random_type)})])

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
	GameManager.battle_params = challenge_params

	# 切换到战斗状态
	GameManager.change_state(GameManager.GameState.BATTLE)

## 打开祭坛
func _open_altar(node: MapNode) -> void:
	# 设置祭坛参数
	var altar_params = {
		"layer": node.layer,
		"altar_type": _select_altar_type()
	}

	# 存储祭坛参数
	GameManager.altar_params = altar_params

	# 切换到祭坛状态
	GameManager.change_state(GameManager.GameState.ALTAR)

## 打开铁匠铺
func _open_blacksmith(node: MapNode) -> void:
	# 设置铁匠铺参数
	var blacksmith_params = {
		"layer": node.layer,
		"discount": randf() < 0.3  # 30%概率有折扣
	}

	# 存储铁匠铺参数
	GameManager.blacksmith_params = blacksmith_params

	# 切换到铁匠铺状态
	GameManager.change_state(GameManager.GameState.BLACKSMITH)

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
