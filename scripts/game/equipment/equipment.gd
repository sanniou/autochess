extends Node
class_name Equipment
## 装备基类
## 定义装备的基本属性和行为

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")

# 信号
signal equipped(character)  # 装备穿戴信号
signal unequipped(character) # 装备卸下信号
signal effect_triggered(effect_data) # 效果触发信号

# 装备属性
var id: String = ""
var display_name: String = ""
var description: String = ""
var type: String = ""  # weapon/armor/accessory
var rarity: int
var icon: String = ""

# 装备效果
var stats: Dictionary = {}  # 基础属性加成
var effects: Array = []     # 特殊效果
var combine_recipes: Array = [] # 合成配方
var recipe: Array = []      # 合成所需装备

# 当前穿戴者
var current_owner: ChessPieceEntity = null

# 效果系统引用
var effect_system: EquipmentEffectSystem = null

# 初始化
func _init():
	# 创建效果系统
	effect_system = EquipmentEffectSystem.new()
	add_child(effect_system)

# 初始化装备数据
func initialize(data: Dictionary):
	id = data.id
	display_name = data.name
	description = data.description
	type = data.type
	rarity = data.rarity
	icon = data.icon_path

	if data.has("stats"):
		stats = data.stats
	if data.has("effects"):
		effects = data.effects
	if data.has("combine_recipes"):
		combine_recipes = data.combine_recipes
	if data.has("recipe"):
		recipe = data.recipe

# 装备到角色
func equip_to(character: ChessPieceEntity) -> bool:
	if current_owner != null:
		return false

	current_owner = character

	# 使用效果系统应用效果
	effect_system.apply_effects(self, character)

	# 发送装备信号
	equipped.emit(character)
	EventBus.equipment.emit_event("equipment_equipped", [self, character])

	return true

# 从角色卸下
func unequip_from() -> bool:
	if current_owner == null:
		return false

	# 使用效果系统移除效果
	effect_system.remove_effects(self, current_owner)

	# 发送卸下信号
	unequipped.emit(current_owner)
	EventBus.equipment.emit_event("equipment_unequipped", [self, current_owner])

	current_owner = null
	return true

# 触发效果
func trigger_effect(effect_data: Dictionary, trigger_context: Dictionary = {}) -> void:
	# 使用效果系统触发效果
	effect_system.trigger_effect(self, effect_data, trigger_context)

# 检查是否可以合成
func can_combine_with(other_equipment: Equipment) -> bool:
	return other_equipment.id in combine_recipes

# 获取合成结果
func get_combine_result(other_equipment: Equipment) -> String:
	if can_combine_with(other_equipment):
		for recipe_id in combine_recipes:
			var recipe_model = GameManager.config_manager.get_equipment_config(recipe_id)
			if recipe_model and other_equipment.id in recipe_model.get_components():
				return recipe_id
	return ""

# 获取装备数据
func get_data() -> Dictionary:
	# 返回装备的完整数据
	var data = {
		"id": id,
		"name": display_name,
		"description": description,
		"type": type,
		"rarity": rarity,
		"icon": icon,
		"stats": stats.duplicate(),
		"effects": effects.duplicate(),
		"combine_recipes": combine_recipes.duplicate(),
		"recipe": recipe.duplicate()
	}
	return data
