extends Node
class_name EventMigrationTest
## 事件迁移测试
## 用于测试和验证事件系统迁移

## 是否启用详细日志
var verbose: bool = true

## 测试结果
var test_results: Dictionary = {
    "total_files": 0,
    "scanned_files": 0,
    "old_event_usages": [],
    "migration_candidates": []
}

## 要扫描的目录
var scan_directories: Array = [
    "res://scripts",
    "res://scenes"
]

## 要忽略的目录
var ignore_directories: Array = [
    "res://scripts/core/events",
    "res://scripts/events"
]

## 旧事件系统的关键字
var old_event_keywords: Array = [
    "EventBus.",
    "emit_event",
    "connect_event",
    "disconnect_event",
    "event_definitions"
]

## 运行测试
func run_test() -> Dictionary:
    print("开始事件迁移测试...")
    
    # 重置测试结果
    test_results = {
        "total_files": 0,
        "scanned_files": 0,
        "old_event_usages": [],
        "migration_candidates": []
    }
    
    # 扫描文件
    for directory in scan_directories:
        _scan_directory(directory)
    
    # 打印测试结果
    _print_test_results()
    
    return test_results

## 扫描目录
func _scan_directory(directory: String) -> void:
    # 检查是否是忽略目录
    for ignore_dir in ignore_directories:
        if directory.begins_with(ignore_dir):
            if verbose:
                print("忽略目录: " + directory)
            return
    
    if verbose:
        print("扫描目录: " + directory)
    
    # 打开目录
    var dir = DirAccess.open(directory)
    if not dir:
        print("无法打开目录: " + directory)
        return
    
    # 扫描目录内容
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        var full_path = directory.path_join(file_name)
        
        if dir.current_is_dir():
            # 递归扫描子目录
            _scan_directory(full_path)
        elif file_name.ends_with(".gd"):
            # 扫描GDScript文件
            _scan_file(full_path)
        
        file_name = dir.get_next()

## 扫描文件
func _scan_file(file_path: String) -> void:
    test_results.total_files += 1
    
    # 打开文件
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("无法打开文件: " + file_path)
        return
    
    # 读取文件内容
    var content = file.get_as_text()
    
    # 检查是否使用了旧事件系统
    var uses_old_event_system = false
    for keyword in old_event_keywords:
        if content.find(keyword) != -1:
            uses_old_event_system = true
            break
    
    if uses_old_event_system:
        test_results.scanned_files += 1
        
        # 分析文件内容
        var lines = content.split("\n")
        var line_number = 0
        
        for line in lines:
            line_number += 1
            
            # 检查是否使用了旧事件系统
            for keyword in old_event_keywords:
                if line.find(keyword) != -1:
                    # 记录旧事件系统使用
                    test_results.old_event_usages.append({
                        "file": file_path,
                        "line": line_number,
                        "content": line.strip_edges(),
                        "keyword": keyword
                    })
                    
                    # 分析迁移候选
                    _analyze_migration_candidate(file_path, line_number, line)
                    
                    break

## 分析迁移候选
func _analyze_migration_candidate(file_path: String, line_number: int, line: String) -> void:
    # 检查是否是emit_event调用
    var emit_regex = RegEx.new()
    emit_regex.compile("emit_event\\(\\s*[\"']([^\"']+)[\"']")
    var matches = emit_regex.search_all(line)
    
    for match_result in matches:
        var event_name = match_result.get_string(1)
        
        # 记录迁移候选
        test_results.migration_candidates.append({
            "file": file_path,
            "line": line_number,
            "content": line.strip_edges(),
            "event_name": event_name,
            "type": "emit"
        })
    
    # 检查是否是connect_event调用
    var connect_regex = RegEx.new()
    connect_regex.compile("connect_event\\(\\s*[\"']([^\"']+)[\"']")
    matches = connect_regex.search_all(line)
    
    for match_result in matches:
        var event_name = match_result.get_string(1)
        
        # 记录迁移候选
        test_results.migration_candidates.append({
            "file": file_path,
            "line": line_number,
            "content": line.strip_edges(),
            "event_name": event_name,
            "type": "connect"
        })

## 打印测试结果
func _print_test_results() -> void:
    print("\n===== 事件迁移测试结果 =====")
    print("总文件数: " + str(test_results.total_files))
    print("扫描文件数: " + str(test_results.scanned_files))
    print("旧事件系统使用数: " + str(test_results.old_event_usages.size()))
    print("迁移候选数: " + str(test_results.migration_candidates.size()))
    
    if verbose:
        print("\n----- 迁移候选 -----")
        for candidate in test_results.migration_candidates:
            print(candidate.file + ":" + str(candidate.line) + " - " + candidate.event_name + " (" + candidate.type + ")")
            print("  " + candidate.content)
    
    print("\n===== 测试完成 =====")

## 生成迁移报告
func generate_migration_report(output_path: String = "user://event_migration_report.md") -> void:
    # 创建报告内容
    var report = "# 事件系统迁移报告\n\n"
    
    report += "## 概述\n\n"
    report += "- 总文件数: " + str(test_results.total_files) + "\n"
    report += "- 扫描文件数: " + str(test_results.scanned_files) + "\n"
    report += "- 旧事件系统使用数: " + str(test_results.old_event_usages.size()) + "\n"
    report += "- 迁移候选数: " + str(test_results.migration_candidates.size()) + "\n\n"
    
    report += "## 迁移候选\n\n"
    
    # 按文件分组
    var files = {}
    for candidate in test_results.migration_candidates:
        if not files.has(candidate.file):
            files[candidate.file] = []
        files[candidate.file].append(candidate)
    
    # 生成文件报告
    for file_path in files:
        report += "### " + file_path + "\n\n"
        report += "| 行号 | 事件名称 | 类型 | 内容 |\n"
        report += "|------|----------|------|------|\n"
        
        for candidate in files[file_path]:
            report += "| " + str(candidate.line) + " | " + candidate.event_name + " | " + candidate.type + " | `" + candidate.content + "` |\n"
        
        report += "\n"
    
    # 保存报告
    var file = FileAccess.open(output_path, FileAccess.WRITE)
    if file:
        file.store_string(report)
        file.close()
        print("迁移报告已保存到: " + output_path)
    else:
        print("无法保存迁移报告: " + output_path)

## 生成迁移脚本
func generate_migration_script(output_path: String = "user://event_migration_script.gd") -> void:
    # 创建脚本内容
    var script = """extends Node
## 事件系统迁移脚本
## 用于自动迁移旧事件系统到新事件系统

## 迁移文件
func migrate_files() -> void:
    print("开始迁移文件...")
    
    # 迁移文件
"""
    
    # 按文件分组
    var files = {}
    for candidate in test_results.migration_candidates:
        if not files.has(candidate.file):
            files[candidate.file] = []
        files[candidate.file].append(candidate)
    
    # 生成迁移代码
    for file_path in files:
        script += "    _migrate_file(\"" + file_path + "\")\n"
    
    script += """    
    print("文件迁移完成")

## 迁移单个文件
func _migrate_file(file_path: String) -> void:
    print("迁移文件: " + file_path)
    
    # 打开文件
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("无法打开文件: " + file_path)
        return
    
    # 读取文件内容
    var content = file.get_as_text()
    file.close()
    
    # 替换旧事件系统代码
    var new_content = content
    
    # 替换emit_event调用
    var emit_regex = RegEx.new()
    emit_regex.compile("(EventBus\\.[a-z_]+)\\.emit_event\\(\\s*[\"']([^\"']+)[\"']\\s*(?:,\\s*\\[([^\\]]+)\\])?\\s*\\)")
    var matches = emit_regex.search_all(content)
    
    for match_result in matches:
        var full_match = match_result.get_string()
        var event_bus = match_result.get_string(1)
        var event_name = match_result.get_string(2)
        var args = match_result.get_string(3)
        
        var new_code = _generate_new_emit_code(event_bus, event_name, args)
        new_content = new_content.replace(full_match, new_code)
    
    # 替换connect_event调用
    var connect_regex = RegEx.new()
    connect_regex.compile("(EventBus\\.[a-z_]+)\\.connect_event\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([^\\)]+)\\)")
    matches = connect_regex.search_all(content)
    
    for match_result in matches:
        var full_match = match_result.get_string()
        var event_bus = match_result.get_string(1)
        var event_name = match_result.get_string(2)
        var callback = match_result.get_string(3)
        
        var new_code = _generate_new_connect_code(event_bus, event_name, callback)
        new_content = new_content.replace(full_match, new_code)
    
    # 保存修改后的文件
    file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(new_content)
        file.close()
        print("文件已迁移: " + file_path)
    else:
        print("无法保存文件: " + file_path)

## 生成新的emit代码
func _generate_new_emit_code(event_bus: String, event_name: String, args: String) -> String:
    var group_name = event_bus.split(".")[1]
    
    # 根据事件名称和参数生成新的事件创建代码
    var event_creation = ""
    
    # 这里需要根据事件类型生成相应的代码
    # 例如：
    match group_name + "." + event_name:
        "game.game_started":
            event_creation = "GameEvents.GameStartedEvent.new(" + (args if not args.is_empty() else "1") + ")"
        "battle.damage_dealt":
            event_creation = "BattleEvents.DamageDealtEvent.new(" + args + ")"
        "event.event_completed":
            event_creation = "EventSystemEvents.EventCompletedEvent.new(" + args + ")"
        "ui.show_toast":
            event_creation = "UIEvents.ToastShownEvent.new(" + args + ")"
        "debug.debug_message":
            event_creation = "DebugEvents.DebugMessageEvent.new(" + args + ")"
        _:
            # 对于未明确处理的事件，使用迁移工具
            event_creation = "EventMigration.new().create_event(\"" + event_name + "\", [" + args + "])"
    
    return "GlobalEventBus." + group_name + ".dispatch_event(" + event_creation + ")"

## 生成新的connect代码
func _generate_new_connect_code(event_bus: String, event_name: String, callback: String) -> String:
    var group_name = event_bus.split(".")[1]
    return "GlobalEventBus." + group_name + ".add_listener(\"" + event_name + "\", " + callback + ")"
"""
    
    # 保存脚本
    var file = FileAccess.open(output_path, FileAccess.WRITE)
    if file:
        file.store_string(script)
        file.close()
        print("迁移脚本已保存到: " + output_path)
    else:
        print("无法保存迁移脚本: " + output_path)

## 运行迁移测试并生成报告
static func run() -> void:
    var test = EventMigrationTest.new()
    test.run_test()
    test.generate_migration_report("res://scripts/core/events/tests/event_migration_report.md")
    test.generate_migration_script("res://scripts/core/events/tests/event_migration_script.gd")
