extends "res://scripts/managers/core/base_manager.gd"
class_name NetworkManager
## 网络管理器
## 负责处理网络连接、断开和数据同步

# 信号
signal connection_established(peer_id)
signal connection_failed(error)
signal connection_closed()
signal peer_connected(peer_id)
signal peer_disconnected(peer_id)
signal server_created()
signal server_closed()
signal network_state_changed(old_state, new_state)
signal network_error(error_code, error_message)
signal data_received(peer_id, data)

# 网络状态
enum NetworkState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	HOSTING
}

# 当前网络状态
var current_state = NetworkState.DISCONNECTED

# 网络配置
var network_config = {
	"server_port": 7777,
	"max_players": 8,
	"use_upnp": true,
	"auto_reconnect": true,
	"reconnect_attempts": 3,
	"reconnect_delay": 2.0,  # 秒
	"ping_interval": 1.0,    # 秒
	"timeout": 10.0,         # 秒
	"compression_mode": ENetConnection.COMPRESS_RANGE_CODER
}

# 玩家信息
var players = {}

# 本地玩家ID
var local_player_id = 0

# 服务器ID
const SERVER_ID = 1

# 重连尝试次数
var _reconnect_attempts = 0

# 重连计时器
var _reconnect_timer = 0.0

# Ping计时器
var _ping_timer = 0.0

# 多人游戏ENet对象
var _multiplayer_peer = null

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "NetworkManager"

	# 原 _ready 函数的内容
	# 设置进程模式
		process_mode = Node.PROCESS_MODE_ALWAYS

		# 连接信号
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	# 进程
func _process(delta: float) -> void:
	match current_state:
		NetworkState.CONNECTING:
			# 处理重连逻辑
			if network_config.auto_reconnect and _reconnect_timer > 0:
				_reconnect_timer -= delta
				if _reconnect_timer <= 0 and _reconnect_attempts < network_config.reconnect_attempts:
					_reconnect()

		NetworkState.CONNECTED, NetworkState.HOSTING:
			# 处理Ping逻辑
			_ping_timer -= delta
			if _ping_timer <= 0:
				_ping_timer = network_config.ping_interval
				_send_ping()

## 创建服务器
func create_server() -> bool:
	# 如果已经连接，先断开
	if current_state != NetworkState.DISCONNECTED:
		close_connection()

	# 创建ENet对等体
	_multiplayer_peer = ENetMultiplayerPeer.new()

	# 创建服务器
	var error = _multiplayer_peer.create_server(network_config.server_port, network_config.max_players)
	if error != OK:
		network_error.emit(error, "无法创建服务器")
		return false

	# 设置压缩模式
	_multiplayer_peer.set_compression_mode(network_config.compression_mode)

	# 设置多人游戏对等体
	multiplayer.multiplayer_peer = _multiplayer_peer

	# 更新状态
	_change_state(NetworkState.HOSTING)

	# 设置本地玩家ID
	local_player_id = SERVER_ID

	# 添加本地玩家信息
	players[local_player_id] = {
		"id": local_player_id,
		"name": "主机",
		"is_host": true,
		"ping": 0
	}

	# 如果启用了UPNP，尝试映射端口
	if network_config.use_upnp:
		_setup_upnp()

	# 发送服务器创建信号
	server_created.emit()

	EventBus.debug.debug_message.emit("服务器已创建，端口: " + str(network_config.server_port), 0)
	return true

## 连接到服务器
func connect_to_server(address: String, port: int = -1) -> bool:
	# 如果已经连接，先断开
	if current_state != NetworkState.DISCONNECTED:
		close_connection()

	# 如果未指定端口，使用默认端口
	if port < 0:
		port = network_config.server_port

	# 创建ENet对等体
	_multiplayer_peer = ENetMultiplayerPeer.new()

	# 设置压缩模式
	_multiplayer_peer.set_compression_mode(network_config.compression_mode)

	# 更新状态
	_change_state(NetworkState.CONNECTING)

	# 连接到服务器
	var error = _multiplayer_peer.create_client(address, port)
	if error != OK:
		_change_state(NetworkState.DISCONNECTED)
		network_error.emit(error, "无法连接到服务器")
		return false

	# 设置多人游戏对等体
	multiplayer.multiplayer_peer = _multiplayer_peer

	# 重置重连尝试
	_reconnect_attempts = 0

	EventBus.debug.debug_message.emit("正在连接到服务器: " + address + ":" + str(port), 0)
	return true

## 关闭连接
func close_connection() -> void:
	# 如果未连接，直接返回
	if current_state == NetworkState.DISCONNECTED:
		return

	# 关闭UPNP映射
	if current_state == NetworkState.HOSTING and network_config.use_upnp:
		_close_upnp()

	# 清理多人游戏对等体
	if _multiplayer_peer != null:
		_multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_multiplayer_peer = null

	# 清理玩家信息
	players.clear()
	local_player_id = 0

	# 更新状态
	_change_state(NetworkState.DISCONNECTED)

	# 发送连接关闭信号
	connection_closed.emit()

	EventBus.debug.debug_message.emit("网络连接已关闭", 0)

## 发送数据
func send_data(data: Variant, target_peer: int = 0) -> bool:
	# 检查是否已连接
	if current_state != NetworkState.CONNECTED and current_state != NetworkState.HOSTING:
		return false

	# 使用RPC发送数据
	if target_peer == 0:
		# 广播给所有人
		_receive_data.rpc(local_player_id, data)
	else:
		# 发送给特定玩家
		_receive_data.rpc_id(target_peer, local_player_id, data)

	return true

## 设置玩家信息
func set_player_info(player_name: String) -> void:
	# 检查是否已连接
	if current_state != NetworkState.CONNECTED and current_state != NetworkState.HOSTING:
		return

	# 更新本地玩家信息
	if players.has(local_player_id):
		players[local_player_id].name = player_name

	# 如果是客户端，发送信息到服务器
	if current_state == NetworkState.CONNECTED:
		_update_player_info.rpc_id(SERVER_ID, player_name)

## 获取玩家列表
func get_player_list() -> Array:
	var player_list = []
	for player_id in players:
		player_list.append(players[player_id])
	return player_list

## 获取玩家信息
func get_player_info(player_id: int) -> Dictionary:
	if players.has(player_id):
		return players[player_id]
	return {}

## 是否是主机
func is_host() -> bool:
	return current_state == NetworkState.HOSTING

## 是否是客户端
func is_client() -> bool:
	return current_state == NetworkState.CONNECTED

## 是否已连接
func is_connected() -> bool:
	return current_state == NetworkState.CONNECTED or current_state == NetworkState.HOSTING

## 获取本地玩家ID
func get_local_player_id() -> int:
	return local_player_id

## 设置网络配置
func set_network_config(config: Dictionary) -> void:
	# 更新配置
	for key in config:
		if network_config.has(key):
			network_config[key] = config[key]

	EventBus.debug.debug_message.emit("网络配置已更新", 0)

## 接收数据（RPC方法）
@rpc("any_peer", "reliable")
func _receive_data(sender_id: int, data: Variant) -> void:
	# 发送数据接收信号
	data_received.emit(sender_id, data)

## 更新玩家信息（RPC方法）
@rpc("any_peer", "reliable")
func _update_player_info(player_name: String) -> void:
	# 获取发送者ID
	var sender_id = multiplayer.get_remote_sender_id()

	# 更新玩家信息
	if players.has(sender_id):
		players[sender_id].name = player_name

	# 如果是服务器，广播更新
	if current_state == NetworkState.HOSTING:
		_sync_player_info.rpc(players)

## 同步玩家信息（RPC方法）
@rpc("authority", "reliable")
func _sync_player_info(player_data: Dictionary) -> void:
	# 更新玩家信息
	players = player_data

## 发送Ping（RPC方法）
@rpc("any_peer", "unreliable")
func _ping() -> void:
	# 获取发送者ID
	var sender_id = multiplayer.get_remote_sender_id()

	# 回复Pong
	_pong.rpc_id(sender_id)

## 接收Pong（RPC方法）
@rpc("any_peer", "unreliable")
func _pong() -> void:
	# 获取发送者ID
	var sender_id = multiplayer.get_remote_sender_id()

	# 更新玩家Ping
	if players.has(sender_id):
		# 这里应该计算实际的Ping值
		# 暂时使用随机值作为示例
		players[sender_id].ping = randi() % 100

## 发送Ping
func _send_ping() -> void:
	# 如果是客户端，发送Ping到服务器
	if current_state == NetworkState.CONNECTED:
		_ping.rpc_id(SERVER_ID)

	# 如果是服务器，发送Ping到所有客户端
	elif current_state == NetworkState.HOSTING:
		for player_id in players:
			if player_id != local_player_id:
				_ping.rpc_id(player_id)

## 重连到服务器
func _reconnect() -> void:
	# 增加重连尝试次数
	_reconnect_attempts += 1

	# 尝试重新连接
	if _multiplayer_peer != null:
		_multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_multiplayer_peer = null

	# 创建新的对等体
	_multiplayer_peer = ENetMultiplayerPeer.new()

	# 设置压缩模式
	_multiplayer_peer.set_compression_mode(network_config.compression_mode)

	# 连接到服务器
	var error = _multiplayer_peer.create_client(multiplayer.get_remote_sender_id(), network_config.server_port)
	if error != OK:
		_change_state(NetworkState.DISCONNECTED)
		network_error.emit(error, "重连失败")
		return

	# 设置多人游戏对等体
	multiplayer.multiplayer_peer = _multiplayer_peer

	# 设置重连计时器
	_reconnect_timer = network_config.reconnect_delay

	EventBus.debug.debug_message.emit("尝试重连 (" + str(_reconnect_attempts) + "/" + str(network_config.reconnect_attempts) + ")", 0)

## 设置UPNP
func _setup_upnp() -> void:
	# 创建UPNP对象
	var upnp = UPNP.new()

	# 发现UPNP设备
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		EventBus.debug.debug_message.emit("UPNP发现失败: " + str(discover_result), 1)
		return

	# 获取网关
	var gateway = upnp.get_gateway()
	if gateway == null:
		EventBus.debug.debug_message.emit("无法获取UPNP网关", 1)
		return

	# 映射端口
	var map_result = gateway.add_port_mapping(network_config.server_port, network_config.server_port, "GodotServer", "UDP")
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		EventBus.debug.debug_message.emit("UPNP端口映射失败: " + str(map_result), 1)
		return

	EventBus.debug.debug_message.emit("UPNP端口映射成功: " + str(network_config.server_port), 0)

## 关闭UPNP
func _close_upnp() -> void:
	# 创建UPNP对象
	var upnp = UPNP.new()

	# 发现UPNP设备
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		return

	# 获取网关
	var gateway = upnp.get_gateway()
	if gateway == null:
		return

	# 删除端口映射
	gateway.delete_port_mapping(network_config.server_port, "UDP")

	EventBus.debug.debug_message.emit("UPNP端口映射已删除", 0)

## 更改网络状态
func _change_state(new_state: int) -> void:
	var old_state = current_state
	current_state = new_state

	# 发送状态变化信号
	network_state_changed.emit(old_state, new_state)

## 对等体连接事件处理
func _on_peer_connected(id: int) -> void:
	# 添加玩家信息
	players[id] = {
		"id": id,
		"name": "玩家" + str(id),
		"is_host": false,
		"ping": 0
	}

	# 如果是服务器，广播更新
	if current_state == NetworkState.HOSTING:
		_sync_player_info.rpc(players)

	# 发送玩家连接信号
	peer_connected.emit(id)

	EventBus.debug.debug_message.emit("玩家已连接: " + str(id), 0)

## 对等体断开事件处理
func _on_peer_disconnected(id: int) -> void:
	# 移除玩家信息
	if players.has(id):
		players.erase(id)

	# 如果是服务器，广播更新
	if current_state == NetworkState.HOSTING:
		_sync_player_info.rpc(players)

	# 发送玩家断开信号
	peer_disconnected.emit(id)

	EventBus.debug.debug_message.emit("玩家已断开: " + str(id), 0)

## 连接到服务器事件处理
func _on_connected_to_server() -> void:
	# 更新状态
	_change_state(NetworkState.CONNECTED)

	# 设置本地玩家ID
	local_player_id = multiplayer.get_unique_id()

	# 添加本地玩家信息
	players[local_player_id] = {
		"id": local_player_id,
		"name": "玩家" + str(local_player_id),
		"is_host": false,
		"ping": 0
	}

	# 重置Ping计时器
	_ping_timer = network_config.ping_interval

	# 发送连接建立信号
	connection_established.emit(local_player_id)

	EventBus.debug.debug_message.emit("已连接到服务器，玩家ID: " + str(local_player_id), 0)

## 连接失败事件处理
func _on_connection_failed() -> void:
	# 更新状态
	_change_state(NetworkState.DISCONNECTED)

	# 清理多人游戏对等体
	if _multiplayer_peer != null:
		_multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_multiplayer_peer = null

	# 如果启用了自动重连，设置重连计时器
	if network_config.auto_reconnect and _reconnect_attempts < network_config.reconnect_attempts:
		_reconnect_timer = network_config.reconnect_delay
	else:
		# 发送连接失败信号
		connection_failed.emit("连接失败")

	EventBus.debug.debug_message.emit("连接到服务器失败", 1)

## 服务器断开事件处理
func _on_server_disconnected() -> void:
	# 更新状态
	_change_state(NetworkState.DISCONNECTED)

	# 清理多人游戏对等体
	if _multiplayer_peer != null:
		_multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_multiplayer_peer = null

	# 清理玩家信息
	players.clear()
	local_player_id = 0

	# 发送连接关闭信号
	connection_closed.emit()

	EventBus.debug.debug_message.emit("服务器已断开连接", 1)

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.debug_message.emit(error_message, 2)
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.debug_message.emit(info_message, 0)
