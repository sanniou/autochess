extends Control

# 引用
@onready var popup_option = $MainPanel/VBoxContainer/PopupContainer/PopupOption
@onready var show_popup_button = $MainPanel/VBoxContainer/PopupContainer/ShowPopupButton
@onready var toast_input = $MainPanel/VBoxContainer/ToastContainer/ToastInput
@onready var show_toast_button = $MainPanel/VBoxContainer/ToastContainer/ShowToastButton
@onready var transition_option = $MainPanel/VBoxContainer/TransitionContainer/TransitionOption
@onready var start_transition_button = $MainPanel/VBoxContainer/TransitionContainer/StartTransitionButton
@onready var theme_option = $MainPanel/VBoxContainer/ThemeContainer/ThemeOption
@onready var apply_theme_button = $MainPanel/VBoxContainer/ThemeContainer/ApplyThemeButton
@onready var test_components_button = $MainPanel/VBoxContainer/TestComponentsButton
@onready var achievement_button = $ControlPanel/VBoxContainer/AchievementButton
@onready var reward_button = $ControlPanel/VBoxContainer/RewardButton
@onready var dialog_button = $ControlPanel/VBoxContainer/DialogButton
@onready var back_button = $BackButton

# UI管理器
var ui_manager = null

# 弹窗类型
var popup_types = ["message", "confirm", "input", "settings", "achievement", "reward"]

# 过渡效果
var transition_types = ["fade", "slide", "zoom", "dissolve", "pixelate"]

# 主题
var themes = ["default", "dark", "light", "fantasy", "sci-fi"]

# 初始化
func _ready():
    # 获取UI管理器
    ui_manager = get_node_or_null("/root/GameManager/UIManager")
    if not ui_manager:
        # 创建临时UI管理器
        ui_manager = UIManager.new()
        add_child(ui_manager)
    
    # 连接按钮信号
    show_popup_button.pressed.connect(_on_show_popup_button_pressed)
    show_toast_button.pressed.connect(_on_show_toast_button_pressed)
    start_transition_button.pressed.connect(_on_start_transition_button_pressed)
    apply_theme_button.pressed.connect(_on_apply_theme_button_pressed)
    test_components_button.pressed.connect(_on_test_components_button_pressed)
    achievement_button.pressed.connect(_on_achievement_button_pressed)
    reward_button.pressed.connect(_on_reward_button_pressed)
    dialog_button.pressed.connect(_on_dialog_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 初始化选项
    _initialize_options()

# 初始化选项
func _initialize_options():
    # 初始化弹窗选项
    for popup_type in popup_types:
        popup_option.add_item(popup_type)
    
    # 初始化过渡效果选项
    for transition_type in transition_types:
        transition_option.add_item(transition_type)
    
    # 初始化主题选项
    for theme_name in themes:
        theme_option.add_item(theme_name)

# 显示弹窗按钮处理
func _on_show_popup_button_pressed():
    # 获取选择的弹窗类型
    var popup_type = popup_types[popup_option.selected]
    
    # 根据类型显示不同的弹窗
    match popup_type:
        "message":
            _show_message_popup()
        "confirm":
            _show_confirm_popup()
        "input":
            _show_input_popup()
        "settings":
            _show_settings_popup()
        "achievement":
            _show_achievement_popup()
        "reward":
            _show_reward_popup()

# 显示提示按钮处理
func _on_show_toast_button_pressed():
    # 获取提示消息
    var message = toast_input.text
    if message.is_empty():
        message = "这是一条测试提示消息"
    
    # 显示提示
    EventBus.ui.show_toast.emit(message)

# 开始过渡按钮处理
func _on_start_transition_button_pressed():
    # 获取选择的过渡效果
    var transition_type = transition_types[transition_option.selected]
    
    # 开始过渡
    EventBus.ui.start_transition.emit(transition_type, 1.0)

# 应用主题按钮处理
func _on_apply_theme_button_pressed():
    # 获取选择的主题
    var theme_name = themes[theme_option.selected]
    
    # 应用主题
    EventBus.ui.theme_changed.emit(theme_name)

# 测试UI组件按钮处理
func _on_test_components_button_pressed():
    # 显示UI组件测试场景
    get_tree().change_scene_to_file("res://scenes/test/ui_components_test.tscn")

# 显示成就通知按钮处理
func _on_achievement_button_pressed():
    # 创建模拟成就数据
    var achievement_data = {
        "id": "test_achievement",
        "name": "测试成就",
        "description": "这是一个测试成就",
        "icon": "res://assets/icons/achievement.png"
    }
    
    # 显示成就通知
    EventBus.achievement.achievement_unlocked.emit(achievement_data)

# 显示奖励弹窗按钮处理
func _on_reward_button_pressed():
    # 创建模拟奖励数据
    var reward_data = {
        "gold": 100,
        "items": [
            {"id": "item_1", "name": "测试物品1", "icon": "res://assets/icons/item.png"},
            {"id": "item_2", "name": "测试物品2", "icon": "res://assets/icons/item.png"}
        ],
        "experience": 50
    }
    
    # 显示奖励弹窗
    ui_manager.show_popup("reward", reward_data)

# 显示对话框按钮处理
func _on_dialog_button_pressed():
    # 创建模拟对话数据
    var dialog_data = {
        "title": "测试对话",
        "message": "这是一个测试对话框，用于测试UI系统的对话功能。",
        "options": [
            {"text": "确定", "value": "ok"},
            {"text": "取消", "value": "cancel"}
        ]
    }
    
    # 显示对话框
    ui_manager.show_popup("dialog", dialog_data)

# 显示消息弹窗
func _show_message_popup():
    # 创建消息数据
    var message_data = {
        "title": "消息",
        "message": "这是一个测试消息弹窗。",
        "button_text": "确定"
    }
    
    # 显示消息弹窗
    ui_manager.show_popup("message", message_data)

# 显示确认弹窗
func _show_confirm_popup():
    # 创建确认数据
    var confirm_data = {
        "title": "确认",
        "message": "这是一个测试确认弹窗，是否继续？",
        "ok_text": "确定",
        "cancel_text": "取消"
    }
    
    # 显示确认弹窗
    ui_manager.show_popup("confirm", confirm_data)

# 显示输入弹窗
func _show_input_popup():
    # 创建输入数据
    var input_data = {
        "title": "输入",
        "message": "请输入测试内容：",
        "placeholder": "在此输入...",
        "default_text": "",
        "ok_text": "确定",
        "cancel_text": "取消"
    }
    
    # 显示输入弹窗
    ui_manager.show_popup("input", input_data)

# 显示设置弹窗
func _show_settings_popup():
    # 显示设置弹窗
    ui_manager.show_popup("settings")

# 显示成就弹窗
func _show_achievement_popup():
    # 显示成就弹窗
    ui_manager.show_popup("achievements")

# 显示奖励弹窗
func _show_reward_popup():
    # 创建奖励数据
    var reward_data = {
        "gold": 100,
        "items": [
            {"id": "item_1", "name": "测试物品1", "icon": "res://assets/icons/item.png"},
            {"id": "item_2", "name": "测试物品2", "icon": "res://assets/icons/item.png"}
        ],
        "experience": 50
    }
    
    # 显示奖励弹窗
    ui_manager.show_popup("reward", reward_data)

# 返回按钮处理
func _on_back_button_pressed():
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
