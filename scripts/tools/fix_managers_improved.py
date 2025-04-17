#!/usr/bin/env python3
# 更可靠的脚本来修改管理器文件

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

def has_ready_method(content):
    """检查文件是否有 _ready 方法"""
    return re.search(r'func\s+_ready\s*\(', content) is not None

def extract_ready_method(content):
    """提取 _ready 方法的内容"""
    match = re.search(r'func\s+_ready\s*\([^)]*\)((?:\s*->\s*\w+)?):\s*(.*?)(?=\n\s*func|\n\s*static\s+func|\n\s*class|\Z)', content, re.DOTALL)
    if match:
        return match.group(2).strip()
    return ""

def create_do_initialize_method(class_name, ready_content):
    """创建 _do_initialize 方法"""
    return f"""# 重写初始化方法
func _do_initialize() -> void:
\t# 设置管理器名称
\tmanager_name = "{class_name}"
\t
\t# 原 _ready 函数的内容
{ready_content}"""

def replace_ready_with_do_initialize(file_path):
    """将 _ready 方法替换为 _do_initialize 方法"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 如果文件已经有 _do_initialize 方法，跳过
    if re.search(r'func\s+_do_initialize\s*\(', content) is not None:
        print(f"  已有 _do_initialize 方法，跳过")
        return
    
    # 如果文件没有 _ready 方法，添加 _do_initialize 方法
    if not has_ready_method(content):
        class_name = get_class_name(file_path)
        do_initialize = f"""
# 重写初始化方法
func _do_initialize() -> void:
\t# 设置管理器名称
\tmanager_name = "{class_name}"
"""
        # 在类定义后添加 _do_initialize 方法
        content = re.sub(r'(class_name\s+\w+.*?\n)', r'\1' + do_initialize, content, flags=re.DOTALL)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  添加了 _do_initialize 方法")
        return
    
    # 提取 _ready 方法的内容
    ready_content = extract_ready_method(content)
    if not ready_content:
        print(f"  无法提取 _ready 方法的内容，跳过")
        return
    
    # 缩进 ready_content
    ready_content = "\t" + ready_content.replace("\n", "\n\t")
    
    # 获取类名
    class_name = get_class_name(file_path)
    
    # 创建 _do_initialize 方法
    do_initialize = create_do_initialize_method(class_name, ready_content)
    
    # 替换 _ready 方法为 _do_initialize 方法
    new_content = re.sub(
        r'func\s+_ready\s*\([^)]*\)((?:\s*->\s*\w+)?):\s*(.*?)(?=\n\s*func|\n\s*static\s+func|\n\s*class|\Z)',
        do_initialize,
        content,
        flags=re.DOTALL
    )
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  已替换 _ready 方法为 _do_initialize 方法")

def main():
    """主函数"""
    manager_files = find_manager_files()
    print(f"找到 {len(manager_files)} 个管理器文件")
    
    for file_path in manager_files:
        print(f"处理文件: {file_path}")
        replace_ready_with_do_initialize(file_path)
    
    print("所有管理器文件处理完成")

if __name__ == "__main__":
    main()
