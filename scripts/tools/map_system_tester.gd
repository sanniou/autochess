@tool
extends EditorScript
## 地图系统测试工具
## 在编辑器中运行此脚本以测试地图系统

func _run() -> void:
    print("开始测试地图系统...")
    
    # 测试配置加载
    test_config_loading()
    
    # 测试地图生成
    test_map_generation()
    
    print("地图系统测试完成!")

## 测试配置加载
func test_config_loading() -> void:
    print("\n=== 测试配置加载 ===")
    
    # 创建配置对象
    var map_config = MapConfig.new()
    
    # 加载配置
    var success = map_config.load_from_json("res://config/map_config.json")
    print("配置加载结果: ", success)
    
    if not success:
        print("配置加载失败，测试终止")
        return
    
    # 检查模板
    print("模板数量: ", map_config.templates.size())
    for template_id in map_config.templates:
        print("模板: ", template_id)
    
    # 检查节点类型
    print("节点类型数量: ", map_config.node_types.size())
    for type_id in map_config.node_types:
        print("节点类型: ", type_id)

## 测试地图生成
func test_map_generation() -> void:
    print("\n=== 测试地图生成 ===")
    
    # 创建配置对象
    var map_config = MapConfig.new()
    map_config.load_from_json("res://config/map_config.json")
    
    # 创建地图生成器
    var map_generator = ProceduralMapGenerator.new()
    
    # 设置配置
    map_generator.map_config = map_config
    
    # 生成地图
    var seed_value = 12345
    print("使用种子值生成地图: ", seed_value)
    var current_map = map_generator.generate_map("standard", seed_value)
    
    # 检查地图
    if current_map:
        print("地图生成成功!")
        print("地图ID: ", current_map.id)
        print("模板ID: ", current_map.template_id)
        print("层数: ", current_map.layers)
        print("节点数: ", current_map.nodes.size())
        print("连接数: ", current_map.connections.size())
        
        # 测试节点
        print("\n测试节点...")
        
        # 按层获取节点
        for layer in range(current_map.layers):
            var layer_nodes = current_map.get_nodes_by_layer(layer)
            print("第 ", layer, " 层节点数: ", layer_nodes.size())
        
        # 按类型获取节点
        var start_nodes = current_map.get_nodes_by_type("start")
        print("起始节点数: ", start_nodes.size())
        
        var battle_nodes = current_map.get_nodes_by_type("battle")
        print("战斗节点数: ", battle_nodes.size())
        
        # 测试序列化
        print("\n测试序列化...")
        var map_dict = current_map.to_dict()
        print("地图字典大小: ", map_dict.size())
        
        var new_map = MapData.from_dict(map_dict)
        print("从字典创建地图成功!")
        print("新地图节点数: ", new_map.nodes.size())
        print("新地图连接数: ", new_map.connections.size())
    else:
        print("地图生成失败!")
