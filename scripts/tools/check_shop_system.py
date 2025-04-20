#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
商店系统检查工具
用于验证商店系统的重构结果
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

def check_shop_system():
    """检查商店系统"""
    print_header("检查商店系统")
    
    # 检查文件是否存在
    shop_system_file = "scripts/game/shop/shop_system.gd"
    shop_manager_file = "scripts/managers/game/shop_manager.gd"
    shop_item_file = "scripts/game/shop/shop_item.gd"
    base_shop_file = "scripts/game/shop/base_shop.gd"
    
    # 检查ShopSystem类
    check_file_exists(shop_system_file)
    check_class_exists(shop_system_file, "ShopSystem")
    check_method_exists(shop_system_file, "refresh_shop")
    check_method_exists(shop_system_file, "manual_refresh_shop")
    check_method_exists(shop_system_file, "purchase_item")
    check_method_exists(shop_system_file, "sell_item")
    check_method_exists(shop_system_file, "apply_discount")
    check_method_exists(shop_system_file, "trigger_black_market")
    check_method_exists(shop_system_file, "trigger_mystery_shop")
    
    # 检查ShopManager类
    check_file_exists(shop_manager_file)
    check_class_exists(shop_manager_file, "ShopManager")
    check_variable_exists(shop_manager_file, "shop_system")
    check_method_exists(shop_manager_file, "refresh_shop")
    check_method_exists(shop_manager_file, "purchase_chess")
    check_method_exists(shop_manager_file, "purchase_equipment")
    check_method_exists(shop_manager_file, "purchase_relic")
    check_method_exists(shop_manager_file, "sell_chess")
    check_method_exists(shop_manager_file, "sell_equipment")
    check_method_exists(shop_manager_file, "sell_relic")
    
    # 检查ShopItem类
    check_file_exists(shop_item_file)
    check_class_exists(shop_item_file, "ShopItem")
    check_method_exists(shop_item_file, "get_data")
    check_method_exists(shop_item_file, "get_cost")
    check_method_exists(shop_item_file, "set_cost")
    
    # 检查BaseShop类
    check_file_exists(base_shop_file)
    check_class_exists(base_shop_file, "BaseShop")
    check_method_exists(base_shop_file, "refresh")
    check_method_exists(base_shop_file, "purchase_item")
    check_method_exists(base_shop_file, "sell_item")
    check_method_exists(base_shop_file, "apply_discount")
    
    # 检查ShopManager中不应该存在的旧方法
    check_string_not_exists(shop_manager_file, "func _generate_chess_items")
    check_string_not_exists(shop_manager_file, "func _generate_equipment_items")
    check_string_not_exists(shop_manager_file, "func _generate_relic_items")
    check_string_not_exists(shop_manager_file, "func _calculate_relic_cost")
    
    print_header("检查完成")

if __name__ == "__main__":
    check_shop_system()
