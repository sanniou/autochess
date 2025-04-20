extends "res://scripts/managers/core/base_manager.gd"
class_name StateManager
## 状态管理器
## 负责管理应用状态，提供统一的状态访问和更新接口

# 状态存储
var state_store = null

# 状态定义
var game_state_class = null

# 状态动作
var state_actions = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "StateManager"

	# 添加依赖
	add_dependency("StatsManager")

	# 加载状态定义
	game_state_class = load("res://scripts/state/game_state.gd")

	# 加载状态动作
	state_actions = load("res://scripts/state/state_actions.gd")

	# 创建状态存储
	state_store = load("res://scripts/state/state_store.gd").new()
	add_child(state_store)

	# 初始化状态
	_initialize_state()

	# 连接事件总线
	_connect_event_bus()

	EventBus.debug.emit_event("debug_message", ["状态管理器初始化完成", 0])

## 初始化状态
func _initialize_state() -> void:
	# 加载保存的状态
	var saved_state = _load_saved_state()

	if not saved_state.is_empty():
		state_store.load_state(saved_state)
	else:
		# 使用默认状态
		state_store.reset_state()

## 连接事件总线
func _connect_event_bus() -> void:
	# 连接游戏事件
	EventBus.game.connect_event("game_started", _on_game_started)
	EventBus.game.connect_event("game_ended", _on_game_ended)
	EventBus.game.connect_event("game_paused", _on_game_paused)
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 连接玩家事件
	EventBus.game.connect_event("player_health_changed", _on_player_health_changed)
	EventBus.game.connect_event("player_level_changed", _on_player_level_changed)
	EventBus.game.connect_event("player_died", _on_player_died)

	# 连接棋盘事件
	EventBus.board.connect_event("board_initialized", _on_board_initialized)
	EventBus.board.connect_event("piece_placed", _on_piece_placed)
	EventBus.board.connect_event("piece_removed", _on_piece_removed)
	EventBus.board.connect_event("piece_moved", _on_piece_moved)
	EventBus.board.connect_event("board_locked", _on_board_locked)

	# 连接战斗事件
	EventBus.battle.connect_event("battle_started", _on_battle_started)
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)

	# 连接经济事件
	EventBus.economy.connect_event("gold_changed", _on_gold_changed)

	# 连接地图事件
	EventBus.map.connect_event("map_generated", _on_map_generated)
	EventBus.map.connect_event("map_node_selected", _on_map_node_selected)

	# 连接UI事件
	EventBus.ui.connect_event("ui_screen_changed", _on_ui_screen_changed)
	EventBus.ui.connect_event("show_notification", _on_show_notification)

	# 连接设置事件
	EventBus.ui.connect_event("language_changed", _on_language_changed)

	# 连接成就事件
	EventBus.achievement.connect_event("achievement_unlocked", _on_achievement_unlocked)
	EventBus.achievement.connect_event("achievement_progress_updated", _on_achievement_progress_updated)

## 获取状态
func get_state() -> Dictionary:
	return state_store.get_state()

## 获取特定状态
func get_state_section(section: String) -> Dictionary:
	return state_store.get_state_section(section)

## 获取特定状态值
func get_state_value(path: String, default_value = null) -> Variant:
	return state_store.get_state_value(path, default_value)

## 分发动作
func dispatch(action) -> void:
	state_store.dispatch(action)

## 订阅状态变更
func subscribe(section: String, subscriber: Object, method: String) -> bool:
	return state_store.subscribe(section, subscriber, method)

## 取消订阅状态变更
func unsubscribe(section: String, subscriber: Object, method: String) -> bool:
	return state_store.unsubscribe(section, subscriber, method)

## 取消对象的所有订阅
func unsubscribe_all(subscriber: Object) -> int:
	return state_store.unsubscribe_all(subscriber)

## 重置状态
func reset_state() -> void:
	state_store.reset_state()

## 保存状态
func save_state() -> void:
	var state_data = state_store.save_state()
	_save_state_to_disk(state_data)

## 加载状态
func load_state() -> bool:
	var state_data = _load_saved_state()

	if state_data.is_empty():
		_log_warning("加载状态失败：没有保存的状态")
		return false

	return state_store.load_state(state_data)

## 从磁盘加载保存的状态
func _load_saved_state() -> Dictionary:
	# 检查保存文件是否存在
	if not FileAccess.file_exists("user://state.json"):
		return {}

	# 打开文件
	var file = FileAccess.open("user://state.json", FileAccess.READ)
	if file == null:
		_log_error("无法打开状态文件")
		return {}

	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()

	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		_log_error("解析状态文件失败: " + json.get_error_message())
		return {}

	return json.get_data()

## 将状态保存到磁盘
func _save_state_to_disk(state_data: Dictionary) -> bool:
	# 打开文件
	var file = FileAccess.open("user://state.json", FileAccess.WRITE)
	if file == null:
		_log_error("无法打开状态文件进行写入")
		return false

	# 将状态转换为JSON
	var json_text = JSON.stringify(state_data)

	# 写入文件
	file.store_string(json_text)
	file.close()

	_log_info("状态已保存到磁盘")
	return true

## 创建动作
func create_action(action_type: String, params: Dictionary = {}) -> Object:
	match action_type:
		# 游戏状态动作
		"SET_GAME_STATE":
			return state_actions.GameActions.SetGameState.new(params.get("state", 0))
		"SET_DIFFICULTY":
			return state_actions.GameActions.SetDifficulty.new(params.get("difficulty", 1))
		"SET_GAME_MODE":
			return state_actions.GameActions.SetGameMode.new(params.get("game_mode", "standard"))
		"SET_PAUSED":
			return state_actions.GameActions.SetPaused.new(params.get("is_paused", false))
		"SET_GAME_OVER":
			return state_actions.GameActions.SetGameOver.new(params.get("is_game_over", false), params.get("win", false))
		"NEXT_TURN":
			return state_actions.GameActions.NextTurn.new()
		"SET_PHASE":
			return state_actions.GameActions.SetPhase.new(params.get("phase", "preparation"))
		"SET_SEED":
			return state_actions.GameActions.SetSeed.new(params.get("seed_value", 0))

		# 玩家状态动作
		"SET_HEALTH":
			return state_actions.PlayerActions.SetHealth.new(params.get("health", 100))
		"CHANGE_HEALTH":
			return state_actions.PlayerActions.ChangeHealth.new(params.get("amount", 0))
		"SET_GOLD":
			return state_actions.PlayerActions.SetGold.new(params.get("gold", 0))
		"CHANGE_GOLD":
			return state_actions.PlayerActions.ChangeGold.new(params.get("amount", 0))
		"SET_EXPERIENCE":
			return state_actions.PlayerActions.SetExperience.new(params.get("experience", 0))
		"CHANGE_EXPERIENCE":
			return state_actions.PlayerActions.ChangeExperience.new(params.get("amount", 0))
		"ADD_RELIC":
			return state_actions.PlayerActions.AddRelic.new(params.get("relic_id", ""))
		"REMOVE_RELIC":
			return state_actions.PlayerActions.RemoveRelic.new(params.get("relic_id", ""))
		"RECORD_BATTLE_RESULT":
			return state_actions.PlayerActions.RecordBattleResult.new(params.get("win", false))

		# 棋盘状态动作
		"SET_BOARD_SIZE":
			return state_actions.BoardActions.SetBoardSize.new(params.get("size", Vector2i(8, 8)))
		"PLACE_PIECE":
			return state_actions.BoardActions.PlacePiece.new(params.get("piece_id", ""), params.get("position", Vector2i(0, 0)))
		"REMOVE_PIECE":
			return state_actions.BoardActions.RemovePiece.new(params.get("position", Vector2i(0, 0)))
		"MOVE_PIECE":
			return state_actions.BoardActions.MovePiece.new(params.get("from_position", Vector2i(0, 0)), params.get("to_position", Vector2i(0, 0)))
		"LOCK_BOARD":
			return state_actions.BoardActions.LockBoard.new(params.get("locked", false))
		"SET_BATTLE_STATE":
			return state_actions.BoardActions.SetBattleState.new(params.get("battle_in_progress", false), params.get("battle_id", ""))
		"UPDATE_SYNERGY":
			return state_actions.BoardActions.UpdateSynergy.new(params.get("synergy_id", ""), params.get("level", 0))
		"CLEAR_BOARD":
			return state_actions.BoardActions.ClearBoard.new()

		# 商店状态动作
		"SET_SHOP_OPEN":
			return state_actions.ShopActions.SetShopOpen.new(params.get("is_open", false))
		"SET_SHOP_ITEMS":
			return state_actions.ShopActions.SetShopItems.new(params.get("items", []))
		"REFRESH_SHOP":
			return state_actions.ShopActions.RefreshShop.new()
		"BUY_ITEM":
			return state_actions.ShopActions.BuyItem.new(params.get("item_index", 0))
		"LOCK_ITEM":
			return state_actions.ShopActions.LockItem.new(params.get("item_index", 0), params.get("locked", false))
		"SET_SHOP_TIER":
			return state_actions.ShopActions.SetShopTier.new(params.get("tier", 1))

		# 地图状态动作
		"SET_MAP":
			return state_actions.MapActions.SetMap.new(params.get("map_data", {}))
		"SELECT_NODE":
			return state_actions.MapActions.SelectNode.new(params.get("node_id", ""))
		"VISIT_NODE":
			return state_actions.MapActions.VisitNode.new(params.get("node_id", ""))
		"SET_AVAILABLE_NODES":
			return state_actions.MapActions.SetAvailableNodes.new(params.get("nodes", []))
		"SET_MAP_LEVEL":
			return state_actions.MapActions.SetMapLevel.new(params.get("level", 1))

		# UI状态动作
		"SET_SCREEN":
			return state_actions.UIActions.SetScreen.new(params.get("screen", "main_menu"))
		"OPEN_WINDOW":
			return state_actions.UIActions.OpenWindow.new(params.get("window", ""))
		"CLOSE_WINDOW":
			return state_actions.UIActions.CloseWindow.new(params.get("window", ""))
		"SELECT_ITEM":
			return state_actions.UIActions.SelectItem.new(params.get("item_id", ""))
		"SET_DRAG_ITEM":
			return state_actions.UIActions.SetDragItem.new(params.get("item_id", ""))
		"SHOW_TOOLTIP":
			return state_actions.UIActions.ShowTooltip.new(params.get("text", ""), params.get("show", true))
		"ADD_NOTIFICATION":
			return state_actions.UIActions.AddNotification.new(params.get("message", ""), params.get("type", "info"), params.get("duration", 3.0))
		"CLEAR_NOTIFICATIONS":
			return state_actions.UIActions.ClearNotifications.new()

		# 设置状态动作
		"SET_VOLUME":
			return state_actions.SettingsActions.SetVolume.new(params.get("volume_type", "master"), params.get("volume", 1.0))
		"SET_FULLSCREEN":
			return state_actions.SettingsActions.SetFullscreen.new(params.get("fullscreen", false))
		"SET_LANGUAGE":
			return state_actions.SettingsActions.SetLanguage.new(params.get("language", "zh_CN"))
		"SET_SHOW_FPS":
			return state_actions.SettingsActions.SetShowFPS.new(params.get("show_fps", false))
		"SET_VSYNC":
			return state_actions.SettingsActions.SetVSync.new(params.get("vsync_enabled", true))
		"SET_PARTICLE_QUALITY":
			return state_actions.SettingsActions.SetParticleQuality.new(params.get("quality", 2))
		"SET_UI_SCALE":
			return state_actions.SettingsActions.SetUIScale.new(params.get("scale", 1.0))

		# 成就状态动作
		"UNLOCK_ACHIEVEMENT":
			return state_actions.AchievementActions.UnlockAchievement.new(params.get("achievement_id", ""))
		"UPDATE_ACHIEVEMENT_PROGRESS":
			return state_actions.AchievementActions.UpdateAchievementProgress.new(params.get("achievement_id", ""), params.get("progress", 0))

		# 统计状态动作
		"RECORD_GAME_RESULT":
			return state_actions.StatsActions.RecordGameResult.new(params.get("win", false))
		"RECORD_GOLD_EARNED":
			return state_actions.StatsActions.RecordGoldEarned.new(params.get("amount", 0))
		"RECORD_DAMAGE":
			return state_actions.StatsActions.RecordDamage.new(params.get("amount", 0), params.get("is_dealt", true))
		"RECORD_HEALING":
			return state_actions.StatsActions.RecordHealing.new(params.get("amount", 0))
		"RECORD_CHESS_PIECE_BOUGHT":
			return state_actions.StatsActions.RecordChessPieceBought.new(params.get("piece_id", ""))
		"RECORD_CHESS_PIECE_3STAR":
			return state_actions.StatsActions.RecordChessPiece3Star.new(params.get("piece_id", ""))
		"RECORD_SYNERGY_ACTIVATED":
			return state_actions.StatsActions.RecordSynergyActivated.new(params.get("synergy_id", ""))

		_:
			_log_error("创建动作失败：未知的动作类型 - " + action_type)
			return null

## 事件处理器
func _on_game_started() -> void:
	dispatch(create_action("SET_GAME_OVER", {"is_game_over": false}))
	dispatch(create_action("SET_PHASE", {"phase": "preparation"}))
	dispatch(create_action("SET_SCREEN", {"screen": "game"}))

func _on_game_ended(win: bool) -> void:
	dispatch(create_action("SET_GAME_OVER", {"is_game_over": true, "win": win}))
	dispatch(create_action("RECORD_GAME_RESULT", {"win": win}))

	# 使用 StatsManager 记录游戏结果
	var stats_manager = GameManager.stats_manager
	if stats_manager:
		stats_manager.increment_stat("games_played")
		if win:
			stats_manager.increment_stat("games_won")
		else:
			stats_manager.increment_stat("games_lost")

func _on_game_paused(is_paused: bool) -> void:
	dispatch(create_action("SET_PAUSED", {"is_paused": is_paused}))

func _on_game_state_changed(old_state: int, new_state: int) -> void:
	dispatch(create_action("SET_GAME_STATE", {"state": new_state}))

func _on_player_health_changed(old_health: int, new_health: int) -> void:
	dispatch(create_action("SET_HEALTH", {"health": new_health}))

func _on_player_level_changed(old_level: int, new_level: int) -> void:
	var experience = get_state_value("player.experience", 0)
	dispatch(create_action("SET_EXPERIENCE", {"experience": experience}))

func _on_player_died() -> void:
	dispatch(create_action("SET_HEALTH", {"health": 0}))
	dispatch(create_action("SET_GAME_OVER", {"is_game_over": true, "win": false}))

func _on_board_initialized() -> void:
	dispatch(create_action("CLEAR_BOARD"))

func _on_piece_placed(piece, position: Vector2i) -> void:
	dispatch(create_action("PLACE_PIECE", {"piece_id": piece.id, "position": position}))

func _on_piece_removed(piece, position: Vector2i) -> void:
	dispatch(create_action("REMOVE_PIECE", {"position": position}))

func _on_piece_moved(piece, from_pos: Vector2i, to_pos: Vector2i) -> void:
	dispatch(create_action("MOVE_PIECE", {"from_position": from_pos, "to_position": to_pos}))

func _on_board_locked(locked: bool) -> void:
	dispatch(create_action("LOCK_BOARD", {"locked": locked}))

func _on_battle_started() -> void:
	dispatch(create_action("SET_BATTLE_STATE", {"battle_in_progress": true, "battle_id": str(Time.get_unix_time_from_system())}))
	dispatch(create_action("SET_PHASE", {"phase": "battle"}))

func _on_battle_ended(result) -> void:
	dispatch(create_action("SET_BATTLE_STATE", {"battle_in_progress": false, "battle_id": ""}))
	dispatch(create_action("SET_PHASE", {"phase": "preparation"}))
	dispatch(create_action("RECORD_BATTLE_RESULT", {"win": result.is_victory}))

	# 使用 StatsManager 记录战斗结果
	var stats_manager = GameManager.stats_manager
	if stats_manager:
		stats_manager.increment_stat("battles_played")
		if result.is_victory:
			stats_manager.increment_stat("battles_won")
		else:
			stats_manager.increment_stat("battles_lost")

		# 更新伤害和治疗统计
		if result.has("player_damage_dealt"):
			stats_manager.increment_stat("total_damage_dealt", result.player_damage_dealt)

		if result.has("player_healing"):
			stats_manager.increment_stat("total_healing", result.player_healing)

func _on_gold_changed(old_value: int, new_value: int) -> void:
	dispatch(create_action("SET_GOLD", {"gold": new_value}))

	if new_value > old_value:
		var amount = new_value - old_value
		dispatch(create_action("RECORD_GOLD_EARNED", {"amount": amount}))

		# 使用 StatsManager 记录金币获取
		var stats_manager = GameManager.stats_manager
		if stats_manager:
			stats_manager.increment_stat("total_gold_earned", amount)

func _on_map_generated() -> void:
	# 获取地图数据
	var map_data = {}  # 这里应该从地图生成器获取地图数据
	dispatch(create_action("SET_MAP", {"map_data": map_data}))

func _on_map_node_selected(node_data) -> void:
	if node_data.has("id"):
		dispatch(create_action("SELECT_NODE", {"node_id": node_data.id}))

func _on_ui_screen_changed(old_screen: String, new_screen: String) -> void:
	dispatch(create_action("SET_SCREEN", {"screen": new_screen}))

func _on_show_notification(message: String, notification_type: String = "info", duration: float = 3.0, notification_id = null) -> void:
	dispatch(create_action("ADD_NOTIFICATION", {"message": message, "type": notification_type, "duration": duration}))

func _on_language_changed(language_code: String) -> void:
	dispatch(create_action("SET_LANGUAGE", {"language": language_code}))

func _on_achievement_unlocked(achievement_id: String) -> void:
	dispatch(create_action("UNLOCK_ACHIEVEMENT", {"achievement_id": achievement_id}))

func _on_achievement_progress_updated(achievement_id: String, old_progress: int, new_progress: int) -> void:
	dispatch(create_action("UPDATE_ACHIEVEMENT_PROGRESS", {"achievement_id": achievement_id, "progress": new_progress}))

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
