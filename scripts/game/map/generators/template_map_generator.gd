extends MapGenerator
class_name TemplateMapGenerator
## 模板地图生成器
## 根据预定义的模板生成地图

# 模板路径
@export var template_path: String = ""

## 生成地图
func generate_map(template_id: String, seed_value: int = -1) -> MapData:
    # 如果没有指定模板路径，使用模板ID作为文件名
    var path = template_path
    if path.is_empty():
        path = "res://config/map_templates/" + template_id + ".json"
    
    # 加载模板文件
    if not FileAccess.file_exists(path):
        push_error("模板文件不存在: " + path)
        return null
    
    var file = FileAccess.open(path, FileAccess.READ)
    var json_text = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_text)
    
    if error != OK:
        push_error("解析模板文件失败: " + json.get_error_message())
        return null
    
    var template_data = json.data
    
    # 创建地图数据
    var map_data = MapData.new()
    
    # 设置随机种子
    if seed_value >= 0:
        seed(seed_value)
    else:
        randomize()
        seed_value = randi()
    
    # 初始化地图数据
    map_data.initialize(template_id, seed_value)
    map_data.name = template_data.get("name", "模板地图")
    map_data.description = template_data.get("description", "一张基于模板的地图")
    map_data.difficulty = template_data.get("difficulty", "normal")
    map_data.layers = template_data.get("layers", 5)
    
    # 加载节点
    for node_data in template_data.get("nodes", []):
        var node = MapNode.new()
        node.initialize(
            node_data.get("id", ""),
            node_data.get("type", ""),
            node_data.get("layer", 0),
            node_data.get("position", 0)
        )
        
        # 设置节点属性
        for key in node_data.get("properties", {}):
            node.set_property(key, node_data.properties[key])
        
        # 设置节点奖励
        for key in node_data.get("rewards", {}):
            node.add_reward(key, node_data.rewards[key])
        
        # 添加到地图
        map_data.add_node(node)
    
    # 加载连接
    for connection_data in template_data.get("connections", []):
        var connection = MapConnection.new()
        connection.initialize(
            connection_data.get("id", ""),
            connection_data.get("from_node_id", ""),
            connection_data.get("to_node_id", "")
        )
        
        # 设置连接属性
        for key in connection_data.get("properties", {}):
            connection.set_property(key, connection_data.properties[key])
        
        # 设置连接是否可通行
        connection.set_traversable(connection_data.get("traversable", true))
        
        # 添加到地图
        map_data.add_connection(connection)
        
        # 更新节点的连接信息
        var from_node = map_data.get_node_by_id(connection.from_node_id)
        var to_node = map_data.get_node_by_id(connection.to_node_id)
        
        if from_node and to_node:
            from_node.add_connection_to(to_node.id)
            to_node.add_connection_from(from_node.id)
    
    # 验证地图
    var errors = validate_map(map_data)
    if not errors.is_empty():
        push_error("模板地图无效: " + str(errors))
        return null
    
    # 发送生成信号
    map_generated.emit(map_data)
    
    return map_data
