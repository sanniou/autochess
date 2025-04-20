extends Component
class_name AbilityComponent
## 技能组件
## 管理棋子的技能和技能使用

# 信号
signal ability_initialized(ability_data)
signal ability_cast(target)
signal ability_cooldown_updated(current_cooldown, max_cooldown)

# 技能属性
var ability_id: String = ""  # 技能ID
var ability_name: String = ""  # 技能名称
var ability_description: String = ""  # 技能描述
var ability_icon: Texture2D = null  # 技能图标
var ability_damage: float = 0.0  # 技能伤害
var ability_cooldown: float = 0.0  # 技能冷却时间
var ability_range: float = 0.0  # 技能范围
var ability_mana_cost: float = 100.0  # 技能法力消耗
var ability_type: String = ""  # 技能类型
var ability_target_type: String = "enemy"  # 技能目标类型
var ability_effects: Array = []  # 技能效果

# 技能状态
var current_cooldown: float = 0.0  # 当前冷却时间
var ability_instance = null  # 技能实例

# 初始化
func _init(p_owner = null, p_name: String = "AbilityComponent"):
	super._init(p_owner, p_name)
	priority = 60  # 中等优先级

# 初始化组件
func initialize() -> void:
	super.initialize()

# 更新组件
func _process_update(delta: float) -> void:
	# 更新冷却时间
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown < 0:
			current_cooldown = 0
		
		# 发送冷却更新信号
		ability_cooldown_updated.emit(current_cooldown, ability_cooldown)

# 初始化技能
func initialize_ability(ability_data: Dictionary) -> void:
	# 设置技能属性
	ability_id = ability_data.get("id", "")
	ability_name = ability_data.get("name", "")
	ability_description = ability_data.get("description", "")
	ability_damage = ability_data.get("damage", 0.0)
	ability_cooldown = ability_data.get("cooldown", 0.0)
	ability_range = ability_data.get("range", 0.0)
	ability_mana_cost = ability_data.get("mana_cost", 100.0)
	ability_type = ability_data.get("type", "")
	ability_target_type = ability_data.get("target_type", "enemy")
	
	# 加载技能图标
	var icon_path = ability_data.get("icon", "")
	if icon_path and ResourceLoader.exists(icon_path):
		ability_icon = load(icon_path)
	
	# 创建技能实例
	_create_ability_instance(ability_data)
	
	# 发送技能初始化信号
	ability_initialized.emit(ability_data)

# 创建技能实例
func _create_ability_instance(ability_data: Dictionary) -> void:
	# 获取技能工厂
	var ability_factory = GameManager.get_manager("AbilityFactory")
	if not ability_factory:
		return
	
	# 创建技能实例
	ability_instance = ability_factory.create_ability(ability_data, owner)

# 检查是否可以施法
func can_cast() -> bool:
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return false
	
	# 检查法力值
	var current_mana = attribute_component.get_attribute("current_mana")
	if current_mana < ability_mana_cost:
		return false
	
	# 检查冷却时间
	if current_cooldown > 0:
		return false
	
	# 检查状态组件
	var state_component = owner.get_component("StateComponent")
	if state_component and state_component.is_silenced:
		return false
	
	return true

# 施放技能
func cast_ability() -> bool:
	# 检查是否可以施法
	if not can_cast():
		return false
	
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return false
	
	# 消耗法力值
	attribute_component.reduce_mana(ability_mana_cost)
	
	# 设置冷却时间
	current_cooldown = ability_cooldown
	
	# 获取目标
	var target = null
	var target_component = owner.get_component("TargetComponent")
	if target_component:
		target = target_component.get_target()
	
	# 执行技能
	if ability_instance:
		ability_instance.activate(target)
	else:
		# 如果没有技能实例，使用默认技能逻辑
		_execute_default_ability(target)
	
	# 发送技能施放信号
	ability_cast.emit(target)
	
	# 发送事件
	EventBus.chess.emit_event("chess_piece_ability_cast", [owner, target])
	EventBus.battle.emit_event("ability_used", [owner, {
		"name": ability_name,
		"damage": ability_damage,
		"target": target
	}])
	
	return true

# 执行默认技能
func _execute_default_ability(target) -> void:
	if not target:
		return
	
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return
	
	# 获取法术强度
	var spell_power = attribute_component.get_attribute("spell_power")
	
	# 计算伤害
	var damage = ability_damage + spell_power
	
	# 造成伤害
	var combat_component = owner.get_component("CombatComponent")
	if combat_component:
		combat_component.deal_damage(target, damage, "magical", false)
	
	# 播放技能特效
	_play_ability_effect(target)

# 播放技能特效
func _play_ability_effect(target) -> void:
	# 获取特效管理器
	var effect_manager = GameManager.get_manager("EffectManager")
	if not effect_manager:
		return
	
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return
	
	# 获取法术强度
	var spell_power = attribute_component.get_attribute("spell_power")
	
	# 创建视觉特效参数
	var params = {
		"color": effect_manager.get_effect_color("magical"),
		"duration": 0.5,
		"damage_type": "magical",
		"damage_amount": ability_damage + spell_power
	}
	
	# 创建特效
	effect_manager.create_visual_effect(
		effect_manager.VisualEffectType.DAMAGE,
		target,
		params
	)

# 获取技能数据
func get_ability_data() -> Dictionary:
	return {
		"id": ability_id,
		"name": ability_name,
		"description": ability_description,
		"damage": ability_damage,
		"cooldown": ability_cooldown,
		"range": ability_range,
		"mana_cost": ability_mana_cost,
		"type": ability_type,
		"target_type": ability_target_type
	}

# 获取当前冷却时间
func get_current_cooldown() -> float:
	return current_cooldown

# 获取冷却进度
func get_cooldown_progress() -> float:
	if ability_cooldown <= 0:
		return 1.0
	
	return 1.0 - (current_cooldown / ability_cooldown)

# 重置冷却时间
func reset_cooldown() -> void:
	current_cooldown = 0.0
	ability_cooldown_updated.emit(current_cooldown, ability_cooldown)
