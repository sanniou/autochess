#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
装备系统检查工具
用于验证装备系统的重构结果
"""

import os
import sys
import re

# 定义颜色常量
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text):
    print(f"{Colors.HEADER}{Colors.BOLD}{text}{Colors.ENDC}")

def print_success(text):
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_warning(text):
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKBLUE}ℹ {text}{Colors.ENDC}")

def check_file_exists(file_path):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print_success(f"文件存在: {file_path}")
        return True
    else:
        print_error(f"文件不存在: {file_path}")
        return False

def check_class_exists(file_path, class_name):
    """检查类是否存在于文件中"""
    if not check_file_exists(file_path):
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        if f"class_name {class_name}" in content:
            print_success(f"类 {class_name} 存在于 {file_path}")
            return True
        else:
            print_error(f"类 {class_name} 不存在于 {file_path}")
            return False

def check_method_exists(file_path, method_name):
    """检查方法是否存在于文件中"""
    if not check_file_exists(file_path):
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        pattern = rf"func\s+{method_name}\s*\("
        if re.search(pattern, content):
            print_success(f"方法 {method_name} 存在于 {file_path}")
            return True
        else:
            print_error(f"方法 {method_name} 不存在于 {file_path}")
            return False

def check_variable_exists(file_path, variable_name):
    """检查变量是否存在于文件中"""
    if not check_file_exists(file_path):
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        pattern = rf"var\s+{variable_name}\s*[=:]"
        if re.search(pattern, content):
            print_success(f"变量 {variable_name} 存在于 {file_path}")
            return True
        else:
            print_error(f"变量 {variable_name} 不存在于 {file_path}")
            return False

def check_string_not_exists(file_path, string):
    """检查字符串是否不存在于文件中"""
    if not check_file_exists(file_path):
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        if string not in content:
            print_success(f"字符串 '{string}' 不存在于 {file_path}")
            return True
        else:
            print_error(f"字符串 '{string}' 存在于 {file_path}")
            return False

def check_equipment_system():
    """检查装备系统"""
    print_header("检查装备系统")
    
    # 检查文件是否存在
    equipment_file = "scripts/game/equipment/equipment.gd"
    equipment_effect_system_file = "scripts/game/equipment/equipment_effect_system.gd"
    equipment_manager_file = "scripts/managers/game/equipment_manager.gd"
    
    # 检查Equipment类
    check_file_exists(equipment_file)
    check_class_exists(equipment_file, "Equipment")
    check_method_exists(equipment_file, "equip_to")
    check_method_exists(equipment_file, "unequip_from")
    check_method_exists(equipment_file, "trigger_effect")
    check_variable_exists(equipment_file, "effect_system")
    
    # 检查EquipmentEffectSystem类
    check_file_exists(equipment_effect_system_file)
    check_class_exists(equipment_effect_system_file, "EquipmentEffectSystem")
    check_method_exists(equipment_effect_system_file, "apply_effects")
    check_method_exists(equipment_effect_system_file, "remove_effects")
    check_method_exists(equipment_effect_system_file, "trigger_effect")
    
    # 检查EquipmentManager类
    check_file_exists(equipment_manager_file)
    check_class_exists(equipment_manager_file, "EquipmentManager")
    check_variable_exists(equipment_manager_file, "effect_system")
    check_string_not_exists(equipment_manager_file, "_shop_inventory")
    check_string_not_exists(equipment_manager_file, "refresh_shop_inventory")
    
    print_header("检查完成")

if __name__ == "__main__":
    check_equipment_system()
