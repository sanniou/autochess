extends RefCounted
class_name Event
## 事件基类
## 所有事件类型都应继承自此类

## 事件时间戳
var timestamp: int = Time.get_unix_time_from_system()

## 事件是否已取消
var canceled: bool = false

## 事件源对象（可选）
var source: Object = null

## 获取事件类型名称
## 子类应该重写此方法以返回特定的事件类型
func get_type() -> String:
    return "Event"
    
## 取消事件
## 被取消的事件可能不会被某些监听器处理
func cancel() -> void:
    canceled = true
    
## 检查事件是否已取消
func is_canceled() -> bool:
    return canceled
    
## 获取事件的字符串表示
func _to_string() -> String:
    return "Event[type=%s, canceled=%s, timestamp=%d]" % [get_type(), canceled, timestamp]
    
## 克隆事件（用于事件记录和重放）
## 子类应该重写此方法以正确克隆所有属性
func clone() -> Event:
    var event = Event.new()
    event.timestamp = timestamp
    event.canceled = canceled
    event.source = source
    return event
