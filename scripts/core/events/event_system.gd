extends Node
## 事件系统
## 负责初始化和管理事件系统

## 是否已初始化
var _initialized: bool = false

## 初始化
func _ready() -> void:
    # 设置为自动加载单例
    name = "EventSystem"
    
    # 初始化事件系统
    initialize()

## 初始化事件系统
func initialize() -> void:
    if _initialized:
        return
    
    print("[EventSystem] 初始化事件系统...")
    
    # # 创建全局事件总线
    # var global_event_bus = load("res://scripts/core/events/global_event_bus.gd").new()
    # global_event_bus.name = "GlobalEventBus"
    # add_child(global_event_bus)
    
    # # 将全局事件总线添加到自动加载
    # Engine.register_singleton("GlobalEventBus", global_event_bus)
    
    # 预加载事件类型
    _preload_event_types()
    
    _initialized = true
    print("[EventSystem] 事件系统初始化完成")

## 预加载事件类型
func _preload_event_types() -> void:
    # 预加载所有事件类型，确保它们在内存中
    var event_types = [
        preload("res://scripts/core/events/types/game_events.gd"),
        preload("res://scripts/core/events/types/battle_events.gd"),
        preload("res://scripts/core/events/types/event_system_events.gd"),
        preload("res://scripts/core/events/types/ui_events.gd"),
        preload("res://scripts/core/events/types/debug_events.gd")
    ]
    
    # 预加载工具类
    var utils = [
        preload("res://scripts/core/events/utils/batch_processor.gd"),
        preload("res://scripts/core/events/utils/event_utils.gd"),
        preload("res://scripts/core/events/utils/event_migration.gd")
    ]
    
    print("[EventSystem] 预加载了 %d 个事件类型和 %d 个工具类" % [event_types.size(), utils.size()])
