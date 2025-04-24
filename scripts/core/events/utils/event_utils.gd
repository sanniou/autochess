extends RefCounted
class_name EventUtils
## 事件工具类
## 提供事件相关的实用函数

## 创建事件过滤器
## @param property 属性名
## @param value 属性值
## @return 过滤函数
static func property_filter(property: String, value) -> Callable:
    return func(event:BusEvent) -> bool:
        return event.get(property) == value

## 创建组合过滤器（AND）
## @param filters 过滤器数组
## @return 组合过滤器
static func and_filter(filters: Array) -> Callable:
    return func(event:BusEvent) -> bool:
        for filter in filters:
            if not filter.call(event):
                return false
        return true

## 创建组合过滤器（OR）
## @param filters 过滤器数组
## @return 组合过滤器
static func or_filter(filters: Array) -> Callable:
    return func(event:BusEvent) -> bool:
        for filter in filters:
            if filter.call(event):
                return true
        return false

## 创建否定过滤器
## @param filter 过滤器
## @return 否定过滤器
static func not_filter(filter: Callable) -> Callable:
    return func(event:BusEvent) -> bool:
        return not filter.call(event)

## 创建类型过滤器
## @param type_name 事件类型名称
## @return 类型过滤器
static func type_filter(type_name: String) -> Callable:
    return func(event:BusEvent) -> bool:
        return event.get_type() == type_name

## 创建源对象过滤器
## @param source 源对象
## @return 源对象过滤器
static func source_filter(source: Object) -> Callable:
    return func(event:BusEvent) -> bool:
        return event.source == source

## 创建一次性监听器
## @param event_type 事件类型
## @param callback 回调函数
## @param priority 优先级
## @param filter_func 过滤函数
## @param process_canceled 是否处理已取消的事件
static func listen_once(event_type: String, callback: Callable, priority: int = 0, 
                       filter_func: Callable = Callable(), process_canceled: bool = false) -> void:
    GlobalEventBus.add_listener(event_type, callback, priority, filter_func, process_canceled, true)

## 创建延迟事件
## @param event 事件
## @param delay_seconds 延迟秒数
static func dispatch_delayed(event: Event, delay_seconds: float) -> void:
    var timer = Timer.new()
    GlobalEventBus.event_bus.add_child(timer)
    timer.one_shot = true
    timer.wait_time = delay_seconds
    timer.timeout.connect(func():
        GlobalEventBus.dispatch_event(event)
        timer.queue_free()
    )
    timer.start()

## 创建条件事件
## @param event 事件
## @param condition 条件函数
## @param check_interval 检查间隔
static func dispatch_when(event: Event, condition: Callable, check_interval: float = 0.1) -> void:
    var timer = Timer.new()
    GlobalEventBus.event_bus.add_child(timer)
    timer.wait_time = check_interval
    
    var check_condition = func():
        if condition.call():
            GlobalEventBus.dispatch_event(event)
            timer.stop()
            timer.queue_free()
    
    timer.timeout.connect(check_condition)
    timer.start()

## 创建事件序列
## @param events 事件数组
## @param interval 间隔
static func dispatch_sequence(events: Array, interval: float = 0.5) -> void:
    if events.is_empty():
        return
    
    var timer = Timer.new()
    GlobalEventBus.event_bus.add_child(timer)
    timer.wait_time = interval
    
    var index = 0
    
    var dispatch_next = func():
        if index < events.size():
            GlobalEventBus.dispatch_event(events[index])
            index += 1
        else:
            timer.stop()
            timer.queue_free()
    
    timer.timeout.connect(dispatch_next)
    
    # 立即分发第一个事件
    dispatch_next.call()
    
    timer.start()
