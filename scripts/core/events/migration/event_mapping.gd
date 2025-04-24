extends RefCounted
class_name EventMapping
## 事件映射
## 提供旧事件名称到新事件类型的映射

## 事件映射表
var _event_mapping: Dictionary = {
    # 游戏事件
    "game.game_state_changed": {"class": "GameEvents.GameStateChangedEvent", "args": ["old_state", "new_state"]},
    "game.game_paused": {"class": "GameEvents.GamePausedEvent", "args": ["is_paused"]},
    "game.game_started": {"class": "GameEvents.GameStartedEvent", "args": ["difficulty_level"]},
    "game.game_ended": {"class": "GameEvents.GameEndedEvent", "args": ["is_victory", "play_time", "score"]},
    "game.player_health_changed": {"class": "GameEvents.PlayerHealthChangedEvent", "args": ["old_health", "new_health", "max_health"]},
    "game.player_level_changed": {"class": "GameEvents.PlayerLevelChangedEvent", "args": ["old_level", "new_level"]},
    "game.player_died": {"class": "GameEvents.PlayerDiedEvent", "args": []},
    "game.difficulty_changed": {"class": "GameEvents.DifficultyChangedEvent", "args": ["old_level", "new_level"]},
    
    # 战斗事件
    "battle.battle_started": {"class": "BattleEvents.BattleStartedEvent", "args": ["battle_id", "round", "player_pieces", "enemy_pieces"]},
    "battle.battle_ended": {"class": "BattleEvents.BattleEndedEvent", "args": ["battle_id", "is_victory", "duration", "remaining_pieces"]},
    "battle.round_started": {"class": "BattleEvents.RoundStartedEvent", "args": ["round"]},
    "battle.round_ended": {"class": "BattleEvents.RoundEndedEvent", "args": ["round"]},
    "battle.damage_dealt": {"class": "BattleEvents.DamageDealtEvent", "args": ["source_entity", "target_entity", "amount", "damage_type", "is_critical"]},
    "battle.heal_received": {"class": "BattleEvents.HealReceivedEvent", "args": ["source_entity", "target_entity", "amount"]},
    "battle.unit_died": {"class": "BattleEvents.UnitDiedEvent", "args": ["unit", "killer"]},
    "battle.ability_used": {"class": "BattleEvents.AbilityUsedEvent", "args": ["caster", "ability_data", "targets"]},
    
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
    "ui.button_clicked": {"class": "UIEvents.ButtonClickedEvent", "args": ["button_id", "button_text", "button_data"]},
    "ui.menu_opened": {"class": "UIEvents.MenuOpenedEvent", "args": ["menu_id", "menu_data"]},
    "ui.menu_closed": {"class": "UIEvents.MenuClosedEvent", "args": ["menu_id"]},
    "ui.dialog_shown": {"class": "UIEvents.DialogShownEvent", "args": ["dialog_id", "title", "content", "options"]},
    "ui.show_toast": {"class": "UIEvents.ToastShownEvent", "args": ["title", "message", "type", "duration"]},
    
    # 调试事件
    "debug.debug_message": {"class": "DebugEvents.DebugMessageEvent", "args": ["message", "level", "tag"]},
    "debug.command_executed": {"class": "DebugEvents.DebugCommandExecutedEvent", "args": ["command", "args", "result"]},
    "debug.console_toggled": {"class": "DebugEvents.DebugConsoleToggledEvent", "args": ["visible"]},
    "debug.performance_warning": {"class": "DebugEvents.PerformanceWarningEvent", "args": ["warning_type", "details"]}
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
