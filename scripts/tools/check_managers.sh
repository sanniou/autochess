#!/bin/bash
# 检查哪些管理器文件还没有修改为继承 BaseManager

# 查找所有管理器文件
MANAGER_FILES=$(find scripts -name "*manager.gd" | grep -v "base_manager.gd" | grep -v "manager_registry.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    # 检查文件是否已经继承 BaseManager
    if grep -q "extends \"res://scripts/core/base_manager.gd\"" "$file"; then
        echo "✓ $file (已继承 BaseManager)"
    elif grep -q "extends Node" "$file"; then
        echo "✗ $file (需要修改)"
    else
        echo "? $file (其他继承关系)"
    fi
done
