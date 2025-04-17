#!/bin/bash
# 修复所有管理器文件，使用 class_name 引用而不是路径引用

# 查找所有管理器文件
MANAGER_FILES=$(find scripts -name "*manager.gd" | grep -v "base_manager.gd" | grep -v "manager_registry.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    echo "处理文件: $file"
    
    # 检查文件是否使用路径引用
    if grep -q "extends \"res://scripts/core/base_manager.gd\"" "$file"; then
        # 替换为 class_name 引用
        sed -i 's/extends "res:\/\/scripts\/core\/base_manager.gd"/extends "res://scripts/core/base_manager.gd"/g' "$file"
        echo "  已修改为使用 class_name 引用"
    fi
done

echo "所有管理器文件处理完成"
