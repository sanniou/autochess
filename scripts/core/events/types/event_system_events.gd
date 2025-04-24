extends RefCounted
class_name EventSystemEvents
## 事件系统事件类型
## 定义与事件系统本身相关的事件

## 事件触发事件
class EventTriggeredEvent extends Event:
    ## 事件对象
    var event_object
    
    ## 事件类型
    var event_type: String
    
    ## 初始化
    func _init(p_event_object, p_event_type: String):
        event_object = p_event_object
        event_type = p_event_type
    
    ## 获取事件类型
    func get_type() -> String:
        return "event.triggered"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "EventTriggeredEvent[event_object=%s, event_type=%s]" % [event_object, event_type]
    
    ## 克隆事件
    func clone() -> Event:
        var event = EventTriggeredEvent.new(event_object, event_type)
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 事件选择事件
class EventChoiceMadeEvent extends Event:
    ## 事件对象
    var event_object
    
    ## 选择数据
    var choice_data: Dictionary
    
    ## 初始化
    func _init(p_event_object, p_choice_data: Dictionary):
        event_object = p_event_object
        choice_data = p_choice_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "event.choice_made"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "EventChoiceMadeEvent[event_object=%s, choice=%s]" % [
            event_object, choice_data.get("text", "unknown")
        ]
    
    ## 克隆事件
    func clone() -> Event:
        var event = EventChoiceMadeEvent.new(event_object, choice_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 事件完成事件
class EventCompletedEvent extends Event:
    ## 事件对象
    var event_object
    
    ## 结果数据
    var result_data: Dictionary
    
    ## 初始化
    func _init(p_event_object, p_result_data: Dictionary):
        event_object = p_event_object
        result_data = p_result_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "event.completed"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "EventCompletedEvent[event_object=%s, result=%s]" % [
            event_object, result_data
        ]
    
    ## 克隆事件
    func clone() -> Event:
        var event = EventCompletedEvent.new(event_object, result_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 事件效果应用事件
class EventEffectAppliedEvent extends Event:
    ## 事件对象
    var event_object
    
    ## 效果数据
    var effect_data: Dictionary
    
    ## 初始化
    func _init(p_event_object, p_effect_data: Dictionary):
        event_object = p_event_object
        effect_data = p_effect_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "event.effect_applied"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "EventEffectAppliedEvent[event_object=%s, effect_type=%s]" % [
            event_object, effect_data.get("type", "unknown")
        ]
    
    ## 克隆事件
    func clone() -> Event:
        var event = EventEffectAppliedEvent.new(event_object, effect_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 事件奖励授予事件
class EventRewardGrantedEvent extends Event:
    ## 事件对象
    var event_object
    
    ## 奖励数据
    var reward_data: Dictionary
    
    ## 初始化
    func _init(p_event_object, p_reward_data: Dictionary):
        event_object = p_event_object
        reward_data = p_reward_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "event.reward_granted"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "EventRewardGrantedEvent[event_object=%s, reward_type=%s]" % [
            event_object, reward_data.get("type", "unknown")
        ]
    
    ## 克隆事件
    func clone() -> Event:
        var event = EventRewardGrantedEvent.new(event_object, reward_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event
