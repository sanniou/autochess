extends Node
class_name EquipmentCombineSystem
## 装备合成系统
## 负责管理装备的合成规则和合成逻辑

# 合成规则
# 1. 相同基础装备可以合成更高品质的装备
# 2. 不同基础装备可以合成新的装备（根据合成配方）
# 3. 高品质装备可以用于合成特殊装备

# 引用
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var config_manager = get_node("/root/GameManager/ConfigManager")

# 合成配方 {[装备ID1, 装备ID2]: 结果装备ID}
var _combine_recipes = {}

func _ready():
	# 加载合成配方
	_load_combine_recipes()

# 加载合成配方
func _load_combine_recipes():
	var recipes = config_manager.get_equipment_recipes()
	for recipe in recipes:
		if recipe.has("ingredients") and recipe.has("result"):
			var ingredients = recipe.ingredients
			if ingredients.size() == 2:
				# 创建配方键
				var recipe_key = ingredients.duplicate()
				recipe_key.sort()  # 排序以确保顺序无关
				var key_str = JSON.stringify(recipe_key)

				# 保存配方
				_combine_recipes[key_str] = recipe.result

# 检查两个装备是否可以合成
func can_combine(equipment1: Equipment, equipment2: Equipment) -> bool:
	# 检查相同基础装备合成
	if _can_combine_same_base(equipment1, equipment2):
		return true

	# 检查配方合成
	if _can_combine_by_recipe(equipment1, equipment2):
		return true

	return false

# 合成两个装备
func combine(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 尝试相同基础装备合成
	var result = _combine_same_base(equipment1, equipment2)
	if result:
		# 创建合成动画
		_create_combine_animation(equipment1, equipment2, result)
		return result

	# 尝试配方合成
	result = _combine_by_recipe(equipment1, equipment2)
	if result:
		# 创建合成动画
		_create_combine_animation(equipment1, equipment2, result)
		return result

	return null

# 创建合成动画
func _create_combine_animation(equipment1: Equipment, equipment2: Equipment, result: Equipment) -> void:
	# 发送合成动画信号
	EventBus.equipment.equipment_combine_animation_started.emit(equipment1, equipment2, result)

	# 在合成动画完成后发送合成完成信号
	var timer = get_tree().create_timer(1.0) # 假设动画时间1秒
	timer.timeout.connect(func():
		EventBus.equipment.equipment_combine_animation_completed.emit(equipment1, equipment2, result)
	)

# 检查两个相同基础装备是否可以合成
func _can_combine_same_base(equipment1: Equipment, equipment2: Equipment) -> bool:
	# 获取基础ID（去除品质后缀）
	var base_id1 = _get_base_id(equipment1.id)
	var base_id2 = _get_base_id(equipment2.id)

	# 基础ID必须相同
	if base_id1 != base_id2:
		return false

	# 品质必须相同
	var tier1 = equipment_manager.get_tier_from_equipment_id(equipment1.id)
	var tier2 = equipment_manager.get_tier_from_equipment_id(equipment2.id)

	if tier1 != tier2:
		return false

	# 不能是传说品质（已经是最高品质）
	if tier1 == EquipmentTierManager.EquipmentTier.LEGENDARY:
		return false

	return true

# 合成两个相同基础装备
func _combine_same_base(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	if not _can_combine_same_base(equipment1, equipment2):
		return null

	# 获取基础ID
	var base_id = _get_base_id(equipment1.id)

	# 获取当前品质
	var current_tier = equipment_manager.get_tier_from_equipment_id(equipment1.id)

	# 计算新品质
	var new_tier = current_tier + 1

	# 创建新装备
	return equipment_manager.generate_random_equipment(base_id, new_tier)

# 检查两个装备是否可以通过配方合成
func _can_combine_by_recipe(equipment1: Equipment, equipment2: Equipment) -> bool:
	# 创建配方键
	var recipe_key = [equipment1.id, equipment2.id]
	recipe_key.sort()
	var key_str = JSON.stringify(recipe_key)

	# 检查是否有匹配的配方
	return _combine_recipes.has(key_str)

# 通过配方合成两个装备
func _combine_by_recipe(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	if not _can_combine_by_recipe(equipment1, equipment2):
		return null

	# 创建配方键
	var recipe_key = [equipment1.id, equipment2.id]
	recipe_key.sort()
	var key_str = JSON.stringify(recipe_key)

	# 获取结果装备ID
	var result_id = _combine_recipes[key_str]

	# 创建结果装备
	return equipment_manager.get_equipment(result_id)

# 获取装备的基础ID（去除品质后缀）
func _get_base_id(equipment_id: String) -> String:
	var parts = equipment_id.split("_")
	if parts.size() > 1 and parts[-1].is_valid_int():
		# 移除最后一个部分（品质后缀）
		parts.pop_back()
		return "_".join(parts)

	return equipment_id

# 获取可能的合成结果
func get_possible_combinations(equipment: Equipment) -> Array:
	var results = []

	# 获取所有装备
	var all_equipments = []
	for id in config_manager.get_all_equipment_ids():
		all_equipments.append(equipment_manager.get_equipment(id))

	# 检查每个装备是否可以与当前装备合成
	for other in all_equipments:
		if can_combine(equipment, other):
			var result = preview_combine_result(equipment, other)
			if result:
				results.append({
					"ingredient": other,
					"result": result
				})

	return results

# 预览合成结果（不创建动画）
func preview_combine_result(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 尝试相同基础装备合成
	if _can_combine_same_base(equipment1, equipment2):
		# 获取基础ID
		var base_id = _get_base_id(equipment1.id)

		# 获取当前品质
		var current_tier = equipment_manager.get_tier_from_equipment_id(equipment1.id)

		# 计算新品质
		var new_tier = current_tier + 1

		# 创建新装备
		return equipment_manager.generate_random_equipment(base_id, new_tier)

	# 尝试配方合成
	if _can_combine_by_recipe(equipment1, equipment2):
		# 创建配方键
		var recipe_key = [equipment1.id, equipment2.id]
		recipe_key.sort()
		var key_str = JSON.stringify(recipe_key)

		# 获取结果装备ID
		var result_id = _combine_recipes[key_str]

		# 创建结果装备
		return equipment_manager.get_equipment(result_id)

	return null
