extends Node
## 地图系统测试脚本
## 用于测试新地图系统的核心功能

# 地图组件
var map_config: MapConfig
var map_generator: ProceduralMapGenerator
var current_map: MapData

func _ready() -> void:
    print("开始测试地图系统...")
    
    # 测试配置加载
    test_config_loading()
    
    # 测试地图生成
    test_map_generation()
    
    # 测试地图节点和连接
    test_map_nodes_and_connections()
    
    # 测试地图序列化
    test_map_serialization()
    
    print("地图系统测试完成!")
    get_tree().quit()

## 测试配置加载
func test_config_loading() -> void:
    print("\n=== 测试配置加载 ===")
    
    # 创建配置对象
    map_config = MapConfig.new()
    
    # 加载配置
    var success = map_config.load_from_json("res://config/map_config.json")
    print("配置加载结果: ", success)
    
    # 验证配置
    var errors = map_config.validate()
    print("配置验证错误: ", errors)
    
    # 检查模板
    print("模板数量: ", map_config.templates.size())
    for template_id in map_config.templates:
        print("模板: ", template_id)
    
    # 检查节点类型
    print("节点类型数量: ", map_config.node_types.size())
    for type_id in map_config.node_types:
        print("节点类型: ", type_id)
    
    # 检查连接类型
    print("连接类型数量: ", map_config.connection_types.size())
    for type_id in map_config.connection_types:
        print("连接类型: ", type_id)
    
    # 检查战斗配置
    print("战斗配置数量: ", map_config.battle_configs.size())
    for config_id in map_config.battle_configs:
        print("战斗配置: ", config_id)

## 测试地图生成
func test_map_generation() -> void:
    print("\n=== 测试地图生成 ===")
    
    # 创建地图生成器
    map_generator = ProceduralMapGenerator.new()
    add_child(map_generator)
    
    # 设置配置
    map_generator.map_config = map_config
    
    # 生成地图
    var seed_value = 12345
    print("使用种子值生成地图: ", seed_value)
    current_map = map_generator.generate_map("standard", seed_value)
    
    # 检查地图
    if current_map:
        print("地图生成成功!")
        print("地图ID: ", current_map.id)
        print("模板ID: ", current_map.template_id)
        print("层数: ", current_map.layers)
        print("节点数: ", current_map.nodes.size())
        print("连接数: ", current_map.connections.size())
    else:
        print("地图生成失败!")

## 测试地图节点和连接
func test_map_nodes_and_connections() -> void:
    print("\n=== 测试地图节点和连接 ===")
    
    if not current_map:
        print("没有地图可测试!")
        return
    
    # 测试节点
    print("测试节点...")
    
    # 按层获取节点
    for layer in range(current_map.layers):
        var layer_nodes = current_map.get_nodes_by_layer(layer)
        print("第 ", layer, " 层节点数: ", layer_nodes.size())
    
    # 按类型获取节点
    var start_nodes = current_map.get_nodes_by_type("start")
    print("起始节点数: ", start_nodes.size())
    
    var battle_nodes = current_map.get_nodes_by_type("battle")
    print("战斗节点数: ", battle_nodes.size())
    
    # 测试连接
    print("测试连接...")
    
    # 获取起始节点的连接
    if not start_nodes.is_empty():
        var start_node = start_nodes[0]
        print("起始节点ID: ", start_node.id)
        
        var connections_from_start = current_map.get_connections_from_node(start_node.id)
        print("从起始节点出发的连接数: ", connections_from_start.size())
        
        var reachable_nodes = current_map.get_reachable_nodes(start_node.id)
        print("从起始节点可到达的节点数: ", reachable_nodes.size())
        
        # 测试路径
        if not reachable_nodes.is_empty():
            var target_node = reachable_nodes[0]
            print("目标节点ID: ", target_node.id)
            
            # 检查连接
            print("起始节点可以到达目标节点: ", start_node.can_reach(target_node.id))
            print("目标节点可以从起始节点到达: ", target_node.can_be_reached_from(start_node.id))

## 测试地图序列化
func test_map_serialization() -> void:
    print("\n=== 测试地图序列化 ===")
    
    if not current_map:
        print("没有地图可测试!")
        return
    
    # 转换为字典
    var map_dict = current_map.to_dict()
    print("地图字典大小: ", map_dict.size())
    
    # 从字典创建地图
    var new_map = MapData.from_dict(map_dict)
    print("从字典创建地图成功!")
    print("新地图ID: ", new_map.id)
    print("新地图节点数: ", new_map.nodes.size())
    print("新地图连接数: ", new_map.connections.size())
    
    # 比较两个地图
    print("原地图和新地图ID相同: ", current_map.id == new_map.id)
    print("原地图和新地图节点数相同: ", current_map.nodes.size() == new_map.nodes.size())
    print("原地图和新地图连接数相同: ", current_map.connections.size() == new_map.connections.size())
