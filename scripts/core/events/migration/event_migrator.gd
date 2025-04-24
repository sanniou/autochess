extends Node
class_name EventMigrator
## 事件迁移工具
## 用于自动替换代码中的EventBus调用

## 事件映射
var _event_mapping = EventMapping.new()

## 迁移文件
## @param file_path 文件路径
## @return 是否成功迁移
func migrate_file(file_path: String) -> bool:
    print("迁移文件: " + file_path)
    
    # 打开文件
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        push_error("无法打开文件: " + file_path)
        return false
    
    # 读取文件内容
    var content = file.get_as_text()
    file.close()
    
    # 替换EventBus调用
    var new_content = _replace_event_bus_calls(content)
    
    # 如果内容没有变化，不需要保存
    if new_content == content:
        return true
    
    # 保存修改后的文件
    file = FileAccess.open(file_path, FileAccess.WRITE)
    if not file:
        push_error("无法保存文件: " + file_path)
        return false
    
    file.store_string(new_content)
    file.close()
    
    print("文件已迁移: " + file_path)
    return true

## 替换EventBus调用
## @param content 文件内容
## @return 替换后的内容
func _replace_event_bus_calls(content: String) -> String:
    var new_content = content
    
    # 替换emit_event调用
    new_content = _replace_emit_event_calls(new_content)
    
    # 替换connect_event调用
    new_content = _replace_connect_event_calls(new_content)
    
    # 替换disconnect_event调用
    new_content = _replace_disconnect_event_calls(new_content)
    
    return new_content

## 替换emit_event调用
## @param content 文件内容
## @return 替换后的内容
func _replace_emit_event_calls(content: String) -> String:
    var new_content = content
    
    # 创建正则表达式
    var regex = RegEx.new()
    regex.compile("(EventBus\\.[a-z_]+)\\.emit_event\\(\\s*[\"']([^\"']+)[\"']\\s*(?:,\\s*\\[([^\\]]+)\\])?\\s*\\)")
    
    # 查找所有匹配
    var matches = regex.search_all(content)
    
    # 从后向前替换，避免位置偏移
    for i in range(matches.size() - 1, -1, -1):
        var match_result = matches[i]
        
        # 提取信息
        var event_bus = match_result.get_string(1)  # EventBus.game
        var event_name = match_result.get_string(2)  # game_started
        var args_str = match_result.get_string(3)    # 1, 2, 3
        
        # 获取分组名称
        var group_name = event_bus.split(".")[1]  # game
        
        # 构造新的事件创建代码
        var new_code = _generate_event_creation_code(group_name, event_name, args_str)
        
        # 替换代码
        var start_pos = match_result.get_start()
        var end_pos = match_result.get_end()
        new_content = new_content.substr(0, start_pos) + new_code + new_content.substr(end_pos)
    
    return new_content

## 替换connect_event调用
## @param content 文件内容
## @return 替换后的内容
func _replace_connect_event_calls(content: String) -> String:
    var new_content = content
    
    # 创建正则表达式
    var regex = RegEx.new()
    regex.compile("(EventBus\\.[a-z_]+)\\.connect_event\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([^\\)]+)\\)")
    
    # 查找所有匹配
    var matches = regex.search_all(content)
    
    # 从后向前替换，避免位置偏移
    for i in range(matches.size() - 1, -1, -1):
        var match_result = matches[i]
        
        # 提取信息
        var event_bus = match_result.get_string(1)  # EventBus.game
        var event_name = match_result.get_string(2)  # game_started
        var callback = match_result.get_string(3)    # _on_game_started
        
        # 获取分组名称
        var group_name = event_bus.split(".")[1]  # game
        
        # 构造新的监听器代码
        var new_code = _generate_listener_code(group_name, event_name, callback)
        
        # 替换代码
        var start_pos = match_result.get_start()
        var end_pos = match_result.get_end()
        new_content = new_content.substr(0, start_pos) + new_code + new_content.substr(end_pos)
    
    return new_content

## 替换disconnect_event调用
## @param content 文件内容
## @return 替换后的内容
func _replace_disconnect_event_calls(content: String) -> String:
    var new_content = content
    
    # 创建正则表达式
    var regex = RegEx.new()
    regex.compile("(EventBus\\.[a-z_]+)\\.disconnect_event\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([^\\)]+)\\)")
    
    # 查找所有匹配
    var matches = regex.search_all(content)
    
    # 从后向前替换，避免位置偏移
    for i in range(matches.size() - 1, -1, -1):
        var match_result = matches[i]
        
        # 提取信息
        var event_bus = match_result.get_string(1)  # EventBus.game
        var event_name = match_result.get_string(2)  # game_started
        var callback = match_result.get_string(3)    # _on_game_started
        
        # 获取分组名称
        var group_name = event_bus.split(".")[1]  # game
        
        # 构造新的移除监听器代码
        var new_code = _generate_remove_listener_code(group_name, event_name, callback)
        
        # 替换代码
        var start_pos = match_result.get_start()
        var end_pos = match_result.get_end()
        new_content = new_content.substr(0, start_pos) + new_code + new_content.substr(end_pos)
    
    return new_content

## 生成事件创建代码
## @param group_name 分组名称
## @param event_name 事件名称
## @param args_str 参数字符串
## @return 事件创建代码
func _generate_event_creation_code(group_name: String, event_name: String, args_str: String) -> String:
    # 获取完整事件名称
    var full_event_name = group_name + "." + event_name
    
    # 获取事件映射
    var mapping = _event_mapping.get_mapping(full_event_name)
    if mapping.is_empty():
        push_warning("未找到事件映射: " + full_event_name)
        return "EventBus." + group_name + ".emit_event(\"" + event_name + "\"" + (", [" + args_str + "]" if args_str else "") + ")"
    
    # 解析类名
    var class_path = mapping.class.split(".")
    if class_path.size() != 2:
        push_error("无效的类路径: " + mapping.class)
        return "EventBus." + group_name + ".emit_event(\"" + event_name + "\"" + (", [" + args_str + "]" if args_str else "") + ")"
    
    # 获取类和事件类型
    var event_class_name = class_path[0]
    var event_type_name = class_path[1]
    
    # 构造事件创建代码
    var args_array = []
    if args_str:
        args_array = args_str.split(",")
        # 去除空格
        for i in range(args_array.size()):
            args_array[i] = args_array[i].strip_edges()
    
    # 构造新代码
    var new_code = "GlobalEventBus." + group_name + ".dispatch_event(" + event_class_name + "." + event_type_name + ".new("
    
    # 添加参数
    if not args_array.is_empty():
        new_code += args_array.join(", ")
    
    new_code += "))"
    
    return new_code

## 生成监听器代码
## @param group_name 分组名称
## @param event_name 事件名称
## @param callback 回调函数
## @return 监听器代码
func _generate_listener_code(group_name: String, event_name: String, callback: String) -> String:
    # 获取完整事件名称
    var full_event_name = group_name + "." + event_name
    
    # 获取事件映射
    var mapping = _event_mapping.get_mapping(full_event_name)
    if mapping.is_empty():
        push_warning("未找到事件映射: " + full_event_name)
        return "EventBus." + group_name + ".connect_event(\"" + event_name + "\", " + callback + ")"
    
    # 构造新代码
    var new_code = "GlobalEventBus." + group_name + ".add_listener(\"" + event_name + "\", " + callback + ")"
    
    return new_code

## 生成移除监听器代码
## @param group_name 分组名称
## @param event_name 事件名称
## @param callback 回调函数
## @return 移除监听器代码
func _generate_remove_listener_code(group_name: String, event_name: String, callback: String) -> String:
    # 获取完整事件名称
    var full_event_name = group_name + "." + event_name
    
    # 获取事件映射
    var mapping = _event_mapping.get_mapping(full_event_name)
    if mapping.is_empty():
        push_warning("未找到事件映射: " + full_event_name)
        return "EventBus." + group_name + ".disconnect_event(\"" + event_name + "\", " + callback + ")"
    
    # 构造新代码
    var new_code = "GlobalEventBus." + group_name + ".remove_listener(\"" + event_name + "\", " + callback + ")"
    
    return new_code
