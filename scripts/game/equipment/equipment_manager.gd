extends Node
class_name EquipmentManager
## 装备管理器
## 管理所有装备的创建、合成和商店逻辑

# 装备缓存 {装备ID: 装备实例}
var _equipment_cache: Dictionary = {}

# 商店库存
var _shop_inventory: Array = []

# 引用
@onready var config_manager: ConfigManager = get_node("/root/GameManager/ConfigManager")

func _ready():
	# 连接信号
	EventBus.shop_refresh_requested.connect(_on_shop_refresh_requested)
	EventBus.equipment_combine_requested.connect(_on_equipment_combine_requested)

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
func refresh_shop_inventory(count: int = 5, player_level: int = 1):
	_shop_inventory.clear()
	
	# 根据玩家等级获取可生成的装备
	var available_equipments = config_manager.get_equipments_by_rarity(get_available_rarities(player_level))
	
	# 随机选择装备
	for i in range(count):
		if available_equipments.is_empty():
			break
		
		var random_index = randi() % available_equipments.size()
		var equipment_id = available_equipments[random_index]
		_shop_inventory.append(equipment_id)
	
	# 发送商店刷新信号
	EventBus.shop_inventory_updated.emit(_shop_inventory)

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
	# 检查是否可以合成
	var result_id = equipment1.get_combine_result(equipment2)
	if result_id.is_empty():
		result_id = equipment2.get_combine_result(equipment1)
		if result_id.is_empty():
			return null
	
	# 创建合成后的装备
	var result_equipment = get_equipment(result_id)
	
	# 发送合成成功信号
	EventBus.equipment_combined.emit(equipment1, equipment2, result_equipment)
	
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
func _on_shop_refresh_requested(player_level: int):
	refresh_shop_inventory(5, player_level)

# 装备合成请求处理
func _on_equipment_combine_requested(equipment1: Equipment, equipment2: Equipment):
	combine_equipments(equipment1, equipment2)

# 重置管理器
func reset():
	_equipment_cache.clear()
	_shop_inventory.clear()
