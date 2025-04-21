extends Node
class_name EquipmentCombineSystem
## 装备合成系统
## 负责管理装备的合成规则和合成逻辑

# 合成规则
# 1. 相同基础装备可以合成更高品质的装备
# 2. 不同基础装备可以合成新的装备（根据合成配方）
# 3. 高品质装备可以用于合成特殊装备


# 合成配方 {[装备ID1, 装备ID2]: 结果装备ID}
var _combine_recipes = {}

func _ready():
	# 加载合成配方
	_load_combine_recipes()

# 加载合成配方
func _load_combine_recipes():
	# 使用 ConfigManager 的 get_equipment_recipes 方法获取所有装备合成配方
	var recipes = ConfigManager.get_all_equipment()

	# 遍历所有配方
	for recipe in recipes:
		# 检查配方是否有效
		if recipe.has("ingredients") and recipe.has("result"):
			var ingredients = recipe.ingredients

			# 只处理需要两个材料的配方
			if ingredients.size() == 2:
				# 创建配方键（排序以确保顺序无关）
				var recipe_key = ingredients.duplicate()
				recipe_key.sort()
				var key_str = JSON.stringify(recipe_key)

				# 保存配方到内部字典
				_combine_recipes[key_str] = recipe.result

	# 输出调试信息
	print("Loaded " + str(_combine_recipes.size()) + " equipment recipes.")

# 检查两个装备是否可以合成
func can_combine(equipment1: Equipment, equipment2: Equipment) -> bool:
	# 验证参数
	if equipment1 == null or equipment2 == null:
		return false

	# 不能与自己合成
	if equipment1 == equipment2:
		return false

	# 检查相同基础装备合成
	if _can_combine_same_base(equipment1, equipment2):
		return true

	# 检查配方合成
	if _can_combine_by_recipe(equipment1, equipment2):
		return true

	return false

# 合成两个装备
func combine(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 验证参数
	if equipment1 == null or equipment2 == null:
		print("Error: Cannot combine null equipment")
		return null

	# 不能与自己合成
	if equipment1 == equipment2:
		print("Error: Cannot combine equipment with itself")
		return null

	# 尝试相同基础装备合成
	var result = _combine_same_base(equipment1, equipment2)
	if result:
		print("Combined same base equipment: " + equipment1.id + " + " + equipment2.id + " = " + result.id)
		# 创建合成动画
		_create_combine_animation(equipment1, equipment2, result)
		return result

	# 尝试配方合成
	result = _combine_by_recipe(equipment1, equipment2)
	if result:
		print("Combined by recipe: " + equipment1.id + " + " + equipment2.id + " = " + result.id)
		# 创建合成动画
		_create_combine_animation(equipment1, equipment2, result)
		return result

	print("Cannot combine: " + equipment1.id + " + " + equipment2.id)
	return null

# 创建合成动画
func _create_combine_animation(equipment1: Equipment, equipment2: Equipment, result: Equipment) -> void:
	# 发送合成动画信号
	EventBus.equipment.emit_event("equipment_combine_animation_started", [equipment1, equipment2, result])

	# 在合成动画完成后发送合成完成信号
	var timer = get_tree().create_timer(1.0) # 假设动画时间1秒
	timer.timeout.connect(func():
		EventBus.equipment.emit_event("equipment_combine_animation_completed", [equipment1, equipment2, result])
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
	var tier1 = GameManager.equipment_manager.get_tier_from_equipment_id(equipment1.id)
	var tier2 = GameManager.equipment_manager.get_tier_from_equipment_id(equipment2.id)

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
	var current_tier = GameManager.equipment_manager.get_tier_from_equipment_id(equipment1.id)

	# 计算新品质
	var new_tier = current_tier + 1

	# 创建新装备
	return GameManager.equipment_manager.generate_random_equipment(base_id, new_tier)

# 检查两个装备是否可以通过配方合成
func _can_combine_by_recipe(equipment1: Equipment, equipment2: Equipment) -> bool:
	# 验证参数
	if equipment1 == null or equipment2 == null:
		return false

	# 创建配方键
	var recipe_key = [equipment1.id, equipment2.id]
	recipe_key.sort()
	var key_str = JSON.stringify(recipe_key)

	# 检查是否有匹配的配方
	var has_recipe = _combine_recipes.has(key_str)

	# 输出调试信息
	if has_recipe:
		print("Found recipe for: " + equipment1.id + " + " + equipment2.id + " = " + _combine_recipes[key_str])

	return has_recipe

# 通过配方合成两个装备
func _combine_by_recipe(equipment1: Equipment, equipment2: Equipment) -> Equipment:
	# 验证参数
	if equipment1 == null or equipment2 == null:
		return null

	# 检查是否可以合成
	if not _can_combine_by_recipe(equipment1, equipment2):
		return null

	# 创建配方键
	var recipe_key = [equipment1.id, equipment2.id]
	recipe_key.sort()
	var key_str = JSON.stringify(recipe_key)

	# 获取结果装备ID
	var result_id = _combine_recipes[key_str]
	if result_id.is_empty():
		print("Error: Recipe result is empty for " + equipment1.id + " + " + equipment2.id)
		return null

	# 创建结果装备
	var result = GameManager.equipment_manager.get_equipment(result_id)
	if result == null:
		print("Error: Failed to create equipment with ID: " + result_id)

	return result

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
	for id in ConfigManager.get_all_equipment_ids():
		all_equipments.append(GameManager.equipment_manager.get_equipment(id))

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
		var current_tier = GameManager.equipment_manager.get_tier_from_equipment_id(equipment1.id)

		# 计算新品质
		var new_tier = current_tier + 1

		# 创建新装备
		return GameManager.equipment_manager.generate_random_equipment(base_id, new_tier)

	# 尝试配方合成
	if _can_combine_by_recipe(equipment1, equipment2):
		# 创建配方键
		var recipe_key = [equipment1.id, equipment2.id]
		recipe_key.sort()
		var key_str = JSON.stringify(recipe_key)

		# 获取结果装备ID
		var result_id = _combine_recipes[key_str]

		# 创建结果装备
		return GameManager.equipment_manager.get_equipment(result_id)

	return null
