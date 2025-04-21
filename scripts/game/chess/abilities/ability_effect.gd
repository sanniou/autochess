extends Resource
class_name AbilityEffect
## 技能效果适配器
## 连接技能系统和战斗效果系统，将技能效果转换为战斗效果

# 效果类型 - 与BattleEffect.EffectType保持一致
enum EffectType {
	DAMAGE,         # 伤害
	HEAL,           # 治疗
	STAT_MOD,       # 属性修改
	STATUS,         # 状态效果
	DOT,            # 持续伤害
	HOT,            # 持续治疗
	MOVEMENT,       # 移动效果
	VISUAL,         # 视觉效果
	SOUND,          # 音效
	SHIELD,         # 护盾效果
	AURA            # 光环效果
}

# 效果属性
var effect_type: int = EffectType.DAMAGE  # 效果类型
var value: float = 0.0                    # 效果值
var duration: float = 0.0                 # 持续时间
var delay: float = 0.0                    # 延迟时间
var source: ChessPieceEntity = null       # 效果来源
var target: ChessPieceEntity = null       # 效果目标
var params: Dictionary = {}               # 附加参数

# 初始化
func _init(p_type: int = EffectType.DAMAGE, p_value: float = 0.0, p_duration: float = 0.0,
		p_delay: float = 0.0, p_source: ChessPieceEntity = null, p_target: ChessPieceEntity = null,
		p_params: Dictionary = {}) -> void:
	effect_type = p_type
	value = p_value
	duration = p_duration
	delay = p_delay
	source = p_source
	target = p_target
	params = p_params

# 应用效果
func apply() -> bool:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return false

	# 将技能效果转换为战斗效果并应用
	var effect_data = _create_effect_data()
	var battle_effect = _create_battle_effect(effect_data)

	# 如果成功创建了战斗效果，应用它
	if battle_effect:
		return _apply_battle_effect(battle_effect)

	return false

## 创建效果数据
## 将技能效果的属性转换为战斗效果系统可用的数据格式
func _create_effect_data() -> Dictionary:
	# 基础效果数据
	var effect_data = {
		"effect_type": _convert_effect_type(effect_type),
		"value": value,
		"duration": duration,
		"source": source,
		"target": target
	}

	# 合并附加参数
	for key in params:
		effect_data[key] = params[key]

	return effect_data

## 转换效果类型
## 将AbilityEffect.EffectType转换为BattleEffect.EffectType
func _convert_effect_type(ability_effect_type: int) -> int:
	match ability_effect_type:
		EffectType.DAMAGE:
			return BattleEffect.EffectType.DAMAGE
		EffectType.HEAL:
			return BattleEffect.EffectType.HEAL
		EffectType.STAT_MOD:
			return BattleEffect.EffectType.STAT_MOD
		EffectType.STATUS:
			return BattleEffect.EffectType.STATUS
		EffectType.DOT:
			return BattleEffect.EffectType.DOT
		EffectType.HOT:
			return BattleEffect.EffectType.HOT
		EffectType.MOVEMENT:
			return BattleEffect.EffectType.MOVEMENT
		EffectType.VISUAL:
			return BattleEffect.EffectType.VISUAL
		EffectType.SOUND:
			return BattleEffect.EffectType.SOUND
		EffectType.SHIELD:
			return BattleEffect.EffectType.SHIELD
		EffectType.AURA:
			return BattleEffect.EffectType.AURA
		_:
			return BattleEffect.EffectType.DAMAGE

## 创建战斗效果
## 使用效果工厂创建战斗效果对象
func _create_battle_effect(effect_data: Dictionary) -> BattleEffect:
	# 使用战斗管理器的效果工厂创建效果
	if GameManager.battle_manager and GameManager.battle_manager.effect_manager:
		var effect_factory = GameManager.battle_manager.effect_manager.effect_factory
		if effect_factory:
			return effect_factory.create_effect(effect_data, source, target)

	# 如果没有效果工厂，返回null
	return null

## 应用战斗效果
## 将创建的战斗效果应用到目标上
func _apply_battle_effect(battle_effect: BattleEffect) -> bool:
	# 检查效果是否有效
	if not battle_effect:
		return false

	# 应用效果
	return battle_effect.apply()

## 创建效果
## 静态工厂方法，用于创建技能效果并应用到目标上
static func create(effect_data: Dictionary, source: ChessPieceEntity, target: ChessPieceEntity) -> AbilityEffect:
	# 获取效果类型
	var effect_type_str = effect_data.get("type", "damage")

	# 根据字符串类型确定效果类型枚举值
	var ability_effect_type = EffectType.DAMAGE

	match effect_type_str:
		"damage":
			ability_effect_type = EffectType.DAMAGE
		"heal":
			ability_effect_type = EffectType.HEAL
		"buff", "stat_mod":
			ability_effect_type = EffectType.STAT_MOD
		"stat_decrease", "attribute_mod":
			ability_effect_type = EffectType.STAT_MOD  # 属性修改
		"control", "status":
			ability_effect_type = EffectType.STATUS
		"dot":
			ability_effect_type = EffectType.DOT
		"hot":
			ability_effect_type = EffectType.HOT
		"movement":
			ability_effect_type = EffectType.MOVEMENT
		"visual":
			ability_effect_type = EffectType.VISUAL
		"sound":
			ability_effect_type = EffectType.SOUND
		"shield":
			ability_effect_type = EffectType.SHIELD
		"aura":
			ability_effect_type = EffectType.AURA

	# 准备参数
	var params = effect_data.duplicate()

	# 添加类型映射
	params["original_type"] = effect_type_str

	# 创建效果对象
	var effect = AbilityEffect.new(
		ability_effect_type,
		effect_data.get("value", 0.0),
		effect_data.get("duration", 0.0),
		effect_data.get("delay", 0.0),
		source,
		target,
		params
	)

	# 应用效果
	effect.apply()

	return effect
