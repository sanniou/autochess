#!/usr/bin/env python3
"""
效果系统迁移工具

此脚本用于将旧的效果系统迁移到新的效果系统。
它会扫描项目中的所有 GDScript 文件，查找对旧效果系统的引用，并替换为新效果系统的引用。

使用方法:
    python effect_system_migration.py [项目路径]

如果未指定项目路径，则使用当前目录。
"""

import os
import sys
import re
from pathlib import Path

# 替换规则
REPLACEMENTS = [
    # 类引用替换
    (r'extends\s+EffectManager', 'extends GameEffectManager'),
    (r'extends\s+BattleEffectManager', 'extends GameEffectManager'),
    (r'extends\s+VisualEffectAnimator', 'extends Node'),  # 不再使用旧的动画器
    
    # 变量引用替换
    (r'var\s+effect_manager\s*:\s*EffectManager', 'var game_effect_manager: GameEffectManager'),
    (r'var\s+effect_manager\s*:\s*BattleEffectManager', 'var game_effect_manager: GameEffectManager'),
    (r'var\s+effect_animator\s*:\s*VisualEffectAnimator', 'var visual_manager: VisualManager'),
    
    # 方法调用替换
    (r'effect_manager\.create_visual_effect\(', 'GameManager.visual_manager.create_combined_effect('),
    (r'effect_manager\.apply_effect\(', 'GameManager.game_effect_manager.apply_effect('),
    (r'effect_manager\.remove_effect\(', 'GameManager.game_effect_manager.remove_effect('),
    (r'effect_manager\.get_target_effects\(', 'GameManager.game_effect_manager.get_target_effects('),
    
    # 枚举引用替换
    (r'effect_manager\.VisualEffectType\.', ''),  # 移除枚举前缀，直接使用字符串
    (r'EffectManager\.VisualEffectType\.', ''),   # 移除枚举前缀，直接使用字符串
    
    # GameManager 引用替换
    (r'GameManager\.effect_manager', 'GameManager.game_effect_manager'),
    (r'GameManager\.get_manager\("EffectManager"\)', 'GameManager.game_effect_manager'),
    
    # 常量引用替换
    (r'MC\.ManagerNames\.EFFECT_MANAGER', 'MC.ManagerNames.GAME_EFFECT_MANAGER'),
]

def process_file(file_path):
    """处理单个文件，应用所有替换规则"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 应用所有替换规则
        for pattern, replacement in REPLACEMENTS:
            content = re.sub(pattern, replacement, content)
        
        # 如果内容有变化，写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"已更新: {file_path}")
            return True
        
        return False
    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")
        return False

def scan_directory(directory):
    """扫描目录中的所有 GDScript 文件并处理"""
    changed_files = 0
    total_files = 0
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.gd'):
                file_path = os.path.join(root, file)
                total_files += 1
                if process_file(file_path):
                    changed_files += 1
    
    print(f"\n迁移完成!")
    print(f"扫描了 {total_files} 个文件，更新了 {changed_files} 个文件。")

def main():
    """主函数"""
    # 获取项目路径
    if len(sys.argv) > 1:
        project_path = sys.argv[1]
    else:
        project_path = '.'
    
    # 检查路径是否存在
    if not os.path.exists(project_path):
        print(f"错误: 路径 '{project_path}' 不存在")
        sys.exit(1)
    
    print(f"开始迁移效果系统...")
    print(f"项目路径: {os.path.abspath(project_path)}")
    
    # 扫描并处理文件
    scan_directory(project_path)

if __name__ == "__main__":
    main()
