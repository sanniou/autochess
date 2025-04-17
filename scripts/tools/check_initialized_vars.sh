#!/bin/bash
# 检查所有管理器文件中是否有 _initialized 变量的定义

# 查找所有管理器文件
MANAGER_FILES=$(find scripts -name "*manager.gd" | grep -v "base_manager.gd" | grep -v "manager_registry.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    # 检查文件是否定义了 _initialized 变量
    if grep -q "var _initialized" "$file"; then
        echo "✗ $file (定义了 _initialized 变量)"
    else
        echo "✓ $file (没有定义 _initialized 变量)"
    fi
done
