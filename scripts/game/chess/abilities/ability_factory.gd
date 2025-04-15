extends Node
class_name AbilityFactory
## 技能工厂
## 负责创建和管理技能实例

# 技能类型映射
var _ability_types = {
	"damage": DamageAbility,
	"heal": HealAbility,
	"buff": BuffAbility,
	"area_damage": AreaDamageAbility,
	"chain": ChainAbility,
	"aura": AuraAbility,
	"summon": SummonAbility,
	"teleport": TeleportAbility
}

# 创建技能
func create_ability(ability_data: Dictionary, owner_piece: ChessPiece) -> Ability:
	# 获取技能类型
	var ability_type = ability_data.get("type", "damage")
	
	# 创建对应类型的技能
	var ability_class = _ability_types.get(ability_type, Ability)
	var ability = ability_class.new()
	
	# 初始化技能
	ability.initialize(ability_data, owner_piece)
	
	return ability

# 注册自定义技能类型
func register_ability_type(type_name: String, ability_class) -> void:
	if not _ability_types.has(type_name):
		_ability_types[type_name] = ability_class
		return true
	return false
