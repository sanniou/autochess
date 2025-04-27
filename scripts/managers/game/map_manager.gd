extends "res://scripts/managers/core/base_manager.gd"
class_name MapManager
## 地图管理器
## 负责地图数据的加载、保存和管理，处理地图生成和随机化，管理地图的全局状态

# 地图组件
var map_controller: MapController
var map_config: MapConfig = MapConfig.new()

# 当前地图状态
var current_map: MapData = null
var current_node: MapNode = null
var visited_nodes: Dictionary = {}
var available_nodes: Dictionary = {}

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
	map_controller.path_highlighted.connect(_on_path_highlighted)
	map_controller.path_highlight_cleared.connect(_on_path_highlight_cleared)

	GlobalEventBus.battle.add_class_listener(BattleEvents.BattleEndedEvent, _on_battle_ended)
	GlobalEventBus.event.add_class_listener(EventEvents.EventCompletedEvent, _on_event_completed)
	GlobalEventBus.economy.add_class_listener(EconomyEvents.ShopClosedEvent, _on_shop_exited)

	# 加载地图配置
	_load_map_config()

	_log_info("地图管理器初始化完成")

## 加载地图配置
func _load_map_config() -> void:
	# 使用新的配置管理器API获取地图配置
	var config_model = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.MAP_CONFIG, "map_config")
	if config_model:
		# 复制配置数据
		map_config.set_data(config_model.get_data())

		# 连接配置变更信号
		if not GameManager.config_manager.config_changed.is_connected(_on_config_changed):
			GameManager.config_manager.config_changed.connect(_on_config_changed)
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

	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapLoadedEvent.new(current_map))

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

	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapClearedEvent.new())

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
		# 使用事件总线分发事件（新方式）
		var completion_time = Time.get_unix_time_from_system() - current_map.creation_time
		GlobalEventBus.map.dispatch_event(MapEvents.MapCompletedEvent.new(
			current_map.id, completion_time, visited_nodes.size()
		))

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
			_start_battle(node)
		"shop":
			_open_shop(node)
		"event":
			_trigger_event(node)
		"treasure":
			_open_treasure(node)
		"rest":
			_rest_at_node(node)
		"boss":
			_start_battle(node)
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
	# 获取节点类型配置
	var battle_type = node.get_property("battle_type")
	var difficulty_scaling = node.get_property("difficulty_scaling")

	# 获取战斗配置
	var battle_config = map_config.get_battle_config(battle_type)
	if not battle_config:
		_log_error("无效的战斗类型: " + battle_type)
		assert(false,"无效的战斗类型: " + battle_type)

	# 计算难度
	var base_difficulty = node.get_property("difficulty", _calculate_battle_difficulty(node.layer, battle_type == "elite"))
	var final_difficulty = base_difficulty
	if difficulty_scaling:
		final_difficulty *= battle_config.difficulty_multiplier

	# 创建战斗参数
	var battle_params = BattleParams.new()
	battle_params.difficulty = final_difficulty
	battle_params.enemy_level = node.get_property("enemy_level", _calculate_enemy_level(node.layer))
	battle_params.is_elite = (battle_type == "elite")
	battle_params.is_boss = (battle_type == "boss")

	# 设置特殊参数
	if battle_type == "boss":
		battle_params.boss_id = node.get_property("boss_id", "")

	# 设置奖励
	# 合并节点奖励和战斗配置奖励
	var rewards = {}
	rewards.merge(battle_config.rewards)
	rewards.merge(node.rewards)
	battle_params.rewards = rewards

	# 存储战斗参数
	# todo
	#GameManager.battle_params = battle_params

	# 切换到战斗状态
	GameManager.change_state(GameManager.GameState.BATTLE)

## 打开商店
func _open_shop(node: MapNode) -> void:
	# 设置商店参数
	var shop_params = {
		"discount": node.get_property("discount"),
		"shop_type": node.get_property("shop_type"),
		"layer": node.layer
	}

	# 存储商店参数
	# todo
	#GameManager.shop_params = shop_params

	# 切换到商店状态
	GameManager.change_state(GameManager.GameState.SHOP)

## 触发事件
func _trigger_event(node: MapNode) -> void:
	# 设置事件参数
	var event_params = {
		"event_id": node.get_property("event_id"),
		"event_type": node.get_property("event_type"),
		"layer": node.layer
	}

	# 存储事件参数
	#todo
	#GameManager.event_params = event_params

	# 切换到事件状态
	GameManager.change_state(GameManager.GameState.EVENT)

## 打开宝藏
func _open_treasure(node: MapNode) -> void:
	# 处理宝藏奖励
	_process_rewards(node.rewards)

	# 显示宝藏获取UI
	# 这里应该显示一个UI，展示获得的奖励
	# 暂时直接返回地图
	GlobalEventBus.map.dispatch_event(MapEvents.TreasureCollectedEvent.new(node.rewards))

## 在节点休息
func _rest_at_node(node: MapNode) -> void:
	# 处理休息效果
	var player_manager = GameManager.play_manager
	if player_manager:
		player_manager.heal_player(node.heal_amount)

	# 显示休息UI
	# 这里应该显示一个UI，展示休息效果
	# 暂时直接返回地图
	GlobalEventBus.map.dispatch_event(MapEvents.RestCompletedEvent.new(node.heal_amount))

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
## 使用地图控制器获取最佳路径
func get_best_path_to_node(target_node_id: String) -> Array:
	# 如果没有当前节点或当前地图，返回空数组
	if not current_node or not current_map:
		return []

	# 使用地图控制器获取路径
	return map_controller.get_best_path_to_node(current_node.id, target_node_id)

## 高亮路径
## 高亮从当前节点到目标节点的路径
func highlight_path_to_node(target_node_id: String) -> bool:
	if not current_node or not current_map:
		return false

	return map_controller.highlight_path(current_node.id, target_node_id)

## 清除路径高亮
## 清除所有高亮的路径
func clear_path_highlights() -> void:
	map_controller.clear_path_highlights()

## 路径高亮事件处理
func _on_path_highlighted(path_nodes: Array) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapPathHighlightedEvent.new(path_nodes))

## 路径高亮清除事件处理
func _on_path_highlight_cleared() -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapPathHighlightClearedEvent.new())

## 地图加载事件处理
func _on_map_loaded(map_data: MapData) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapLoadedEvent.new(map_data))

## 地图清除事件处理
func _on_map_cleared() -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapClearedEvent.new())

## 节点选择事件处理
func _on_node_selected(node: MapNode) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapNodeSelectedEvent.new(
		node.id, node.type, node.to_dict()
	))

## 节点访问事件处理
func _on_node_visited(node: MapNode) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapNodeVisitedEvent.new(
		node.id, node.type, node.to_dict()
	))

## 节点悬停事件处理
func _on_node_hovered(node: MapNode) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapNodeHoveredEvent.new(
		node.id, node.type, node.to_dict(), true
	))

## 节点取消悬停事件处理
func _on_node_unhovered(node: MapNode) -> void:
	# 使用事件总线分发事件（新方式）
	GlobalEventBus.map.dispatch_event(MapEvents.MapNodeHoveredEvent.new(
		node.id, node.type, node.to_dict(), false
	))

## 战斗结束事件处理
func _on_battle_ended(event:BattleEvents.BattleEndedEvent) -> void:
	# 如果战斗失败，不处理奖励
	if not event.result.victory:
		return

	# 处理战斗奖励
	if event.result.has("rewards"):
		_process_rewards(event.result.rewards)

## 事件完成事件处理
func _on_event_completed(_event, result: Dictionary) -> void:
	# 处理事件奖励
	if result.has("rewards"):
		_process_rewards(result.rewards)

## 商店退出事件处理
func _on_shop_exited() -> void:
	# 商店退出后的处理
	pass

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
	GlobalEventBus.ui.dispatch_event(UIEvents.ToastShownEvent.new("todo",LocalizationManager.tr("ui.map.mystery_revealed").format({"type": LocalizationManager.tr("ui.map.node_" + random_type)})))

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

## 重写清理方法
func _do_cleanup() -> void:
	# 断开信号连接
	if map_controller:
		map_controller.map_loaded.disconnect(_on_map_loaded)
		map_controller.map_cleared.disconnect(_on_map_cleared)
		map_controller.node_selected.disconnect(_on_node_selected)
		map_controller.node_visited.disconnect(_on_node_visited)
		map_controller.node_hovered.disconnect(_on_node_hovered)
		map_controller.node_unhovered.disconnect(_on_node_unhovered)

	# 断开事件总线信号
	GlobalEventBus.battle.remove_class_listener(BattleEvents.BattleEndedEvent, _on_battle_ended)
	GlobalEventBus.event.remove_class_listener(EventEvents.EventCompletedEvent, _on_event_completed)
	GlobalEventBus.economy.remove_class_listener(EconomyEvents.ShopClosedEvent, _on_shop_exited)

	# 断开配置变更信号连接
	if GameManager.config_manager.config_changed.is_connected(_on_config_changed):
		GameManager.config_manager.config_changed.disconnect(_on_config_changed)

	# 清除地图
	clear_map()

	# 清理地图控制器
	if map_controller:
		map_controller.queue_free()
		map_controller = null

	# 清理地图生成器
	if map_generator:
		map_generator.queue_free()
		map_generator = null

	_log_info("地图管理器已清理")

## 配置变更回调
func _on_config_changed(config_type: String, config_id: String) -> void:
	# 检查是否是地图配置
	if config_type == ConfigTypes.int_to_string(ConfigTypes.Type.MAP_CONFIG) and config_id == "map_config":
		# 重新加载地图配置
		_log_info("地图配置已更新，重新加载")
		_load_map_config()
