extends Node
## 事件总线系统
## 负责全局事件的分发和处理，实现系统间的松耦合通信

# 游戏状态相关信号
signal game_state_changed(old_state, new_state)
signal game_paused(is_paused)
signal game_started
signal game_ended(win)

# 地图相关信号
signal map_generated
signal map_node_selected(node_data)
signal map_completed

# 棋盘相关信号
signal board_initialized
signal cell_selected(cell_position)
signal cell_hovered(cell_position)

# 棋子相关信号
signal chess_piece_created(piece_data)
signal chess_piece_upgraded(piece_data)
signal chess_piece_sold(piece_data)
signal chess_piece_moved(piece_data, from_pos, to_pos)
signal chess_piece_ability_activated(piece_data, target_data)
signal synergy_activated(synergy_type, level)
signal synergy_deactivated(synergy_type)

# 战斗相关信号
signal battle_started
signal battle_ended(result)
signal battle_round_started(round_number)
signal battle_round_ended(round_number)
signal damage_dealt(source, target, amount, damage_type)
signal unit_died(unit_data)

# 经济相关信号
signal gold_changed(old_amount, new_amount)
signal shop_refreshed
signal item_purchased(item_data)
signal item_sold(item_data)

# 装备相关信号
signal equipment_created(equipment_data)
signal equipment_equipped(equipment_data, piece_data)
signal equipment_unequipped(equipment_data, piece_data)
signal equipment_combined(base_equipment, target_equipment, result_equipment)

# 遗物相关信号
signal relic_acquired(relic_data)
signal relic_activated(relic_data)
signal relic_effect_triggered(relic_data, effect_data)

# 事件相关信号
signal event_triggered(event_data)
signal event_choice_made(event_data, choice_data)
signal event_completed(event_data, result_data)

# 玩家相关信号
signal player_health_changed(old_health, new_health)
signal player_level_changed(old_level, new_level)
signal player_died

# UI相关信号
signal ui_screen_changed(old_screen, new_screen)
signal ui_popup_opened(popup_name)
signal ui_popup_closed(popup_name)
signal ui_button_pressed(button_name)

# 成就相关信号
signal achievement_progress(achievement_id, progress, total)
signal achievement_unlocked(achievement_id)

# 存档相关信号
signal game_saved(save_slot)
signal game_loaded(save_slot)
signal autosave_triggered

# 多语言相关信号
signal language_changed(new_language)

# 音频相关信号
signal bgm_changed(track_name)
signal sfx_played(sfx_name)

# 调试相关信号
signal debug_message(message, level)
signal debug_command_executed(command, result)

# 自定义事件注册表
var _custom_events = {}

func _ready():
	# 初始化事件总线
	pass

## 注册自定义事件
func register_event(event_name):
	if not _custom_events.has(event_name):
		_custom_events[event_name] = []
		return true
	return false

## 连接自定义事件
func connect_event(event_name, target, method):
	if not _custom_events.has(event_name):
		register_event(event_name)
	
	if not _custom_events[event_name].has({"target": target, "method": method}):
		_custom_events[event_name].append({"target": target, "method": method})
		return true
	return false

## 断开自定义事件
func disconnect_event(event_name, target, method):
	if not _custom_events.has(event_name):
		return false
	
	for i in range(_custom_events[event_name].size()):
		var connection = _custom_events[event_name][i]
		if connection.target == target and connection.method == method:
			_custom_events[event_name].remove_at(i)
			return true
	
	return false

## 触发自定义事件
func emit_event(event_name, args = []):
	if not _custom_events.has(event_name):
		return false
	
	for connection in _custom_events[event_name]:
		if connection.target and is_instance_valid(connection.target):
			if args.size() > 0:
				connection.target.callv(connection.method, args)
			else:
				connection.target.call(connection.method)
	
	return true

## 清除特定对象的所有事件连接
func clear_connections(target):
	for event_name in _custom_events.keys():
		var i = 0
		while i < _custom_events[event_name].size():
			if _custom_events[event_name][i].target == target:
				_custom_events[event_name].remove_at(i)
			else:
				i += 1
