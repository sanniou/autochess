extends RefCounted
class_name EventMapping
## 事件映射
## 提供旧事件名称到新事件类型的映射

## 事件映射表
var _event_mapping: Dictionary = {
    # 游戏事件
    "game.game_state_changed": {"class": "GameEvents.GameStateChangedEvent", "args": ["old_state", "new_state"]},
    "game.state_changed": {"class": "GameEvents.GameStateChangedEvent", "args": ["old_state", "new_state"]},
    "game.game_paused": {"class": "GameEvents.GamePausedEvent", "args": ["is_paused"]},
    "game.paused": {"class": "GameEvents.GamePausedEvent", "args": ["is_paused"]},
    "game.game_started": {"class": "GameEvents.GameStartedEvent", "args": ["difficulty_level"]},
    "game.started": {"class": "GameEvents.GameStartedEvent", "args": ["difficulty_level"]},
    "game.game_ended": {"class": "GameEvents.GameEndedEvent", "args": ["is_victory", "play_time", "score"]},
    "game.ended": {"class": "GameEvents.GameEndedEvent", "args": ["is_victory", "play_time", "score"]},
    "game.player_health_changed": {"class": "GameEvents.PlayerHealthChangedEvent", "args": ["old_health", "new_health", "max_health"]},
    "game.player_level_changed": {"class": "GameEvents.PlayerLevelChangedEvent", "args": ["old_level", "new_level"]},
    "game.player_died": {"class": "GameEvents.PlayerDiedEvent", "args": []},
    "game.difficulty_changed": {"class": "GameEvents.DifficultyChangedEvent", "args": ["old_level", "new_level"]},
    "game.player_exp_changed": {"class": "GameEvents.PlayerExpChangedEvent", "args": ["old_exp", "new_exp", "exp_to_level"]},

    # 战斗事件
    "battle.battle_started": {"class": "BattleEvents.BattleStartedEvent", "args": ["battle_id", "round", "player_pieces", "enemy_pieces"]},
    "battle.started": {"class": "BattleEvents.BattleStartedEvent", "args": ["battle_id", "round", "player_pieces", "enemy_pieces"]},
    "battle.battle_ended": {"class": "BattleEvents.BattleEndedEvent", "args": ["battle_id", "is_victory", "duration", "remaining_pieces"]},
    "battle.ended": {"class": "BattleEvents.BattleEndedEvent", "args": ["battle_id", "is_victory", "duration", "remaining_pieces"]},
    "battle.round_started": {"class": "BattleEvents.RoundStartedEvent", "args": ["round"]},
    "battle.round_ended": {"class": "BattleEvents.RoundEndedEvent", "args": ["round"]},
    "battle.damage_dealt": {"class": "BattleEvents.DamageDealtEvent", "args": ["source_entity", "target_entity", "amount", "damage_type", "is_critical"]},
    "battle.heal_received": {"class": "BattleEvents.HealReceivedEvent", "args": ["source_entity", "target_entity", "amount"]},
    "battle.unit_died": {"class": "BattleEvents.UnitDiedEvent", "args": ["unit", "killer"]},
    "battle.ability_used": {"class": "BattleEvents.AbilityUsedEvent", "args": ["caster", "ability_data", "targets"]},
    "battle.battle_preparing_phase_started": {"class": "BattleEvents.BattlePreparingPhaseStartedEvent", "args": ["battle_id", "round"]},
    "battle.battle_fighting_phase_started": {"class": "BattleEvents.BattleFightingPhaseStartedEvent", "args": ["battle_id", "round"]},
    "battle.critical_hit": {"class": "BattleEvents.CriticalHitEvent", "args": ["attacker", "target", "damage", "crit_multiplier"]},
    "battle.mana_changed": {"class": "BattleEvents.ManaChangedEvent", "args": ["entity", "old_mana", "new_mana"]},
    "battle.healing_done": {"class": "BattleEvents.HealingDoneEvent", "args": ["healer", "target", "amount"]},
    "battle.delayed_stun_removal": {"class": "BattleEvents.DelayedStunRemovalEvent", "args": ["entity"]},

    # 棋子事件
    "chess.chess_piece_created": {"class": "ChessEvents.ChessPieceCreatedEvent", "args": ["piece"]},
    "chess.chess_piece_upgraded": {"class": "ChessEvents.ChessPieceUpgradedEvent", "args": ["piece", "old_level", "new_level"]},
    "chess.chess_piece_sold": {"class": "ChessEvents.ChessPieceSoldEvent", "args": ["piece", "gold_amount"]},
    "chess.chess_piece_moved": {"class": "ChessEvents.ChessPieceMovedEvent", "args": ["piece", "from_position", "to_position"]},
    "chess.chess_piece_target_changed": {"class": "ChessEvents.ChessPieceTargetChangedEvent", "args": ["piece", "old_target", "new_target"]},
    "chess.chess_piece_target_lost": {"class": "ChessEvents.ChessPieceTargetLostEvent", "args": ["piece", "old_target"]},
    "chess.chess_piece_damaged": {"class": "ChessEvents.ChessPieceDamagedEvent", "args": ["piece", "source", "amount", "damage_type", "is_critical"]},
    "chess.chess_piece_healed": {"class": "ChessEvents.ChessPieceHealedEvent", "args": ["piece", "source", "amount"]},
    "chess.chess_piece_dodged": {"class": "ChessEvents.ChessPieceDodgedEvent", "args": ["piece", "source"]},

    # UI事件
    "ui.update_ui": {"class": "UIEvents.UIUpdateEvent", "args": ["component", "data"]},
    "ui.update": {"class": "UIEvents.UIUpdateEvent", "args": ["component", "data"]},
    "ui.button_clicked": {"class": "UIEvents.ButtonClickedEvent", "args": ["button_id", "button_text", "button_data"]},
    "ui.menu_opened": {"class": "UIEvents.MenuOpenedEvent", "args": ["menu_id", "menu_data"]},
    "ui.menu_closed": {"class": "UIEvents.MenuClosedEvent", "args": ["menu_id"]},
    "ui.dialog_shown": {"class": "UIEvents.DialogShownEvent", "args": ["dialog_id", "title", "content", "options"]},
    "ui.show_toast": {"class": "UIEvents.ToastShownEvent", "args": ["title", "message", "type", "duration"]},
    "ui.toast_shown": {"class": "UIEvents.ToastShownEvent", "args": ["title", "message", "type", "duration"]},
    "ui.theme_changed": {"class": "UIEvents.ThemeChangedEvent", "args": ["theme_name", "theme_data"]},
    "ui.language_changed": {"class": "UIEvents.LanguageChangedEvent", "args": ["language_code", "language_name"]},
    "ui.scale_changed": {"class": "UIEvents.ScaleChangedEvent", "args": ["scale_factor"]},
    "ui.ui_screen_changed": {"class": "UIEvents.UIScreenChangedEvent", "args": ["old_screen", "new_screen", "screen_data"]},
    "ui.show_notification": {"class": "UIEvents.ShowNotificationEvent", "args": ["notification_id", "title", "content", "type", "duration"]},
    "ui.hide_notification": {"class": "UIEvents.HideNotificationEvent", "args": ["notification_id"]},
    "ui.clear_notifications": {"class": "UIEvents.ClearNotificationsEvent", "args": []},
    "ui.show_popup": {"class": "UIEvents.ShowPopupEvent", "args": ["popup_id", "popup_data"]},
    "ui.close_popup": {"class": "UIEvents.ClosePopupEvent", "args": ["popup_id"]},
    "ui.start_transition": {"class": "UIEvents.StartTransitionEvent", "args": ["transition_type", "duration", "params"]},
    "ui.transition_midpoint": {"class": "UIEvents.TransitionMidpointEvent", "args": ["transition_type", "params"]},
    "ui.register_ui_throttler": {"class": "UIEvents.RegisterUIThrottlerEvent", "args": ["throttler_id", "update_interval"]},
    "ui.unregister_ui_throttler": {"class": "UIEvents.UnregisterUIThrottlerEvent", "args": ["throttler_id"]},
    "ui.force_ui_update": {"class": "UIEvents.ForceUIUpdateEvent", "args": ["throttler_id"]},

    # 调试事件
    "debug.debug_message": {"class": "DebugEvents.DebugMessageEvent", "args": ["message", "level", "tag"]},
    "debug.message": {"class": "DebugEvents.DebugMessageEvent", "args": ["message", "level", "tag"]},
    "debug.command_executed": {"class": "DebugEvents.DebugCommandExecutedEvent", "args": ["command", "args", "result"]},
    "debug.console_toggled": {"class": "DebugEvents.DebugConsoleToggledEvent", "args": ["visible"]},
    "debug.performance_warning": {"class": "DebugEvents.PerformanceWarningEvent", "args": ["warning_type", "details"]},

    # 组件事件
    "component.added": {"class": "ComponentEvents.ComponentAddedEvent", "args": ["entity", "component"]},
    "component.removed": {"class": "ComponentEvents.ComponentRemovedEvent", "args": ["entity", "component"]},
    "component.enabled": {"class": "ComponentEvents.ComponentEnabledEvent", "args": ["entity", "component"]},
    "component.disabled": {"class": "ComponentEvents.ComponentDisabledEvent", "args": ["entity", "component"]},
    "component.attribute_changed": {"class": "ComponentEvents.AttributeChangedEvent", "args": ["entity", "attribute_name", "old_value", "new_value"]},
    "component.state_changed": {"class": "ComponentEvents.StateChangedEvent", "args": ["entity", "old_state", "new_state", "state_names"]},
    "component.target_changed": {"class": "ComponentEvents.TargetChangedEvent", "args": ["entity", "old_target", "new_target"]},
    "component.damage": {"class": "ComponentEvents.DamageEvent", "args": ["source_entity", "target_entity", "amount", "damage_type", "is_critical"]},
    "component.heal": {"class": "ComponentEvents.HealEvent", "args": ["source_entity", "target_entity", "amount"]},
    "component.ability_used": {"class": "ComponentEvents.AbilityUsedEvent", "args": ["caster", "ability_id", "ability_name", "target", "ability_data"]},
    "component.equipment_changed": {"class": "ComponentEvents.EquipmentEvent", "args": ["entity", "equipment", "slot"]},

    # 经济事件
    "economy.gold_changed": {"class": "EconomyEvents.GoldChangedEvent", "args": ["old_amount", "new_amount", "reason"]},
    "economy.shop_refreshed": {"class": "EconomyEvents.ShopRefreshedEvent", "args": ["shop_id", "items", "is_manual"]},
    "economy.shop_manually_refreshed": {"class": "EconomyEvents.ShopManuallyRefreshedEvent", "args": ["shop_id", "refresh_cost"]},
    "economy.item_purchased": {"class": "EconomyEvents.ItemPurchasedEvent", "args": ["shop_id", "item_id", "item_data", "price"]},
    "economy.item_sold": {"class": "EconomyEvents.ItemSoldEvent", "args": ["item_id", "item_data", "price"]},
    "economy.shop_discount_applied": {"class": "EconomyEvents.ShopDiscountAppliedEvent", "args": ["shop_id", "discount_percent", "reason"]},
    "economy.chess_shop_inventory_updated": {"class": "EconomyEvents.ChessShopInventoryUpdatedEvent", "args": ["shop_id", "chess_pieces"]},

    # 地图事件
    "map.map_generated": {"class": "MapEvents.MapGeneratedEvent", "args": ["map_id", "map_data"]},
    "map.map_node_selected": {"class": "MapEvents.MapNodeSelectedEvent", "args": ["node_id", "node_type", "node_data"]},
    "map.map_node_hovered": {"class": "MapEvents.MapNodeHoveredEvent", "args": ["node_id", "node_type", "node_data", "is_hovered"]},
    "map.map_completed": {"class": "MapEvents.MapCompletedEvent", "args": ["map_id", "completion_time", "visited_nodes"]},
    "map.equipment_upgraded": {"class": "MapEvents.EquipmentUpgradedEvent", "args": ["equipment_id", "old_level", "new_level", "upgrade_cost"]},
    "map.altar_sacrifice_made": {"class": "MapEvents.AltarSacrificeMadeEvent", "args": ["chess_id", "chess_data", "rewards"]},

    # 棋盘事件
    "board.board_initialized": {"class": "BoardEvents.BoardInitializedEvent", "args": ["board_id", "board_size"]},
    "board.piece_placed": {"class": "BoardEvents.PiecePlacedEvent", "args": ["piece", "position"]},
    "board.piece_removed": {"class": "BoardEvents.PieceRemovedEvent", "args": ["piece", "position"]},
    "board.piece_moved": {"class": "BoardEvents.PieceMovedEvent", "args": ["piece", "from_position", "to_position"]},
    "board.board_locked": {"class": "BoardEvents.BoardLockedEvent", "args": ["board_id", "is_locked"]},
    "board.board_reset": {"class": "BoardEvents.BoardResetEvent", "args": ["board_id"]},
    "board.board_battle_started": {"class": "BoardEvents.BoardBattleStartedEvent", "args": ["board_id", "battle_id"]},
    "board.board_battle_ended": {"class": "BoardEvents.BoardBattleEndedEvent", "args": ["board_id", "battle_id", "is_victory"]},

    # 装备事件
    "equipment.equipment_created": {"class": "EquipmentEvents.EquipmentCreatedEvent", "args": ["equipment_id", "equipment_data"]},
    "equipment.equipment_combined": {"class": "EquipmentEvents.EquipmentCombinedEvent", "args": ["material_ids", "result_id", "result_data"]},
    "equipment.equipment_equipped": {"class": "EquipmentEvents.EquipmentEquippedEvent", "args": ["equipment_id", "equipment_data", "wearer"]},
    "equipment.equipment_unequipped": {"class": "EquipmentEvents.EquipmentUnequippedEvent", "args": ["equipment_id", "equipment_data", "wearer"]},

    # 事件系统事件
    "event.event_started": {"class": "EventEvents.EventStartedEvent", "args": ["event_id", "event_data"]},
    "event.event_option_selected": {"class": "EventEvents.EventOptionSelectedEvent", "args": ["event_id", "option_id", "option_data"]},
    "event.event_completed": {"class": "EventEvents.EventCompletedEvent", "args": ["event_id", "result"]},

    # 遗物事件
    "relic.relic_acquired": {"class": "RelicEvents.RelicAcquiredEvent", "args": ["relic_id", "relic_data"]},
    "relic.relic_activated": {"class": "RelicEvents.RelicActivatedEvent", "args": ["relic_id", "relic_data"]},
    "relic.show_relic_info": {"class": "RelicEvents.ShowRelicInfoEvent", "args": ["relic_id", "relic_data"]},
    "relic.hide_relic_info": {"class": "RelicEvents.HideRelicInfoEvent", "args": ["relic_id"]},

    # 皮肤事件
    "skin.skin_changed": {"class": "SkinEvents.SkinChangedEvent", "args": ["skin_type", "old_skin_id", "new_skin_id"]},
    "skin.skin_unlocked": {"class": "SkinEvents.SkinUnlockedEvent", "args": ["skin_type", "skin_id"]},
    "skin.chess_skin_changed": {"class": "SkinEvents.ChessSkinChangedEvent", "args": ["chess_id", "old_skin_id", "new_skin_id"]},
    "skin.board_skin_changed": {"class": "SkinEvents.BoardSkinChangedEvent", "args": ["old_skin_id", "new_skin_id"]},
    "skin.ui_skin_changed": {"class": "SkinEvents.UISkinChangedEvent", "args": ["old_skin_id", "new_skin_id"]},

    # 存档事件
    "save.save_game_requested": {"class": "SaveEvents.SaveGameRequestedEvent", "args": ["save_id", "save_data"]},
    "save.load_game_requested": {"class": "SaveEvents.LoadGameRequestedEvent", "args": ["save_id"]},
    "save.game_loaded": {"class": "SaveEvents.GameLoadedEvent", "args": ["save_id", "save_data"]},
    "save.autosave_triggered": {"class": "SaveEvents.AutosaveTriggeredEvent", "args": []},

    # 本地化事件
    "localization.language_changed": {"class": "LocalizationEvents.LanguageChangedEvent", "args": ["language_code", "language_name"]},
    "localization.request_language_code": {"class": "LocalizationEvents.RequestLanguageCodeEvent", "args": []},
    "localization.request_font": {"class": "LocalizationEvents.RequestFontEvent", "args": ["font_name", "font_size"]},
    "localization.font_loaded": {"class": "LocalizationEvents.FontLoadedEvent", "args": ["font_name", "font_size", "font_resource"]},

    # 音频事件
    "audio.play_sound": {"class": "AudioEvents.PlaySoundEvent", "args": ["sound_id", "volume", "pitch"]},
    "audio.play_music": {"class": "AudioEvents.PlayMusicEvent", "args": ["music_id", "volume", "fade_in"]},
    "audio.stop_music": {"class": "AudioEvents.StopMusicEvent", "args": ["fade_out"]},
    "audio.set_volume": {"class": "AudioEvents.SetVolumeEvent", "args": ["audio_type", "volume"]},

    # 成就事件
    "achievement.achievement_unlocked": {"class": "AchievementEvents.AchievementUnlockedEvent", "args": ["achievement_id", "achievement_data"]},
    "achievement.achievement_progress_updated": {"class": "AchievementEvents.AchievementProgressUpdatedEvent", "args": ["achievement_id", "old_progress", "new_progress", "target_progress"]},

    # 状态效果事件
    "status_effect.status_effect_added": {"class": "StatusEffectEvents.StatusEffectAddedEvent", "args": ["target", "effect_id", "effect_data", "source"]},
    "status_effect.status_effect_removed": {"class": "StatusEffectEvents.StatusEffectRemovedEvent", "args": ["target", "effect_id"]},
    "status_effect.status_effect_resisted": {"class": "StatusEffectEvents.StatusEffectResistedEvent", "args": ["target", "effect_id", "source"]},
    "status_effect.status_effect_triggered": {"class": "StatusEffectEvents.StatusEffectTriggeredEvent", "args": ["target", "effect_id", "effect_data"]}
}

## 获取事件映射
## @param old_event_name 旧事件名称
## @return 事件映射信息
func get_mapping(old_event_name: String) -> Dictionary:
    # 检查是否有直接映射
    if _event_mapping.has(old_event_name):
        return _event_mapping[old_event_name]

    # 检查是否有分组前缀
    var parts = old_event_name.split(".")
    if parts.size() == 2:
        var group = parts[0]
        var event_name = parts[1]

        # 尝试使用完整名称
        var full_name = group + "." + event_name
        if _event_mapping.has(full_name):
            return _event_mapping[full_name]

    # 未找到映射
    return {}

## 创建新事件
## @param old_event_name 旧事件名称
## @param args 事件参数
## @return 新事件实例
func create_event(old_event_name: String, args: Array) -> Event:
    # 获取映射
    var mapping = get_mapping(old_event_name)
    if mapping.is_empty():
        push_warning("未找到事件映射: " + old_event_name)
        return null

    # 解析类名
    var class_path = mapping.class.split(".")
    if class_path.size() != 2:
        push_error("无效的类路径: " + mapping.class)
        return null

    # 获取类
    var event_class_name = class_path[0]
    var event_type_name = class_path[1]

    # 加载类
    var event_class
    match event_class_name:
        "GameEvents":
            event_class = GameEvents
        "BattleEvents":
            event_class = BattleEvents
        "ChessEvents":
            event_class = ChessEvents
        "UIEvents":
            event_class = UIEvents
        "DebugEvents":
            event_class = DebugEvents
        "ComponentEvents":
            event_class = ComponentEvents
        "EconomyEvents":
            event_class = EconomyEvents
        "MapEvents":
            event_class = MapEvents
        "BoardEvents":
            event_class = BoardEvents
        "EquipmentEvents":
            event_class = EquipmentEvents
        "EventEvents":
            event_class = EventEvents
        "RelicEvents":
            event_class = RelicEvents
        "SkinEvents":
            event_class = SkinEvents
        "SaveEvents":
            event_class = SaveEvents
        "LocalizationEvents":
            event_class = LocalizationEvents
        "AudioEvents":
            event_class = AudioEvents
        "AchievementEvents":
            event_class = AchievementEvents
        "StatusEffectEvents":
            event_class = StatusEffectEvents
        _:
            push_error("未知的事件类: " + event_class_name)
            return null

    # 获取事件类型
    var event_type = event_class.get(event_type_name)
    if not event_type:
        push_error("未找到事件类型: " + event_class_name + "." + event_type_name)
        return null

    # 创建事件实例
    var event
    match args.size():
        0:
            event = event_type.new()
        1:
            event = event_type.new(args[0])
        2:
            event = event_type.new(args[0], args[1])
        3:
            event = event_type.new(args[0], args[1], args[2])
        4:
            event = event_type.new(args[0], args[1], args[2], args[3])
        5:
            event = event_type.new(args[0], args[1], args[2], args[3], args[4])
        _:
            push_error("参数过多: " + str(args.size()))
            return null

    return event
