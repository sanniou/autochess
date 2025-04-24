#!/usr/bin/env python3
"""
事件系统迁移工具

用于将旧的EventBus系统迁移到新的基于信号的事件系统。
此工具会自动替换代码中的EventBus调用。

用法:
    python event_system_migrator.py [--dry-run] [--verbose] [path]

参数:
    --dry-run   不实际修改文件，只显示将要进行的更改
    --verbose   显示详细输出
    path        要处理的目录或文件路径，默认为当前目录
"""

import os
import re
import sys
import argparse
from typing import Dict, List, Tuple, Optional

# 事件映射表
EVENT_MAPPING = {
    # 游戏事件
    "game.game_state_changed": {"class": "GameEvents.GameStateChangedEvent", "args": ["old_state", "new_state"]},
    "game.game_paused": {"class": "GameEvents.GamePausedEvent", "args": ["is_paused"]},
    "game.game_started": {"class": "GameEvents.GameStartedEvent", "args": ["difficulty_level"]},
    "game.game_ended": {"class": "GameEvents.GameEndedEvent", "args": ["is_victory", "play_time", "score"]},
    "game.player_health_changed": {"class": "GameEvents.PlayerHealthChangedEvent", "args": ["old_health", "new_health", "max_health"]},
    "game.player_level_changed": {"class": "GameEvents.PlayerLevelChangedEvent", "args": ["old_level", "new_level"]},
    "game.player_died": {"class": "GameEvents.PlayerDiedEvent", "args": []},
    "game.difficulty_changed": {"class": "GameEvents.DifficultyChangedEvent", "args": ["old_level", "new_level"]},
    "game.player_exp_changed": {"class": "GameEvents.PlayerExpChangedEvent", "args": ["old_exp", "new_exp", "max_exp"]},
    "game.player_initialized": {"class": "GameEvents.PlayerInitializedEvent", "args": ["player"]},
    "game.ai_opponents_initialized": {"class": "GameEvents.AIOpponentsInitializedEvent", "args": ["opponents"]},
    "game.player_state_changed": {"class": "GameEvents.PlayerStateChangedEvent", "args": ["old_state", "new_state"]},
    "game.player_chess_updated": {"class": "GameEvents.PlayerChessUpdatedEvent", "args": ["player", "chess_pieces"]},
    "game.player_inventory_updated": {"class": "GameEvents.PlayerInventoryUpdatedEvent", "args": ["player", "inventory"]},
    "game.player_equipment_updated": {"class": "GameEvents.PlayerEquipmentUpdatedEvent", "args": ["player", "equipment"]},
    "game.player_relic_updated": {"class": "GameEvents.PlayerRelicUpdatedEvent", "args": ["player", "relics"]},

    # 战斗事件
    "battle.battle_started": {"class": "BattleEvents.BattleStartedEvent", "args": ["battle_id", "round", "player_pieces", "enemy_pieces"]},
    "battle.battle_ended": {"class": "BattleEvents.BattleEndedEvent", "args": ["battle_id", "is_victory", "duration", "remaining_pieces"]},
    "battle.round_started": {"class": "BattleEvents.RoundStartedEvent", "args": ["round"]},
    "battle.round_ended": {"class": "BattleEvents.RoundEndedEvent", "args": ["round"]},
    "battle.damage_dealt": {"class": "BattleEvents.DamageDealtEvent", "args": ["source_entity", "target_entity", "amount", "damage_type", "is_critical"]},
    "battle.heal_received": {"class": "BattleEvents.HealReceivedEvent", "args": ["source_entity", "target_entity", "amount"]},
    "battle.unit_died": {"class": "BattleEvents.UnitDiedEvent", "args": ["unit", "killer"]},
    "battle.ability_used": {"class": "BattleEvents.AbilityUsedEvent", "args": ["caster", "ability_data", "targets"]},
    "battle.battle_round_started": {"class": "BattleEvents.BattleRoundStartedEvent", "args": ["round"]},
    "battle.battle_round_ended": {"class": "BattleEvents.BattleRoundEndedEvent", "args": ["round"]},
    "battle.battle_preparing_phase_started": {"class": "BattleEvents.BattlePreparingPhaseStartedEvent", "args": []},
    "battle.battle_fighting_phase_started": {"class": "BattleEvents.BattleFightingPhaseStartedEvent", "args": []},
    "battle.battle_result_phase_started": {"class": "BattleEvents.BattleResultPhaseStartedEvent", "args": []},
    "battle.delayed_stun_removal": {"class": "BattleEvents.DelayedStunRemovalEvent", "args": ["entity", "duration"]},
    "battle.vampiric_heal": {"class": "BattleEvents.VampiricHealEvent", "args": ["source", "target", "amount"]},
    "battle.dot_damage": {"class": "BattleEvents.DotDamageEvent", "args": ["source", "target", "amount", "dot_type"]},
    "battle.hot_healing": {"class": "BattleEvents.HotHealingEvent", "args": ["source", "target", "amount", "hot_type"]},
    "battle.shield_absorbed": {"class": "BattleEvents.ShieldAbsorbedEvent", "args": ["entity", "shield", "damage_absorbed"]},
    "battle.damage_reflected": {"class": "BattleEvents.DamageReflectedEvent", "args": ["source", "target", "amount"]},
    "battle.critical_hit": {"class": "BattleEvents.CriticalHitEvent", "args": ["source", "target", "damage", "multiplier"]},
    "battle.mana_changed": {"class": "BattleEvents.ManaChangedEvent", "args": ["entity", "old_mana", "new_mana", "max_mana"]},
    "battle.healing_done": {"class": "BattleEvents.HealingDoneEvent", "args": ["source", "target", "amount"]},
    "battle.opponent_selected": {"class": "BattleEvents.OpponentSelectedEvent", "args": ["player", "opponent"]},

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
    "chess.chess_piece_level_changed": {"class": "ChessEvents.ChessPieceLevelChangedEvent", "args": ["piece", "old_level", "new_level"]},
    "chess.chess_piece_died": {"class": "ChessEvents.ChessPieceDiedEvent", "args": ["piece", "killer"]},
    "chess.chess_piece_ability_cast": {"class": "ChessEvents.ChessPieceAbilityCastEvent", "args": ["piece", "ability", "targets"]},
    "chess.chess_piece_elemental_effect_triggered": {"class": "ChessEvents.ChessPieceElementalEffectTriggeredEvent", "args": ["piece", "effect_type", "target"]},
    "chess.show_chess_info": {"class": "ChessEvents.ShowChessInfoEvent", "args": ["piece"]},
    "chess.hide_chess_info": {"class": "ChessEvents.HideChessInfoEvent", "args": []},
    "chess.chess_piece_placed": {"class": "ChessEvents.ChessPiecePlacedEvent", "args": ["piece", "position"]},
    "chess.chess_piece_removed": {"class": "ChessEvents.ChessPieceRemovedEvent", "args": ["piece", "position"]},
    "chess.chess_piece_bought": {"class": "ChessEvents.ChessPieceBoughtEvent", "args": ["piece", "cost"]},
    "chess.chess_piece_purchased": {"class": "ChessEvents.ChessPiecePurchasedEvent", "args": ["piece", "cost"]},
    "chess.chess_piece_added": {"class": "ChessEvents.ChessPieceAddedEvent", "args": ["piece"]},
    "chess.synergy_activated": {"class": "ChessEvents.SynergyActivatedEvent", "args": ["synergy_type", "level"]},
    "chess.synergy_deactivated": {"class": "ChessEvents.SynergyDeactivatedEvent", "args": ["synergy_type"]},
    "chess.synergy_level_changed": {"class": "ChessEvents.SynergyLevelChangedEvent", "args": ["synergy_type", "old_level", "new_level"]},
    "chess.synergy_type_added": {"class": "ChessEvents.SynergyTypeAddedEvent", "args": ["synergy_type", "count"]},
    "chess.synergy_type_removed": {"class": "ChessEvents.SynergyTypeRemovedEvent", "args": ["synergy_type", "count"]},
    "synergy.synergy_type_added": {"class": "ChessEvents.SynergyTypeAddedEvent", "args": ["synergy_type", "count"]},
    "synergy.synergy_type_removed": {"class": "ChessEvents.SynergyTypeRemovedEvent", "args": ["synergy_type", "count"]},
    "synergy.synergy_level_changed": {"class": "ChessEvents.SynergyLevelChangedEvent", "args": ["synergy_type", "old_level", "new_level"]},

    # 地图事件
    "map.map_node_hovered": {"class": "MapEvents.MapNodeHoveredEvent", "args": ["node"]},
    "map.map_node_selected": {"class": "MapEvents.MapNodeSelectedEvent", "args": ["node"]},
    "map.map_completed": {"class": "MapEvents.MapCompletedEvent", "args": []},
    "map.altar_sacrifice_made": {"class": "MapEvents.AltarSacrificeMadeEvent", "args": ["piece", "reward"]},
    "map.equipment_upgraded": {"class": "MapEvents.EquipmentUpgradedEvent", "args": ["equipment", "level"]},
    "map.treasure_collected": {"class": "MapEvents.TreasureCollectedEvent", "args": ["rewards"]},
    "map.rest_completed": {"class": "MapEvents.RestCompletedEvent", "args": ["healing_amount"]},
    "map.map_generated": {"class": "MapEvents.MapGeneratedEvent", "args": ["map_data"]},

    # 经济事件
    "economy.gold_changed": {"class": "EconomyEvents.GoldChangedEvent", "args": ["old_amount", "new_amount", "change_reason"]},
    "economy.shop_refreshed": {"class": "EconomyEvents.ShopRefreshedEvent", "args": ["shop_type", "items"]},
    "economy.shop_manually_refreshed": {"class": "EconomyEvents.ShopManuallyRefreshedEvent", "args": ["shop_type", "cost"]},
    "economy.shop_refresh_requested": {"class": "EconomyEvents.ShopRefreshRequestedEvent", "args": ["shop_type"]},
    "economy.item_purchased": {"class": "EconomyEvents.ItemPurchasedEvent", "args": ["item", "cost"]},
    "economy.item_sold": {"class": "EconomyEvents.ItemSoldEvent", "args": ["item", "gold_amount"]},
    "economy.shop_discount_applied": {"class": "EconomyEvents.ShopDiscountAppliedEvent", "args": ["discount_percent", "shop_type"]},
    "economy.shop_closed": {"class": "EconomyEvents.ShopClosedEvent", "args": ["shop_type"]},
    "economy.income_granted": {"class": "EconomyEvents.IncomeGrantedEvent", "args": ["amount", "source"]},
    "economy.chess_shop_inventory_updated": {"class": "EconomyEvents.ChessShopInventoryUpdatedEvent", "args": ["items"]},
    "shop.shop_refreshed": {"class": "EconomyEvents.ShopRefreshedEvent", "args": ["shop_type", "items"]},
    "shop.discount_applied": {"class": "EconomyEvents.ShopDiscountAppliedEvent", "args": ["discount_percent", "shop_type"]},

    # 装备事件
    "equipment.equipment_equipped": {"class": "EquipmentEvents.EquipmentEquippedEvent", "args": ["equipment", "piece"]},
    "equipment.equipment_unequipped": {"class": "EquipmentEvents.EquipmentUnequippedEvent", "args": ["equipment", "piece"]},
    "equipment.equipment_created": {"class": "EquipmentEvents.EquipmentCreatedEvent", "args": ["equipment"]},
    "equipment.equipment_combined": {"class": "EquipmentEvents.EquipmentCombinedEvent", "args": ["base_equipment", "material_equipment", "result_equipment"]},
    "equipment.equipment_combine_requested": {"class": "EquipmentEvents.EquipmentCombineRequestedEvent", "args": ["base_equipment", "material_equipment"]},
    "equipment.equipment_combine_animation_started": {"class": "EquipmentEvents.EquipmentCombineAnimationStartedEvent", "args": ["base_equipment", "material_equipment"]},
    "equipment.equipment_combine_animation_completed": {"class": "EquipmentEvents.EquipmentCombineAnimationCompletedEvent", "args": ["result_equipment"]},
    "equipment.equipment_effect_triggered": {"class": "EquipmentEvents.EquipmentEffectTriggeredEvent", "args": ["equipment", "effect_type", "target"]},
    "equipment.equipment_tier_changed": {"class": "EquipmentEvents.EquipmentTierChangedEvent", "args": ["equipment", "old_tier", "new_tier"]},

    # UI事件
    "ui.update_ui": {"class": "UIEvents.UIUpdateEvent", "args": ["component", "data"]},
    "ui.button_clicked": {"class": "UIEvents.ButtonClickedEvent", "args": ["button_id", "button_text", "button_data"]},
    "ui.menu_opened": {"class": "UIEvents.MenuOpenedEvent", "args": ["menu_id", "menu_data"]},
    "ui.menu_closed": {"class": "UIEvents.MenuClosedEvent", "args": ["menu_id"]},
    "ui.dialog_shown": {"class": "UIEvents.DialogShownEvent", "args": ["dialog_id", "title", "content", "options"]},
    "ui.show_toast": {"class": "UIEvents.ToastShownEvent", "args": ["title", "message", "type", "duration"]},

    # UI事件（续）
    "ui.start_transition": {"class": "UIEvents.StartTransitionEvent", "args": ["from_scene", "to_scene", "transition_type"]},
    "ui.transition_midpoint": {"class": "UIEvents.TransitionMidpointEvent", "args": ["from_scene", "to_scene"]},
    "ui.show_popup": {"class": "UIEvents.ShowPopupEvent", "args": ["popup_type", "data"]},
    "ui.close_popup": {"class": "UIEvents.ClosePopupEvent", "args": ["popup_type"]},
    "ui.theme_changed": {"class": "UIEvents.ThemeChangedEvent", "args": ["theme_name"]},
    "ui.language_changed": {"class": "UIEvents.LanguageChangedEvent", "args": ["language_code"]},
    "ui.scale_changed": {"class": "UIEvents.ScaleChangedEvent", "args": ["scale_factor"]},
    "ui.show_notification": {"class": "UIEvents.ShowNotificationEvent", "args": ["title", "message", "type", "duration"]},
    "ui.hide_notification": {"class": "UIEvents.HideNotificationEvent", "args": ["notification_id"]},
    "ui.clear_notifications": {"class": "UIEvents.ClearNotificationsEvent", "args": []},
    "ui.register_ui_throttler": {"class": "UIEvents.RegisterUIThrottlerEvent", "args": ["throttler", "priority"]},
    "ui.unregister_ui_throttler": {"class": "UIEvents.UnregisterUIThrottlerEvent", "args": ["throttler"]},
    "ui.force_ui_update": {"class": "UIEvents.ForceUIUpdateEvent", "args": []},
    "ui.ui_screen_changed": {"class": "UIEvents.UIScreenChangedEvent", "args": ["screen_name"]},

    # 遗物事件
    "relic.relic_acquired": {"class": "RelicEvents.RelicAcquiredEvent", "args": ["relic"]},
    "relic.relic_activated": {"class": "RelicEvents.RelicActivatedEvent", "args": ["relic", "target"]},
    "relic.relic_effect_triggered": {"class": "RelicEvents.RelicEffectTriggeredEvent", "args": ["relic", "effect_type", "target"]},
    "relic.relic_updated": {"class": "RelicEvents.RelicUpdatedEvent", "args": ["relic", "old_state", "new_state"]},
    "relic.show_relic_info": {"class": "RelicEvents.ShowRelicInfoEvent", "args": ["relic"]},
    "relic.hide_relic_info": {"class": "RelicEvents.HideRelicInfoEvent", "args": []},

    # 音频事件
    "audio.play_sound": {"class": "AudioEvents.PlaySoundEvent", "args": ["sound_id", "volume", "pitch"]},
    "audio.bgm_changed": {"class": "AudioEvents.BGMChangedEvent", "args": ["track_id", "transition_time"]},
    "audio.sfx_played": {"class": "AudioEvents.SFXPlayedEvent", "args": ["sound_id", "position"]},

    # 本地化事件
    "localization.language_changed": {"class": "LocalizationEvents.LanguageChangedEvent", "args": ["language_code"]},
    "localization.request_font": {"class": "LocalizationEvents.RequestFontEvent", "args": ["language_code", "font_size"]},
    "localization.request_language_code": {"class": "LocalizationEvents.RequestLanguageCodeEvent", "args": []},
    "localization.font_loaded": {"class": "LocalizationEvents.FontLoadedEvent", "args": ["language_code", "font_resource"]},

    # 事件系统事件
    "event.event_triggered": {"class": "EventEvents.EventTriggeredEvent", "args": ["event_id", "event_data"]},
    "event.event_choice_made": {"class": "EventEvents.EventChoiceMadeEvent", "args": ["event_id", "choice_id"]},
    "event.event_completed": {"class": "EventEvents.EventCompletedEvent", "args": ["event_id", "result"]},
    "event.event_started": {"class": "EventEvents.EventStartedEvent", "args": ["event_id", "event_data"]},
    "event.event_option_selected": {"class": "EventEvents.EventOptionSelectedEvent", "args": ["event_id", "option_id"]},

    # 状态效果事件
    "status_effect.status_effect_added": {"class": "StatusEffectEvents.StatusEffectAddedEvent", "args": ["entity", "effect", "source"]},
    "status_effect.status_effect_resisted": {"class": "StatusEffectEvents.StatusEffectResistedEvent", "args": ["entity", "effect_type", "source"]},

    # 皮肤事件
    "skin.chess_skin_changed": {"class": "SkinEvents.ChessSkinChangedEvent", "args": ["piece_type", "skin_id"]},
    "skin.board_skin_changed": {"class": "SkinEvents.BoardSkinChangedEvent", "args": ["skin_id"]},
    "skin.ui_skin_changed": {"class": "SkinEvents.UISkinChangedEvent", "args": ["skin_id"]},
    "skin.skin_changed": {"class": "SkinEvents.SkinChangedEvent", "args": ["skin_type", "skin_id"]},
    "skin.skin_unlocked": {"class": "SkinEvents.SkinUnlockedEvent", "args": ["skin_type", "skin_id"]},

    # 保存事件
    "save.game_saved": {"class": "SaveEvents.GameSavedEvent", "args": ["save_id", "save_data"]},
    "save.game_loaded": {"class": "SaveEvents.GameLoadedEvent", "args": ["save_id", "save_data"]},
    "save.autosave_triggered": {"class": "SaveEvents.AutosaveTriggeredEvent", "args": []},
    "save.save_game_requested": {"class": "SaveEvents.SaveGameRequestedEvent", "args": ["save_id"]},
    "save.load_game_requested": {"class": "SaveEvents.LoadGameRequestedEvent", "args": ["save_id"]},

    # 调试事件
    "debug.debug_message": {"class": "DebugEvents.DebugMessageEvent", "args": ["message", "level", "tag"]},
    "debug.command_executed": {"class": "DebugEvents.DebugCommandExecutedEvent", "args": ["command", "args", "result"]},
    "debug.console_toggled": {"class": "DebugEvents.DebugConsoleToggledEvent", "args": ["visible"]},
    "debug.performance_warning": {"class": "DebugEvents.PerformanceWarningEvent", "args": ["warning_type", "details"]},
    "debug.debug_command_executed": {"class": "DebugEvents.DebugCommandExecutedEvent", "args": ["command", "result"]},
    "debug.performance_data_updated": {"class": "DebugEvents.PerformanceDataUpdatedEvent", "args": ["fps", "memory_usage", "draw_calls"]},

    # 成就事件
    "achievement.achievement_unlocked": {"class": "AchievementEvents.AchievementUnlockedEvent", "args": ["achievement_id", "achievement_data"]},
    "achievement.achievement_progress_updated": {"class": "AchievementEvents.AchievementProgressUpdatedEvent", "args": ["achievement_id", "progress", "max_progress"]},

    # 教程事件
    "tutorial.start_tutorial": {"class": "TutorialEvents.StartTutorialEvent", "args": ["tutorial_id"]},
    "tutorial.skip_tutorial": {"class": "TutorialEvents.SkipTutorialEvent", "args": ["tutorial_id"]},
    "tutorial.complete_tutorial": {"class": "TutorialEvents.CompleteTutorialEvent", "args": ["tutorial_id"]},

    # 棋盘事件
    "board.board_reset": {"class": "BoardEvents.BoardResetEvent", "args": []},
    "board.board_battle_started": {"class": "BoardEvents.BoardBattleStartedEvent", "args": []},
    "board.board_battle_ended": {"class": "BoardEvents.BoardBattleEndedEvent", "args": ["is_victory"]},
    "board.cell_clicked": {"class": "BoardEvents.CellClickedEvent", "args": ["cell_position"]},
    "board.cell_hovered": {"class": "BoardEvents.CellHoveredEvent", "args": ["cell_position"]},
    "board.cell_exited": {"class": "BoardEvents.CellExitedEvent", "args": ["cell_position"]},
    "board.piece_placed_on_board": {"class": "BoardEvents.PiecePlacedOnBoardEvent", "args": ["piece", "position"]},
    "board.piece_removed_from_board": {"class": "BoardEvents.PieceRemovedFromBoardEvent", "args": ["piece", "position"]},
    "board.piece_placed_on_bench": {"class": "BoardEvents.PiecePlacedOnBenchEvent", "args": ["piece", "position"]},
    "board.piece_removed_from_bench": {"class": "BoardEvents.PieceRemovedFromBenchEvent", "args": ["piece", "position"]},
    "board.board_initialized": {"class": "BoardEvents.BoardInitializedEvent", "args": []},
    "board.piece_placed": {"class": "BoardEvents.PiecePlacedEvent", "args": ["piece", "position", "is_board"]},
    "board.piece_removed": {"class": "BoardEvents.PieceRemovedEvent", "args": ["piece", "position", "is_board"]},
    "board.piece_moved": {"class": "BoardEvents.PieceMovedEvent", "args": ["piece", "from_position", "to_position"]},
    "board.board_locked": {"class": "BoardEvents.BoardLockedEvent", "args": ["is_locked"]}
}

# 要跳过的目录
skip_dirs = ['.git', '.github', '.godot', 'addons', 'build', 'dist', 'export', 'logs', 'temp', 'tmp']

# 统计信息
stats = {
    "files_processed": 0,
    "files_modified": 0,
    "emit_event_replaced": 0,
    "connect_event_replaced": 0,
    "disconnect_event_replaced": 0,
    "errors": 0
}

def get_event_mapping(event_name: str) -> Optional[Dict]:
    """获取事件映射"""
    # 检查是否有直接映射
    if event_name in EVENT_MAPPING:
        return EVENT_MAPPING[event_name]

    # 检查是否有分组前缀
    parts = event_name.split(".")
    if len(parts) == 2:
        group, name = parts

        # 尝试使用完整名称
        full_name = f"{group}.{name}"
        if full_name in EVENT_MAPPING:
            return EVENT_MAPPING[full_name]

    # 未找到映射
    return None

def generate_event_creation_code(group_name: str, event_name: str, args_str: str) -> str:
    """生成事件创建代码"""
    # 获取完整事件名称
    full_event_name = f"{group_name}.{event_name}"

    # 获取事件映射
    mapping = get_event_mapping(full_event_name)
    if not mapping:
        print(f"警告: 未找到事件映射: {full_event_name}")
        return f"EventBus.{group_name}.emit_event(\"{event_name}\"{f', [{args_str}]' if args_str else ''})"

    # 解析类名
    class_path = mapping["class"].split(".")
    if len(class_path) != 2:
        print(f"错误: 无效的类路径: {mapping['class']}")
        return f"EventBus.{group_name}.emit_event(\"{event_name}\"{f', [{args_str}]' if args_str else ''})"

    # 获取类和事件类型
    event_class_name, event_type_name = class_path

    # 构造事件创建代码
    args_array = []
    if args_str:
        args_array = [arg.strip() for arg in args_str.split(",")]

    # 构造新代码
    new_code = f"GlobalEventBus.{group_name}.dispatch_event({event_class_name}.{event_type_name}.new("

    # 添加参数
    if args_array:
        new_code += ", ".join(args_array)

    new_code += "))"

    return new_code

def generate_listener_code(group_name: str, event_name: str, callback: str) -> str:
    """生成监听器代码"""
    # 获取完整事件名称
    full_event_name = f"{group_name}.{event_name}"

    # 获取事件映射
    mapping = get_event_mapping(full_event_name)
    if not mapping:
        print(f"警告: 未找到事件映射: {full_event_name}")
        return f"EventBus.{group_name}.connect_event(\"{event_name}\", {callback})"

    # 构造新代码
    new_code = f"GlobalEventBus.{group_name}.add_listener(\"{event_name}\", {callback})"

    return new_code

def generate_remove_listener_code(group_name: str, event_name: str, callback: str) -> str:
    """生成移除监听器代码"""
    # 获取完整事件名称
    full_event_name = f"{group_name}.{event_name}"

    # 获取事件映射
    mapping = get_event_mapping(full_event_name)
    if not mapping:
        print(f"警告: 未找到事件映射: {full_event_name}")
        return f"EventBus.{group_name}.disconnect_event(\"{event_name}\", {callback})"

    # 构造新代码
    new_code = f"GlobalEventBus.{group_name}.remove_listener(\"{event_name}\", {callback})"

    return new_code

def replace_emit_event_calls(content: str) -> Tuple[str, int]:
    """替换emit_event调用"""
    count = 0

    # 创建正则表达式
    pattern = r'(EventBus\.[a-z_]+)\.emit_event\(\s*["\']([^"\']+)["\'](?:\s*,\s*\[([^\]]*)\])?\s*\)'

    # 定义替换函数
    def replace_func(match):
        nonlocal count
        event_bus = match.group(1)  # EventBus.game
        event_name = match.group(2)  # game_started
        args_str = match.group(3) or ""  # 1, 2, 3

        # 获取分组名称
        group_name = event_bus.split(".")[1]  # game

        # 构造新的事件创建代码
        new_code = generate_event_creation_code(group_name, event_name, args_str)

        count += 1
        return new_code

    # 替换代码
    new_content = re.sub(pattern, replace_func, content)

    return new_content, count

def replace_connect_event_calls(content: str) -> Tuple[str, int]:
    """替换connect_event调用"""
    count = 0

    # 创建正则表达式
    pattern = r'(EventBus\.[a-z_]+)\.connect_event\(\s*["\']([^"\']+)["\'](?:\s*,\s*([^)]+))?\s*\)'

    # 定义替换函数
    def replace_func(match):
        nonlocal count
        event_bus = match.group(1)  # EventBus.game
        event_name = match.group(2)  # game_started
        callback = match.group(3) or ""  # _on_game_started

        # 获取分组名称
        group_name = event_bus.split(".")[1]  # game

        # 构造新的监听器代码
        new_code = generate_listener_code(group_name, event_name, callback)

        count += 1
        return new_code

    # 替换代码
    new_content = re.sub(pattern, replace_func, content)

    return new_content, count

def replace_disconnect_event_calls(content: str) -> Tuple[str, int]:
    """替换disconnect_event调用"""
    count = 0

    # 创建正则表达式
    pattern = r'(EventBus\.[a-z_]+)\.disconnect_event\(\s*["\']([^"\']+)["\'](?:\s*,\s*([^)]+))?\s*\)'

    # 定义替换函数
    def replace_func(match):
        nonlocal count
        event_bus = match.group(1)  # EventBus.game
        event_name = match.group(2)  # game_started
        callback = match.group(3) or ""  # _on_game_started

        # 获取分组名称
        group_name = event_bus.split(".")[1]  # game

        # 构造新的移除监听器代码
        new_code = generate_remove_listener_code(group_name, event_name, callback)

        count += 1
        return new_code

    # 替换代码
    new_content = re.sub(pattern, replace_func, content)

    return new_content, count

def process_file(file_path: str, dry_run: bool = False, verbose: bool = False) -> bool:
    """处理单个文件"""
    try:
        # 读取文件内容
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # 替换EventBus调用
        modified = False

        # 替换emit_event调用
        new_content, emit_count = replace_emit_event_calls(content)
        if emit_count > 0:
            content = new_content
            modified = True
            stats["emit_event_replaced"] += emit_count
            if verbose:
                print(f"  替换了 {emit_count} 个 emit_event 调用")

        # 替换connect_event调用
        new_content, connect_count = replace_connect_event_calls(content)
        if connect_count > 0:
            content = new_content
            modified = True
            stats["connect_event_replaced"] += connect_count
            if verbose:
                print(f"  替换了 {connect_count} 个 connect_event 调用")

        # 替换disconnect_event调用
        new_content, disconnect_count = replace_disconnect_event_calls(content)
        if disconnect_count > 0:
            content = new_content
            modified = True
            stats["disconnect_event_replaced"] += disconnect_count
            if verbose:
                print(f"  替换了 {disconnect_count} 个 disconnect_event 调用")

        # 如果文件被修改，保存更改
        if modified and not dry_run:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)

            stats["files_modified"] += 1
            if verbose:
                print(f"  文件已修改: {file_path}")

        stats["files_processed"] += 1
        return modified

    except Exception as e:
        print(f"错误: 处理文件 {file_path} 时出错: {e}")
        stats["errors"] += 1
        return False

def process_directory(directory: str, dry_run: bool = False, verbose: bool = False) -> None:
    """处理目录中的所有文件"""
    global skip_dirs

    for root, dirs, files in os.walk(directory):
        # 修改dirs列表，跳过不需要处理的目录
        dirs[:] = [d for d in dirs if d not in skip_dirs and not d.startswith('.')]

        for file in files:
            # 只处理.gd文件
            if not file.endswith('.gd'):
                continue

            file_path = os.path.join(root, file)
            if verbose:
                print(f"处理文件: {file_path}")
            process_file(file_path, dry_run, verbose)

def main():
    """主函数"""
    # 解析命令行参数
    parser = argparse.ArgumentParser(description="事件系统迁移工具")
    parser.add_argument("--dry-run", action="store_true", help="不实际修改文件，只显示将要进行的更改")
    parser.add_argument("--verbose", action="store_true", help="显示详细输出")
    parser.add_argument("--skip-dirs", type=str, default=".git,.github,.godot,addons,build,dist,export,logs,temp,tmp",
                        help="要跳过的目录，用逗号分隔，默认为'.git,.github,.godot,addons,build,dist,export,logs,temp,tmp'")
    parser.add_argument("path", nargs="?", default=".", help="要处理的目录或文件路径，默认为当前目录")
    args = parser.parse_args()

    # 解析要跳过的目录
    global skip_dirs
    skip_dirs = args.skip_dirs.split(",")

    # 处理路径
    path = args.path
    if os.path.isfile(path):
        print(f"处理文件: {path}")
        process_file(path, args.dry_run, args.verbose)
    elif os.path.isdir(path):
        print(f"处理目录: {path}")
        process_directory(path, args.dry_run, args.verbose)
    else:
        print(f"错误: 路径不存在: {path}")
        return 1

    # 打印统计信息
    print("\n统计信息:")
    print(f"  处理文件数: {stats['files_processed']}")
    print(f"  修改文件数: {stats['files_modified']}")
    print(f"  替换 emit_event 调用数: {stats['emit_event_replaced']}")
    print(f"  替换 connect_event 调用数: {stats['connect_event_replaced']}")
    print(f"  替换 disconnect_event 调用数: {stats['disconnect_event_replaced']}")
    print(f"  错误数: {stats['errors']}")

    if args.dry_run:
        print("\n注意: 这是一次试运行，没有实际修改文件。")

    return 0

if __name__ == "__main__":
    sys.exit(main())
