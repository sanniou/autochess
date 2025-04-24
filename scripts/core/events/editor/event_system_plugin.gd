@tool
extends EditorPlugin
## 事件系统编辑器插件
## 提供事件系统的编辑器集成

## 菜单项
var menu_button: MenuButton

## 进入树
func _enter_tree() -> void:
    # 创建菜单按钮
    menu_button = MenuButton.new()
    menu_button.text = "事件系统"
    
    # 创建菜单项
    var popup = menu_button.get_popup()
    popup.add_item("运行迁移测试", 0)
    popup.add_item("生成迁移报告", 1)
    popup.add_item("生成迁移脚本", 2)
    popup.add_separator()
    popup.add_item("关于事件系统", 3)
    
    # 连接信号
    popup.id_pressed.connect(_on_menu_item_pressed)
    
    # 添加到编辑器
    add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, menu_button)

## 离开树
func _exit_tree() -> void:
    # 移除菜单按钮
    if menu_button:
        remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, menu_button)
        menu_button.queue_free()

## 菜单项点击处理
func _on_menu_item_pressed(id: int) -> void:
    match id:
        0:  # 运行迁移测试
            _run_migration_test()
        1:  # 生成迁移报告
            _generate_migration_report()
        2:  # 生成迁移脚本
            _generate_migration_script()
        3:  # 关于事件系统
            _show_about_dialog()

## 运行迁移测试
func _run_migration_test() -> void:
    # 加载测试脚本
    var EventMigrationTest = load("res://scripts/core/events/tests/event_migration_test.gd")
    var test = EventMigrationTest.new()
    
    # 运行测试
    var results = test.run_test()
    
    # 显示结果
    var dialog = AcceptDialog.new()
    dialog.title = "迁移测试结果"
    dialog.dialog_text = "总文件数: %d\n扫描文件数: %d\n旧事件系统使用数: %d\n迁移候选数: %d" % [
        results.total_files,
        results.scanned_files,
        results.old_event_usages.size(),
        results.migration_candidates.size()
    ]
    
    get_editor_interface().get_base_control().add_child(dialog)
    dialog.popup_centered()

## 生成迁移报告
func _generate_migration_report() -> void:
    # 加载测试脚本
    var EventMigrationTest = load("res://scripts/core/events/tests/event_migration_test.gd")
    var test = EventMigrationTest.new()
    
    # 运行测试
    test.run_test()
    
    # 生成报告
    var report_path = "res://scripts/core/events/tests/event_migration_report.md"
    test.generate_migration_report(report_path)
    
    # 显示结果
    var dialog = AcceptDialog.new()
    dialog.title = "迁移报告已生成"
    dialog.dialog_text = "迁移报告已保存到:\n" + report_path
    
    get_editor_interface().get_base_control().add_child(dialog)
    dialog.popup_centered()

## 生成迁移脚本
func _generate_migration_script() -> void:
    # 加载测试脚本
    var EventMigrationTest = load("res://scripts/core/events/tests/event_migration_test.gd")
    var test = EventMigrationTest.new()
    
    # 运行测试
    test.run_test()
    
    # 生成脚本
    var script_path = "res://scripts/core/events/tests/event_migration_script.gd"
    test.generate_migration_script(script_path)
    
    # 显示结果
    var dialog = AcceptDialog.new()
    dialog.title = "迁移脚本已生成"
    dialog.dialog_text = "迁移脚本已保存到:\n" + script_path
    
    get_editor_interface().get_base_control().add_child(dialog)
    dialog.popup_centered()

## 显示关于对话框
func _show_about_dialog() -> void:
    var dialog = AcceptDialog.new()
    dialog.title = "关于事件系统"
    dialog.dialog_text = """事件系统 v1.0.0

基于信号的强类型事件系统，提供以下功能：
- 类型安全的事件定义和处理
- 事件分组和命名空间
- 事件过滤和优先级
- 事件批处理
- 事件历史记录
- 从旧事件系统迁移工具

作者：AI助手
"""
    
    get_editor_interface().get_base_control().add_child(dialog)
    dialog.popup_centered()
