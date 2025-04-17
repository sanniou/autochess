extends Control

# 引用
@onready var event_bus_button = $ScrollContainer/VBoxContainer/EventBusButton
@onready var save_system_button = $ScrollContainer/VBoxContainer/SaveSystemButton
@onready var localization_button = $ScrollContainer/VBoxContainer/LocalizationButton
@onready var board_button = $ScrollContainer/VBoxContainer/BoardButton
@onready var battle_button = $ScrollContainer/VBoxContainer/BattleButton
@onready var map_button = $ScrollContainer/VBoxContainer/MapButton
@onready var ui_button = $ScrollContainer/VBoxContainer/UIButton
@onready var animation_button = $ScrollContainer/VBoxContainer/AnimationButton
@onready var object_pool_button = $ScrollContainer/VBoxContainer/ObjectPoolButton
@onready var resource_manager_button = $ScrollContainer/VBoxContainer/ResourceManagerButton
@onready var performance_monitor_button = $ScrollContainer/VBoxContainer/PerformanceMonitorButton
@onready var back_button = $BackButton

# 初始化
func _ready():
    # 连接按钮信号
    event_bus_button.pressed.connect(_on_event_bus_button_pressed)
    save_system_button.pressed.connect(_on_save_system_button_pressed)
    localization_button.pressed.connect(_on_localization_button_pressed)
    board_button.pressed.connect(_on_board_button_pressed)
    battle_button.pressed.connect(_on_battle_button_pressed)
    map_button.pressed.connect(_on_map_button_pressed)
    ui_button.pressed.connect(_on_ui_button_pressed)
    animation_button.pressed.connect(_on_animation_button_pressed)
    object_pool_button.pressed.connect(_on_object_pool_button_pressed)
    resource_manager_button.pressed.connect(_on_resource_manager_button_pressed)
    performance_monitor_button.pressed.connect(_on_performance_monitor_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

# 事件总线按钮处理
func _on_event_bus_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/event_bus_test.tscn")

# 存档系统按钮处理
func _on_save_system_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/save_system_test.tscn")

# 本地化按钮处理
func _on_localization_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/localization_test.tscn")

# 棋盘按钮处理
func _on_board_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/board_test.tscn")

# 战斗按钮处理
func _on_battle_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/battle_test.tscn")

# 地图按钮处理
func _on_map_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/map_test.tscn")

# UI按钮处理
func _on_ui_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/ui_test.tscn")

# 动画按钮处理
func _on_animation_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/animation_test.tscn")

# 对象池按钮处理
func _on_object_pool_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/object_pool_test.tscn")

# 资源管理器按钮处理
func _on_resource_manager_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/resource_manager_test.tscn")

# 性能监控按钮处理
func _on_performance_monitor_button_pressed():
    get_tree().change_scene_to_file("res://scenes/test/performance_test.tscn")

# 返回按钮处理
func _on_back_button_pressed():
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
