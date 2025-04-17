extends "res://scripts/managers/core/base_manager.gd"
class_name SyncManager
## 数据同步管理器
## 负责同步游戏状态和处理网络数据

# 信号
signal state_synchronized(state_data)
signal entity_synchronized(entity_id, entity_data)
signal action_received(player_id, action_data)
signal sync_error(error_message)

# 同步类型
enum SyncType {
	FULL_STATE,    # 完整状态同步
	DELTA_STATE,   # 增量状态同步
	ENTITY_UPDATE, # 实体更新
	PLAYER_ACTION, # 玩家动作
	GAME_EVENT     # 游戏事件
}

# 同步配置
var sync_config = {
	"sync_interval": 0.1,        # 同步间隔（秒）
	"full_sync_interval": 5.0,   # 完整同步间隔（秒）
	"use_delta_compression": true, # 使用增量压缩
	"use_prediction": true,      # 使用预测
	"max_prediction_steps": 5,   # 最大预测步数
	"interpolation_delay": 0.1,  # 插值延迟（秒）
	"snapshot_history_size": 10  # 快照历史大小
}

# 网络管理器引用
var network_manager = null

# 游戏状态管理器引用
var game_state_manager = null

# 同步计时器
var _sync_timer = 0.0
var _full_sync_timer = 0.0

# 状态快照历史
var _state_history = []

# 预测状态
var _predicted_states = {}

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SyncManager"

	# 原 _ready 函数的内容
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 进程
func _process(delta: float) -> void:
	# 检查是否有网络管理器
	if network_manager == null or not network_manager.is_connected():
		return

	# 更新同步计时器
	_sync_timer += delta
	_full_sync_timer += delta

	# 检查是否需要同步
	if network_manager.is_host():
		# 主机同步逻辑
		if _sync_timer >= sync_config.sync_interval:
			_sync_timer = 0.0
			_sync_game_state(false)

		if _full_sync_timer >= sync_config.full_sync_interval:
			_full_sync_timer = 0.0
			_sync_game_state(true)

## 设置网络管理器
func set_network_manager(manager: NetworkManager) -> void:
	network_manager = manager

	# 连接信号
	if network_manager != null:
		network_manager.data_received.connect(_on_data_received)
		network_manager.connection_established.connect(_on_connection_established)
		network_manager.connection_closed.connect(_on_connection_closed)

## 设置游戏状态管理器
func set_game_state_manager(manager: Node) -> void:
	game_state_manager = manager

## 同步游戏状态
func _sync_game_state(full_sync: bool) -> void:
	# 检查是否有游戏状态管理器
	if game_state_manager == null:
		return

	# 获取当前游戏状态
	var state_data = {}

	if game_state_manager.has_method("get_sync_state"):
		state_data = game_state_manager.get_sync_state(full_sync)
	else:
		# 如果没有专门的同步方法，尝试获取完整状态
		if game_state_manager.has_method("get_game_state"):
			state_data = game_state_manager.get_game_state()
		else:
			sync_error.emit("游戏状态管理器没有提供状态获取方法")
			return

	# 添加同步类型
	state_data["sync_type"] = SyncType.FULL_STATE if full_sync else SyncType.DELTA_STATE

	# 添加时间戳
	state_data["timestamp"] = Time.get_unix_time_from_system()

	# 如果使用增量压缩，计算与上一个状态的差异
	if not full_sync and sync_config.use_delta_compression and not _state_history.is_empty():
		var last_state = _state_history.back()
		state_data = _calculate_delta_state(last_state, state_data)

	# 保存状态到历史
	_add_state_to_history(state_data)

	# 发送状态到所有客户端
	network_manager.send_data(state_data)

## 同步实体状态
func sync_entity(entity_id: String, entity_data: Dictionary) -> void:
	# 检查是否有网络管理器
	if network_manager == null or not network_manager.is_connected():
		return

	# 添加同步类型
	entity_data["sync_type"] = SyncType.ENTITY_UPDATE
	entity_data["entity_id"] = entity_id
	entity_data["timestamp"] = Time.get_unix_time_from_system()

	# 发送实体数据
	network_manager.send_data(entity_data)

## 发送玩家动作
func send_player_action(action_data: Dictionary) -> void:
	# 检查是否有网络管理器
	if network_manager == null or not network_manager.is_connected():
		return

	# 添加同步类型
	action_data["sync_type"] = SyncType.PLAYER_ACTION
	action_data["player_id"] = network_manager.get_local_player_id()
	action_data["timestamp"] = Time.get_unix_time_from_system()

	# 如果启用了预测，应用本地预测
	if sync_config.use_prediction and game_state_manager != null and game_state_manager.has_method("apply_player_action"):
		# 保存当前状态用于回滚
		var current_state = null
		if game_state_manager.has_method("get_game_state"):
			current_state = game_state_manager.get_game_state()

		# 应用动作进行预测
		game_state_manager.apply_player_action(action_data)

		# 保存预测状态
		_predicted_states[action_data.timestamp] = {
			"action": action_data,
			"previous_state": current_state
		}

		# 限制预测状态历史大小
		while _predicted_states.size() > sync_config.max_prediction_steps:
			var oldest_key = _predicted_states.keys().min()
			_predicted_states.erase(oldest_key)

	# 发送动作数据
	network_manager.send_data(action_data)

## 发送游戏事件
func send_game_event(event_data: Dictionary) -> void:
	# 检查是否有网络管理器
	if network_manager == null or not network_manager.is_connected():
		return

	# 添加同步类型
	event_data["sync_type"] = SyncType.GAME_EVENT
	event_data["timestamp"] = Time.get_unix_time_from_system()

	# 发送事件数据
	network_manager.send_data(event_data)

## 计算增量状态
func _calculate_delta_state(old_state: Dictionary, new_state: Dictionary) -> Dictionary:
	var delta_state = {"sync_type": SyncType.DELTA_STATE, "timestamp": new_state.timestamp, "changes": {}}

	# 遍历新状态，找出与旧状态的差异
	for key in new_state:
		if key == "sync_type" or key == "timestamp":
			continue

		if not old_state.has(key) or old_state[key] != new_state[key]:
			delta_state.changes[key] = new_state[key]

	return delta_state

## 应用增量状态
func _apply_delta_state(base_state: Dictionary, delta_state: Dictionary) -> Dictionary:
	var result_state = base_state.duplicate(true)

	# 应用变更
	for key in delta_state.changes:
		result_state[key] = delta_state.changes[key]

	# 更新时间戳
	result_state["timestamp"] = delta_state.timestamp

	return result_state

## 添加状态到历史
func _add_state_to_history(state: Dictionary) -> void:
	_state_history.append(state)

	# 限制历史大小
	while _state_history.size() > sync_config.snapshot_history_size:
		_state_history.pop_front()

## 应用状态到游戏
func _apply_state_to_game(state_data: Dictionary) -> void:
	# 检查是否有游戏状态管理器
	if game_state_manager == null:
		return

	# 发送状态同步信号
	state_synchronized.emit(state_data)

	# 应用状态
	if game_state_manager.has_method("apply_sync_state"):
		game_state_manager.apply_sync_state(state_data)
	else:
		sync_error.emit("游戏状态管理器没有提供状态应用方法")

## 应用实体更新
func _apply_entity_update(entity_data: Dictionary) -> void:
	# 检查是否有游戏状态管理器
	if game_state_manager == null:
		return

	var entity_id = entity_data.entity_id

	# 发送实体同步信号
	entity_synchronized.emit(entity_id, entity_data)

	# 应用实体更新
	if game_state_manager.has_method("apply_entity_update"):
		game_state_manager.apply_entity_update(entity_id, entity_data)
	else:
		sync_error.emit("游戏状态管理器没有提供实体更新方法")

## 处理玩家动作
func _handle_player_action(player_id: int, action_data: Dictionary) -> void:
	# 检查是否有游戏状态管理器
	if game_state_manager == null:
		return

	# 发送动作接收信号
	action_received.emit(player_id, action_data)

	# 如果是主机，应用动作并广播
	if network_manager.is_host():
		# 应用动作
		if game_state_manager.has_method("apply_player_action"):
			game_state_manager.apply_player_action(action_data)

		# 广播动作给其他客户端
		for peer_id in network_manager.players:
			if peer_id != network_manager.get_local_player_id() and peer_id != player_id:
				network_manager.send_data(action_data, peer_id)

	# 如果是客户端，检查是否需要回滚和重放
	elif sync_config.use_prediction:
		var action_timestamp = action_data.timestamp

		# 检查是否有对应的预测
		if _predicted_states.has(action_timestamp):
			var predicted = _predicted_states[action_timestamp]

			# 比较服务器动作和预测动作
			if _actions_differ(predicted.action, action_data):
				# 回滚到预测前的状态
				if game_state_manager.has_method("set_game_state") and predicted.previous_state != null:
					game_state_manager.set_game_state(predicted.previous_state)

				# 应用服务器动作
				if game_state_manager.has_method("apply_player_action"):
					game_state_manager.apply_player_action(action_data)

				# 重放后续预测
				_replay_predictions_after(action_timestamp)

			# 清理已确认的预测
			_predicted_states.erase(action_timestamp)
		else:
			# 直接应用动作
			if game_state_manager.has_method("apply_player_action"):
				game_state_manager.apply_player_action(action_data)

## 处理游戏事件
func _handle_game_event(event_data: Dictionary) -> void:
	# 检查是否有游戏状态管理器
	if game_state_manager == null:
		return

	# 应用事件
	if game_state_manager.has_method("apply_game_event"):
		game_state_manager.apply_game_event(event_data)
	else:
		sync_error.emit("游戏状态管理器没有提供事件应用方法")

## 比较两个动作是否不同
func _actions_differ(action1: Dictionary, action2: Dictionary) -> bool:
	# 简单比较，实际应用中可能需要更复杂的比较逻辑
	for key in action1:
		if key == "timestamp" or key == "player_id":
			continue

		if not action2.has(key) or action1[key] != action2[key]:
			return true

	return false

## 重放指定时间戳后的预测
func _replay_predictions_after(timestamp: float) -> void:
	# 获取所有时间戳大于指定时间戳的预测
	var timestamps_to_replay = []
	for ts in _predicted_states:
		if ts > timestamp:
			timestamps_to_replay.append(ts)

	# 按时间戳排序
	timestamps_to_replay.sort()

	# 重放预测
	for ts in timestamps_to_replay:
		var action = _predicted_states[ts].action
		if game_state_manager.has_method("apply_player_action"):
			game_state_manager.apply_player_action(action)

## 数据接收事件处理
func _on_data_received(sender_id: int, data: Variant) -> void:
	# 检查数据是否有效
	if not data is Dictionary or not data.has("sync_type"):
		return

	# 根据同步类型处理数据
	match data.sync_type:
		SyncType.FULL_STATE:
			_apply_state_to_game(data)

		SyncType.DELTA_STATE:
			# 如果是增量状态，需要找到基础状态
			if not _state_history.is_empty():
				var base_state = _state_history.back()
				var full_state = _apply_delta_state(base_state, data)
				_apply_state_to_game(full_state)
				_add_state_to_history(full_state)
			else:
				sync_error.emit("收到增量状态但没有基础状态")

		SyncType.ENTITY_UPDATE:
			_apply_entity_update(data)

		SyncType.PLAYER_ACTION:
			_handle_player_action(sender_id, data)

		SyncType.GAME_EVENT:
			_handle_game_event(data)

## 连接建立事件处理
func _on_connection_established(peer_id: int) -> void:
	# 重置同步计时器
	_sync_timer = 0.0
	_full_sync_timer = 0.0

	# 清空状态历史
	_state_history.clear()

	# 清空预测状态
	_predicted_states.clear()

	# 如果是主机，立即发送完整状态
	if network_manager.is_host():
		_sync_game_state(true)

## 连接关闭事件处理
func _on_connection_closed() -> void:
	# 清空状态历史
	_state_history.clear()

	# 清空预测状态
	_predicted_states.clear()

## 设置同步配置
func set_sync_config(config: Dictionary) -> void:
	# 更新配置
	for key in config:
		if sync_config.has(key):
			sync_config[key] = config[key]

	EventBus.debug.emit_event("debug_message", ["同步配置已更新", 0])

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
