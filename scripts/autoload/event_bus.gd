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
signal board_reset
signal cell_selected(cell_position)
signal cell_hovered(cell_position)
signal cell_clicked(cell)
signal piece_placed_on_board(piece)
signal piece_removed_from_board(piece)
signal piece_placed_on_bench(piece)
signal piece_removed_from_bench(piece)

# 棋子相关信号
signal chess_piece_created(piece_data)
signal chess_piece_upgraded(piece_data)
signal chess_piece_sold(piece_data)
signal chess_pieces_merged(source_pieces, result_piece)
signal chess_piece_moved(piece_data, from_pos, to_pos)
signal chess_piece_ability_activated(piece_data, target_data)
signal synergy_activated(synergy_type, level)
signal synergy_deactivated(synergy_type)
signal show_chess_info(piece_data)
signal hide_chess_info()

# 战斗相关信号
signal battle_started
signal battle_ended(result)
signal battle_round_started(round_number)
signal battle_round_ended(round_number)
signal damage_dealt(source, target, amount, damage_type)
signal healing_done(target, amount, source)
signal ability_used(piece, ability_data)
signal unit_died(unit_data)
signal battle_speed_changed(speed_multiplier)
signal battle_preparing_phase_started
signal battle_fighting_phase_started

# 经济相关信号
signal gold_changed(old_amount, new_amount)
signal shop_refreshed(shop_items)
signal shop_opened(shop_items)
signal shop_closed()
signal shop_item_purchased(item)
signal item_purchased(item_data)
signal item_sold(item_data)
signal income_granted(amount)
signal shop_inventory_updated(inventory)
signal black_market_appeared
signal mystery_shop_appeared
signal equipment_shop_appeared
signal chess_piece_obtained(piece_data)
signal equipment_obtained(equipment_data)
signal exp_gained(amount)

# 装备相关信号
signal equipment_created(equipment_data)
signal equipment_equipped(equipment_data, piece_data)
signal equipment_unequipped(equipment_data, piece_data)
signal equipment_combined(base_equipment, target_equipment, result_equipment)
signal equipment_combine_animation_started(base_equipment, target_equipment, result_equipment)
signal equipment_combine_animation_completed(base_equipment, target_equipment, result_equipment)
signal equipment_effect_triggered(equipment, effect_data)
signal equipment_preview_requested(equipment)
signal equipment_combine_requested(equipment1, equipment2)
signal shop_refresh_requested(player_level, shop_tier)

# 遗物相关信号
signal relic_acquired(relic_data)
signal relic_activated(relic_data)
signal relic_effect_triggered(relic_data, effect_data)
signal show_relic_info(relic_data)
signal hide_relic_info()
signal relic_deactivated(relic_data)
signal relic_removed(relic_data)

# 事件相关信号
signal event_triggered(event_data)
signal event_choice_made(event_data, choice_data)
signal event_completed(event_data, result_data)

# 剧情相关信号
signal story_flag_set(flag_name, value)
signal story_branch_selected(branch_name, path)
signal story_progress_advanced(progress)

# 诅咒相关信号
signal curse_applied(curse_type, duration)
signal curse_removed(curse_type)
signal curse_effect_triggered(curse_type, effect)

# 玩家相关信号
signal player_health_changed(old_health, new_health)
signal player_level_changed(old_level, new_level)
signal player_died

# UI相关信号
signal ui_screen_changed(old_screen, new_screen)
signal ui_popup_opened(popup_name)
signal ui_popup_closed(popup_name)
signal ui_button_pressed(button_name)
signal show_toast(message, duration)
signal show_popup(popup_name, popup_data)
signal close_popup(popup_instance)
signal start_transition(transition_type, duration)
signal transition_midpoint
signal battle_preparing_phase_started
signal battle_fighting_phase_started
signal shop_manually_refreshed(cost)
signal shop_discount_applied(discount_rate)
signal event_started(event)
signal event_option_selected(option_index, result)
signal map_node_hovered(node_data)
signal treasure_collected(rewards)
signal rest_completed(heal_amount)

# 成就相关信号
signal achievement_progress(achievement_id, progress, total)
signal achievement_unlocked(achievement_id)

# 教程相关信号
signal start_tutorial(tutorial_id)
signal skip_tutorial(tutorial_id)
signal complete_tutorial(tutorial_id)
signal tutorial_step_changed(tutorial_id, step)

# 存档相关信号
signal game_saved(save_slot)
signal game_loaded(save_slot)
signal autosave_triggered

# 多语言相关信号
signal language_changed(new_language)

# 音频相关信号
signal bgm_changed(track_name)
signal sfx_played(sfx_name)
signal play_sound(sound_name, position)

# 皮肤相关信号
signal skin_changed(skin_type, skin_id)
signal skin_unlocked(skin_type, skin_id)
signal chess_skin_changed(skin_id)
signal board_skin_changed(skin_id)
signal ui_skin_changed(skin_id)

# 通知相关信号
signal show_notification(message, notification_type, duration, notification_id)
signal hide_notification(notification_id)
signal clear_notifications

# 工具提示相关信号
signal show_tooltip(control)
signal hide_tooltip(control)
signal update_tooltip(control, tooltip_text)

# 主题相关信号
signal theme_changed(theme_name)

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
