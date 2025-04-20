# 管理器标准化规范

## 1. 概述

本文档定义了项目中管理器的标准化规范，所有管理器都应遵循这些规范，以确保代码的一致性和可维护性。

## 2. 管理器基本结构

所有管理器都应该继承自`BaseManager`类，并遵循以下基本结构：

```gdscript
extends "res://scripts/managers/core/base_manager.gd"
class_name YourManagerName
## 管理器描述
## 详细说明管理器的功能和职责

# 信号
signal example_signal(param)

# 管理器数据
var example_data: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
    # 设置管理器名称
    manager_name = "YourManagerName"
    
    # 添加依赖
    add_dependency("ConfigManager")
    
    # 连接事件
    EventBus.game.connect_event("game_started", _on_game_started)
    
    # 初始化数据
    _initialize_data()
    
    _log_info("管理器初始化完成")

# 初始化数据
func _initialize_data() -> void:
    # 初始化数据
    example_data = {
        "initialized": true,
        "timestamp": Time.get_unix_time_from_system()
    }

# 重写重置方法
func _do_reset() -> void:
    # 清空数据
    example_data.clear()
    
    # 重新初始化数据
    _initialize_data()
    
    _log_info("管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
    # 断开事件连接
    EventBus.game.disconnect_event("game_started", _on_game_started)
    
    # 清空数据
    example_data.clear()
    
    _log_info("管理器清理完成")

# 事件处理方法
func _on_game_started() -> void:
    _log_info("游戏开始事件处理")
```

## 3. 管理器命名规范

- 管理器类名应使用PascalCase命名法，并以`Manager`结尾，例如：`ChessManager`、`EquipmentManager`
- 管理器文件名应使用snake_case命名法，并以`_manager.gd`结尾，例如：`chess_manager.gd`、`equipment_manager.gd`
- 管理器名称（`manager_name`属性）应与类名相同

## 4. 管理器生命周期方法

所有管理器都应实现以下生命周期方法：

### 4.1 初始化方法

```gdscript
func _do_initialize() -> void:
    # 设置管理器名称
    manager_name = "YourManagerName"
    
    # 添加依赖
    add_dependency("ConfigManager")
    
    # 连接事件
    EventBus.game.connect_event("game_started", _on_game_started)
    
    # 初始化数据
    _initialize_data()
    
    _log_info("管理器初始化完成")
```

### 4.2 重置方法

```gdscript
func _do_reset() -> void:
    # 清空数据
    example_data.clear()
    
    # 重新初始化数据
    _initialize_data()
    
    _log_info("管理器重置完成")
```

### 4.3 清理方法

```gdscript
func _do_cleanup() -> void:
    # 断开事件连接
    EventBus.game.disconnect_event("game_started", _on_game_started)
    
    # 清空数据
    example_data.clear()
    
    _log_info("管理器清理完成")
```

## 5. 管理器依赖管理

管理器之间的依赖关系应通过`add_dependency`方法明确声明：

```gdscript
func _do_initialize() -> void:
    # 添加依赖
    add_dependency("ConfigManager")
    add_dependency("PlayerManager")
    
    # ...
```

## 6. 管理器事件处理

管理器应使用标准的事件连接和断开方式：

```gdscript
# 连接事件
EventBus.game.connect_event("game_started", _on_game_started)

# 断开事件
EventBus.game.disconnect_event("game_started", _on_game_started)
```

## 7. 管理器日志记录

管理器应使用标准的日志记录方法：

```gdscript
# 记录错误信息
func _log_error(error_message: String) -> void:
    _error = error_message
    EventBus.debug.emit_event("debug_message", [error_message, 2])
    error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
    EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
    EventBus.debug.emit_event("debug_message", [info_message, 0])
```

## 8. 管理器检查工具

项目提供了管理器标准化检查工具，用于检查所有管理器是否符合标准化要求：

```bash
python scripts/tools/check_manager_standards.py
```

## 9. 管理器模板

项目提供了标准化的管理器模板，供开发人员参考：

- `scripts/managers/core/standard_manager_template.gd`

## 10. 注意事项

- 不要在管理器中使用`_ready()`方法，应该使用`_do_initialize()`方法
- 确保在`_do_cleanup()`方法中断开所有事件连接
- 确保在`_do_reset()`方法中重置所有数据
- 使用`_log_info()`、`_log_warning()`和`_log_error()`方法记录日志，而不是直接使用`print()`
