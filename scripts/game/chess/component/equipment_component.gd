extends Component
class_name EquipmentComponent
## 装备组件
## 管理棋子的装备和装备效果

# 信号
signal equipment_equipped(equipment, slot)
signal equipment_unequipped(equipment, slot)
signal equipment_effect_triggered(equipment, effect)

# 装备槽
enum EquipmentSlot {
	WEAPON,    # 武器槽
	ARMOR,     # 护甲槽
	ACCESSORY  # 饰品槽
}

# 装备数据
var equipment_slots: Dictionary = {
	EquipmentSlot.WEAPON: null,
	EquipmentSlot.ARMOR: null,
	EquipmentSlot.ACCESSORY: null
}

# 装备效果系统
var effect_system = null

# 初始化
func _init(p_owner = null, p_name: String = "EquipmentComponent"):
	super._init(p_owner, p_name)
	priority = 40  # 中等优先级

# 初始化组件
func initialize() -> void:
	# 创建装备效果系统
	effect_system = EquipmentEffectSystem.new()
	
	super.initialize()

# 装备物品
func equip_item(equipment, slot: int) -> bool:
	# 检查槽位是否有效
	if not equipment_slots.has(slot):
		return false
	
	# 检查槽位是否已有装备
	if equipment_slots[slot] != null:
		return false
	
	# 装备到槽位
	equipment_slots[slot] = equipment
	
	# 应用装备效果
	effect_system.apply_effects(equipment, owner)
	
	# 发送装备信号
	equipment_equipped.emit(equipment, slot)
	
	# 发送事件
	EventBus.equipment.emit_event("equipment_equipped", [equipment, owner])
	
	return true

# 卸下装备
func unequip_item(slot: int) -> bool:
	# 检查槽位是否有效
	if not equipment_slots.has(slot):
		return false
	
	# 检查槽位是否有装备
	if equipment_slots[slot] == null:
		return false
	
	# 获取装备
	var equipment = equipment_slots[slot]
	
	# 移除装备效果
	effect_system.remove_effects(equipment, owner)
	
	# 清空槽位
	equipment_slots[slot] = null
	
	# 发送卸下信号
	equipment_unequipped.emit(equipment, slot)
	
	# 发送事件
	EventBus.equipment.emit_event("equipment_unequipped", [equipment, owner])
	
	return true

# 获取装备
func get_equipment(slot: int):
	# 检查槽位是否有效
	if not equipment_slots.has(slot):
		return null
	
	return equipment_slots[slot]

# 获取所有装备
func get_all_equipment() -> Array:
	var result = []
	
	for slot in equipment_slots:
		var equipment = equipment_slots[slot]
		if equipment:
			result.append(equipment)
	
	return result

# 检查槽位是否有装备
func has_equipment(slot: int) -> bool:
	# 检查槽位是否有效
	if not equipment_slots.has(slot):
		return false
	
	return equipment_slots[slot] != null

# 检查是否有指定ID的装备
func has_equipment_id(equipment_id: String) -> bool:
	for slot in equipment_slots:
		var equipment = equipment_slots[slot]
		if equipment and equipment.id == equipment_id:
			return true
	
	return false

# 触发装备效果
func trigger_equipment_effect(trigger_type: String, context: Dictionary = {}) -> void:
	# 遍历所有装备
	for slot in equipment_slots:
		var equipment = equipment_slots[slot]
		if not equipment:
			continue
		
		# 触发装备效果
		var triggered_effects = effect_system.trigger_effects_by_type(equipment, trigger_type, context)
		
		# 发送效果触发信号
		for effect in triggered_effects:
			equipment_effect_triggered.emit(equipment, effect)

# 清除所有装备
func clear_equipment() -> void:
	# 卸下所有装备
	for slot in equipment_slots:
		unequip_item(slot)

# 从字典初始化装备
func initialize_from_dict(data: Dictionary) -> void:
	# 清除现有装备
	clear_equipment()
	
	# 装备新装备
	if data.has("weapon") and data.weapon:
		var equipment = GameManager.equipment_manager.get_equipment(data.weapon)
		if equipment:
			equip_item(equipment, EquipmentSlot.WEAPON)
	
	if data.has("armor") and data.armor:
		var equipment = GameManager.equipment_manager.get_equipment(data.armor)
		if equipment:
			equip_item(equipment, EquipmentSlot.ARMOR)
	
	if data.has("accessory") and data.accessory:
		var equipment = GameManager.equipment_manager.get_equipment(data.accessory)
		if equipment:
			equip_item(equipment, EquipmentSlot.ACCESSORY)

# 获取装备数据
func get_equipment_data() -> Dictionary:
	var result = {
		"weapon": null,
		"armor": null,
		"accessory": null
	}
	
	# 获取装备ID
	for slot in equipment_slots:
		var equipment = equipment_slots[slot]
		if equipment:
			match slot:
				EquipmentSlot.WEAPON:
					result.weapon = equipment.id
				EquipmentSlot.ARMOR:
					result.armor = equipment.id
				EquipmentSlot.ACCESSORY:
					result.accessory = equipment.id
	
	return result
