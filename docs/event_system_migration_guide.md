# 事件系统迁移指南

本文档提供了从旧的EventBus系统迁移到新的基于信号的事件系统的详细指南。

## 迁移概述

我们将使用Python脚本自动替换代码中的EventBus调用，直接迁移到新的事件系统，而不使用兼容层。这种方法更加彻底，但需要一次性完成所有更改。

## 迁移步骤

### 1. 准备工作

1. 确保所有代码已提交到版本控制系统，以便在需要时回滚更改。
2. 确保新的事件系统已经设置为自动加载。
3. 确保Python 3已安装在系统上。

### 2. 运行迁移测试

在进行实际迁移之前，我们应该先运行迁移测试，确保迁移工具能够正确工作：

```bash
cd scripts/tools
python test_event_migration.py
```

如果测试通过，说明迁移工具能够正确替换代码中的EventBus调用。

### 3. 运行迁移工具（试运行）

首先，我们应该进行一次试运行，查看将要进行的更改：

```bash
cd scripts/tools
python event_system_migrator.py --dry-run --verbose ../../
```

这将显示将要进行的所有更改，但不会实际修改文件。

### 4. 运行迁移工具（实际迁移）

如果试运行结果符合预期，我们可以进行实际迁移：

```bash
cd scripts/tools
python event_system_migrator.py --verbose ../../
```

这将替换项目中所有的EventBus调用。

### 5. 测试迁移结果

迁移完成后，我们应该运行项目，确保所有功能正常工作。如果发现问题，可以使用版本控制系统回滚更改，然后手动修复问题。

## 迁移映射表

以下是旧事件名称到新事件类型的映射表：

| 旧事件名称 | 新事件类型 |
|-----------|-----------|
| game.game_started | GameEvents.GameStartedEvent |
| game.game_ended | GameEvents.GameEndedEvent |
| battle.damage_dealt | BattleEvents.DamageDealtEvent |
| battle.heal_received | BattleEvents.HealReceivedEvent |
| chess.chess_piece_moved | ChessEvents.ChessPieceMovedEvent |
| chess.chess_piece_target_changed | ChessEvents.ChessPieceTargetChangedEvent |
| ui.update_ui | UIEvents.UIUpdateEvent |
| ui.show_toast | UIEvents.ToastShownEvent |
| debug.debug_message | DebugEvents.DebugMessageEvent |

## 代码示例

### 旧代码

```gdscript
# 触发事件
EventBus.game.emit_event("game_started", [1])
EventBus.battle.emit_event("damage_dealt", [source, target, 25.0, "physical", true])

# 监听事件
EventBus.game.connect_event("game_started", _on_game_started)
EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)

# 取消监听事件
EventBus.game.disconnect_event("game_started", _on_game_started)
EventBus.battle.disconnect_event("damage_dealt", _on_damage_dealt)
```

### 新代码

```gdscript
# 触发事件
GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new(1))
GlobalEventBus.battle.dispatch_event(BattleEvents.DamageDealtEvent.new(source, target, 25.0, "physical", true))

# 监听事件
GlobalEventBus.game.add_listener("game_started", _on_game_started)
GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)

# 取消监听事件
GlobalEventBus.game.remove_listener("game_started", _on_game_started)
GlobalEventBus.battle.remove_listener("damage_dealt", _on_damage_dealt)
```

## 事件处理函数

在旧的事件系统中，事件处理函数接收一个参数数组：

```gdscript
func _on_damage_dealt(args: Array) -> void:
    var source = args[0]
    var target = args[1]
    var amount = args[2]
    var damage_type = args[3]
    var is_critical = args[4]
    
    print("伤害事件: " + source.name + " 对 " + target.name + " 造成 " + str(amount) + " 点 " + damage_type + " 伤害")
```

在新的事件系统中，事件处理函数接收一个事件对象：

```gdscript
func _on_damage_dealt(event: BattleEvents.DamageDealtEvent) -> void:
    print("伤害事件: " + event.source_entity.name + " 对 " + event.target_entity.name + " 造成 " + str(event.amount) + " 点 " + event.damage_type + " 伤害")
```

您需要手动更新所有事件处理函数，以适应新的事件对象格式。

## 注意事项

1. **事件处理函数**：迁移工具只会替换EventBus调用，不会修改事件处理函数的参数。您需要手动更新所有事件处理函数，以适应新的事件对象格式。

2. **自定义事件**：如果您有自定义事件，需要为它们创建相应的事件类型，并更新迁移工具的映射表。

3. **事件名称**：在新的事件系统中，事件名称不包含分组前缀。例如，旧系统中的"game.game_started"在新系统中是"game_started"。

4. **事件参数**：在新的事件系统中，事件参数是通过事件对象的属性访问的，而不是通过数组索引。

5. **事件过滤**：新的事件系统支持事件过滤和优先级，您可以利用这些功能来优化事件处理。

## 故障排除

如果在迁移过程中遇到问题，可以尝试以下方法：

1. **检查事件处理函数**：确保所有事件处理函数都已更新，以适应新的事件对象格式。

2. **检查事件名称**：确保事件名称正确，不包含分组前缀。

3. **检查事件参数**：确保事件参数正确，通过事件对象的属性访问。

4. **手动修复**：如果自动迁移失败，可以手动修复问题。

5. **回滚更改**：如果问题无法解决，可以使用版本控制系统回滚更改，然后重新尝试迁移。

## 结论

通过这个迁移过程，我们可以将旧的EventBus系统直接迁移到新的基于信号的事件系统，而不使用兼容层。这种方法更加彻底，但需要一次性完成所有更改。

如果您有任何问题或建议，请随时联系我们。
