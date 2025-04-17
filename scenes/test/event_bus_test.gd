extends Control

# 引用
@onready var event_list = $EventList
@onready var trigger_button = $TriggerButton
@onready var clear_button = $ClearButton
@onready var back_button = $BackButton

# 测试事件类型
var test_events = [
    "game_started",
    "game_ended",
    "player_died",
    "chess_piece_created",
    "chess_piece_upgraded",
    "damage_dealt",
    "gold_changed",
    "map_node_selected"
]

# 初始化
func _ready():
    # 连接按钮信号
    trigger_button.pressed.connect(_on_trigger_button_pressed)
    clear_button.pressed.connect(_on_clear_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 连接测试事件
    _connect_test_events()
    
    # 更新UI
    _update_event_list()

# 连接测试事件
func _connect_test_events():
    # 连接所有测试事件
    EventBus.game.game_started.connect(func(): _on_event_triggered("game_started"))
    EventBus.game.game_ended.connect(func(): _on_event_triggered("game_ended"))
    EventBus.game.player_died.connect(func(): _on_event_triggered("player_died"))
    EventBus.chess.chess_piece_created.connect(func(piece): _on_event_triggered("chess_piece_created"))
    EventBus.chess.chess_piece_upgraded.connect(func(piece): _on_event_triggered("chess_piece_upgraded"))
    EventBus.battle.damage_dealt.connect(func(attacker, defender, damage, type): _on_event_triggered("damage_dealt"))
    EventBus.economy.gold_changed.connect(func(old_value, new_value): _on_event_triggered("gold_changed"))
    EventBus.map.map_node_selected.connect(func(node_data): _on_event_triggered("map_node_selected"))

# 触发按钮处理
func _on_trigger_button_pressed():
    # 随机选择一个事件触发
    var event = test_events[randi() % test_events.size()]
    
    # 根据事件类型触发不同的事件
    match event:
        "game_started":
            EventBus.game.game_started.emit()
        "game_ended":
            EventBus.game.game_ended.emit()
        "player_died":
            EventBus.game.player_died.emit()
        "chess_piece_created":
            # 创建一个模拟棋子
            var mock_piece = {"id": "test_piece", "name": "Test Piece"}
            EventBus.chess.chess_piece_created.emit(mock_piece)
        "chess_piece_upgraded":
            # 创建一个模拟棋子
            var mock_piece = {"id": "test_piece", "name": "Test Piece", "level": 2}
            EventBus.chess.chess_piece_upgraded.emit(mock_piece)
        "damage_dealt":
            # 创建模拟攻击者和防御者
            var mock_attacker = {"id": "attacker", "name": "Attacker"}
            var mock_defender = {"id": "defender", "name": "Defender"}
            EventBus.battle.damage_dealt.emit(mock_attacker, mock_defender, 100, "physical")
        "gold_changed":
            EventBus.economy.gold_changed.emit(100, 150)
        "map_node_selected":
            # 创建模拟节点数据
            var mock_node = {"id": "node_1", "type": "battle", "difficulty": 1}
            EventBus.map.map_node_selected.emit(mock_node)

# 事件触发处理
func _on_event_triggered(event_name):
    # 添加事件到列表
    event_list.add_item(event_name + " - " + Time.get_time_string_from_system())
    
    # 滚动到底部
    event_list.ensure_current_is_visible()

# 清除按钮处理
func _on_clear_button_pressed():
    # 清除事件列表
    event_list.clear()

# 返回按钮处理
func _on_back_button_pressed():
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")

# 更新事件列表
func _update_event_list():
    # 清除列表
    event_list.clear()
    
    # 添加标题
    event_list.add_item("事件监听器已启动，等待事件触发...")
