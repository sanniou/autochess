extends Node
class_name Equipment
## 装备基类
## 定义装备的基本属性和行为

# 信号
signal equipped(character)  # 装备穿戴信号
signal unequipped(character) # 装备卸下信号
signal effect_triggered(effect_data) # 效果触发信号

# 装备属性
var id: String = ""
var display_name: String = ""
var description: String = ""
var type: String = ""  # weapon/armor/accessory
var rarity: String = "" # common/rare/epic/legendary
var icon: String = ""

# 装备效果
var stats: Dictionary = {}  # 基础属性加成
var effects: Array = []     # 特殊效果
var combine_recipes: Array = [] # 合成配方
var recipe: Array = []      # 合成所需装备

# 当前穿戴者
var current_owner: ChessPiece = null

# 初始化
func initialize(data: Dictionary):
	id = data.id
	display_name = data.name
	description = data.description
	type = data.type
	rarity = data.rarity
	icon = data.icon
	
	if data.has("stats"):
		stats = data.stats
	if data.has("effects"):
		effects = data.effects
	if data.has("combine_recipes"):
		combine_recipes = data.combine_recipes
	if data.has("recipe"):
		recipe = data.recipe

# 装备到角色
func equip_to(character: ChessPiece) -> bool:
	if current_owner != null:
		return false
	
	current_owner = character
	
	# 应用基础属性
	_apply_stats()
	
	# 应用特殊效果
	_apply_effects()
	
	# 发送装备信号
	equipped.emit(character)
	EventBus.equipment_equipped.emit(self, character)
	
	return true

# 从角色卸下
func unequip_from() -> bool:
	if current_owner == null:
		return false
	
	# 移除基础属性
	_remove_stats()
	
	# 移除特殊效果
	_remove_effects()
	
	# 发送卸下信号
	unequipped.emit(current_owner)
	EventBus.equipment_unequipped.emit(self, current_owner)
	
	current_owner = null
	return true

# 应用基础属性
func _apply_stats():
	if current_owner == null:
		return
	
	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				current_owner.max_health += value
				current_owner.current_health += value
			"attack_damage":
				current_owner.attack_damage += value
			"attack_speed":
				current_owner.attack_speed += value
			"armor":
				current_owner.armor += value
			"magic_resist":
				current_owner.magic_resist += value
			"spell_power":
				current_owner.spell_power += value
			"move_speed":
				current_owner.move_speed += value
			"crit_chance":
				current_owner.crit_chance += value
			"crit_damage":
				current_owner.crit_damage += value
			"dodge_chance":
				current_owner.dodge_chance += value

# 移除基础属性
func _remove_stats():
	if current_owner == null:
		return
	
	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				current_owner.max_health -= value
				current_owner.current_health = min(current_owner.current_health, current_owner.max_health)
			"attack_damage":
				current_owner.attack_damage -= value
			"attack_speed":
				current_owner.attack_speed -= value
			"armor":
				current_owner.armor -= value
			"magic_resist":
				current_owner.magic_resist -= value
			"spell_power":
				current_owner.spell_power -= value
			"move_speed":
				current_owner.move_speed -= value
			"crit_chance":
				current_owner.crit_chance -= value
			"crit_damage":
				current_owner.crit_damage -= value
			"dodge_chance":
				current_owner.dodge_chance -= value

# 应用特殊效果
func _apply_effects():
	if current_owner == null:
		return
	
	for effect in effects:
		var effect_data = effect.duplicate()
		effect_data["source"] = self
		effect_data["id"] = "equip_%s_%s" % [id, effect.type]
		
		# 根据效果类型连接信号
		match effect.trigger:
			"attack":
				current_owner.ability_activated.connect(_on_owner_attack.bind(effect_data))
			"take_damage":
				current_owner.health_changed.connect(_on_owner_take_damage.bind(effect_data))
			"ability_cast":
				current_owner.ability_activated.connect(_on_owner_ability.bind(effect_data))
			"low_health":
				current_owner.health_changed.connect(_on_owner_health_changed.bind(effect_data))
		
		current_owner.add_effect(effect_data)

# 移除特殊效果
func _remove_effects():
	if current_owner == null:
		return
	
	for effect in effects:
		var effect_id = "equip_%s_%s" % [id, effect.type]
		current_owner.remove_effect(effect_id)

# 攻击事件处理
func _on_owner_attack(_target, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 受伤事件处理
func _on_owner_take_damage(_old_value, _new_value, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 技能释放事件处理
func _on_owner_ability(_target, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 生命值变化事件处理
func _on_owner_health_changed(_old_value, new_value, effect_data):
	var max_health = current_owner.max_health
	if new_value <= max_health * effect_data.threshold:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 检查是否可以合成
func can_combine_with(other_equipment: Equipment) -> bool:
	return other_equipment.id in combine_recipes

# 获取合成结果
func get_combine_result(other_equipment: Equipment) -> String:
	if can_combine_with(other_equipment):
		for recipe_id in combine_recipes:
			var recipe_data = ConfigManager.get_equipment(recipe_id)
			if recipe_data and other_equipment.id in recipe_data.recipe:
				return recipe_id
	return ""
