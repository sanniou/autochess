extends RefCounted
class_name UIEvents
## UI事件类型
## 定义与用户界面相关的事件

## UI更新事件
class UIUpdateEvent extends Event:
    ## UI组件
    var component: String
    
    ## 更新数据
    var data: Dictionary
    
    ## 初始化
    func _init(p_component: String, p_data: Dictionary = {}):
        component = p_component
        data = p_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.update"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "UIUpdateEvent[component=%s, data=%s]" % [component, data]
    
    ## 克隆事件
    func clone() -> Event:
        var event = UIUpdateEvent.new(component, data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 按钮点击事件
class ButtonClickedEvent extends Event:
    ## 按钮ID
    var button_id: String
    
    ## 按钮文本
    var button_text: String
    
    ## 按钮数据
    var button_data: Dictionary
    
    ## 初始化
    func _init(p_button_id: String, p_button_text: String = "", p_button_data: Dictionary = {}):
        button_id = p_button_id
        button_text = p_button_text
        button_data = p_button_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.button_clicked"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "ButtonClickedEvent[button_id=%s, button_text=%s]" % [button_id, button_text]
    
    ## 克隆事件
    func clone() -> Event:
        var event = ButtonClickedEvent.new(button_id, button_text, button_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 菜单打开事件
class MenuOpenedEvent extends Event:
    ## 菜单ID
    var menu_id: String
    
    ## 菜单数据
    var menu_data: Dictionary
    
    ## 初始化
    func _init(p_menu_id: String, p_menu_data: Dictionary = {}):
        menu_id = p_menu_id
        menu_data = p_menu_data
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.menu_opened"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "MenuOpenedEvent[menu_id=%s]" % [menu_id]
    
    ## 克隆事件
    func clone() -> Event:
        var event = MenuOpenedEvent.new(menu_id, menu_data.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 菜单关闭事件
class MenuClosedEvent extends Event:
    ## 菜单ID
    var menu_id: String
    
    ## 初始化
    func _init(p_menu_id: String):
        menu_id = p_menu_id
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.menu_closed"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "MenuClosedEvent[menu_id=%s]" % [menu_id]
    
    ## 克隆事件
    func clone() -> Event:
        var event = MenuClosedEvent.new(menu_id)
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 对话框显示事件
class DialogShownEvent extends Event:
    ## 对话框ID
    var dialog_id: String
    
    ## 对话框标题
    var title: String
    
    ## 对话框内容
    var content: String
    
    ## 对话框选项
    var options: Array
    
    ## 初始化
    func _init(p_dialog_id: String, p_title: String, p_content: String, p_options: Array = []):
        dialog_id = p_dialog_id
        title = p_title
        content = p_content
        options = p_options
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.dialog_shown"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "DialogShownEvent[dialog_id=%s, title=%s, options=%d]" % [dialog_id, title, options.size()]
    
    ## 克隆事件
    func clone() -> Event:
        var event = DialogShownEvent.new(dialog_id, title, content, options.duplicate())
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event

## 提示显示事件
class ToastShownEvent extends Event:
    ## 提示标题
    var title: String
    
    ## 提示内容
    var message: String
    
    ## 提示类型
    var type: String
    
    ## 显示时长
    var duration: float
    
    ## 初始化
    func _init(p_title: String, p_message: String, p_type: String = "info", p_duration: float = 3.0):
        title = p_title
        message = p_message
        type = p_type
        duration = p_duration
    
    ## 获取事件类型
    func get_type() -> String:
        return "ui.toast_shown"
    
    ## 获取事件的字符串表示
    func _to_string() -> String:
        return "ToastShownEvent[title=%s, message=%s, type=%s, duration=%.1f]" % [title, message, type, duration]
    
    ## 克隆事件
    func clone() -> Event:
        var event = ToastShownEvent.new(title, message, type, duration)
        event.timestamp = timestamp
        event.canceled = canceled
        event.source = source
        return event
