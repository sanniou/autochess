extends RefCounted
class_name EquipmentEvents
## 装备事件类型
## 定义与装备系统相关的事件

## 装备创建事件
class EquipmentCreatedEvent extends Event:
	## 装备ID
	var equipment_id: String
	
	## 装备数据
	var equipment_data: Dictionary
	
	## 初始化
	func _init(p_equipment_id: String, p_equipment_data: Dictionary):
		equipment_id = p_equipment_id
		equipment_data = p_equipment_data
	
	## 获取事件类型
	func get_type() -> String:
		return "equipment.equipment_created"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentCreatedEvent[equipment_id=%s]" % [equipment_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = EquipmentCreatedEvent.new(equipment_id, equipment_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 装备合成事件
class EquipmentCombinedEvent extends Event:
	## 材料装备ID列表
	var material_ids: Array
	
	## 结果装备ID
	var result_id: String
	
	## 结果装备数据
	var result_data: Dictionary
	
	## 初始化
	func _init(p_material_ids: Array, p_result_id: String, p_result_data: Dictionary):
		material_ids = p_material_ids
		result_id = p_result_id
		result_data = p_result_data
	
	## 获取事件类型
	func get_type() -> String:
		return "equipment.equipment_combined"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentCombinedEvent[material_ids=%s, result_id=%s]" % [
			material_ids, result_id
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = EquipmentCombinedEvent.new(material_ids.duplicate(), result_id, result_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 装备装备事件
class EquipmentEquippedEvent extends Event:
	## 装备ID
	var equipment_id: String
	
	## 装备数据
	var equipment_data: Dictionary
	
	## 装备者
	var wearer
	
	## 初始化
	func _init(p_equipment_id: String, p_equipment_data: Dictionary, p_wearer):
		equipment_id = p_equipment_id
		equipment_data = p_equipment_data
		wearer = p_wearer
	
	## 获取事件类型
	func get_type() -> String:
		return "equipment.equipment_equipped"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentEquippedEvent[equipment_id=%s, wearer=%s]" % [
			equipment_id, wearer
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = EquipmentEquippedEvent.new(equipment_id, equipment_data.duplicate(true), wearer)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 装备卸下事件
class EquipmentUnequippedEvent extends Event:
	## 装备ID
	var equipment_id: String
	
	## 装备数据
	var equipment_data: Dictionary
	
	## 装备者
	var wearer
	
	## 初始化
	func _init(p_equipment_id: String, p_equipment_data: Dictionary, p_wearer):
		equipment_id = p_equipment_id
		equipment_data = p_equipment_data
		wearer = p_wearer
	
	## 获取事件类型
	func get_type() -> String:
		return "equipment.equipment_unequipped"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EquipmentUnequippedEvent[equipment_id=%s, wearer=%s]" % [
			equipment_id, wearer
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = EquipmentUnequippedEvent.new(equipment_id, equipment_data.duplicate(true), wearer)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
