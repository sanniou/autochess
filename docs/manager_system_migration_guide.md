# 管理器系统迁移指南

本文档提供了从旧版管理器系统迁移到新版管理器系统的指南。

## 概述

我们已经重构了管理器系统，提供了更简洁、更统一的管理器注册和访问机制。新的管理器系统具有以下特点：

- 更简洁的管理器注册流程
- 统一的管理器访问接口
- 更强大的依赖管理
- 更清晰的生命周期管理
- 更健壮的错误处理

## 主要变化

1. 使用 `ManagerSystem` 替代 `ManagerRegistry`
2. 使用 `BaseManagerNew` 替代 `BaseManager`
3. 使用 `ManagerAccessor` 提供统一的管理器访问接口
4. 简化了依赖管理，不再需要在注册时指定依赖
5. 更清晰的错误处理和日志记录

## 迁移步骤

### 1. 更新管理器基类

将管理器从继承 `BaseManager` 改为继承 `BaseManagerNew`：

```gdscript
# 旧代码
extends "res://scripts/managers/core/base_manager.gd"
class_name MyManager

# 新代码
extends "res://scripts/managers/core/base_manager_new.gd"
class_name MyManager
```

### 2. 更新初始化方法

在 `_do_initialize` 方法中设置管理器名称和依赖：

```gdscript
# 旧代码
func _do_initialize() -> void:
    # 初始化逻辑
    pass

# 新代码
func _do_initialize() -> void:
    # 设置管理器名称
    manager_name = "MyManager"
    
    # 添加依赖
    add_dependency("ConfigManager")
    add_dependency("PlayerManager")
    
    # 初始化逻辑
    pass
```

### 3. 更新管理器获取方式

使用新的管理器访问方式：

```gdscript
# 旧代码
var config_manager = get_node("/root/GameManager").get_manager("ConfigManager")
# 或
var config_manager = get_node("/root/ConfigManager")

# 新代码
var config_manager = get_manager("ConfigManager")
```

### 4. 更新错误处理

使用新的错误处理方式：

```gdscript
# 旧代码
EventBus.debug.emit_event("debug_message", ["错误信息", 2])

# 新代码
_log_error("错误信息")
```

### 5. 更新事件处理

保持事件处理方式不变，但确保在清理方法中断开连接：

```gdscript
# 初始化中连接事件
func _do_initialize() -> void:
    # ...
    EventBus.game.connect_event("game_started", _on_game_started)
    # ...

# 清理中断开事件
func _do_cleanup() -> void:
    # ...
    if Engine.has_singleton("EventBus"):
        var EventBus = Engine.get_singleton("EventBus")
        if EventBus:
            EventBus.game.disconnect_event("game_started", _on_game_started)
    # ...
```

## 示例

### 旧版管理器

```gdscript
extends "res://scripts/managers/core/base_manager.gd"
class_name OldManager

func _do_initialize() -> void:
    # 初始化逻辑
    var config_manager = get_node("/root/ConfigManager")
    if not config_manager:
        EventBus.debug.emit_event("debug_message", ["无法获取配置管理器", 2])
        return
        
    # 连接事件
    EventBus.game.connect_event("game_started", _on_game_started)
    
    # 其他初始化逻辑
    
func _on_game_started() -> void:
    # 处理游戏开始事件
    pass
```

### 新版管理器

```gdscript
extends "res://scripts/managers/core/base_manager_new.gd"
class_name NewManager

func _do_initialize() -> void:
    # 设置管理器名称
    manager_name = "NewManager"
    
    # 添加依赖
    add_dependency("ConfigManager")
    
    # 连接事件
    EventBus.game.connect_event("game_started", _on_game_started)
    
    # 获取配置管理器
    var config_manager = get_manager("ConfigManager")
    if not config_manager:
        _log_error("无法获取配置管理器")
        return
        
    # 其他初始化逻辑
    
func _do_cleanup() -> void:
    # 断开事件连接
    if Engine.has_singleton("EventBus"):
        var EventBus = Engine.get_singleton("EventBus")
        if EventBus:
            EventBus.game.disconnect_event("game_started", _on_game_started)
    
func _on_game_started() -> void:
    # 处理游戏开始事件
    pass
```

## 注意事项

1. 确保在 `_do_initialize` 方法中设置管理器名称
2. 使用 `add_dependency` 方法添加依赖，而不是在注册时指定
3. 使用 `get_manager` 方法获取其他管理器，而不是直接使用节点路径
4. 使用 `_log_error`、`_log_warning` 和 `_log_info` 方法记录日志
5. 在 `_do_cleanup` 方法中断开事件连接

## 迁移检查清单

- [ ] 更新管理器基类
- [ ] 在 `_do_initialize` 方法中设置管理器名称
- [ ] 使用 `add_dependency` 方法添加依赖
- [ ] 更新管理器获取方式
- [ ] 更新错误处理
- [ ] 确保在 `_do_cleanup` 方法中断开事件连接
- [ ] 测试管理器初始化、重置和清理功能
