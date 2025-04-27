extends RefCounted
class_name MapEvents
## 地图事件类型
## 定义与地图系统相关的事件

## 地图加载事件
class MapLoadedEvent extends BusEvent:
	## 地图数据
	var map_data: MapData

	## 初始化
	func _init(p_map_data: MapData):
		map_data = p_map_data

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_loaded"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapLoadedEvent[map_id=%s]" % [map_data.id if map_data else "null"]

	## 克隆事件
	func clone() -> BusEvent:
		var event = MapLoadedEvent.new(map_data)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 地图清除事件
class MapClearedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_cleared"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapClearedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = MapClearedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 地图生成事件
class MapGeneratedEvent extends BusEvent:
	## 地图ID
	var map_id: String

	## 地图数据
	var map_data: Dictionary

	## 初始化
	func _init(p_map_id: String, p_map_data: Dictionary):
		map_id = p_map_id
		map_data = p_map_data

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_generated"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapGeneratedEvent[map_id=%s, nodes=%d]" % [
			map_id, map_data.get("nodes", []).size()
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = MapGeneratedEvent.new(map_id, map_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 地图节点选择事件
class MapNodeSelectedEvent extends BusEvent:
	## 节点ID
	var node_id: String

	## 节点类型
	var node_type: String

	## 节点数据
	var node_data: Dictionary

	## 初始化
	func _init(p_node_id: String, p_node_type: String, p_node_data: Dictionary):
		node_id = p_node_id
		node_type = p_node_type
		node_data = p_node_data

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_node_selected"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapNodeSelectedEvent[node_id=%s, node_type=%s]" % [
			node_id, node_type
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = MapNodeSelectedEvent.new(node_id, node_type, node_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 地图节点访问事件
class MapNodeVisitedEvent extends BusEvent:
	## 节点ID
	var node_id: String

	## 节点类型
	var node_type: String

	## 节点数据
	var node_data: Dictionary

	## 初始化
	func _init(p_node_id: String, p_node_type: String, p_node_data: Dictionary):
		node_id = p_node_id
		node_type = p_node_type
		node_data = p_node_data

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_node_visited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapNodeVisitedEvent[node_id=%s, node_type=%s]" % [
			node_id, node_type
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = MapNodeVisitedEvent.new(node_id, node_type, node_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 地图节点悬停事件
class MapNodeUnhoveredEvent extends BusEvent:
	## 节点ID
	var node_id: String

	## 节点类型
	var node_type: String

	## 节点数据
	var node_data: Dictionary

	## 是否悬停
	var is_hovered: bool

	## 初始化
	func _init(p_node_id: String, p_node_type: String, p_node_data: Dictionary, p_is_hovered: bool):
		node_id = p_node_id
		node_type = p_node_type
		node_data = p_node_data
		is_hovered = p_is_hovered

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_node_unhovered"

## 地图节点悬停事件
class MapNodeHoveredEvent extends BusEvent:
	## 节点ID
	var node_id: String

	## 节点类型
	var node_type: String

	## 节点数据
	var node_data: Dictionary

	## 是否悬停
	var is_hovered: bool

	## 初始化
	func _init(p_node_id: String, p_node_type: String, p_node_data: Dictionary, p_is_hovered: bool):
		node_id = p_node_id
		node_type = p_node_type
		node_data = p_node_data
		is_hovered = p_is_hovered

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_node_hovered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapNodeHoveredEvent[node_id=%s, node_type=%s, is_hovered=%s]" % [
			node_id, node_type, is_hovered
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = MapNodeHoveredEvent.new(node_id, node_type, node_data.duplicate(true), is_hovered)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 地图完成事件
class MapCompletedEvent extends BusEvent:
	## 地图ID
	var map_id: String

	## 完成时间
	var completion_time: float

	## 访问的节点数
	var visited_nodes: int

	## 初始化
	func _init(p_map_id: String, p_completion_time: float, p_visited_nodes: int):
		map_id = p_map_id
		completion_time = p_completion_time
		visited_nodes = p_visited_nodes

	## 获取事件类型
	static func get_type() -> String:
		return "map.map_completed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapCompletedEvent[map_id=%s, completion_time=%.1f, visited_nodes=%d]" % [
			map_id, completion_time, visited_nodes
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = MapCompletedEvent.new(map_id, completion_time, visited_nodes)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 装备升级事件
class EquipmentUpgradedEvent extends BusEvent:

	var selected_equipment: Dictionary
	
	var success:bool

	## 初始化
	func _init(p_selected_equipment: Dictionary, p_success: bool):
		selected_equipment=p_selected_equipment
		success=p_success

	## 获取事件类型
	static func get_type() -> String:
		return "map.equipment_upgraded"

## 祭坛献祭事件
class AltarSacrificeMadeEvent extends BusEvent:
	
	var altar_type: String
	
	var altar_data: Dictionary

	## 初始化
	func _init(p_altar_type: String, p_altar_data: Dictionary):
		altar_type = p_altar_type
		altar_data = p_altar_data

	## 获取事件类型
	static func get_type() -> String:
		return "map.altar_sacrifice_made"

class TreasureCollectedEvent extends BusEvent:
	## 奖励数据
	var rewards: Dictionary

	## 初始化
	func _init(p_rewards: Dictionary):
		rewards = p_rewards

	## 获取事件类型
	static func get_type() -> String:
		return "map.treasure_collected"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TreasureCollectedEvent[rewards=%s]" % [rewards]

	## 克隆事件
	func clone() -> BusEvent:
		var event = TreasureCollectedEvent.new(rewards.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

class RestCompletedEvent extends BusEvent:
	## 地图节点
	var mapNode: MapNode

	## 初始化
	func _init(p_mapNode: MapNode):
		mapNode = p_mapNode

	## 获取事件类型
	static func get_type() -> String:
		return "map.rest_completed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RestCompletedEvent[node_id=%s]" % [mapNode.id if mapNode else "null"]

	## 克隆事件
	func clone() -> BusEvent:
		var event = RestCompletedEvent.new(mapNode)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 路径高亮事件
class MapPathHighlightedEvent extends BusEvent:
	## 路径节点
	var path_nodes: Array

	## 初始化
	func _init(p_path_nodes: Array):
		path_nodes = p_path_nodes

	## 获取事件类型
	static func get_type() -> String:
		return "map.path_highlighted"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapPathHighlightedEvent[nodes=%d]" % [path_nodes.size()]

	## 克隆事件
	func clone() -> BusEvent:
		var event = MapPathHighlightedEvent.new(path_nodes.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 路径高亮清除事件
class MapPathHighlightClearedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "map.path_highlight_cleared"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapPathHighlightClearedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = MapPathHighlightClearedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event
