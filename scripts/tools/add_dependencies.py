#!/usr/bin/env python3
# 分析管理器之间的依赖关系，并自动添加依赖

import os
import re
import sys

def find_manager_files():
    """查找所有管理器文件"""
    manager_files = []
    for root, dirs, files in os.walk("scripts"):
        for file in files:
            if file.endswith("manager.gd") and file != "base_manager.gd" and file != "manager_registry.gd":
                manager_files.append(os.path.join(root, file))
    return manager_files

def get_class_name(file_path):
    """获取文件中的类名"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 使用正则表达式查找类名
    match = re.search(r'class_name\s+(\w+)', content)
    if match:
        return match.group(1)
    
    # 如果没有找到类名，使用文件名作为类名
    file_name = os.path.basename(file_path)
    class_name = ''.join(word.capitalize() for word in file_name.replace('.gd', '').split('_'))
    return class_name

def find_dependencies(file_path, all_managers):
    """查找文件中的依赖关系"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    dependencies = []
    
    # 查找 get_node 调用
    get_node_pattern = r'get_node(?:_or_null)?\s*\(\s*["\']\/root\/(\w+)["\']'
    get_node_matches = re.findall(get_node_pattern, content)
    
    # 查找变量引用
    var_pattern = r'var\s+(\w+)\s*=\s*(?:get_node(?:_or_null)?\s*\(\s*["\']\/root\/(\w+)["\']|null)'
    var_matches = re.findall(var_pattern, content)
    
    # 查找 @onready 变量引用
    onready_pattern = r'@onready\s+var\s+(\w+)\s*=\s*get_node(?:_or_null)?\s*\(\s*["\']\/root\/(\w+)["\']'
    onready_matches = re.findall(onready_pattern, content)
    
    # 合并所有匹配结果
    for match in get_node_matches:
        if match.endswith("Manager") and match in all_managers:
            dependencies.append(match)
    
    for var_name, node_name in var_matches:
        if node_name and node_name.endswith("Manager") and node_name in all_managers:
            dependencies.append(node_name)
        elif var_name.endswith("_manager") or var_name.endswith("Manager"):
            # 尝试根据变量名猜测管理器名称
            possible_manager = var_name[0].upper() + var_name[1:]
            if not possible_manager.endswith("Manager"):
                possible_manager += "Manager"
            if possible_manager in all_managers:
                dependencies.append(possible_manager)
    
    for var_name, node_name in onready_matches:
        if node_name and node_name.endswith("Manager") and node_name in all_managers:
            dependencies.append(node_name)
    
    # 去重
    return list(set(dependencies))

def add_dependencies_to_file(file_path, dependencies):
    """向文件添加依赖关系"""
    if not dependencies:
        print(f"  没有找到依赖关系，跳过")
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 检查文件是否已经有 add_dependency 调用
    existing_dependencies = re.findall(r'add_dependency\s*\(\s*["\'](\w+)["\']', content)
    
    # 过滤掉已经存在的依赖
    new_dependencies = [dep for dep in dependencies if dep not in existing_dependencies]
    
    if not new_dependencies:
        print(f"  所有依赖已经存在，跳过")
        return
    
    # 查找 _do_initialize 方法
    do_initialize_match = re.search(r'func\s+_do_initialize\s*\(\s*\)\s*->\s*void\s*:(.*?)(?=\n\s*func|\n\s*static\s+func|\n\s*class|\Z)', content, re.DOTALL)
    
    if not do_initialize_match:
        print(f"  没有找到 _do_initialize 方法，跳过")
        return
    
    do_initialize_content = do_initialize_match.group(1)
    
    # 查找设置 manager_name 的行
    manager_name_match = re.search(r'(\s*manager_name\s*=\s*["\'].*?["\'])', do_initialize_content)
    
    if not manager_name_match:
        print(f"  没有找到设置 manager_name 的行，跳过")
        return
    
    # 构建依赖添加代码
    dependency_code = ""
    for dep in new_dependencies:
        dependency_code += f"\n\t# 添加依赖\n\tadd_dependency(\"{dep}\")"
    
    # 在设置 manager_name 的行后添加依赖
    new_do_initialize_content = do_initialize_content.replace(
        manager_name_match.group(1),
        manager_name_match.group(1) + dependency_code
    )
    
    # 替换 _do_initialize 方法的内容
    new_content = content.replace(do_initialize_content, new_do_initialize_content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  已添加依赖: {', '.join(new_dependencies)}")

def main():
    """主函数"""
    manager_files = find_manager_files()
    print(f"找到 {len(manager_files)} 个管理器文件")
    
    # 获取所有管理器的类名
    all_managers = {}
    for file_path in manager_files:
        class_name = get_class_name(file_path)
        all_managers[class_name] = file_path
    
    # 分析依赖关系并添加依赖
    for class_name, file_path in all_managers.items():
        print(f"处理文件: {file_path}")
        dependencies = find_dependencies(file_path, all_managers.keys())
        if dependencies:
            print(f"  找到依赖: {', '.join(dependencies)}")
            add_dependencies_to_file(file_path, dependencies)
        else:
            print(f"  没有找到依赖")
    
    print("所有管理器文件处理完成")

if __name__ == "__main__":
    main()
