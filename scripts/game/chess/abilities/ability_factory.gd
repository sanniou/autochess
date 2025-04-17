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

# 技能配置加载器
var _config_loader = null

# 初始化
func _ready() -> void:
	# 创建技能配置加载器
	_config_loader = AbilityConfigLoader.new()

	# 添加到场景树
	add_child(_config_loader)

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

# 从配置创建技能
func create_ability_from_config(ability_id: String, owner_piece: ChessPiece) -> Ability:
	# 获取技能配置
	var ability_config = _config_loader.get_ability_config(ability_id)
	if ability_config.is_empty():
		push_error("\u65e0法找到技能配置: " + ability_id)
		return null

	# 创建技能
	return create_ability(ability_config, owner_piece)

# 注册自定义技能类型
func register_ability_type(type_name: String, ability_class) -> bool:
	if not _ability_types.has(type_name):
		_ability_types[type_name] = ability_class
		return true
	return false

# 获取所有技能配置
func get_all_ability_configs() -> Dictionary:
	return _config_loader.get_all_ability_configs()

# 重新加载技能配置
func reload_ability_configs() -> void:
	_config_loader.reload_ability_configs()
