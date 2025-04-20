#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
管理器标准化检查工具
检查所有管理器是否符合标准化要求
"""

import os
import re
import sys
from pathlib import Path

# 定义颜色
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# 定义管理器标准
MANAGER_STANDARDS = {
    "extends_base_manager": r'extends\s+"res://scripts/managers/core/base_manager.gd"',
    "class_name": r'class_name\s+(\w+)',
    "do_initialize": r'func\s+_do_initialize\(\)\s*->\s*void',
    "do_reset": r'func\s+_do_reset\(\)\s*->\s*void',
    "do_cleanup": r'func\s+_do_cleanup\(\)\s*->\s*void',
    "ready_method": r'func\s+_ready\(\)\s*->\s*void',
    "manager_name": r'manager_name\s*=\s*"(\w+)"',
    "add_dependency": r'add_dependency\("(\w+)"\)',
    "log_info": r'_log_info\("(.+)"\)',
}

def find_managers(root_dir):
    """查找所有管理器文件"""
    managers = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith("_manager.gd") and not file.startswith("base_manager"):
                managers.append(os.path.join(root, file))
    return managers

def check_manager(manager_path):
    """检查管理器是否符合标准"""
    with open(manager_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    results = {
        "path": manager_path,
        "name": os.path.basename(manager_path),
        "issues": [],
        "standards": {}
    }
    
    # 检查是否继承BaseManager
    if not re.search(MANAGER_STANDARDS["extends_base_manager"], content):
        results["issues"].append("未继承BaseManager")
    
    # 检查是否有class_name
    class_match = re.search(MANAGER_STANDARDS["class_name"], content)
    if class_match:
        results["standards"]["class_name"] = class_match.group(1)
    else:
        results["issues"].append("未定义class_name")
    
    # 检查是否实现_do_initialize方法
    if not re.search(MANAGER_STANDARDS["do_initialize"], content):
        results["issues"].append("未实现_do_initialize方法")
    
    # 检查是否实现_do_reset方法
    if not re.search(MANAGER_STANDARDS["do_reset"], content):
        results["issues"].append("未实现_do_reset方法")
    
    # 检查是否实现_do_cleanup方法
    if not re.search(MANAGER_STANDARDS["do_cleanup"], content):
        results["issues"].append("未实现_do_cleanup方法")
    
    # 检查是否有_ready方法
    if re.search(MANAGER_STANDARDS["ready_method"], content):
        results["issues"].append("存在_ready方法，应该移除并使用_do_initialize")
    
    # 检查是否设置manager_name
    manager_name_match = re.search(MANAGER_STANDARDS["manager_name"], content)
    if manager_name_match:
        results["standards"]["manager_name"] = manager_name_match.group(1)
    else:
        results["issues"].append("未设置manager_name")
    
    # 检查是否添加依赖
    dependency_matches = re.findall(MANAGER_STANDARDS["add_dependency"], content)
    if dependency_matches:
        results["standards"]["dependencies"] = dependency_matches
    
    # 检查是否有日志输出
    log_matches = re.findall(MANAGER_STANDARDS["log_info"], content)
    if log_matches:
        results["standards"]["logs"] = log_matches
    
    return results

def print_results(results):
    """打印检查结果"""
    print(f"\n{Colors.HEADER}管理器标准化检查结果{Colors.ENDC}")
    print(f"{Colors.BOLD}检查了 {len(results)} 个管理器{Colors.ENDC}")
    
    # 统计问题
    issues_count = sum(len(r["issues"]) for r in results)
    if issues_count == 0:
        print(f"{Colors.OKGREEN}所有管理器都符合标准！{Colors.ENDC}")
        return
    
    print(f"{Colors.WARNING}发现 {issues_count} 个问题{Colors.ENDC}")
    
    # 打印每个管理器的问题
    for result in results:
        if not result["issues"]:
            continue
        
        print(f"\n{Colors.BOLD}{result['name']}{Colors.ENDC}")
        print(f"  路径: {result['path']}")
        print(f"  问题: {Colors.FAIL}{len(result['issues'])}{Colors.ENDC}")
        
        for issue in result["issues"]:
            print(f"    - {Colors.FAIL}{issue}{Colors.ENDC}")
        
        # 打印标准信息
        if "class_name" in result["standards"]:
            print(f"  类名: {result['standards']['class_name']}")
        
        if "manager_name" in result["standards"]:
            print(f"  管理器名称: {result['standards']['manager_name']}")
        
        if "dependencies" in result["standards"]:
            print(f"  依赖: {', '.join(result['standards']['dependencies'])}")

def main():
    """主函数"""
    # 获取项目根目录
    if len(sys.argv) > 1:
        root_dir = sys.argv[1]
    else:
        root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    print(f"检查目录: {root_dir}")
    
    # 查找所有管理器
    managers = find_managers(os.path.join(root_dir, "scripts", "managers"))
    print(f"找到 {len(managers)} 个管理器")
    
    # 检查每个管理器
    results = []
    for manager in managers:
        results.append(check_manager(manager))
    
    # 打印结果
    print_results(results)

if __name__ == "__main__":
    main()
