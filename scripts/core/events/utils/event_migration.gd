#extends RefCounted
#class_name EventMigration
### 事件迁移工具
### 提供从旧事件系统迁移到新事件系统的工具
#
### 旧事件名称到新事件类型的映射
#var _event_mapping: Dictionary = {
	## 游戏事件
	#"game_state_changed": "game.state_changed",
	#"game_paused": "game.paused",
	#"game_started": "game.started",
	#"game_ended": "game.ended",
	#"player_health_changed": "game.player_health_changed",
	#"player_level_changed": "game.player_level_changed",
	#"player_died": "game.player_died",
	#"difficulty_changed": "game.difficulty_changed",
	#
	## 战斗事件
	#"battle_started": "battle.started",
	#"battle_ended": "battle.ended",
	#"round_started": "battle.round_started",
	#"round_ended": "battle.round_ended",
	#"damage_dealt": "battle.damage_dealt",
	#"heal_received": "battle.heal_received",
	#"unit_died": "battle.unit_died",
	#"ability_used": "battle.ability_used",
	#
	## 事件系统事件
	#"event_triggered": "event.triggered",
	#"event_choice_made": "event.choice_made",
	#"event_completed": "event.completed",
	#"event_effect_applied": "event.effect_applied",
	#"event_reward_granted": "event.reward_granted",
	#
	## UI事件
	#"update_ui": "ui.update",
	#"button_clicked": "ui.button_clicked",
	#"menu_opened": "ui.menu_opened",
	#"menu_closed": "ui.menu_closed",
	#"dialog_shown": "ui.dialog_shown",
	#"show_toast": "ui.toast_shown",
	#
	## 调试事件
	#"debug_message": "debug.message",
	#"debug_command_executed": "debug.command_executed",
	#"debug_console_toggled": "debug.console_toggled",
	#"performance_warning": "debug.performance_warning"
#}
#
### 创建新事件实例
### @param old_event_name 旧事件名称
### @param args 事件参数
### @return 新事件实例
#func create_event(old_event_name: String, args: Array) ->BusEvent:
	## 获取新事件类型
	#var new_event_type = _get_new_event_type(old_event_name)
	#if new_event_type.is_empty():
		#push_error("无法迁移未知的事件类型: " + old_event_name)
		#return null
	#
	## 根据事件类型创建事件实例
	#match new_event_type:
		## 游戏事件
		#"game.state_changed":
			#return GameEvents.GameStateChangedEvent.new(args[0], args[1])
		#"game.paused":
			#return GameEvents.GamePausedEvent.new(args[0])
		#"game.started":
			#return GameEvents.GameStartedEvent.new(args[0] if args.size() > 0 else 1)
		#"game.ended":
			#return GameEvents.GameEndedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else 0.0,
				#args[2] if args.size() > 2 else 0
			#)
		#"game.player_health_changed":
			#return GameEvents.PlayerHealthChangedEvent.new(
				#args[0],
				#args[1],
				#args[2] if args.size() > 2 else 100.0
			#)
		#"game.player_level_changed":
			#return GameEvents.PlayerLevelChangedEvent.new(args[0], args[1])
		#"game.difficulty_changed":
			#return GameEvents.DifficultyChangedEvent.new(args[0], args[1])
		#
		## 战斗事件
		#"battle.started":
			#return BattleEvents.BattleStartedEvent.new(
				#args[0] if args.size() > 0 else "",
				#args[1] if args.size() > 1 else 1,
				#args[2] if args.size() > 2 else [],
				#args[3] if args.size() > 3 else []
			#)
		#"battle.ended":
			#return BattleEvents.BattleEndedEvent.new(
				#args[0] if args.size() > 0 else "",
				#args[1] if args.size() > 1 else false,
				#args[2] if args.size() > 2 else 0.0,
				#args[3] if args.size() > 3 else []
			#)
		#"battle.round_started":
			#return BattleEvents.RoundStartedEvent.new(args[0])
		#"battle.round_ended":
			#return BattleEvents.RoundEndedEvent.new(args[0])
		#"battle.damage_dealt":
			#return BattleEvents.DamageDealtEvent.new(
				#args[0],
				#args[1],
				#args[2],
				#args[3],
				#args[4] if args.size() > 4 else false
			#)
		#"battle.heal_received":
			#return BattleEvents.HealReceivedEvent.new(args[0], args[1], args[2])
		#"battle.unit_died":
			#return BattleEvents.UnitDiedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else null
			#)
		#"battle.ability_used":
			#return BattleEvents.AbilityUsedEvent.new(
				#args[0],
				#args[1],
				#args[2] if args.size() > 2 else []
			#)
		#
		## 事件系统事件
		#"event.triggered":
			#return EventSystemEvents.EventTriggeredEvent.new(
				#args[0],
				#args[0].get("event_type") if args.size() > 0 and args[0] is Object and args[0].has("event_type") else ""
			#)
		#"event.choice_made":
			#return EventSystemEvents.EventChoiceMadeEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#"event.completed":
			#return EventSystemEvents.EventCompletedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#"event.effect_applied":
			#return EventSystemEvents.EventEffectAppliedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#"event.reward_granted":
			#return EventSystemEvents.EventRewardGrantedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#
		## UI事件
		#"ui.update":
			#return UIEvents.UIUpdateEvent.new(
				#args[0] if args.size() > 0 else "",
				#args[1] if args.size() > 1 else {}
			#)
		#"ui.button_clicked":
			#return UIEvents.ButtonClickedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else "",
				#args[2] if args.size() > 2 else {}
			#)
		#"ui.menu_opened":
			#return UIEvents.MenuOpenedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#"ui.menu_closed":
			#return UIEvents.MenuClosedEvent.new(args[0])
		#"ui.dialog_shown":
			#return UIEvents.DialogShownEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else "",
				#args[2] if args.size() > 2 else "",
				#args[3] if args.size() > 3 else []
			#)
		#"ui.toast_shown":
			#return UIEvents.ToastShownEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else "",
				#args[2] if args.size() > 2 else "info",
				#args[3] if args.size() > 3 else 3.0
			#)
		#
		## 调试事件
		#"debug.message":
			#return DebugEvents.DebugMessageEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else 0,
				#args[2] if args.size() > 2 else ""
			#)
		#"debug.command_executed":
			#return DebugEvents.DebugCommandExecutedEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else [],
				#args[2] if args.size() > 2 else ""
			#)
		#"debug.console_toggled":
			#return DebugEvents.DebugConsoleToggledEvent.new(args[0])
		#"debug.performance_warning":
			#return DebugEvents.PerformanceWarningEvent.new(
				#args[0],
				#args[1] if args.size() > 1 else {}
			#)
		#
		#_:
			#push_error("未实现的事件类型迁移: " + new_event_type)
			#return null
#
### 获取新事件类型
### @param old_event_name 旧事件名称
### @return 新事件类型
#func _get_new_event_type(old_event_name: String) -> String:
	## 检查是否有直接映射
	#if _event_mapping.has(old_event_name):
		#return _event_mapping[old_event_name]
	#
	## 检查是否有分组前缀
	#var parts = old_event_name.split(".")
	#if parts.size() == 2:
		#var group = parts[0]
		#var event_name = parts[1]
		#
		## 检查是否有映射
		#if _event_mapping.has(event_name):
			#return _event_mapping[event_name]
	#
	## 未找到映射
	#return ""
