extends RefCounted
class_name EquipmentEvents
## 装备事件类型
## 定义与装备系统相关的事件

## 装备创建事件
class EquipmentCreatedEvent extends BusEvent:
	## 装备ID
	var equipment: Equipment
	
	## 初始化
	func _init(p_equipment: Equipment):
		equipment = p_equipment

## 装备合成事件
class EquipmentCombinedEvent extends BusEvent:
	## 材料装备ID列表
	var material_ids: Array
	
	## 结果装备ID
	var result_id: String
	
	## 结果装备数据
	var result_data: Equipment
	
	## 初始化
	func _init(p_material_ids: Array, p_result_id: String, p_result_data: Equipment):
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
	func clone() ->BusEvent:
		var event = EquipmentCombinedEvent.new(material_ids.duplicate(), result_id, result_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 装备装备事件
class EquipmentEquippedEvent extends BusEvent:

	## 装备数据
	var equipment: Equipment
	
	## 装备者
	var wearer
	
	## 初始化
	func _init( p_equipment_data: Equipment, p_wearer):
		equipment = p_equipment_data
		wearer = p_wearer


## 装备卸下事件
class EquipmentUnequippedEvent extends BusEvent:
	## 装备数据
	var equipment_data: Equipment
	
	## 装备者
	var wearer
	
	## 初始化
	func _init( p_equipment_data: Equipment, p_wearer):
		equipment_data = p_equipment_data
		wearer = p_wearer

class EquipmentEffectTriggeredEvent extends BusEvent:
	## 装备数据
	var equipment_data: Equipment
	
	var effect_data:Dictionary
	
	## 初始化
	func _init( p_equipment_data: Equipment, p_effect_data:Dictionary):
		equipment_data = p_equipment_data
		effect_data = effect_data

class EquipmentTierChangedEvent extends BusEvent:
	var original_id: String
	var tier: int
	var config:Dictionary
	
	## 初始化
	func _init( p_original_id: String, p_tier:int,p_config:Dictionary):
		original_id = p_original_id
		tier = p_tier
		config = p_config

class EquipmentCombineAnimationStartedEvent extends BusEvent:
	var equipment1: Equipment 
	var equipment2: Equipment 
	var result: Equipment
	
	## 初始化
	func _init(p_equipment1: Equipment, p_equipment2: Equipment, p_result: Equipment):
		equipment1 = p_equipment1
		equipment2 = p_equipment2
		result = p_result

class EquipmentCombineAnimationCompletedEvent extends BusEvent:
	var equipment1: Equipment 
	var equipment2: Equipment 
	var result: Equipment
	
	## 初始化
	func _init(p_equipment1: Equipment, p_equipment2: Equipment, p_result: Equipment):
		equipment1 = p_equipment1
		equipment2 = p_equipment2
		result = p_result
