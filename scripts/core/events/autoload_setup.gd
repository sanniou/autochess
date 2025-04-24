@tool
extends EditorScript
## 事件系统自动加载设置
## 用于自动设置事件系统的自动加载

## 运行脚本
func _run() -> void:
    print("设置事件系统自动加载...")
    
    # 获取项目设置
    var project_settings = ProjectSettings
    
    # 设置事件系统自动加载
    var autoload_path = "res://scripts/core/events/event_system.gd"
    var autoload_name = "EventSystem"
    
    # 检查是否已存在
    if not project_settings.has_setting("autoload/" + autoload_name):
        # 添加自动加载
        project_settings.set_setting("autoload/" + autoload_name, "*" + autoload_path)
        
        # 保存项目设置
        project_settings.save()
        
        print("事件系统自动加载已设置: " + autoload_name + " -> " + autoload_path)
    else:
        print("事件系统自动加载已存在: " + autoload_name)
    
    print("事件系统自动加载设置完成")
