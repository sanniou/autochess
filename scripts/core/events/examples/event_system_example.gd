extends Node
## 事件系统示例
## 演示如何使用新的事件系统

## 初始化
func _ready() -> void:
    print("事件系统示例初始化...")
    
    # 注册事件监听器
    _register_event_listeners()
    
    # 触发一些示例事件
    _trigger_example_events()

## 注册事件监听器
func _register_event_listeners() -> void:
    # 游戏事件监听
    GlobalEventBus.game.add_listener("started", _on_game_started)
    GlobalEventBus.game.add_listener("ended", _on_game_ended)
    GlobalEventBus.game.add_listener("player_health_changed", _on_player_health_changed)
    
    # 战斗事件监听
    GlobalEventBus.battle.add_listener("damage_dealt", _on_damage_dealt)
    GlobalEventBus.battle.add_listener("heal_received", _on_heal_received)
    GlobalEventBus.battle.add_listener("unit_died", _on_unit_died)
    
    # UI事件监听
    GlobalEventBus.ui.add_listener("button_clicked", _on_button_clicked)
    GlobalEventBus.ui.add_listener("toast_shown", _on_toast_shown)
    
    # 调试事件监听
    GlobalEventBus.debug.add_listener("message", _on_debug_message)
    
    # 使用过滤器
    GlobalEventBus.battle.add_listener("damage_dealt", _on_critical_damage, 10, 
        func(event): return event is BattleEvents.DamageDealtEvent and event.is_critical)
    
    # 使用一次性监听器
    GlobalEventBus.game.add_listener("started", func(event): print("游戏已启动（一次性监听器）"), 0, Callable(), false, true)
    
    print("事件监听器注册完成")

## 触发示例事件
func _trigger_example_events() -> void:
    print("触发示例事件...")
    
    # 创建并分发游戏开始事件
    var game_started_event = GameEvents.GameStartedEvent.new(1)
    GlobalEventBus.game.dispatch_event(game_started_event)
    
    # 创建并分发玩家生命值变更事件
    var health_changed_event = GameEvents.PlayerHealthChangedEvent.new(100.0, 90.0, 100.0)
    GlobalEventBus.game.dispatch_event(health_changed_event)
    
    # 创建并分发伤害事件
    var damage_event = BattleEvents.DamageDealtEvent.new(self, self, 25.0, "physical", true)
    GlobalEventBus.battle.dispatch_event(damage_event)
    
    # 创建并分发治疗事件
    var heal_event = BattleEvents.HealReceivedEvent.new(self, self, 10.0)
    GlobalEventBus.battle.dispatch_event(heal_event)
    
    # 创建并分发UI事件
    var toast_event = UIEvents.ToastShownEvent.new("提示", "这是一个测试提示", "info", 3.0)
    GlobalEventBus.ui.dispatch_event(toast_event)
    
    # 创建并分发调试事件
    var debug_event = DebugEvents.DebugMessageEvent.new("这是一个测试调试消息", 0, "示例")
    GlobalEventBus.debug.dispatch_event(debug_event)
    
    # 创建并分发游戏结束事件
    var game_ended_event = GameEvents.GameEndedEvent.new(true, 120.0, 1000)
    GlobalEventBus.game.dispatch_event(game_ended_event)
    
    print("示例事件触发完成")

## 游戏开始事件处理
func _on_game_started(event: GameEvents.GameStartedEvent) -> void:
    print("游戏已开始，难度级别: %d" % event.difficulty_level)

## 游戏结束事件处理
func _on_game_ended(event: GameEvents.GameEndedEvent) -> void:
    print("游戏已结束，胜利: %s，游戏时长: %.1f秒，得分: %d" % [event.is_victory, event.play_time, event.score])

## 玩家生命值变更事件处理
func _on_player_health_changed(event: GameEvents.PlayerHealthChangedEvent) -> void:
    print("玩家生命值变更: %.1f -> %.1f (最大: %.1f)" % [event.old_health, event.new_health, event.max_health])

## 伤害事件处理
func _on_damage_dealt(event: BattleEvents.DamageDealtEvent) -> void:
    print("伤害事件: %s 对 %s 造成 %.1f 点 %s 伤害" % [event.source_entity, event.target_entity, event.amount, event.damage_type])

## 暴击伤害事件处理
func _on_critical_damage(event: BattleEvents.DamageDealtEvent) -> void:
    print("暴击伤害事件: %s 对 %s 造成 %.1f 点 %s 暴击伤害" % [event.source_entity, event.target_entity, event.amount, event.damage_type])

## 治疗事件处理
func _on_heal_received(event: BattleEvents.HealReceivedEvent) -> void:
    print("治疗事件: %s 为 %s 恢复 %.1f 点生命值" % [event.source_entity, event.target_entity, event.amount])

## 单位死亡事件处理
func _on_unit_died(event: BattleEvents.UnitDiedEvent) -> void:
    print("单位死亡事件: %s 已死亡，击杀者: %s" % [event.unit, event.killer])

## 按钮点击事件处理
func _on_button_clicked(event: UIEvents.ButtonClickedEvent) -> void:
    print("按钮点击事件: %s (%s)" % [event.button_id, event.button_text])

## 提示显示事件处理
func _on_toast_shown(event: UIEvents.ToastShownEvent) -> void:
    print("提示显示事件: %s - %s (类型: %s, 持续时间: %.1f秒)" % [event.title, event.message, event.type, event.duration])

## 调试消息事件处理
func _on_debug_message(event: DebugEvents.DebugMessageEvent) -> void:
    var level_str = ["INFO", "WARNING", "ERROR"][event.level] if event.level >= 0 and event.level < 3 else "UNKNOWN"
    print("调试消息事件: [%s] %s%s" % [level_str, "[" + event.tag + "] " if not event.tag.is_empty() else "", event.message])
