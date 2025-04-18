extends Resource
class_name ChessPieceData
## 棋子数据类
## 存储棋子的所有属性数据，与逻辑和表现分离

# 基本信息
var id: String = ""                # 棋子ID
var display_name: String = ""      # 显示名称
var description: String = ""       # 描述
var cost: int = 1                  # 费用
var synergies: Array = []          # 羁绊列表
var star_level: int = 1            # 星级

# 战斗属性
var max_health: float = 100.0      # 最大生命值
var current_health: float = 100.0  # 当前生命值
var attack_damage: float = 10.0    # 攻击力
var attack_speed: float = 1.0      # 攻击速度
var attack_range: float = 1.0      # 攻击范围
var armor: float = 0.0             # 护甲
var magic_resist: float = 0.0      # 魔法抗性
var move_speed: float = 300.0      # 移动速度
var base_move_speed: float = 300.0 # 基础移动速度

# 技能属性
var ability_name: String = ""      # 技能名称
var ability_description: String = "" # 技能描述
var ability_damage: float = 0.0    # 技能伤害
var ability_cooldown: float = 0.0  # 技能冷却时间
var ability_range: float = 0.0     # 技能范围
var ability_mana_cost: float = 100.0 # 技能法力消耗
var current_cooldown: float = 0.0  # 当前冷却时间
var current_mana: float = 0.0      # 当前法力值
var max_mana: float = 100.0        # 最大法力值

# 战斗增强属性
var crit_chance: float = 0.0       # 暴击几率
var crit_damage: float = 1.5       # 暴击伤害
var dodge_chance: float = 0.0      # 闪避几率
var lifesteal: float = 0.0         # 生命偷取
var spell_power: float = 0.0       # 法术强度
var healing_bonus: float = 0.0     # 治疗加成
var damage_reduction: float = 0.0  # 伤害减免
var elemental_effect_chance: float = 0.0 # 元素效果触发几率

# 控制效果相关
var is_silenced: bool = false      # 是否被沉默
var is_disarmed: bool = false      # 是否被缴械
var is_frozen: bool = false        # 是否被冰冻
var taunted_by = null              # 嘲讽来源
var control_resistance: float = 0.0 # 控制抗性

# 装备和效果
var equipment_slots: Array = []    # 装备槽
var active_effects: Array = []     # 激活的效果

# 位置和目标
var board_position: Vector2i = Vector2i(-1, -1)  # 棋盘位置
var target_id: String = ""         # 当前目标ID

# 其他属性
var is_player_piece: bool = true   # 是否属于玩家
var attack_timer: float = 0.0      # 攻击计时器

# 从字典初始化数据
func initialize_from_dict(data: Dictionary) -> void:
	# 基本信息
	id = data.get("id", "")
	display_name = data.get("name", "")
	description = data.get("description", "")
	cost = data.get("cost", 1)
	synergies = data.get("synergies", [])
	star_level = data.get("star_level", 1)
	
	# 战斗属性
	max_health = data.get("health", 100.0)
	current_health = max_health
	attack_damage = data.get("attack_damage", 10.0)
	attack_speed = data.get("attack_speed", 1.0)
	attack_range = data.get("attack_range", 1.0)
	armor = data.get("armor", 0.0)
	magic_resist = data.get("magic_resist", 0.0)
	move_speed = data.get("move_speed", 300.0)
	base_move_speed = move_speed
	
	# 技能属性
	if data.has("ability"):
		var ability_data = data.get("ability", {})
		ability_name = ability_data.get("name", "")
		ability_description = ability_data.get("description", "")
		ability_damage = ability_data.get("damage", 0.0)
		ability_cooldown = ability_data.get("cooldown", 0.0)
		ability_range = ability_data.get("range", 0.0)
		ability_mana_cost = ability_data.get("mana_cost", 100.0)
	
	# 其他属性
	is_player_piece = data.get("is_player_piece", true)
	
	# 设置控制抗性（基于费用和星级）
	control_resistance = 0.05 * cost + 0.05 * star_level  # 每费用5%，每星级5%

# 升级棋子
func upgrade() -> void:
	if star_level >= 3:
		return
	
	star_level += 1
	
	# 属性提升
	var health_increase = max_health * 0.8
	var damage_increase = attack_damage * 0.5
	var ability_increase = ability_damage * 0.5
	
	# 更新属性
	max_health += health_increase
	current_health = max_health  # 升级时恢复满血
	attack_damage += damage_increase
	ability_damage += ability_increase
	armor += 5
	magic_resist += 5
	
	# 更新控制抗性
	control_resistance = 0.05 * cost + 0.05 * star_level

# 重置属性
func reset() -> void:
	current_health = max_health
	current_mana = 0
	current_cooldown = 0
	attack_timer = 0
	
	# 重置控制效果
	is_silenced = false
	is_disarmed = false
	is_frozen = false
	taunted_by = null
	
	# 清空效果
	active_effects.clear()

# 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"cost": cost,
		"synergies": synergies,
		"star_level": star_level,
		"max_health": max_health,
		"current_health": current_health,
		"attack_damage": attack_damage,
		"attack_speed": attack_speed,
		"attack_range": attack_range,
		"armor": armor,
		"magic_resist": magic_resist,
		"move_speed": move_speed,
		"ability_name": ability_name,
		"ability_description": ability_description,
		"ability_damage": ability_damage,
		"ability_cooldown": ability_cooldown,
		"ability_range": ability_range,
		"ability_mana_cost": ability_mana_cost,
		"current_cooldown": current_cooldown,
		"current_mana": current_mana,
		"max_mana": max_mana,
		"crit_chance": crit_chance,
		"crit_damage": crit_damage,
		"dodge_chance": dodge_chance,
		"lifesteal": lifesteal,
		"spell_power": spell_power,
		"healing_bonus": healing_bonus,
		"damage_reduction": damage_reduction,
		"elemental_effect_chance": elemental_effect_chance,
		"is_silenced": is_silenced,
		"is_disarmed": is_disarmed,
		"is_frozen": is_frozen,
		"control_resistance": control_resistance,
		"board_position": {"x": board_position.x, "y": board_position.y},
		"is_player_piece": is_player_piece
	}

# 从另一个数据对象复制
func copy_from(other: ChessPieceData) -> void:
	id = other.id
	display_name = other.display_name
	description = other.description
	cost = other.cost
	synergies = other.synergies.duplicate()
	star_level = other.star_level
	
	max_health = other.max_health
	current_health = other.current_health
	attack_damage = other.attack_damage
	attack_speed = other.attack_speed
	attack_range = other.attack_range
	armor = other.armor
	magic_resist = other.magic_resist
	move_speed = other.move_speed
	base_move_speed = other.base_move_speed
	
	ability_name = other.ability_name
	ability_description = other.ability_description
	ability_damage = other.ability_damage
	ability_cooldown = other.ability_cooldown
	ability_range = other.ability_range
	ability_mana_cost = other.ability_mana_cost
	current_cooldown = other.current_cooldown
	current_mana = other.current_mana
	max_mana = other.max_mana
	
	crit_chance = other.crit_chance
	crit_damage = other.crit_damage
	dodge_chance = other.dodge_chance
	lifesteal = other.lifesteal
	spell_power = other.spell_power
	healing_bonus = other.healing_bonus
	damage_reduction = other.damage_reduction
	elemental_effect_chance = other.elemental_effect_chance
	
	is_silenced = other.is_silenced
	is_disarmed = other.is_disarmed
	is_frozen = other.is_frozen
	control_resistance = other.control_resistance
	
	board_position = other.board_position
	is_player_piece = other.is_player_piece
