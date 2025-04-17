extends Node
class_name EventDefinitions
## 事件定义
## 集中定义所有事件，提供统一的事件命名和访问接口

## 游戏核心事件
class GameEvents:
	# 游戏状态事件
	const GAME_STATE_CHANGED = "game_state_changed"  # (old_state, new_state)
	const GAME_PAUSED = "game_paused"                # (is_paused)
	const GAME_STARTED = "game_started"              # ()
	const GAME_ENDED = "game_ended"                  # (win)

	# 玩家状态事件
	const PLAYER_HEALTH_CHANGED = "player_health_changed"  # (old_health, new_health)
	const PLAYER_LEVEL_CHANGED = "player_level_changed"    # (old_level, new_level)
	const PLAYER_DIED = "player_died"                      # ()

	# 难度事件
	const DIFFICULTY_CHANGED = "difficulty_changed"        # (old_level: int, new_level: int) - 难度从旧等级变为新等级

## 地图事件
class MapEvents:
	# 地图生成和导航
	const MAP_GENERATED = "map_generated"              # ()
	const MAP_NODE_SELECTED = "map_node_selected"      # (node_data)
	const MAP_NODE_HOVERED = "map_node_hovered"        # (node_data)
	const MAP_COMPLETED = "map_completed"              # ()

	# 特殊节点事件
	const MYSTERY_NODE_REVEALED = "mystery_node_revealed"  # (node_type)
	const CHALLENGE_STARTED = "challenge_started"          # (challenge_type)
	const CHALLENGE_COMPLETED = "challenge_completed"      # (challenge_type, success)
	const ALTAR_OPENED = "altar_opened"                    # (altar_type)
	const ALTAR_SACRIFICE_MADE = "altar_sacrifice_made"    # (altar_type, sacrifice_data)
	const BLACKSMITH_OPENED = "blacksmith_opened"          # (blacksmith_type)
	const EQUIPMENT_UPGRADED = "equipment_upgraded"        # (equipment_data, success)
	const TREASURE_COLLECTED = "treasure_collected"        # (rewards)
	const REST_COMPLETED = "rest_completed"                # (heal_amount)

## 棋盘事件
class BoardEvents:
	# 棋盘操作
	const BOARD_INITIALIZED = "board_initialized"        # ()
	const BOARD_RESIZED = "board_resized"                # (old_size, new_size)
	const BOARD_CLEARED = "board_cleared"                # ()

	# 棋子放置
	const PIECE_PLACED = "piece_placed"                  # (piece, position)
	const PIECE_REMOVED = "piece_removed"                # (piece, position)
	const PIECE_MOVED = "piece_moved"                    # (piece, from_pos, to_pos)
	const PIECE_SWAPPED = "piece_swapped"                # (piece1, piece2)

	# 棋盘状态
	const BOARD_STATE_CHANGED = "board_state_changed"    # (state)
	const BOARD_LOCKED = "board_locked"                  # (locked)
	const BOARD_UNLOCKED = "board_unlocked"              # ()

## 棋子事件
class ChessEvents:
	# 棋子生命周期
	const CHESS_PIECE_CREATED = "chess_piece_created"      # (piece_data)
	const CHESS_PIECE_UPGRADED = "chess_piece_upgraded"    # (piece_data)
	const CHESS_PIECE_SOLD = "chess_piece_sold"            # (piece_data)
	const CHESS_PIECES_MERGED = "chess_pieces_merged"      # (source_pieces, result_piece)

	# 棋子行为
	const CHESS_PIECE_MOVED = "chess_piece_moved"                # (piece_data, from_pos, to_pos)
	const CHESS_PIECE_ABILITY_ACTIVATED = "chess_piece_ability_activated"  # (piece_data, target_data)

	# 羁绊
	const SYNERGY_ACTIVATED = "synergy_activated"          # (synergy_type, level)
	const SYNERGY_DEACTIVATED = "synergy_deactivated"      # (synergy_type)

	# UI相关
	const SHOW_CHESS_INFO = "show_chess_info"              # (piece_data)
	const HIDE_CHESS_INFO = "hide_chess_info"              # ()
	const CHESS_PIECE_OBTAINED = "chess_piece_obtained"    # (piece_data)

## 战斗事件
class BattleEvents:
	# 战斗流程
	const BATTLE_STARTED = "battle_started"                # ()
	const BATTLE_ENDED = "battle_ended"                    # (result)
	const BATTLE_ROUND_STARTED = "battle_round_started"    # (round_number)
	const BATTLE_ROUND_ENDED = "battle_round_ended"        # (round_number)

	# 战斗行为
	const DAMAGE_DEALT = "damage_dealt"                    # (source: ChessPiece, target: ChessPiece, amount: float, damage_type: String)
	const HEAL_RECEIVED = "heal_received"                  # (target: ChessPiece, amount: float, source: ChessPiece|null) - 治疗目标、治疗量、治疗来源
	const ABILITY_USED = "ability_used"                    # (piece: ChessPiece, ability_data: Dictionary)
	const ABILITY_EFFECT_APPLIED = "ability_effect_applied"  # (source: ChessPiece, target: ChessPiece, effect_type: String, effect_value: float)
	const UNIT_DIED = "unit_died"                          # (unit: ChessPiece) - 死亡的棋子单位

	# 战斗控制
	const BATTLE_SPEED_CHANGED = "battle_speed_changed"    # (speed_multiplier)
	const BATTLE_PREPARING_PHASE_STARTED = "battle_preparing_phase_started"  # ()
	const BATTLE_FIGHTING_PHASE_STARTED = "battle_fighting_phase_started"    # ()

	# 战斗效果
	const CRITICAL_HIT = "critical_hit"                    # (source, target, amount)
	const ATTACK_MISSED = "attack_missed"                  # (source, target)
	const MANA_CHANGED = "mana_changed"                    # (piece, old_value, new_value, source)

## 经济事件
class EconomyEvents:
	# 金币
	const GOLD_CHANGED = "gold_changed"                    # (old_value, new_value)
	const GOLD_EARNED = "gold_earned"                      # (amount, source)
	const GOLD_SPENT = "gold_spent"                        # (amount, reason)

	# 商店
	const SHOP_OPENED = "shop_opened"                      # ()
	const SHOP_CLOSED = "shop_closed"                      # ()
	const SHOP_REFRESHED = "shop_refreshed"                # (cost)
	const SHOP_ITEM_PURCHASED = "shop_item_purchased"      # (item, cost)
	const SHOP_ITEM_SOLD = "shop_item_sold"                # (item, value)

	# 经济系统
	const INTEREST_EARNED = "interest_earned"              # (amount)
	const STREAK_BONUS_EARNED = "streak_bonus_earned"      # (streak_count, amount)
	const ECONOMY_LEVEL_CHANGED = "economy_level_changed"  # (old_level, new_level)

## 装备事件
class EquipmentEvents:
	# 装备生命周期
	const EQUIPMENT_CREATED = "equipment_created"          # (equipment_data)
	const EQUIPMENT_EQUIPPED = "equipment_equipped"        # (equipment_data, piece_data)
	const EQUIPMENT_UNEQUIPPED = "equipment_unequipped"    # (equipment_data, piece_data)
	const EQUIPMENT_COMBINED = "equipment_combined"        # (base_equipment, target_equipment, result_equipment)

	# 装备动画
	const EQUIPMENT_COMBINE_ANIMATION_STARTED = "equipment_combine_animation_started"    # (base_equipment, target_equipment, result_equipment)
	const EQUIPMENT_COMBINE_ANIMATION_COMPLETED = "equipment_combine_animation_completed"  # (base_equipment, target_equipment, result_equipment)

	# 装备效果
	const EQUIPMENT_EFFECT_TRIGGERED = "equipment_effect_triggered"  # (equipment, effect_data)

	# UI相关
	const EQUIPMENT_PREVIEW_REQUESTED = "equipment_preview_requested"  # (equipment)
	const EQUIPMENT_COMBINE_REQUESTED = "equipment_combine_requested"  # (equipment1, equipment2)
	const EQUIPMENT_OBTAINED = "equipment_obtained"        # (equipment_data)

## 遗物事件
class RelicEvents:
	# 遗物生命周期
	const RELIC_OBTAINED = "relic_obtained"                # (relic_data)
	const RELIC_ACTIVATED = "relic_activated"              # (relic_data)
	const RELIC_DEACTIVATED = "relic_deactivated"          # (relic_data)
	const RELIC_REMOVED = "relic_removed"                  # (relic_data)

	# 遗物效果
	const RELIC_EFFECT_TRIGGERED = "relic_effect_triggered"  # (relic_data, effect_data)
	const RELIC_EFFECT_ENDED = "relic_effect_ended"        # (relic_data, effect_data)

	# UI相关
	const RELIC_PREVIEW_REQUESTED = "relic_preview_requested"  # (relic_data)
	const RELIC_SELECTION_STARTED = "relic_selection_started"  # (relic_options)
	const RELIC_SELECTED = "relic_selected"                # (relic_data)

## 事件系统事件
class EventSystemEvents:
	# 事件生命周期
	const EVENT_TRIGGERED = "event_triggered"              # (event)
	const EVENT_CHOICE_MADE = "event_choice_made"          # (event, choice)
	const EVENT_COMPLETED = "event_completed"              # (event, result)

	# 事件效果
	const EVENT_EFFECT_APPLIED = "event_effect_applied"    # (event, effect)
	const EVENT_REWARD_GRANTED = "event_reward_granted"    # (event, reward)

	# 事件系统
	const EVENT_SYSTEM_INITIALIZED = "event_system_initialized"  # ()
	const EVENT_POOL_UPDATED = "event_pool_updated"        # ()

## 剧情事件
class StoryEvents:
	# 剧情进度
	const STORY_PROGRESSED = "story_progressed"            # (old_progress, new_progress)
	const STORY_CHAPTER_STARTED = "story_chapter_started"  # (chapter_id)
	const STORY_CHAPTER_COMPLETED = "story_chapter_completed"  # (chapter_id)

	# 剧情标记
	const STORY_FLAG_SET = "story_flag_set"                # (flag_name, value)
	const STORY_BRANCH_CHOSEN = "story_branch_chosen"      # (branch_name, choice)

	# 剧情事件
	const STORY_EVENT_TRIGGERED = "story_event_triggered"  # (event_id)
	const STORY_EVENT_COMPLETED = "story_event_completed"  # (event_id, result)
	const STORY_CHARACTER_INTRODUCED = "story_character_introduced"  # (character_id)
	const STORY_ENDING_REACHED = "story_ending_reached"    # (ending_id)

## 诅咒事件
class CurseEvents:
	# 诅咒生命周期
	const CURSE_APPLIED = "curse_applied"                  # (curse_type, duration)
	const CURSE_REMOVED = "curse_removed"                  # (curse_type)
	const CURSE_DURATION_CHANGED = "curse_duration_changed"  # (curse_type, old_duration, new_duration)

	# 诅咒效果
	const CURSE_EFFECT_TRIGGERED = "curse_effect_triggered"  # (curse_type, effect_data)
	const CURSE_EFFECT_RESISTED = "curse_effect_resisted"  # (curse_type, resist_amount)

	# 诅咒系统
	const CURSE_SYSTEM_INITIALIZED = "curse_system_initialized"  # ()
	const CURSE_CLEANSED = "curse_cleansed"                # (curse_type, source)

## UI事件
class UIEvents:
	# 界面导航
	const UI_SCREEN_CHANGED = "ui_screen_changed"          # (old_screen, new_screen)
	const UI_POPUP_OPENED = "ui_popup_opened"              # (popup_name)
	const UI_POPUP_CLOSED = "ui_popup_closed"              # (popup_name)
	const UI_BUTTON_PRESSED = "ui_button_pressed"          # (button_name)

	# 通知和提示
	const SHOW_TOAST = "show_toast"                        # (message, duration)
	const SHOW_POPUP = "show_popup"                        # (popup_name, popup_data)
	const CLOSE_POPUP = "close_popup"                      # (popup_instance)
	const START_TRANSITION = "start_transition"            # (transition_type, duration)
	const TRANSITION_MIDPOINT = "transition_midpoint"      # ()
	const SHOW_NOTIFICATION = "show_notification"          # (message, notification_type, duration, notification_id)
	const HIDE_NOTIFICATION = "hide_notification"          # (notification_id)
	const CLEAR_NOTIFICATIONS = "clear_notifications"      # ()

	# 工具提示
	const SHOW_TOOLTIP = "show_tooltip"                    # (control)
	const HIDE_TOOLTIP = "hide_tooltip"                    # (control)
	const UPDATE_TOOLTIP = "update_tooltip"                # (control, tooltip_text)

	# 主题和样式
	const THEME_CHANGED = "theme_changed"                  # (theme_name)
	const LANGUAGE_CHANGED = "language_changed"            # (language_code)
	const SCALE_CHANGED = "scale_changed"                  # (scale_factor)
	const FONT_SIZE_CHANGED = "font_size_changed"          # (font_size)

## 成就事件
class AchievementEvents:
	# 成就生命周期
	const ACHIEVEMENT_UNLOCKED = "achievement_unlocked"    # (achievement_id)
	const ACHIEVEMENT_PROGRESS_UPDATED = "achievement_progress_updated"  # (achievement_id, old_progress, new_progress)
	const ACHIEVEMENT_COMPLETED = "achievement_completed"  # (achievement_id)

	# 成就系统
	const ACHIEVEMENT_SYSTEM_INITIALIZED = "achievement_system_initialized"  # ()
	const ACHIEVEMENT_REWARD_GRANTED = "achievement_reward_granted"  # (achievement_id, reward)

## 教程事件
class TutorialEvents:
	# 教程生命周期
	const TUTORIAL_STARTED = "tutorial_started"            # (tutorial_id)
	const TUTORIAL_STEP_COMPLETED = "tutorial_step_completed"  # (tutorial_id, step_id)
	const TUTORIAL_COMPLETED = "tutorial_completed"        # (tutorial_id)
	const TUTORIAL_SKIPPED = "tutorial_skipped"            # (tutorial_id)

	# 教程系统
	const TUTORIAL_SYSTEM_INITIALIZED = "tutorial_system_initialized"  # ()
	const TUTORIAL_HIGHLIGHT_SHOWN = "tutorial_highlight_shown"  # (target_node)
	const TUTORIAL_HIGHLIGHT_HIDDEN = "tutorial_highlight_hidden"  # ()

## 存档事件
class SaveEvents:
	# 存档操作
	const GAME_SAVED = "game_saved"                        # (save_slot, save_data)
	const GAME_LOADED = "game_loaded"                      # (save_slot, save_data)
	const SAVE_DELETED = "save_deleted"                    # (save_slot)

	# 存档系统
	const SAVE_SYSTEM_INITIALIZED = "save_system_initialized"  # ()
	const AUTOSAVE_CREATED = "autosave_created"            # (save_slot)
	const SAVE_CORRUPTED = "save_corrupted"                # (save_slot, error)

## 本地化事件
class LocalizationEvents:
	# 本地化操作
	const LANGUAGE_CHANGED = "language_changed"            # (language_code)
	const TRANSLATION_LOADED = "translation_loaded"        # (language_code)
	const TRANSLATION_MISSING = "translation_missing"      # (key)

	# 本地化系统
	const LOCALIZATION_SYSTEM_INITIALIZED = "localization_system_initialized"  # ()
	const FALLBACK_TRANSLATION_USED = "fallback_translation_used"  # (key, fallback_language)

## 音频事件
class AudioEvents:
	# 音频播放
	const MUSIC_STARTED = "music_started"                  # (track_name)
	const MUSIC_STOPPED = "music_stopped"                  # (track_name)
	const MUSIC_VOLUME_CHANGED = "music_volume_changed"    # (old_volume, new_volume)
	const SFX_PLAYED = "sfx_played"                        # (sfx_name)
	const SFX_VOLUME_CHANGED = "sfx_volume_changed"        # (old_volume, new_volume)

	# 音频系统
	const AUDIO_SYSTEM_INITIALIZED = "audio_system_initialized"  # ()
	const AUDIO_MUTED = "audio_muted"                      # (audio_type)
	const AUDIO_UNMUTED = "audio_unmuted"                  # (audio_type)

## 皮肤事件
class SkinEvents:
	# 皮肤操作
	const SKIN_UNLOCKED = "skin_unlocked"                  # (skin_id)
	const SKIN_EQUIPPED = "skin_equipped"                  # (entity_id, skin_id)
	const SKIN_UNEQUIPPED = "skin_unequipped"              # (entity_id, skin_id)

	# 皮肤系统
	const SKIN_SYSTEM_INITIALIZED = "skin_system_initialized"  # ()
	const SKIN_PREVIEW_SHOWN = "skin_preview_shown"        # (skin_id)
	const SKIN_PREVIEW_HIDDEN = "skin_preview_hidden"      # ()

## 状态效果事件
class StatusEffectEvents:
	# 状态效果生命周期
	const STATUS_EFFECT_APPLIED = "status_effect_applied"  # (target, effect_type, effect_value, duration)
	const STATUS_EFFECT_REMOVED = "status_effect_removed"  # (target, effect_type)
	const STATUS_EFFECT_DURATION_CHANGED = "status_effect_duration_changed"  # (target, effect_type, old_duration, new_duration)
	const STATUS_EFFECT_VALUE_CHANGED = "status_effect_value_changed"  # (target, effect_type, old_value, new_value)

	# 状态效果触发
	const STATUS_EFFECT_TRIGGERED = "status_effect_triggered"  # (target, effect_type, effect_data)
	const STATUS_EFFECT_RESISTED = "status_effect_resisted"  # (target, effect_type, resist_amount)

	# 状态效果系统
	const STATUS_EFFECT_SYSTEM_INITIALIZED = "status_effect_system_initialized"  # ()
	const STATUS_EFFECT_CLEANSED = "status_effect_cleansed"  # (target, effect_type, source)

## 调试事件
class DebugEvents:
	# 调试消息
	const DEBUG_MESSAGE = "debug_message"                  # (message, level)
	const DEBUG_COMMAND_EXECUTED = "debug_command_executed"  # (command, args)
	const DEBUG_CONSOLE_TOGGLED = "debug_console_toggled"  # (visible)

	# 调试工具
	const DEBUG_TOOL_ACTIVATED = "debug_tool_activated"    # (tool_name)
	const DEBUG_TOOL_DEACTIVATED = "debug_tool_deactivated"  # (tool_name)
	const DEBUG_SCREENSHOT_TAKEN = "debug_screenshot_taken"  # (path)

	# 性能监控
	const PERFORMANCE_WARNING = "performance_warning"      # (warning_type, details)
	const MEMORY_WARNING = "memory_warning"                # (memory_type, current_usage, threshold)
	const FPS_WARNING = "fps_warning"                      # (current_fps, threshold)

## 获取所有事件类别
static func get_all_event_categories() -> Array:
	return [
		"GameEvents",
		"MapEvents",
		"BoardEvents",
		"ChessEvents",
		"BattleEvents",
		"EconomyEvents",
		"EquipmentEvents",
		"RelicEvents",
		"EventSystemEvents",
		"StoryEvents",
		"CurseEvents",
		"UIEvents",
		"AchievementEvents",
		"TutorialEvents",
		"SaveEvents",
		"LocalizationEvents",
		"AudioEvents",
		"SkinEvents",
		"StatusEffectEvents",
		"DebugEvents"
	]

## 获取指定类别的所有事件
static func get_events_for_category(category: String) -> Dictionary:
	var events = {}

	match category:
		"GameEvents":
			events = _get_class_constants(GameEvents)
		"MapEvents":
			events = _get_class_constants(MapEvents)
		"BoardEvents":
			events = _get_class_constants(BoardEvents)
		"ChessEvents":
			events = _get_class_constants(ChessEvents)
		"BattleEvents":
			events = _get_class_constants(BattleEvents)
		"EconomyEvents":
			events = _get_class_constants(EconomyEvents)
		"EquipmentEvents":
			events = _get_class_constants(EquipmentEvents)
		"RelicEvents":
			events = _get_class_constants(RelicEvents)
		"EventSystemEvents":
			events = _get_class_constants(EventSystemEvents)
		"StoryEvents":
			events = _get_class_constants(StoryEvents)
		"CurseEvents":
			events = _get_class_constants(CurseEvents)
		"UIEvents":
			events = _get_class_constants(UIEvents)
		"AchievementEvents":
			events = _get_class_constants(AchievementEvents)
		"TutorialEvents":
			events = _get_class_constants(TutorialEvents)
		"SaveEvents":
			events = _get_class_constants(SaveEvents)
		"LocalizationEvents":
			events = _get_class_constants(LocalizationEvents)
		"AudioEvents":
			events = _get_class_constants(AudioEvents)
		"SkinEvents":
			events = _get_class_constants(SkinEvents)
		"StatusEffectEvents":
			events = _get_class_constants(StatusEffectEvents)
		"DebugEvents":
			events = _get_class_constants(DebugEvents)

	return events

## 获取类的所有常量
static func _get_class_constants(cls) -> Dictionary:
	var constants = {}
	var script = cls.new().get_script()

	for constant in script.get_script_constant_map():
		constants[constant] = script.get_script_constant_map()[constant]

	return constants

## 获取所有事件
static func get_all_events() -> Dictionary:
	var all_events = {}

	for category in get_all_event_categories():
		var category_events = get_events_for_category(category)
		for event_name in category_events:
			all_events[event_name] = category_events[event_name]

	return all_events
