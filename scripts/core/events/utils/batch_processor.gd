extends RefCounted
## 事件批处理器
## 用于批量处理频繁触发的事件，减少性能开销

## 事件总线引用
var _event_bus = null

## 批处理配置
var batch_interval: float = 0.1  # 批处理间隔
var _batch_timer: float = 0.0    # 批处理计时器

## 批处理事件映射 {事件类型 -> 批处理信息}
var _batched_events: Dictionary = {}

## 初始化
## @param event_bus 事件总线
func _init(event_bus):
    _event_bus = event_bus

## 添加事件类型到批处理
## @param event_type 事件类型
func add_batch_event_type(event_type: String) -> void:
    if not _batched_events.has(event_type):
        _batched_events[event_type] = {
            "event": null,
            "count": 0,
            "last_time": 0
        }

## 检查事件是否应该批处理
## @param event 事件
## @return 是否应该批处理
func should_batch(event:BusEvent) -> bool:
    var event_type = event.get_type()
    return _batched_events.has(event_type)

## 添加事件到批处理
## @param event 事件
## @return 是否成功添加
func add_event(event:BusEvent) -> bool:
    var event_type = event.get_type()
    
    if not _batched_events.has(event_type):
        return false
    
    # 更新批处理信息
    _batched_events[event_type].event = event
    _batched_events[event_type].count += 1
    _batched_events[event_type].last_time = Time.get_unix_time_from_system()
    
    return true

## 处理批处理
## @param delta 时间增量
func process(delta: float) -> void:
    _batch_timer += delta
    
    if _batch_timer >= batch_interval:
        _batch_timer = 0.0
        _process_batched_events()

## 处理所有批处理事件
func _process_batched_events() -> void:
    for event_type in _batched_events:
        var batch_info = _batched_events[event_type]
        
        if batch_info.event != null and batch_info.count > 0:
            # 创建批处理事件
            var batch_event = BatchEvent.new(
                event_type,
                batch_info.event,
                batch_info.count,
                batch_info.last_time
            )
            
            # 分发批处理事件
            _event_bus._dispatcher.dispatch_event(batch_event)
            
            # 重置批处理信息
            batch_info.event = null
            batch_info.count = 0

## 批处理事件类
class BatchEvent extends BusEvent:
    ## 原始事件类型
    var original_type: String
    
    ## 原始事件
    var original_event: Event
    
    ## 事件计数
    var count: int
    
    ## 最后触发时间
    var last_time: int
    
    ## 初始化
    func _init(p_original_type: String, p_original_event: Event, p_count: int, p_last_time: int):
        original_type = p_original_type
        original_event = p_original_event
        count = p_count
        last_time = p_last_time
    
    ## 获取事件类型
    func get_type() -> String:
        return "batch." + original_type
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "BatchEvent[type=%s, count=%d, original=%s]" % [get_type(), count, original_event]
    
    ## 克隆事件
    func clone() ->BusEvent:
        var cloned_original = original_event.clone() if original_event.has_method("clone") else original_event
        return BatchEvent.new(original_type, cloned_original, count, last_time)
