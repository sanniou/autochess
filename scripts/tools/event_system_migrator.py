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
    # 检查文件是否是GDScript文件
    if not file_path.endswith(".gd"):
        return False
    
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
    if directory == '.git':
        return
    """处理目录中的所有文件"""
    for root, dirs, files in os.walk(directory):
        for file in files:
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
    parser.add_argument("path", nargs="?", default=".", help="要处理的目录或文件路径，默认为当前目录")
    args = parser.parse_args()
    
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
