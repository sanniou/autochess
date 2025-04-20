extends Node
class_name MapRenderer
## 地图渲染器基类
## 定义地图渲染器的基本接口

# 渲染信号
signal node_clicked(node_data)
signal node_hovered(node_data)
signal node_unhovered(node_data)

# 地图数据
var map_data: MapData = null

# 渲染设置
@export var node_scene: PackedScene
@export var connection_scene: PackedScene
@export var container: Control

# 节点实例字典
var node_instances = {}
var connection_instances = {}

# 当前选中的节点
var selected_node: MapNode = null
var current_player_node: MapNode = null

## 设置地图数据
func set_map_data(data: MapData) -> void:
    map_data = data

## 渲染地图
## 这是一个虚函数，子类需要实现
func render_map() -> void:
    push_error("MapRenderer.render_map() 是一个虚函数，子类需要实现")

## 清除地图
func clear_map() -> void:
    # 清除节点实例
    for node_id in node_instances:
        if is_instance_valid(node_instances[node_id]):
            node_instances[node_id].queue_free()
    
    # 清除连接实例
    for connection_id in connection_instances:
        if is_instance_valid(connection_instances[connection_id]):
            connection_instances[connection_id].queue_free()
    
    # 重置字典
    node_instances = {}
    connection_instances = {}

## 选择节点
func select_node(node_id: String) -> void:
    if not map_data:
        return
    
    var node = map_data.get_node_by_id(node_id)
    if not node:
        return
    
    # 更新选中的节点
    selected_node = node
    
    # 更新节点实例的状态
    if node_instances.has(node_id):
        node_instances[node_id].set_selected(true)
    
    # 发送信号
    node_clicked.emit(node)

## 设置当前玩家节点
func set_current_player_node(node_id: String) -> void:
    if not map_data:
        return
    
    var node = map_data.get_node_by_id(node_id)
    if not node:
        return
    
    # 更新当前玩家节点
    current_player_node = node
    
    # 更新节点实例的状态
    if node_instances.has(node_id):
        node_instances[node_id].set_current(true)
    
    # 更新可到达节点的状态
    _update_reachable_nodes()

## 更新可到达节点
func _update_reachable_nodes() -> void:
    if not map_data or not current_player_node:
        return
    
    # 获取可到达的节点
    var reachable_nodes = map_data.get_reachable_nodes(current_player_node.id)
    
    # 更新所有节点的可到达状态
    for node_id in node_instances:
        var is_reachable = false
        for reachable_node in reachable_nodes:
            if reachable_node.id == node_id:
                is_reachable = true
                break
        
        node_instances[node_id].set_reachable(is_reachable)

## 处理节点点击事件
func _on_node_clicked(node_id: String) -> void:
    select_node(node_id)

## 处理节点悬停事件
func _on_node_hovered(node_id: String) -> void:
    if not map_data:
        return
    
    var node = map_data.get_node_by_id(node_id)
    if not node:
        return
    
    # 发送信号
    node_hovered.emit(node)

## 处理节点取消悬停事件
func _on_node_unhovered(node_id: String) -> void:
    if not map_data:
        return
    
    var node = map_data.get_node_by_id(node_id)
    if not node:
        return
    
    # 发送信号
    node_unhovered.emit(node)
