# 事件系统

基于信号的强类型事件系统，提供类型安全的事件定义和处理、事件分组和命名空间、事件过滤和优先级、事件批处理、事件历史记录以及从旧事件系统迁移工具。

## 特性

- **强类型事件**：每种事件都有明确的类型定义，提供编译时类型检查
- **事件分组**：通过命名空间组织事件，使代码更清晰
- **优先级和过滤**：支持事件处理优先级和条件过滤
- **批处理机制**：优化频繁触发的事件，提高性能
- **事件历史**：记录事件历史，便于调试
- **迁移工具**：提供从旧事件系统迁移的工具和测试

## 目录结构

```
scripts/core/events/
├── event.gd                  # 事件基类
├── event_bus.gd              # 事件总线
├── event_dispatcher.gd       # 事件分发器
├── event_system.gd           # 事件系统初始化
├── global_event_bus.gd       # 全局事件总线
├── autoload_setup.gd         # 自动加载设置
├── README.md                 # 文档
├── editor/                   # 编辑器插件
│   ├── event_system_plugin.gd # 编辑器插件
│   └── plugin.cfg            # 插件配置
├── examples/                 # 示例
│   └── event_system_example.gd # 使用示例
├── tests/                    # 测试
│   ├── event_migration_test.gd # 迁移测试
│   ├── event_migration_report.md # 迁移报告
│   └── event_migration_script.gd # 迁移脚本
├── types/                    # 事件类型
│   ├── battle_events.gd      # 战斗事件
│   ├── debug_events.gd       # 调试事件
│   ├── event_system_events.gd # 事件系统事件
│   ├── game_events.gd        # 游戏事件
│   └── ui_events.gd          # UI事件
└── utils/                    # 工具类
    ├── batch_processor.gd    # 批处理器
    ├── event_migration.gd    # 迁移工具
    └── event_utils.gd        # 事件工具
```

## 安装

1. 将 `scripts/core/events` 目录复制到你的项目中
2. 运行 `scripts/core/events/autoload_setup.gd` 脚本设置自动加载
3. 启用编辑器插件（可选）：项目 -> 项目设置 -> 插件 -> 事件系统

## 使用方法

### 1. 定义事件

```gdscript
# 自定义事件
class MyCustomEvent extends Event:
    var data: Dictionary
    
    func _init(p_data: Dictionary):
        data = p_data
    
    func get_type() -> String:
        return "my_group.custom_event"
    
    func clone() -> Event:
        var event = MyCustomEvent.new(data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event
```

### 2. 监听事件

```gdscript
# 添加事件监听器
func _ready():
    # 监听游戏开始事件
    GlobalEventBus.game.add_listener("started", _on_game_started)
    
    # 带过滤器的监听器
    GlobalEventBus.battle.add_listener("damage_dealt", _on_critical_damage, 10, 
        func(event): return event is BattleEvents.DamageDealtEvent and event.is_critical)
    
    # 一次性监听器
    GlobalEventBus.game.add_listener("ended", _on_game_ended, 0, Callable(), false, true)

# 事件处理函数
func _on_game_started(event: GameEvents.GameStartedEvent) -> void:
    print("游戏已开始，难度级别: %d" % event.difficulty_level)

func _on_critical_damage(event: BattleEvents.DamageDealtEvent) -> void:
    print("暴击伤害: %s 对 %s 造成 %.1f 点 %s 暴击伤害" % 
        [event.source_entity, event.target_entity, event.amount, event.damage_type])

func _on_game_ended(event: GameEvents.GameEndedEvent) -> void:
    print("游戏已结束，胜利: %s，得分: %d" % [event.is_victory, event.score])
```

### 3. 触发事件

```gdscript
# 创建并分发事件
func _trigger_events():
    # 游戏开始事件
    var game_started_event = GameEvents.GameStartedEvent.new(2)
    GlobalEventBus.game.dispatch_event(game_started_event)
    
    # 伤害事件
    var damage_event = BattleEvents.DamageDealtEvent.new(
        player,      # 伤害来源
        enemy,       # 伤害目标
        25.0,        # 伤害数值
        "physical",  # 伤害类型
        true         # 是否暴击
    )
    GlobalEventBus.battle.dispatch_event(damage_event)
    
    # 自定义事件
    var custom_event = MyCustomEvent.new({"value": 42})
    GlobalEventBus.get_group("my_group").dispatch_event(custom_event)
```

### 4. 取消事件

```gdscript
# 取消事件处理
func _on_damage_before(event: BattleEvents.DamageDealtEvent) -> void:
    # 检查是否应该取消伤害
    if event.target_entity.has_shield:
        print("伤害被护盾抵消")
        event.cancel()  # 取消事件，阻止后续处理
```

### 5. 使用事件工具

```gdscript
# 使用事件工具
func _use_event_utils():
    # 创建过滤器
    var critical_filter = EventUtils.property_filter("is_critical", true)
    var high_damage_filter = func(event): return event.amount > 50.0
    
    # 组合过滤器
    var combined_filter = EventUtils.and_filter([critical_filter, high_damage_filter])
    
    # 添加带组合过滤器的监听器
    GlobalEventBus.battle.add_listener("damage_dealt", _on_high_critical_damage, 20, combined_filter)
    
    # 延迟触发事件
    var event = GameEvents.GameEndedEvent.new(true, 120.0, 1000)
    EventUtils.dispatch_delayed(event, 5.0)  # 5秒后触发
```

## 迁移指南

### 从旧事件系统迁移

1. 运行迁移测试：使用编辑器插件中的"运行迁移测试"功能
2. 生成迁移报告：使用"生成迁移报告"功能查看需要迁移的代码
3. 生成迁移脚本：使用"生成迁移脚本"功能创建自动迁移脚本
4. 手动调整：根据需要手动调整迁移后的代码

### 旧API到新API的映射

| 旧API | 新API |
|-------|-------|
| `EventBus.game.emit_event("game_started", [1])` | `GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new(1))` |
| `EventBus.battle.emit_event("damage_dealt", [source, target, amount, type])` | `GlobalEventBus.battle.dispatch_event(BattleEvents.DamageDealtEvent.new(source, target, amount, type))` |
| `EventBus.game.connect_event("game_started", _on_game_started)` | `GlobalEventBus.game.add_listener("started", _on_game_started)` |
| `EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)` | `GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)` |

## 高级用法

### 批处理

对于频繁触发的事件（如伤害事件、UI更新等），可以使用批处理机制减少性能开销：

```gdscript
# 在事件系统初始化时添加批处理事件类型
func _initialize_batch_processor() -> void:
    var batch_processor = BatchProcessor.new(self)
    
    # 添加需要批处理的事件类型
    batch_processor.add_batch_event_type("ui.update")
    batch_processor.add_batch_event_type("battle.damage_dealt")
    
    # 设置批处理间隔
    batch_processor.batch_interval = 0.1  # 100ms
    
    return batch_processor

# 监听批处理事件
func _ready():
    GlobalEventBus.add_listener("batch.battle.damage_dealt", _on_batch_damage)

# 处理批处理事件
func _on_batch_damage(event: BatchProcessor.BatchEvent) -> void:
    print("批处理伤害事件: 在过去 %.1f 秒内发生了 %d 次伤害" % 
        [event.batch_interval, event.count])
```

### 事件历史

事件历史记录可用于调试和回放：

```gdscript
# 获取事件历史
func _debug_event_history():
    var history = GlobalEventBus.get_event_history()
    
    print("事件历史记录:")
    for entry in history:
        var timestamp = Time.get_datetime_string_from_system_time(entry.timestamp, true)
        print("[%s] %s" % [timestamp, entry.event])
```

## 贡献

欢迎提交问题和改进建议！

## 许可

MIT 许可证
