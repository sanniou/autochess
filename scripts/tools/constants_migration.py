#!/usr/bin/env python3
"""
常量迁移工具
用于更新现有代码中的常量引用
"""

import os
import re
import sys

# 项目根目录
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))

# 文件路径
SCRIPTS_DIR = os.path.join(PROJECT_ROOT, "scripts")
CONSTANTS_DIR = os.path.join(PROJECT_ROOT, "scripts/constants")

# 旧常量文件
OLD_CONSTANTS = {
    "relic_constants.gd": "RelicConstants",
    "effect_constants.gd": "EffectConstants",
    "rarity.gd": "RarityConstants"
}

# 新常量文件
NEW_CONSTANTS = {
    "game_constants.gd": "GameConstants",
    "effect_constants_new.gd": "EffectConstants",
    "relic_constants_new.gd": "RelicConstants"
}

# 常量映射
CONSTANT_MAPPING = {
    # 稀有度映射
    "RarityConstants.COMMON": "GameConstants.Rarity.COMMON",
    "RarityConstants.UNCOMMON": "GameConstants.Rarity.UNCOMMON",
    "RarityConstants.RARE": "GameConstants.Rarity.RARE",
    "RarityConstants.EPIC": "GameConstants.Rarity.EPIC",
    "RarityConstants.LEGENDARY": "GameConstants.Rarity.LEGENDARY",
    
    # 方法映射
    "RarityConstants.get_rarity_name": "GameConstants.get_rarity_name",
    "RarityConstants.get_rarity_color": "GameConstants.get_rarity_color",
    "RarityConstants.get_rarities_by_level": "GameConstants.get_rarities_by_level",
    
    # RelicConstants 方法映射
    "RelicConstants.get_valid_triggers": "EffectConstants.get_trigger_type_names",
    "RelicConstants.get_valid_effect_types": "EffectConstants.get_effect_type_names",
    "RelicConstants.get_valid_condition_types": "EffectConstants.get_condition_type_names",
    
    # EffectConstants 方法映射
    "EffectConstants.get_all_effect_type_names": "EffectConstants.get_effect_type_names",
    "EffectConstants.get_all_trigger_type_names": "EffectConstants.get_trigger_type_names",
    "EffectConstants.get_all_condition_type_names": "EffectConstants.get_condition_type_names"
}

def get_all_script_files(dir_path):
    """获取所有脚本文件"""
    files = []
    
    for root, dirs, filenames in os.walk(dir_path):
        for filename in filenames:
            if filename.endswith(".gd"):
                full_path = os.path.join(root, filename)
                files.append(full_path)
    
    return files

def update_constants_in_file(file_path):
    """更新文件中的常量引用"""
    if not os.path.exists(file_path):
        return False
    
    # 跳过新的常量文件
    for const_file in NEW_CONSTANTS.keys():
        if file_path.endswith(const_file):
            return False
    
    # 跳过迁移工具本身
    if file_path.endswith("constants_migration.py") or file_path.endswith("constants_migration_tool.gd"):
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
    except Exception as e:
        print(f"无法读取文件 {file_path}: {e}")
        return False
    
    original_content = content
    
    # 更新常量引用
    for old_const, new_const in CONSTANT_MAPPING.items():
        content = content.replace(old_const, new_const)
    
    # 更新 preload 语句
    for old_file, old_class in OLD_CONSTANTS.items():
        old_preload = f'preload("res://scripts/constants/{old_file}")'
        
        for new_file, new_class in NEW_CONSTANTS.items():
            if old_class == new_class:
                new_preload = f'preload("res://scripts/constants/{new_file}")'
                content = content.replace(old_preload, new_preload)
    
    # 如果内容有变化，保存文件
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(content)
            
            print(f"更新文件: {file_path}")
            return True
        except Exception as e:
            print(f"无法写入文件 {file_path}: {e}")
            return False
    
    return False

def rename_constant_files():
    """重命名常量文件"""
    # 备份旧文件
    for old_file in OLD_CONSTANTS.keys():
        old_path = os.path.join(CONSTANTS_DIR, old_file)
        if os.path.exists(old_path):
            backup_path = os.path.join(CONSTANTS_DIR, f"{old_file}.bak")
            try:
                if not os.path.exists(backup_path):
                    os.rename(old_path, backup_path)
                    print(f"备份文件: {old_path} -> {backup_path}")
            except Exception as e:
                print(f"无法备份文件 {old_path}: {e}")
    
    # 重命名新文件
    for new_file, new_name in NEW_CONSTANTS.items():
        if new_file.endswith("_new.gd"):
            old_path = os.path.join(CONSTANTS_DIR, new_file)
            new_path = os.path.join(CONSTANTS_DIR, new_file.replace("_new.gd", ".gd"))
            
            if os.path.exists(old_path) and not os.path.exists(new_path):
                try:
                    os.rename(old_path, new_path)
                    print(f"重命名文件: {old_path} -> {new_path}")
                except Exception as e:
                    print(f"无法重命名文件 {old_path}: {e}")

def main():
    """主函数"""
    print("开始迁移常量引用...")
    
    # 获取所有脚本文件
    script_files = get_all_script_files(SCRIPTS_DIR)
    
    # 更新常量引用
    updated_count = 0
    for script_file in script_files:
        if update_constants_in_file(script_file):
            updated_count += 1
    
    print(f"迁移完成，共更新 {updated_count} 个文件")
    
    # 询问是否重命名常量文件
    answer = input("是否重命名常量文件？(y/n): ")
    if answer.lower() == 'y':
        rename_constant_files()
        print("文件重命名完成")

if __name__ == "__main__":
    main()
