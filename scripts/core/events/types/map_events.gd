extends RefCounted
class_name MapEvents
## 地图事件类型
## 定义与地图系统相关的事件

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
	## 装备ID
	var equipment_id: String
	
	## 旧等级
	var old_level: int
	
	## 新等级
	var new_level: int
	
	## 升级成本
	var upgrade_cost: int
	
	## 初始化
	func _init(p_equipment_id: String, p_old_level: int, p_new_level: int, p_upgrade_cost: int):
		equipment_id = p_equipment_id
		old_level = p_old_level
		new_level = p_new_level
		upgrade_cost = p_upgrade_cost
	
	## 获取事件类型
	static func get_type() -> String:
		return "map.equipment_upgraded"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentUpgradedEvent[equipment_id=%s, old_level=%d, new_level=%d, upgrade_cost=%d]" % [
			equipment_id, old_level, new_level, upgrade_cost
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = EquipmentUpgradedEvent.new(equipment_id, old_level, new_level, upgrade_cost)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 祭坛献祭事件
class AltarSacrificeMadeEvent extends BusEvent:
	## 献祭的棋子ID
	var chess_id: String
	
	## 献祭的棋子数据
	var chess_data: Dictionary
	
	## 获得的奖励
	var rewards: Array
	
	## 初始化
	func _init(p_chess_id: String, p_chess_data: Dictionary, p_rewards: Array):
		chess_id = p_chess_id
		chess_data = p_chess_data
		rewards = p_rewards
	
	## 获取事件类型
	static func get_type() -> String:
		return "map.altar_sacrifice_made"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AltarSacrificeMadeEvent[chess_id=%s, rewards=%d]" % [
			chess_id, rewards.size()
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AltarSacrificeMadeEvent.new(chess_id, chess_data.duplicate(true), rewards.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

class TreasureCollectedEvent extends BusEvent:
	var rewards: Dictionary
	
	func _init(rewards: Dictionary):
		self.rewards=rewards

class RestCompletedEvent extends BusEvent:
	var mapNode: MapNode
	
	func _init(mapNode: MapNode):
		self.mapNode=mapNode
