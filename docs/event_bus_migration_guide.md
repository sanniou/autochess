# EventBus 迁移指南

本文档提供了从旧版 EventBus 迁移到新版 EventBus 的指南。

## 概述

我们已经重构了 EventBus 系统，提供了更强大、更统一的事件处理机制。新的 EventBus 系统具有以下特点：

- 集中定义的事件常量
- 更强大的事件处理机制
- 事件历史记录和统计
- 更好的类型安全性
- 更好的性能

## 主要变化

1. 事件定义现在集中在 `scripts/events/event_definitions.gd` 文件中
2. 事件总线实现移至 `scripts/events/event_bus.gd`
3. 自定义事件系统（`register_event`, `connect_event`, `disconnect_event`, `emit_event`）已被替换为更强大的事件处理机制

## 迁移步骤

### 1. 使用事件常量

旧代码：
```gdscript
EventBus.game.game_started.connect(_on_game_started)
```

新代码（保持不变）：
```gdscript
EventBus.game.game_started.connect(_on_game_started)
```

### 2. 使用调试消息

旧代码：
```gdscript
EventBus.debug_message.emit("消息", 1)
```

新代码：
```gdscript
EventBus.debug.debug_message.emit("消息", 1)
```

### 3. 使用自定义事件系统

旧代码：
```gdscript
EventBus.register_event("custom_event")
EventBus.connect_event("custom_event", self, "_on_custom_event")
EventBus.emit_event("custom_event", [arg1, arg2])
EventBus.disconnect_event("custom_event", self, "_on_custom_event")
```

新代码：
```gdscript
EventBus.register_handler("custom_event", self, "_on_custom_event")
EventBus.emit_event("custom_event", [arg1, arg2])
EventBus.unregister_handler("custom_event", self, "_on_custom_event")
```

## 新功能

### 1. 事件历史记录

```gdscript
# 获取事件历史
var history = EventBus.get_event_history()

# 清除事件历史
EventBus.clear_event_history()

# 设置事件历史最大长度
EventBus.set_max_history_length(200)
```

### 2. 事件统计

```gdscript
# 获取事件统计
var stats = EventBus.get_event_stats()

# 获取特定事件的处理器数量
var handler_count = EventBus.get_handler_count("game_started")
```

### 3. 事件记录

```gdscript
# 启用事件记录
EventBus.enable_logging(true)

# 禁用事件记录
EventBus.enable_logging(false)
```

## 事件类别

新的 EventBus 系统将事件分为以下类别：

- `GameEvents` - 游戏核心事件
- `MapEvents` - 地图事件
- `BoardEvents` - 棋盘事件
- `ChessEvents` - 棋子事件
- `BattleEvents` - 战斗事件
- `EconomyEvents` - 经济事件
- `EquipmentEvents` - 装备事件
- `RelicEvents` - 遗物事件
- `EventSystemEvents` - 事件系统事件
- `StoryEvents` - 剧情事件
- `CurseEvents` - 诅咒事件
- `UIEvents` - UI事件
- `AchievementEvents` - 成就事件
- `TutorialEvents` - 教程事件
- `SaveEvents` - 存档事件
- `LocalizationEvents` - 本地化事件
- `AudioEvents` - 音频事件
- `SkinEvents` - 皮肤事件
- `StatusEffectEvents` - 状态效果事件
- `DebugEvents` - 调试事件

每个类别都有一组预定义的事件常量，可以在 `scripts/events/event_definitions.gd` 文件中找到。

## 最佳实践

1. 使用预定义的事件常量，而不是硬编码的字符串
2. 在对象销毁前注销事件处理器
3. 使用事件历史记录和统计来调试事件问题
4. 避免在事件处理器中执行耗时操作
5. 使用事件过滤器来控制事件的传播

## 常见问题

### 1. 我的事件处理器不再被调用

检查事件名称是否正确，以及事件处理器是否已正确注册。

### 2. 我需要创建自定义事件

使用 `EventBus.register_handler` 和 `EventBus.emit_event` 方法创建和使用自定义事件。

### 3. 我需要在对象销毁前注销所有事件处理器

使用 `EventBus.unregister_all_handlers(self)` 方法注销对象的所有事件处理器。

## 结论

新的 EventBus 系统提供了更强大、更统一的事件处理机制，使代码更加清晰和可维护。通过遵循本指南，您可以轻松地将代码从旧版 EventBus 迁移到新版 EventBus。
