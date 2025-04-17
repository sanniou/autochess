#!/usr/bin/env python3
# 完善管理器文件中的错误处理和日志记录

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

def add_error_handling(file_path):
    """向文件添加错误处理和日志记录"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 获取类名
    class_name = get_class_name(file_path)
    
    # 检查文件是否已经有错误处理
    if "_error = " in content:
        print(f"  已有错误处理，跳过")
        return
    
    # 添加错误处理方法
    error_handling_methods = f"""
# 记录错误信息
func _log_error(error_message: String) -> void:
\t_error = error_message
\tEventBus.debug.debug_message.emit(error_message, 2)
\terror_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
\tEventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
\tEventBus.debug.debug_message.emit(info_message, 0)
"""
    
    # 在文件末尾添加错误处理方法
    new_content = content + error_handling_methods
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  已添加错误处理方法")

def main():
    """主函数"""
    manager_files = find_manager_files()
    print(f"找到 {len(manager_files)} 个管理器文件")
    
    for file_path in manager_files:
        print(f"处理文件: {file_path}")
        add_error_handling(file_path)
    
    print("所有管理器文件处理完成")

if __name__ == "__main__":
    main()
