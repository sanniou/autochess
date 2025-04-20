extends Node
## 地图系统集成测试
## 测试新地图系统与游戏其他部分的集成

# 地图管理器
var map_manager: NewMapManager

func _ready() -> void:
    # 创建地图管理器
    map_manager = NewMapManager.new()
    add_child(map_manager)
    
    # 初始化地图管理器
    map_manager._do_initialize()
    
    # 连接信号
    map_manager.map_loaded.connect(_on_map_loaded)
    map_manager.node_selected.connect(_on_node_selected)
    map_manager.node_visited.connect(_on_node_visited)
    
    # 初始化地图
    print("初始化地图...")
    map_manager.initialize_map("standard", 1, 12345)

func _on_map_loaded(map_data: MapData) -> void:
    print("地图加载完成!")
    print("地图ID: ", map_data.id)
    print("模板ID: ", map_data.template_id)
    print("层数: ", map_data.layers)
    print("节点数: ", map_data.nodes.size())
    print("连接数: ", map_data.connections.size())
    
    # 获取当前节点
    var current_node = map_manager.current_node
    print("当前节点: ", current_node.id)
    
    # 获取可选节点
    var selectable_nodes = map_manager.get_selectable_nodes()
    print("可选节点数: ", selectable_nodes.size())
    
    # 如果有可选节点，选择第一个
    if not selectable_nodes.is_empty():
        var node_to_select = selectable_nodes[0]
        print("选择节点: ", node_to_select.id)
        map_manager.select_node(node_to_select.id)

func _on_node_selected(node_data: Dictionary) -> void:
    print("节点被选中: ", node_data.id)
    print("节点类型: ", node_data.type)
    
    # 访问节点
    map_manager.visit_node(node_data.id)

func _on_node_visited(node_data: Dictionary) -> void:
    print("节点被访问: ", node_data.id)
    
    # 获取新的可选节点
    var selectable_nodes = map_manager.get_selectable_nodes()
    print("新的可选节点数: ", selectable_nodes.size())
    
    # 如果有可选节点，选择第一个
    if not selectable_nodes.is_empty():
        var node_to_select = selectable_nodes[0]
        print("选择下一个节点: ", node_to_select.id)
        map_manager.select_node(node_to_select.id)
    else:
        print("没有更多可选节点，测试完成")
        get_tree().quit()
