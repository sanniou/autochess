extends "res://scripts/core/base_manager.gd"
class_name EquipmentManager
## 装备管理器
## 管理所有装备的创建、合成和商店逻辑

# 装备缓存 {装备ID: 装备实例}
var _equipment_cache: Dictionary = {}

# 商店库存
var _shop_inventory: Array = []

# 引用
@onready var config_manager: ConfigManager = get_node("/root/GameManager/ConfigManager")
@onready var tier_manager: EquipmentTierManager = EquipmentTierManager.new()
@onready var combine_system: EquipmentCombineSystem = EquipmentCombineSystem.new()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "EquipmentManager"
	
	# 原 _ready 函数的内容
	# 添加装备拉格管理器
		add_child(tier_manager)
	
		# 添加装备合成系统
		add_child(combine_system)
	
		# 连接信号
		EventBus.economy.shop_refresh_requested.connect(_on_shop_refresh_requested)
		EventBus.equipment.equipment_combine_requested.connect(_on_equipment_combine_requested)
	
	# 获取装备实例
func get_equipment(equipment_id: String) -> Equipment:
	# 先从缓存查找
	if _equipment_cache.has(equipment_id):
		return _equipment_cache[equipment_id]

	# 从配置创建新实例
	var config = config_manager.get_equipment(equipment_id)
	if not config:
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

# 刷新商店库存
func refresh_shop_inventory(count: int = 5, player_level: int = 1, shop_tier: int = 1):
	_shop_inventory.clear()

	# 根据玩家等级获取可生成的装备
	var available_equipments = config_manager.get_equipments_by_rarity(get_available_rarities(player_level))

	# 随机选择装备
	for i in range(count):
		if available_equipments.is_empty():
			break

		var random_index = randi() % available_equipments.size()
		var base_equipment_id = available_equipments[random_index]

		# 决定装备品质
		var tier_chances = {
			EquipmentTierManager.EquipmentTier.NORMAL: 0.5,
			EquipmentTierManager.EquipmentTier.MAGIC: 0.3,
			EquipmentTierManager.EquipmentTier.RARE: 0.15,
			EquipmentTierManager.EquipmentTier.EPIC: 0.04,
			EquipmentTierManager.EquipmentTier.LEGENDARY: 0.01
		}

		# 根据玩家等级和商店等级调整品质概率
		var level_factor = min(player_level / 10.0, 1.0)  # 玩家等级因子，最高10级
		var shop_factor = min(shop_tier / 3.0, 1.0)  # 商店等级因子，最高3级

		# 调整概率
		tier_chances[EquipmentTierManager.EquipmentTier.NORMAL] -= 0.3 * (level_factor + shop_factor) / 2.0
		tier_chances[EquipmentTierManager.EquipmentTier.MAGIC] += 0.1 * (level_factor + shop_factor) / 2.0
		tier_chances[EquipmentTierManager.EquipmentTier.RARE] += 0.1 * (level_factor + shop_factor) / 2.0
		tier_chances[EquipmentTierManager.EquipmentTier.EPIC] += 0.07 * (level_factor + shop_factor) / 2.0
		tier_chances[EquipmentTierManager.EquipmentTier.LEGENDARY] += 0.03 * (level_factor + shop_factor) / 2.0

		# 确保概率合理
		for tier in tier_chances:
			tier_chances[tier] = max(0.0, min(tier_chances[tier], 1.0))

		# 随机选择品质
		var selected_tier = EquipmentTierManager.EquipmentTier.NORMAL
		var rand = randf()
		var cumulative_chance = 0.0

		for tier in tier_chances:
			cumulative_chance += tier_chances[tier]
			if rand <= cumulative_chance:
				selected_tier = tier
				break

		# 创建装备实例
		var equipment = generate_random_equipment(base_equipment_id, selected_tier)
		if equipment:
			_shop_inventory.append(equipment.id)

	# 发送商店刷新信号
	EventBus.economy.shop_inventory_updated.emit(_shop_inventory)

# 获取当前商店库存
func get_shop_inventory() -> Array:
	return _shop_inventory.duplicate()

# 购买装备
func purchase_equipment(equipment_id: String) -> Equipment:
	if not equipment_id in _shop_inventory:
		return null

	# 从库存移除
	_shop_inventory.erase(equipment_id)

	# 返回装备实例
	return get_equipment(equipment_id)

# 合成装备
func combine_equipments(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 使用装备合成系统合成装备
	var result_equipment = combine_system.combine(equipment1, equipment2)

	if result_equipment:
		# 发送合成成功信号
		EventBus.equipment.equipment_combined.emit(equipment1, equipment2, result_equipment)

	return result_equipment

# 根据玩家等级获取可用稀有度
func get_available_rarities(player_level: int) -> Array:
	var rarities = ["common"]

	if player_level >= 3:
		rarities.append("rare")
	if player_level >= 6:
		rarities.append("epic")
	if player_level >= 9:
		rarities.append("legendary")

	return rarities

# 商店刷新请求处理
func _on_shop_refresh_requested(player_level: int, shop_tier: int = 1):
	refresh_shop_inventory(5, player_level, shop_tier)

# 装备合成请求处理
func _on_equipment_combine_requested(equipment1: Equipment, equipment2: Equipment):
	combine_equipments(equipment1, equipment2)

# 生成随机装备
func generate_random_equipment(base_equipment_id: String, tier: int = EquipmentTierManager.EquipmentTier.NORMAL) -> Equipment:
	return tier_manager.generate_random_equipment(base_equipment_id, tier)

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

# 重置管理器
func reset():
	_equipment_cache.clear()
	_shop_inventory.clear()

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.debug_message.emit(error_message, 2)
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.debug_message.emit(info_message, 0)
