extends Node
class_name StateStore
## 状态存储
## 集中管理应用状态，实现单向数据流

# 状态定义
var state_definitions = preload("res://scripts/state/state_definitions.gd")

# 状态动作
var state_actions = preload("res://scripts/state/state_actions.gd")

# 应用状态
var _state: Dictionary = {}

# 状态订阅者
var _subscribers: Dictionary = {}

# 状态变更历史
var _history: Array = []

# 最大历史记录数
var max_history_size: int = 100

# 是否启用历史记录
var enable_history: bool = false

# 是否处于调试模式
var debug_mode: bool = false

# 初始化
func _init():
	# 初始化状态
	_state = state_definitions.create_app_state()
	
	# 设置调试模式
	debug_mode = OS.is_debug_build()
	
	# 如果处于调试模式，启用历史记录
	if debug_mode:
		enable_history = true

## 获取状态
func get_state() -> Dictionary:
	return _state.duplicate(true)

## 获取特定状态
func get_state_section(section: String) -> Dictionary:
	if _state.has(section):
		return _state[section].duplicate(true)
	return {}

## 获取特定状态值
func get_state_value(path: String, default_value = null) -> Variant:
	var parts = path.split(".")
	
	if parts.size() < 2:
		_log_error("无效的状态路径: " + path)
		return default_value
	
	var section = parts[0]
	var key = parts[1]
	
	if not _state.has(section):
		_log_error("状态部分不存在: " + section)
		return default_value
	
	if not _state[section].has(key):
		_log_error("状态键不存在: " + section + "." + key)
		return default_value
	
	return _state[section][key]

## 分发动作
func dispatch(action) -> void:
	# 记录动作
	if debug_mode:
		_log_info("分发动作: " + action.type)
	
	# 保存当前状态到历史记录
	if enable_history:
		_add_to_history(_state.duplicate(true), action.to_dictionary())
	
	# 根据动作类型更新状态
	var new_state = _reduce(action)
	
	# 如果状态发生变化，通知订阅者
	if new_state != _state:
		_state = new_state
		_notify_subscribers()

## 订阅状态变更
func subscribe(section: String, subscriber: Object, method: String) -> bool:
	# 检查参数有效性
	if section.is_empty() or not is_instance_valid(subscriber) or method.is_empty():
		_log_error("订阅状态变更失败：无效的参数")
		return false
	
	# 如果部分不存在，创建部分
	if not _subscribers.has(section):
		_subscribers[section] = []
	
	# 检查是否已经订阅
	for sub in _subscribers[section]:
		if sub.subscriber == subscriber and sub.method == method:
			_log_warning("状态变更已经订阅：" + section)
			return false
	
	# 订阅状态变更
	_subscribers[section].append({
		"subscriber": subscriber,
		"method": method
	})
	
	_log_info("订阅状态变更：" + section + " -> " + subscriber.get_class() + "." + method)
	return true

## 取消订阅状态变更
func unsubscribe(section: String, subscriber: Object, method: String) -> bool:
	# 检查参数有效性
	if section.is_empty() or not is_instance_valid(subscriber) or method.is_empty():
		_log_error("取消订阅状态变更失败：无效的参数")
		return false
	
	# 如果部分不存在，返回失败
	if not _subscribers.has(section):
		_log_warning("取消订阅状态变更失败：部分不存在 - " + section)
		return false
	
	# 查找并移除订阅者
	for i in range(_subscribers[section].size()):
		var sub = _subscribers[section][i]
		if sub.subscriber == subscriber and sub.method == method:
			_subscribers[section].remove_at(i)
			_log_info("取消订阅状态变更：" + section + " -> " + subscriber.get_class() + "." + method)
			return true
	
	_log_warning("取消订阅状态变更失败：订阅者不存在 - " + section)
	return false

## 取消对象的所有订阅
func unsubscribe_all(subscriber: Object) -> int:
	# 检查参数有效性
	if not is_instance_valid(subscriber):
		_log_error("取消所有订阅失败：无效的目标对象")
		return 0
	
	var count = 0
	
	# 遍历所有部分
	for section in _subscribers.keys():
		var i = 0
		
		# 查找并移除订阅者
		while i < _subscribers[section].size():
			if _subscribers[section][i].subscriber == subscriber:
				_subscribers[section].remove_at(i)
				count += 1
			else:
				i += 1
	
	if count > 0:
		_log_info("取消所有订阅：" + subscriber.get_class() + " - " + str(count) + " 个订阅")
	
	return count

## 获取状态历史
func get_history() -> Array:
	return _history.duplicate(true)

## 清除状态历史
func clear_history() -> void:
	_history.clear()
	_log_info("状态历史已清除")

## 设置最大历史记录数
func set_max_history_size(size: int) -> void:
	if size < 0:
		_log_error("设置最大历史记录数失败：无效的大小")
		return
	
	max_history_size = size
	
	# 如果当前历史记录超过最大大小，裁剪历史记录
	while _history.size() > max_history_size:
		_history.pop_front()
	
	_log_info("最大历史记录数已设置为：" + str(size))

## 启用历史记录
func enable_history_recording(enable: bool = true) -> void:
	enable_history = enable
	
	if not enable:
		_history.clear()
	
	_log_info("历史记录已" + ("启用" if enable else "禁用"))

## 重置状态
func reset_state() -> void:
	_state = state_definitions.create_app_state()
	_notify_subscribers()
	_log_info("状态已重置")

## 加载状态
func load_state(state_data: Dictionary) -> bool:
	if state_data.is_empty():
		_log_error("加载状态失败：状态数据为空")
		return false
	
	_state = state_data.duplicate(true)
	_notify_subscribers()
	_log_info("状态已加载")
	return true

## 保存状态
func save_state() -> Dictionary:
	return _state.duplicate(true)

## 添加到历史记录
func _add_to_history(state: Dictionary, action: Dictionary) -> void:
	# 创建历史记录
	var history_record = {
		"state": state,
		"action": action,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# 添加到历史记录
	_history.append(history_record)
	
	# 如果历史记录超过最大大小，移除最旧的记录
	while _history.size() > max_history_size:
		_history.pop_front()

## 通知订阅者
func _notify_subscribers() -> void:
	# 通知所有部分的订阅者
	for section in _subscribers.keys():
		if _state.has(section):
			var section_state = _state[section]
			
			for sub in _subscribers[section]:
				if is_instance_valid(sub.subscriber):
					sub.subscriber.call(sub.method, section_state)

## 根据动作更新状态
func _reduce(action) -> Dictionary:
	var new_state = _state.duplicate(true)
	
	match action.type:
		# 游戏状态动作
		"SET_DIFFICULTY":
			new_state.game.difficulty = action.difficulty
		"SET_GAME_MODE":
			new_state.game.game_mode = action.game_mode
		"SET_PAUSED":
			new_state.game.is_paused = action.is_paused
		"SET_GAME_OVER":
			new_state.game.is_game_over = action.is_game_over
			if action.is_game_over and action.has("win"):
				# 记录游戏结果
				if action.win:
					new_state.stats.games_won += 1
				else:
					new_state.stats.games_lost += 1
				new_state.stats.games_played += 1
		"NEXT_TURN":
			new_state.game.current_turn += 1
		"SET_PHASE":
			new_state.game.current_phase = action.phase
		"SET_SEED":
			new_state.game.seed_value = action.seed_value
		
		# 玩家状态动作
		"SET_HEALTH":
			new_state.player.health = action.health
		"CHANGE_HEALTH":
			new_state.player.health = max(0, min(new_state.player.max_health, new_state.player.health + action.amount))
		"SET_GOLD":
			new_state.player.gold = action.gold
		"CHANGE_GOLD":
			new_state.player.gold = max(0, new_state.player.gold + action.amount)
			if action.amount > 0:
				new_state.stats.total_gold_earned += action.amount
		"SET_EXPERIENCE":
			new_state.player.experience = action.experience
			# 计算等级
			var level = 1
			var exp_required = 2
			var total_exp = action.experience
			
			while total_exp >= exp_required:
				total_exp -= exp_required
				level += 1
				exp_required = 2 * level
			
			new_state.player.level = level
		"CHANGE_EXPERIENCE":
			new_state.player.experience += action.amount
			# 计算等级
			var level = 1
			var exp_required = 2
			var total_exp = new_state.player.experience
			
			while total_exp >= exp_required:
				total_exp -= exp_required
				level += 1
				exp_required = 2 * level
			
			new_state.player.level = level
		"ADD_RELIC":
			if not new_state.player.relics.has(action.relic_id):
				new_state.player.relics.append(action.relic_id)
		"REMOVE_RELIC":
			if new_state.player.relics.has(action.relic_id):
				new_state.player.relics.erase(action.relic_id)
		"RECORD_BATTLE_RESULT":
			if action.win:
				new_state.player.win_streak += 1
				new_state.player.lose_streak = 0
				new_state.player.total_wins += 1
			else:
				new_state.player.lose_streak += 1
				new_state.player.win_streak = 0
				new_state.player.total_losses += 1
		
		# 棋盘状态动作
		"SET_BOARD_SIZE":
			new_state.board.size = Vector2i(action.size.x, action.size.y)
		"PLACE_PIECE":
			var pos_key = str(action.position.x) + "," + str(action.position.y)
			new_state.board.pieces[pos_key] = action.piece_id
		"REMOVE_PIECE":
			var pos_key = str(action.position.x) + "," + str(action.position.y)
			if new_state.board.pieces.has(pos_key):
				new_state.board.pieces.erase(pos_key)
		"MOVE_PIECE":
			var from_key = str(action.from_position.x) + "," + str(action.from_position.y)
			var to_key = str(action.to_position.x) + "," + str(action.to_position.y)
			
			if new_state.board.pieces.has(from_key):
				var piece_id = new_state.board.pieces[from_key]
				new_state.board.pieces.erase(from_key)
				new_state.board.pieces[to_key] = piece_id
		"LOCK_BOARD":
			new_state.board.locked = action.locked
		"SET_BATTLE_STATE":
			new_state.board.battle_in_progress = action.battle_in_progress
			new_state.board.current_battle_id = action.battle_id
		"UPDATE_SYNERGY":
			new_state.board.synergies[action.synergy_id] = action.level
			# 记录羁绊激活
			if action.level > 0:
				if not new_state.stats.synergies_activated.has(action.synergy_id):
					new_state.stats.synergies_activated[action.synergy_id] = 0
				new_state.stats.synergies_activated[action.synergy_id] += 1
		"CLEAR_BOARD":
			new_state.board.pieces.clear()
		
		# 商店状态动作
		"SET_SHOP_OPEN":
			new_state.shop.is_open = action.is_open
		"SET_SHOP_ITEMS":
			new_state.shop.current_items = action.items.duplicate()
		"REFRESH_SHOP":
			new_state.shop.refresh_count += 1
		"BUY_ITEM":
			if action.item_index >= 0 and action.item_index < new_state.shop.current_items.size():
				var item = new_state.shop.current_items[action.item_index]
				new_state.shop.current_items.remove_at(action.item_index)
				
				# 如果是棋子，记录购买
				if item.has("type") and item.type == "chess_piece":
					if not new_state.stats.chess_pieces_bought.has(item.id):
						new_state.stats.chess_pieces_bought[item.id] = 0
					new_state.stats.chess_pieces_bought[item.id] += 1
		"LOCK_ITEM":
			if action.item_index >= 0 and action.item_index < new_state.shop.current_items.size():
				if action.locked:
					if not new_state.shop.locked_items.has(action.item_index):
						new_state.shop.locked_items.append(action.item_index)
				else:
					if new_state.shop.locked_items.has(action.item_index):
						new_state.shop.locked_items.erase(action.item_index)
		"SET_SHOP_TIER":
			new_state.shop.shop_tier = action.tier
		
		# 地图状态动作
		"SET_MAP":
			new_state.map.current_map = action.map_data.duplicate()
		"SELECT_NODE":
			new_state.map.current_node = action.node_id
		"VISIT_NODE":
			if not new_state.map.visited_nodes.has(action.node_id):
				new_state.map.visited_nodes.append(action.node_id)
		"SET_AVAILABLE_NODES":
			new_state.map.available_nodes = action.nodes.duplicate()
		"SET_MAP_LEVEL":
			new_state.map.map_level = action.level
		
		# UI状态动作
		"SET_SCREEN":
			new_state.ui.current_screen = action.screen
		"OPEN_WINDOW":
			if not new_state.ui.open_windows.has(action.window):
				new_state.ui.open_windows.append(action.window)
		"CLOSE_WINDOW":
			if new_state.ui.open_windows.has(action.window):
				new_state.ui.open_windows.erase(action.window)
		"SELECT_ITEM":
			new_state.ui.selected_item = action.item_id
		"SET_DRAG_ITEM":
			new_state.ui.drag_item = action.item_id
		"SHOW_TOOLTIP":
			new_state.ui.tooltip_text = action.text
			new_state.ui.show_tooltip = action.show
		"ADD_NOTIFICATION":
			new_state.ui.notification_queue.append({
				"message": action.message,
				"type": action.type,
				"duration": action.duration,
				"id": Time.get_unix_time_from_system()
			})
		"CLEAR_NOTIFICATIONS":
			new_state.ui.notification_queue.clear()
		
		# 设置状态动作
		"SET_VOLUME":
			match action.volume_type:
				"music":
					new_state.settings.music_volume = action.volume
				"sfx":
					new_state.settings.sfx_volume = action.volume
				"master":
					new_state.settings.master_volume = action.volume
		"SET_FULLSCREEN":
			new_state.settings.fullscreen = action.fullscreen
		"SET_LANGUAGE":
			new_state.settings.language = action.language
		"SET_SHOW_FPS":
			new_state.settings.show_fps = action.show_fps
		"SET_VSYNC":
			new_state.settings.vsync_enabled = action.vsync_enabled
		"SET_PARTICLE_QUALITY":
			new_state.settings.particle_quality = action.quality
		"SET_UI_SCALE":
			new_state.settings.ui_scale = action.scale
		
		# 成就状态动作
		"UNLOCK_ACHIEVEMENT":
			if not new_state.achievements.unlocked_achievements.has(action.achievement_id):
				new_state.achievements.unlocked_achievements[action.achievement_id] = Time.get_unix_time_from_system()
		"UPDATE_ACHIEVEMENT_PROGRESS":
			new_state.achievements.achievement_progress[action.achievement_id] = action.progress
		
		# 统计状态动作
		"RECORD_GAME_RESULT":
			new_state.stats.games_played += 1
			if action.win:
				new_state.stats.games_won += 1
			else:
				new_state.stats.games_lost += 1
		"RECORD_GOLD_EARNED":
			new_state.stats.total_gold_earned += action.amount
		"RECORD_DAMAGE":
			if action.is_dealt:
				new_state.stats.total_damage_dealt += action.amount
			else:
				new_state.stats.total_damage_taken += action.amount
		"RECORD_HEALING":
			new_state.stats.total_healing += action.amount
		"RECORD_CHESS_PIECE_BOUGHT":
			if not new_state.stats.chess_pieces_bought.has(action.piece_id):
				new_state.stats.chess_pieces_bought[action.piece_id] = 0
			new_state.stats.chess_pieces_bought[action.piece_id] += 1
		"RECORD_CHESS_PIECE_3STAR":
			if not new_state.stats.chess_pieces_3star.has(action.piece_id):
				new_state.stats.chess_pieces_3star[action.piece_id] = 0
			new_state.stats.chess_pieces_3star[action.piece_id] += 1
		"RECORD_SYNERGY_ACTIVATED":
			if not new_state.stats.synergies_activated.has(action.synergy_id):
				new_state.stats.synergies_activated[action.synergy_id] = 0
			new_state.stats.synergies_activated[action.synergy_id] += 1
	
	return new_state

## 记录错误信息
func _log_error(message: String) -> void:
	if debug_mode:
		print("[StateStore] 错误: " + message)
	
	# 使用事件总线发送错误消息
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		if event_bus.has_method("debug") and event_bus.debug.has_method("debug_message"):
			event_bus.debug.debug_message.emit(message, 2)

## 记录警告信息
func _log_warning(message: String) -> void:
	if debug_mode:
		print("[StateStore] 警告: " + message)
	
	# 使用事件总线发送警告消息
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		if event_bus.has_method("debug") and event_bus.debug.has_method("debug_message"):
			event_bus.debug.debug_message.emit(message, 1)

## 记录信息
func _log_info(message: String) -> void:
	if debug_mode:
		print("[StateStore] 信息: " + message)
	
	# 使用事件总线发送信息消息
	if has_node("/root/EventBus"):
		var event_bus = get_node("/root/EventBus")
		if event_bus.has_method("debug") and event_bus.debug.has_method("debug_message"):
			event_bus.debug.debug_message.emit(message, 0)
