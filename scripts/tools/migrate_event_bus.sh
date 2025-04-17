#!/bin/bash
# 迁移 EventBus 引用的脚本
# 此脚本会自动更新所有 .gd 文件中的 EventBus 引用

# 统计要处理的文件数量
total_files=$(grep -r "EventBus" --include="*.gd" . | grep -v "scripts/events/event_bus.gd" | grep -v "scripts/tools/migrate_event_bus.sh" | cut -d: -f1 | sort | uniq | wc -l)
echo "找到 $total_files 个文件包含 EventBus 引用"

# 创建备份目录
backup_dir="event_bus_migration_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup_dir"
echo "创建备份目录: $backup_dir"

# 处理每个文件
processed=0
for file in $(grep -r "EventBus" --include="*.gd" . | grep -v "scripts/events/event_bus.gd" | grep -v "scripts/tools/migrate_event_bus.sh" | cut -d: -f1 | sort | uniq); do
    # 创建备份
    cp "$file" "$backup_dir/$(basename "$file")"
    
    # 更新文件
    # 注意：我们不需要更改 EventBus 的引用方式，因为新的 EventBus 保持了相同的接口
    # 但我们需要更新任何使用旧的自定义事件系统的代码
    
    # 替换 EventBus.register_event, EventBus.connect_event, EventBus.disconnect_event, EventBus.emit_event
    sed -i 's/EventBus\.register_event/EventBus\.register_handler/g' "$file"
    sed -i 's/EventBus\.connect_event/EventBus\.register_handler/g' "$file"
    sed -i 's/EventBus\.disconnect_event/EventBus\.unregister_handler/g' "$file"
    sed -i 's/EventBus\.emit_event/EventBus\.emit_event/g' "$file"
    
    # 替换 EventBus.debug_message 为 EventBus.debug.debug_message
    sed -i 's/EventBus\.debug_message/EventBus\.debug\.debug_message/g' "$file"
    
    # 替换 EventBus.exp_changed 为 EventBus.game.player_exp_changed
    sed -i 's/EventBus\.exp_changed/EventBus\.game\.player_exp_changed/g' "$file"
    
    # 更新进度
    processed=$((processed + 1))
    echo "处理文件 ($processed/$total_files): $file"
done

echo "迁移完成！"
echo "备份文件保存在: $backup_dir"
echo "请手动检查更新后的文件，确保所有引用都已正确更新。"
