extends Control

# 引用
@onready var save_slot_list = $SavePanel/VBoxContainer/SaveSlotList
@onready var test_data_input = $SavePanel/VBoxContainer/TestDataContainer/TestDataInput
@onready var save_button = $SavePanel/VBoxContainer/ButtonContainer/SaveButton
@onready var load_button = $SavePanel/VBoxContainer/ButtonContainer/LoadButton
@onready var delete_button = $SavePanel/VBoxContainer/ButtonContainer/DeleteButton
@onready var refresh_button = $SavePanel/VBoxContainer/ButtonContainer/RefreshButton
@onready var result_label = $SavePanel/VBoxContainer/ResultLabel
@onready var back_button = $BackButton

# 存档管理器
var save_manager = null

# 当前选择的存档槽
var selected_slot = ""

# 初始化
func _ready():
    # 获取存档管理器
    save_manager = SaveManager
    
    # 连接按钮信号
    save_button.pressed.connect(_on_save_button_pressed)
    load_button.pressed.connect(_on_load_button_pressed)
    delete_button.pressed.connect(_on_delete_button_pressed)
    refresh_button.pressed.connect(_on_refresh_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 连接列表信号
    save_slot_list.item_selected.connect(_on_save_slot_selected)
    
    # 刷新存档列表
    _refresh_save_list()

# 刷新存档列表
func _refresh_save_list():
    # 清空列表
    save_slot_list.clear()
    
    # 获取存档列表
    var saves = save_manager.get_save_list()
    
    # 添加到列表
    for save in saves:
        var slot_name = save.name
        var date_str = save.date if save.has("date") else "未知日期"
        
        save_slot_list.add_item(slot_name + " - " + date_str)
    
    # 添加新存档选项
    save_slot_list.add_item("+ 新存档")
    
    # 重置选择
    selected_slot = ""
    
    # 更新按钮状态
    _update_button_states()

# 更新按钮状态
func _update_button_states():
    # 禁用加载和删除按钮，除非选择了有效的存档
    load_button.disabled = selected_slot.is_empty()
    delete_button.disabled = selected_slot.is_empty()
    
    # 保存按钮始终可用
    save_button.disabled = false

# 存档槽选择处理
func _on_save_slot_selected(index):
    if index < save_slot_list.item_count - 1:
        # 选择了现有存档
        var item_text = save_slot_list.get_item_text(index)
        selected_slot = item_text.split(" - ")[0]
    else:
        # 选择了新存档
        selected_slot = "save_" + str(Time.get_unix_time_from_system())
    
    # 更新按钮状态
    _update_button_states()

# 保存按钮处理
func _on_save_button_pressed():
    # 获取测试数据
    var test_data = test_data_input.text
    if test_data.is_empty():
        test_data = "测试数据 " + Time.get_datetime_string_from_system()
    
    # 创建存档数据
    var save_data = {
        "test_data": test_data,
        "timestamp": Time.get_unix_time_from_system(),
        "date": Time.get_datetime_string_from_system()
    }
    
    # 如果没有选择存档槽，创建新的
    if selected_slot.is_empty():
        selected_slot = "save_" + str(Time.get_unix_time_from_system())
    
    # 保存数据
    var success = save_manager.save_game(selected_slot, save_data)
    
    # 显示结果
    if success:
        result_label.text = "保存成功: " + selected_slot
    else:
        result_label.text = "保存失败!"
    
    # 刷新存档列表
    _refresh_save_list()

# 加载按钮处理
func _on_load_button_pressed():
    if selected_slot.is_empty():
        result_label.text = "请先选择一个存档!"
        return
    
    # 加载存档
    var save_data = save_manager.load_game(selected_slot)
    
    # 显示结果
    if save_data:
        var test_data = save_data.test_data if save_data.has("test_data") else "无数据"
        test_data_input.text = test_data
        result_label.text = "加载成功: " + selected_slot + "\n数据: " + test_data
    else:
        result_label.text = "加载失败!"

# 删除按钮处理
func _on_delete_button_pressed():
    if selected_slot.is_empty():
        result_label.text = "请先选择一个存档!"
        return
    
    # 删除存档
    var success = save_manager.delete_save(selected_slot)
    
    # 显示结果
    if success:
        result_label.text = "删除成功: " + selected_slot
    else:
        result_label.text = "删除失败!"
    
    # 刷新存档列表
    _refresh_save_list()

# 刷新按钮处理
func _on_refresh_button_pressed():
    _refresh_save_list()
    result_label.text = "存档列表已刷新"

# 返回按钮处理
func _on_back_button_pressed():
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
