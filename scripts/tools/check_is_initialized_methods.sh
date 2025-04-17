#!/bin/bash
# 检查所有管理器文件中是否有 is_initialized 方法的定义

# 查找所有管理器文件
MANAGER_FILES=$(find scripts -name "*manager.gd" | grep -v "base_manager.gd" | grep -v "manager_registry.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    # 检查文件是否定义了 is_initialized 方法
    if grep -q "func is_initialized" "$file"; then
        echo "✗ $file (定义了 is_initialized 方法)"
    else
        echo "✓ $file (没有定义 is_initialized 方法)"
    fi
done
