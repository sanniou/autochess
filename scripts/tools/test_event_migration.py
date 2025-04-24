#!/usr/bin/env python3
"""
事件系统迁移测试脚本

用于测试事件系统迁移工具的效果。
此脚本会创建一些测试文件，然后运行迁移工具，最后检查迁移结果。
"""

import os
import sys
import tempfile
import shutil
import subprocess
from typing import List, Dict

# 测试用例
TEST_CASES = [
    {
        "name": "emit_event_basic",
        "code": """
func test_emit_event():
    # 触发游戏开始事件
    EventBus.game.emit_event("game_started", [1])
    
    # 触发伤害事件
    EventBus.battle.emit_event("damage_dealt", [source, target, 25.0, "physical", true])
""",
        "expected": """
func test_emit_event():
    # 触发游戏开始事件
    GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new(1))
    
    # 触发伤害事件
    GlobalEventBus.battle.dispatch_event(BattleEvents.DamageDealtEvent.new(source, target, 25.0, "physical", true))
"""
    },
    {
        "name": "connect_event_basic",
        "code": """
func _ready():
    # 监听游戏开始事件
    EventBus.game.connect_event("game_started", _on_game_started)
    
    # 监听伤害事件
    EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)
""",
        "expected": """
func _ready():
    # 监听游戏开始事件
    GlobalEventBus.game.add_listener("game_started", _on_game_started)
    
    # 监听伤害事件
    GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)
"""
    },
    {
        "name": "disconnect_event_basic",
        "code": """
func _exit_tree():
    # 取消监听游戏开始事件
    EventBus.game.disconnect_event("game_started", _on_game_started)
    
    # 取消监听伤害事件
    EventBus.battle.disconnect_event("damage_dealt", _on_damage_dealt)
""",
        "expected": """
func _exit_tree():
    # 取消监听游戏开始事件
    GlobalEventBus.game.remove_listener("game_started", _on_game_started)
    
    # 取消监听伤害事件
    GlobalEventBus.battle.remove_listener("damage_dealt", _on_damage_dealt)
"""
    },
    {
        "name": "complex_case",
        "code": """
extends Node
class_name TestEventSystem

func _ready():
    # 监听事件
    EventBus.game.connect_event("game_started", _on_game_started)
    EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)
    EventBus.chess.connect_event("chess_piece_moved", _on_chess_piece_moved)

func _exit_tree():
    # 取消监听事件
    EventBus.game.disconnect_event("game_started", _on_game_started)
    EventBus.battle.disconnect_event("damage_dealt", _on_damage_dealt)
    EventBus.chess.disconnect_event("chess_piece_moved", _on_chess_piece_moved)

func test_events():
    # 触发事件
    EventBus.game.emit_event("game_started", [1])
    EventBus.battle.emit_event("damage_dealt", [self, target, 25.0, "physical", true])
    EventBus.chess.emit_event("chess_piece_moved", [piece, Vector2(0, 0), Vector2(1, 1)])

func _on_game_started(event):
    print("游戏已开始")

func _on_damage_dealt(event):
    print("伤害已造成")

func _on_chess_piece_moved(event):
    print("棋子已移动")
""",
        "expected": """
extends Node
class_name TestEventSystem

func _ready():
    # 监听事件
    GlobalEventBus.game.add_listener("game_started", _on_game_started)
    GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)
    GlobalEventBus.chess.add_listener("chess_piece_moved", _on_chess_piece_moved)

func _exit_tree():
    # 取消监听事件
    GlobalEventBus.game.remove_listener("game_started", _on_game_started)
    GlobalEventBus.battle.remove_listener("damage_dealt", _on_damage_dealt)
    GlobalEventBus.chess.remove_listener("chess_piece_moved", _on_chess_piece_moved)

func test_events():
    # 触发事件
    GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new(1))
    GlobalEventBus.battle.dispatch_event(BattleEvents.DamageDealtEvent.new(self, target, 25.0, "physical", true))
    GlobalEventBus.chess.dispatch_event(ChessEvents.ChessPieceMovedEvent.new(piece, Vector2(0, 0), Vector2(1, 1)))

func _on_game_started(event):
    print("游戏已开始")

func _on_damage_dealt(event):
    print("伤害已造成")

func _on_chess_piece_moved(event):
    print("棋子已移动")
"""
    }
]

def create_test_files(temp_dir: str) -> List[str]:
    """创建测试文件"""
    file_paths = []
    
    for test_case in TEST_CASES:
        file_path = os.path.join(temp_dir, f"{test_case['name']}.gd")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(test_case["code"])
        file_paths.append(file_path)
    
    return file_paths

def run_migration_tool(temp_dir: str) -> bool:
    """运行迁移工具"""
    migrator_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "event_system_migrator.py")
    
    try:
        result = subprocess.run(
            [sys.executable, migrator_path, "--verbose", temp_dir],
            capture_output=True,
            text=True,
            check=True
        )
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"错误: 运行迁移工具失败: {e}")
        print(e.stdout)
        print(e.stderr)
        return False

def check_migration_results(temp_dir: str) -> bool:
    """检查迁移结果"""
    all_passed = True
    
    for test_case in TEST_CASES:
        file_path = os.path.join(temp_dir, f"{test_case['name']}.gd")
        
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            expected = test_case["expected"].strip()
            actual = content.strip()
            
            if expected == actual:
                print(f"测试通过: {test_case['name']}")
            else:
                print(f"测试失败: {test_case['name']}")
                print("预期:")
                print(expected)
                print("实际:")
                print(actual)
                all_passed = False
        except Exception as e:
            print(f"错误: 检查文件 {file_path} 时出错: {e}")
            all_passed = False
    
    return all_passed

def main():
    """主函数"""
    print("开始事件系统迁移测试...")
    
    # 创建临时目录
    temp_dir = tempfile.mkdtemp()
    print(f"创建临时目录: {temp_dir}")
    
    try:
        # 创建测试文件
        file_paths = create_test_files(temp_dir)
        print(f"创建了 {len(file_paths)} 个测试文件")
        
        # 运行迁移工具
        print("运行迁移工具...")
        if not run_migration_tool(temp_dir):
            return 1
        
        # 检查迁移结果
        print("检查迁移结果...")
        if not check_migration_results(temp_dir):
            return 1
        
        print("所有测试通过!")
        return 0
    
    finally:
        # 清理临时目录
        shutil.rmtree(temp_dir)
        print(f"清理临时目录: {temp_dir}")

if __name__ == "__main__":
    sys.exit(main())
