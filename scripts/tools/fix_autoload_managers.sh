#!/bin/bash
# 修复所有 autoload 管理器文件，使用 Node 而不是 BaseManager

# 查找所有 autoload 管理器文件
MANAGER_FILES=$(find scripts/autoload -name "*manager.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    echo "处理文件: $file"
    
    # 检查文件是否使用 BaseManager
    if grep -q "extends "res://scripts/core/base_manager.gd"" "$file"; then
        # 替换为 Node
        sed -i 's/extends "res://scripts/core/base_manager.gd"/extends Node/g' "$file"
        echo "  已修改为使用 Node"
    fi
done

echo "所有 autoload 管理器文件处理完成"
