#!/usr/bin/env python3
# 更新 EventBus 引用的脚本
# 此脚本会自动更新所有 .gd 文件中的 EventBus 引用

import os
import re
import glob
import shutil
from datetime import datetime

# 创建备份目录
backup_dir = f"event_bus_update_backup_{datetime.now().strftime('%Y%m%d%H%M%S')}"
os.makedirs(backup_dir, exist_ok=True)
print(f"创建备份目录: {backup_dir}")

# 查找所有 .gd 文件
gd_files = glob.glob("**/*.gd", recursive=True)
print(f"找到 {len(gd_files)} 个 .gd 文件")

# 排除 event_bus.gd 和工具脚本
gd_files = [f for f in gd_files if not (f.endswith("event_bus.gd") or f.startswith("scripts/tools/"))]
print(f"处理 {len(gd_files)} 个文件")

# 正则表达式模式
emit_pattern = re.compile(r'EventBus\.(\w+)\.(\w+)\.emit\((.*?)\)')
connect_pattern = re.compile(r'EventBus\.(\w+)\.(\w+)\.connect\((.*?)\)')
debug_message_pattern = re.compile(r'EventBus\.debug\.debug_message\.emit\((.*?)\)')

# 处理每个文件
for file_path in gd_files:
    # 读取文件内容
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 检查是否包含 EventBus 引用
    if 'EventBus' not in content:
        continue
    
    # 创建备份
    backup_path = os.path.join(backup_dir, os.path.basename(file_path))
    shutil.copy2(file_path, backup_path)
    
    # 替换 emit 调用
    content = emit_pattern.sub(r'EventBus.\1.emit_event("\2", [\3])', content)
    
    # 替换 connect 调用
    content = connect_pattern.sub(r'EventBus.\1.connect_event("\2", \3)', content)
    
    # 替换 debug_message 调用
    content = debug_message_pattern.sub(r'EventBus.debug.emit_event("debug_message", [\1])', content)
    
    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"已更新: {file_path}")

print("更新完成!")
