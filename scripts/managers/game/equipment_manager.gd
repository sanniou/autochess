extends "res://scripts/managers/core/base_manager.gd"
class_name EquipmentManager
## 装备管理器
## 管理所有装备的创建和合成

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")

# 装备实例缓存 {装备ID: 装备实例}
var _equipment_cache: Dictionary = {}

# 引用
@onready var tier_manager: EquipmentTierManager = EquipmentTierManager.new()
@onready var combine_system: EquipmentCombineSystem = EquipmentCombineSystem.new()
@onready var effect_system: EquipmentEffectSystem = EquipmentEffectSystem.new()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EquipmentManager"

	# 添加依赖
	add_dependency("ConfigManager")

	# 添加装备拉格管理器
	add_child(tier_manager)

	# 添加装备合成系统
	add_child(combine_system)

	# 添加装备效果系统
	add_child(effect_system)

	# 连接信号
	EventBus.equipment.connect_event("equipment_combine_requested", _on_equipment_combine_requested)

	# 连接配置变更信号
	if not GameManager.config_manager.config_changed.is_connected(_on_config_changed):
		GameManager.config_manager.config_changed.connect(_on_config_changed)

	_log_info("装备管理器初始化完成")

## 配置变更回调
func _on_config_changed(config_type: String, config_id: String) -> void:
	# 检查是否是装备配置
	if config_type == ConfigTypes.int_to_string(ConfigTypes.Type.EQUIPMENT):
		# 如果缓存中存在该装备，则更新它
		if _equipment_cache.has(config_id):
			# 从缓存中移除
			_equipment_cache.erase(config_id)
			_log_info("装备配置已更新，已从缓存中移除: " + config_id)

# 获取装备实例
func get_equipment(equipment_id: String) -> Equipment:
	# 先从缓存查找
	if _equipment_cache.has(equipment_id):
		return _equipment_cache[equipment_id]

	# 从配置创建新实例
	var config = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.EQUIPMENT, equipment_id)
	if not config:
		_log_warning("无法获取装备配置: " + equipment_id)
		return null

	var equipment = Equipment.new()
	equipment.initialize(config)
	_equipment_cache[equipment_id] = equipment

	return equipment

# 批量获取装备实例
func get_equipments(equipment_ids: Array) -> Array:
	var result = []
	for id in equipment_ids:
		var equipment = get_equipment(id)
		if equipment:
			result.append(equipment)
	return result



# 合成装备
func combine_equipments(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 使用装备合成系统合成装备
	var result_equipment = combine_system.combine(equipment1, equipment2)

	if result_equipment:
		# 发送合成成功信号
		EventBus.equipment.emit_event("equipment_combined", [equipment1, equipment2, result_equipment])

	return result_equipment



# 装备合成请求处理
func _on_equipment_combine_requested(equipment1: Equipment, equipment2: Equipment):
	combine_equipments(equipment1, equipment2)

# 生成随机装备
func generate_random_equipment(base_equipment_id: String, tier: int = EquipmentTierManager.EquipmentTier.NORMAL) -> Equipment:
	# 使用装备等级管理器生成随机装备
	var equipment = tier_manager.generate_random_equipment(base_equipment_id, tier)

	# 将装备实例保存到缓存中
	if equipment:
		_equipment_cache[equipment.id] = equipment

	return equipment

# 升级装备品质
func upgrade_equipment_tier(equipment: Equipment, new_tier: int) -> Equipment:
	return tier_manager.upgrade_equipment_tier(equipment, new_tier)

# 获取装备品质颜色
func get_equipment_tier_color(tier: int) -> Color:
	return tier_manager.get_tier_color(tier)

# 获取装备品质名称
func get_equipment_tier_name(tier: int) -> String:
	return tier_manager.get_tier_name(tier)

# 从装备ID获取品质
func get_tier_from_equipment_id(equipment_id: String) -> int:
	return tier_manager.get_tier_from_id(equipment_id)

# 检查两个装备是否可以合成
func can_combine_equipments(equipment1: Equipment, equipment2: Equipment) -> bool:
	return combine_system.can_combine(equipment1, equipment2)

# 获取可能的合成结果
func get_possible_combinations(equipment: Equipment) -> Array:
	return combine_system.get_possible_combinations(equipment)



# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus:
			EventBus.equipment.disconnect_event("equipment_combine_requested", _on_equipment_combine_requested)

	# 断开配置变更信号连接
	if GameManager and GameManager.config_manager:
		if GameManager.config_manager.config_changed.is_connected(_on_config_changed):
			GameManager.config_manager.config_changed.disconnect(_on_config_changed)

	# 清理装备缓存
	_equipment_cache.clear()

	# 清理装备拉格管理器、合成系统和效果系统
	if tier_manager:
		tier_manager.queue_free()
		tier_manager = null

	if combine_system:
		combine_system.queue_free()
		combine_system = null

	if effect_system:
		effect_system.queue_free()
		effect_system = null

	_log_info("装备管理器清理完成")

# 重写重置方法
func _do_reset() -> void:
	# 清理装备缓存
	_equipment_cache.clear()

	_log_info("装备管理器重置完成")
