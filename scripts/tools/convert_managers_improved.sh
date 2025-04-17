#!/bin/bash
# 将所有管理器文件修改为继承 BaseManager

# 查找所有管理器文件
MANAGER_FILES=$(find scripts -name "*manager.gd" | grep -v "base_manager.gd" | grep -v "manager_registry.gd")

# 遍历所有管理器文件
for file in $MANAGER_FILES; do
    echo "处理文件: $file"
    
    # 检查文件是否已经继承 BaseManager
    if grep -q "extends \"res://scripts/core/base_manager.gd\"" "$file"; then
        echo "  已经继承 BaseManager，跳过"
        continue
    fi
    
    # 检查文件是否继承 Node
    if grep -q "extends Node" "$file"; then
        # 替换继承关系
        sed -i 's/extends Node/extends "res:\/\/scripts\/core\/base_manager.gd"/g' "$file"
        echo "  已修改继承关系"
        
        # 获取类名
        CLASS_NAME=$(grep -o "class_name [A-Za-z0-9_]*" "$file" | cut -d ' ' -f 2)
        if [ -z "$CLASS_NAME" ]; then
            echo "  无法获取类名，跳过"
            continue
        fi
        
        # 检查是否有 _ready 函数
        if grep -q "func _ready" "$file"; then
            # 获取 _ready 函数的内容
            READY_START=$(grep -n "func _ready" "$file" | cut -d ':' -f 1)
            
            # 查找下一个函数的开始行
            NEXT_FUNC=$(grep -n "^func " "$file" | awk -v start="$READY_START" '$1 > start {print $0; exit}')
            
            if [ -n "$NEXT_FUNC" ]; then
                # 提取下一个函数的行号
                READY_END=$(echo "$NEXT_FUNC" | cut -d ':' -f 1)
                READY_END=$((READY_END - 1))
            else
                # 如果没有找到下一个函数，使用文件末尾
                READY_END=$(wc -l "$file" | cut -d ' ' -f 1)
            fi
            
            # 提取 _ready 函数的内容
            READY_CONTENT=$(sed -n "${READY_START},${READY_END}p" "$file")
            
            # 创建 _do_initialize 函数的内容
            DO_INITIALIZE="# 重写初始化方法
func _do_initialize() -> void:
\t# 设置管理器名称
\tmanager_name = \"$CLASS_NAME\"
\t
\t# 原 _ready 函数的内容（去掉第一行）
\t$(echo "$READY_CONTENT" | tail -n +2)"
            
            # 替换 _ready 函数为 _do_initialize 函数
            sed -i "${READY_START},${READY_END}c\\${DO_INITIALIZE}" "$file"
            echo "  已替换 _ready 函数为 _do_initialize 函数"
        else
            # 如果没有 _ready 函数，添加 _do_initialize 函数
            DO_INITIALIZE="
# 重写初始化方法
func _do_initialize() -> void:
\t# 设置管理器名称
\tmanager_name = \"$CLASS_NAME\"
"
            
            # 在类定义后添加 _do_initialize 函数
            CLASS_LINE=$(grep -n "class_name" "$file" | cut -d ':' -f 1)
            if [ -n "$CLASS_LINE" ]; then
                sed -i "${CLASS_LINE}a\\${DO_INITIALIZE}" "$file"
                echo "  已添加 _do_initialize 函数"
            else
                echo "  无法找到类定义，跳过"
            fi
        fi
        
        # 检查是否有 is_initialized 函数
        if grep -q "func is_initialized" "$file"; then
            echo "  已有 is_initialized 函数，不需要修改"
        else
            # 如果没有 is_initialized 函数，但有 _initialized 变量
            if grep -q "_initialized" "$file"; then
                # 删除 _initialized 变量的定义
                INIT_VAR_LINE=$(grep -n "_initialized" "$file" | head -n 1 | cut -d ':' -f 1)
                if [ -n "$INIT_VAR_LINE" ]; then
                    sed -i "${INIT_VAR_LINE}d" "$file"
                    echo "  已删除 _initialized 变量的定义"
                fi
            fi
        fi
    else
        echo "  不是继承 Node 的文件，跳过"
    fi
done

echo "所有管理器文件处理完成"
