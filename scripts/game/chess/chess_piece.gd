extends Node2D
class_name ChessPiece
## 棋子基类
## 定义棋子的基本属性和行为

@onready var EventBus = get_node("/root/EventBus")

# 信号
signal health_changed(old_value, new_value)
signal mana_changed(old_value, new_value)
signal state_changed(old_state, new_state)
signal ability_activated(target)
signal died
signal dodge_successful(attacker)               # 闪避成功信号
signal critical_hit(target, damage)             # 暴击信号
signal elemental_effect_triggered(target, element_type) # 元素效果触发信号

# 棋子状态枚举
enum ChessState {
	IDLE,       # 空闲状态
	MOVING,     # 移动状态
	ATTACKING,  # 攻击状态
	CASTING,    # 施法状态
	STUNNED,    # 眩晕状态
	DEAD        # 死亡状态
}

# 基本属性
var id: String = ""                # 棋子ID
var display_name: String = ""      # 显示名称
var description: String = ""       # 描述
var cost: int = 1                  # 费用
var star_level: int = 1            # 星级 (1-3)
var synergies: Array = []          # 羁绊类型

# 战斗属性
var max_health: float = 100.0      # 最大生命值
var current_health: float = 100.0  # 当前生命值
var max_mana: float = 100.0        # 最大法力值
var current_mana: float = 0.0      # 当前法力值
var attack_damage: float = 10.0    # 攻击力
var attack_speed: float = 1.0      # 攻击速度
var attack_range: float = 1.0      # 攻击范围
var armor: float = 0.0             # 护甲
var magic_resist: float = 0.0      # 魔法抗性
var move_speed: float = 300.0      # 移动速度
var base_move_speed: float = 300.0 # 基础移动速度
var crit_chance: float = 0.0       # 暴击几率
var crit_damage: float = 1.5       # 暴击伤害
var dodge_chance: float = 0.0      # 闪避几率
var spell_power: float = 0.0       # 法术强度
var elemental_effect_chance: float = 0.0 # 元素效果几率

# 技能属性
var ability_name: String = ""      # 技能名称
var ability_description: String = "" # 技能描述
var ability_damage: float = 0.0    # 技能伤害
var ability_cooldown: float = 0.0  # 技能冷却时间
var ability_range: float = 0.0     # 技能范围
var ability_mana_cost: float = 100.0 # 技能法力消耗
var current_cooldown: float = 0.0  # 当前冷却时间
var ability = null        # 技能实例

# 装备和效果
var weapon_slot: Equipment = null  # 武器槽
var armor_slot: Equipment = null   # 护甲槽
var accessory_slot: Equipment = null # 饰品槽
var active_effects: Array = []     # 激活的效果（旧系统，保留向后兼容）

# 控制效果相关
var is_silenced: bool = false      # 是否被沉默
var is_disarmed: bool = false      # 是否被缴械
var is_frozen: bool = false        # 是否被冰冻
var taunted_by = null              # 嘲讽来源
var control_resistance: float = 0.0 # 控制抗性

# 状态效果由 EffectManager 管理   # 状态效果管理器

# 位置和目标
var board_position: Vector2i = Vector2i(-1, -1)  # 棋盘位置
var target: ChessPiece = null      # 当前目标
var attack_timer: float = 0.0      # 攻击计时器

# 当前状态
var current_state: int = ChessState.IDLE

# 视觉组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var star_indicator: Node2D = $StarIndicator
@onready var effect_container: Node2D = $EffectContainer

# 状态机
var state_machine: StateMachine

# 是否属于玩家
var is_player_piece: bool = true

# 原始属性（用于重置效果）
var base_stats: Dictionary = {}

# 初始化
func _ready():
	# 初始化视觉组件
	_initialize_visuals()

	# 初始化状态机
	_initialize_state_machine()

	# 初始化状态效果管理器
	_initialize_status_effect_manager()

	# 保存基础属性
	_save_base_stats()

	# 连接信号
	_connect_signals()

# 物理更新
func _physics_process(delta):
	# 更新状态机
	if state_machine:
		state_machine.physics_process(delta)

	# 更新状态效果 - 由效果系统处理

	# 更新冷却时间
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown < 0:
			current_cooldown = 0

	# 更新攻击计时器
	if current_state == ChessState.ATTACKING and not is_disarmed:
		attack_timer += delta
		if attack_timer >= 1.0 / attack_speed:
			attack_timer = 0
			_perform_attack()

	# 自动回蓝
	if current_state != ChessState.DEAD and current_mana < max_mana:
		gain_mana(delta * 10.0, "passive")  # 每秒回复10点法力值

# 初始化棋子
func initialize(piece_data: Dictionary) -> void:
	id = piece_data.id
	display_name = piece_data.name
	description = piece_data.description
	cost = piece_data.cost
	synergies = piece_data.synergies

	# 设置战斗属性
	max_health = piece_data.health
	current_health = max_health
	attack_damage = piece_data.attack_damage
	attack_speed = piece_data.attack_speed
	attack_range = piece_data.attack_range
	armor = piece_data.armor
	magic_resist = piece_data.magic_resist
	move_speed = piece_data.move_speed
	base_move_speed = piece_data.move_speed

	# 设置控制抗性（基于费用和星级）
	control_resistance = 0.05 * cost + 0.05 * star_level  # 每费用5%，每星级5%

	# 设置技能属性
	if piece_data.has("ability"):
		ability_name = piece_data.ability.name
		ability_description = piece_data.ability.description
		ability_damage = piece_data.ability.damage
		ability_cooldown = piece_data.ability.cooldown
		ability_range = piece_data.ability.range

		# 创建技能实例
		if piece_data.ability.has("type"):
			# 获取技能工厂
			var ability_factory = get_node_or_null("/root/GameManager/AbilityFactory")

			if ability_factory:
				# 使用技能工厂创建技能
				ability = ability_factory.create_ability(piece_data.ability, self)
			else:
				# 如果找不到技能工厂，使用简单方式创建
				# 注释掉技能创建代码，因为我们使用技能工厂
				print("Warning: AbilityFactory not found, ability creation skipped.")

	# 保存基础属性
	_save_base_stats()

	# 更新视觉效果
	_update_visuals()

# 升级棋子
func upgrade() -> void:
	if star_level >= 3:
		return

	# 保存旧星级
	var old_star_level = star_level
	star_level += 1

	# 根据星级提升属性
	var multiplier = 1.0
	if star_level == 2:
		multiplier = 1.8
	elif star_level == 3:
		multiplier = 3.0

	# 保存旧属性值用于显示提升效果
	var old_max_health = max_health
	var old_attack_damage = attack_damage
	var old_ability_damage = ability_damage

	# 提升属性
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	ability_damage *= multiplier

	# 提升控制抗性
	control_resistance += 0.05  # 每星级提升控制抗性加5%

	# 重新初始化状态效果管理器
	if status_effect_manager:
		_initialize_status_effect_manager()

	# 更新视觉效果
	_update_visuals()

	# 播放升星特效
	_play_upgrade_effect(old_star_level, star_level, {
		"health": max_health - old_max_health,
		"attack": attack_damage - old_attack_damage,
		"ability": ability_damage - old_ability_damage
	})

	# 发送升级信号
	EventBus.chess.emit_event("chess_piece_upgraded", [self])

# 受到伤害
func take_damage(amount: float, damage_type: String = "physical", source = null) -> float:
	if current_state == ChessState.DEAD:
		return 0

	# 检查闪避
	if randf() < dodge_chance:
		# 触发闪避效果
		_on_dodge(source)
		# 发送闪避成功信号
		dodge_successful.emit(source)
		return 0

	# 计算实际伤害
	var actual_damage = amount

	# 应用护甲或魔抗
	if damage_type == "physical":
		actual_damage *= (100.0 / (100.0 + armor))
	elif damage_type == "magical":
		actual_damage *= (100.0 / (100.0 + magic_resist))

	# 应用伤害减免效果
	for effect in active_effects:
		if effect.has("damage_reduction"):
			actual_damage *= (1.0 - effect.damage_reduction)

	# 确保伤害至少为1
	actual_damage = max(1.0, actual_damage)

	# 减少生命值
	var old_health = current_health
	current_health -= actual_damage

	# 增加法力值（受到伤害时获得法力值）
	gain_mana(actual_damage * 0.1, "damage_taken")

	# 发送伤害信号
	EventBus.battle.emit_event("damage_dealt", [source, self, actual_damage, damage_type])

	# 更新生命值显示
	health_changed.emit(old_health, current_health)
	_update_health_bar()

	# 检查是否死亡
	if current_health <= 0:
		die()

	# 触发受伤效果
	_on_damaged(actual_damage, damage_type, source)

	return actual_damage

# 治疗
func heal(amount: float, source = null) -> float:
	if current_state == ChessState.DEAD:
		return 0

	var old_health = current_health
	current_health = min(current_health + amount, max_health)

	# 更新生命值显示
	health_changed.emit(old_health, current_health)
	_update_health_bar()

	# 发送治疗信号 - 使用常量而非字符串字面量
	var event_definitions = load("res://scripts/events/event_definitions.gd")
	EventBus.battle.emit_event(event_definitions.BattleEvents.HEAL_RECEIVED, [self, amount, source])

	# 触发治疗效果
	_on_healed(amount, source)

	return current_health - old_health

# 获得法力值
func gain_mana(amount: float, source_type: String = "passive") -> float:
	if current_state == ChessState.DEAD:
		return 0

	# 应用法力获取系数
	var mana_gain_multiplier = 1.0
	# 法力获取颜色
	var mana_gain_color = Color(0.0, 0.5, 1.0, 0.7) # 默认蓝色

	# 根据法力来源调整获取系数和颜色
	match source_type:
		"passive":
			# 被动回蓝，基础系数
			mana_gain_multiplier = 1.0
			mana_gain_color = Color(0.0, 0.5, 1.0, 0.7) # 蓝色
		"attack":
			# 普通攻击获得法力
			mana_gain_multiplier = 1.5
			mana_gain_color = Color(0.8, 0.2, 0.8, 0.7) # 紫色
		"damage_taken":
			# 受伤获得法力，根据伤害比例
			mana_gain_multiplier = 1.2
			mana_gain_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
		"ability":
			# 技能命中获得法力
			mana_gain_multiplier = 2.0
			mana_gain_color = Color(1.0, 0.8, 0.0, 0.7) # 金色
		"item":
			# 装备效果获得法力
			mana_gain_multiplier = 1.0
			mana_gain_color = Color(0.0, 0.8, 0.5, 0.7) # 青绿色

	# 根据棋子星级提升法力获取
	mana_gain_multiplier += 0.1 * star_level  # 每星级提升法力获取10%

	# 根据装备提升法力获取
	if weapon_slot and weapon_slot.has_method("get_stat") and weapon_slot.has_method("has_stat"):
		if weapon_slot.has_stat("mana_gain"):
			mana_gain_multiplier += weapon_slot.get_stat("mana_gain") / 100.0

	if armor_slot and armor_slot.has_method("get_stat") and armor_slot.has_method("has_stat"):
		if armor_slot.has_stat("mana_gain"):
			mana_gain_multiplier += armor_slot.get_stat("mana_gain") / 100.0

	if accessory_slot and accessory_slot.has_method("get_stat") and accessory_slot.has_method("has_stat"):
		if accessory_slot.has_stat("mana_gain"):
			mana_gain_multiplier += accessory_slot.get_stat("mana_gain") / 100.0

	# 根据状态调整法力获取
	if current_state == ChessState.ATTACKING:
		# 攻击状态下获得更多法力
		mana_gain_multiplier *= 1.2
	elif current_state == ChessState.STUNNED:
		# 眩晕状态下获得更少法力
		mana_gain_multiplier *= 0.5
	elif current_state == ChessState.MOVING:
		# 移动状态下获得法力略微提升
		mana_gain_multiplier *= 1.1

	# 检查是否被沉默，沉默时法力获取减少
	if is_silenced:
		mana_gain_multiplier *= 0.7

	# 应用法力获取系数
	var original_amount = amount
	amount *= mana_gain_multiplier

	# 确保法力获取至少为1
	amount = max(1.0, amount)

	var old_mana = current_mana
	current_mana = min(current_mana + amount, max_mana)

	# 更新法力值显示
	mana_changed.emit(old_mana, current_mana)
	_update_mana_bar()

	# 显示法力获取视觉效果
	_show_mana_gain_effect(amount, mana_gain_color, source_type)

	# 检查是否可以释放技能
	if current_mana >= ability_mana_cost and current_cooldown <= 0 and not is_silenced:
		activate_ability()

	return current_mana - old_mana

# 显示法力获取视觉效果
func _show_mana_gain_effect(amount: float, color: Color, source_type: String) -> void:
	# 如果法力获取量很小，不显示效果
	if amount < 2.0 and source_type == "passive":
		return

	# 创建法力获取效果容器
	var mana_effect_container = Node2D.new()
	add_child(mana_effect_container)

	# 创建法力获取视觉对象
	var mana_visual = ColorRect.new()
	mana_visual.color = color
	mana_visual.size = Vector2(30, 30)
	mana_visual.position = Vector2(-15, -15)
	mana_effect_container.add_child(mana_visual)

	# 创建法力获取数值文本
	var mana_label = Label.new()
	mana_label.text = "+" + str(int(amount))
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mana_label.size = Vector2(30, 30)
	mana_label.position = Vector2(-15, -15)
	mana_effect_container.add_child(mana_label)

	# 设置初始位置（在法力条附近）
	mana_effect_container.position = Vector2(0, -30)

	# 创建浮动和消失动画
	var tween = create_tween()
	tween.tween_property(mana_effect_container, "position", Vector2(0, -60), 0.5)
	tween.parallel().tween_property(mana_effect_container, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(mana_effect_container.queue_free)

# 消耗法力值
func spend_mana(amount: float) -> bool:
	if current_mana < amount:
		return false

	var old_mana = current_mana
	current_mana -= amount

	# 更新法力值显示
	mana_changed.emit(old_mana, current_mana)
	_update_mana_bar()

	return true

# 激活技能
func activate_ability() -> bool:
	# 检查是否可以使用技能
	if current_state == ChessState.DEAD or current_cooldown > 0 or current_mana < ability_mana_cost:
		return false

	# 检查是否被沉默
	if is_silenced:
		return false

	# 消耗法力值
	if not spend_mana(ability_mana_cost):
		return false

	# 设置冷却时间
	current_cooldown = ability_cooldown

	# 切换到施法状态
	change_state(ChessState.CASTING)

	# 执行技能逻辑
	_perform_ability()

	# 创建技能数据
	var ability_data = {
		"name": ability_name,
		"damage": ability_damage,
		"target": target
	}

	# 发送技能激活信号
	ability_activated.emit(target)
	EventBus.chess.emit_event("chess_piece_ability_activated", [self, target])

	# 发送技能使用信号
	EventBus.battle.emit_event("ability_used", [self, ability_data])

	return true

# 执行技能
func _perform_ability() -> void:
	# 如果有技能实例，激活技能
	if ability:
		ability.activate(target)
	else:
		# 默认技能：造成伤害
		if target:
			var damage = ability_damage + spell_power
			target.take_damage(damage, "magical", self)

			# 播放技能特效
			_play_ability_effect(target)

# 播放技能特效
func _play_ability_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color("magical"),
		"duration": 0.5,
		"damage_type": "magical",
		"damage_amount": ability_damage + spell_power
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.DAMAGE,
		target,
		params
	)

# 死亡
func die() -> void:
	if current_state == ChessState.DEAD:
		return

	# 切换到死亡状态
	change_state(ChessState.DEAD)

	# 发送死亡信号
	died.emit()
	var event_definitions = load("res://scripts/events/event_definitions.gd")
	EventBus.battle.emit_event(event_definitions.BattleEvents.UNIT_DIED, [self])

	# 触发死亡效果
	_on_death()

	# 延迟移除
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

# 复活
func resurrect(health_percent: float = 0.3) -> void:
	if current_state != ChessState.DEAD:
		return

	# 恢复生命值
	current_health = max_health * health_percent

	# 重置状态
	change_state(ChessState.IDLE)

	# 更新视觉效果
	modulate.a = 1.0
	_update_health_bar()

	# 触发复活效果
	_on_resurrect()

# 改变状态
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return

	var old_state = current_state
	current_state = new_state

	# 使用状态机切换状态
	var state_name = ""
	match new_state:
		ChessState.IDLE:
			state_name = "idle"
		ChessState.MOVING:
			state_name = "moving"
		ChessState.ATTACKING:
			state_name = "attacking"
		ChessState.CASTING:
			state_name = "casting"
		ChessState.STUNNED:
			state_name = "stunned"
		ChessState.DEAD:
			state_name = "dead"

	# 切换状态机状态
	if state_name != "" and state_machine:
		state_machine.change_state(state_name)

	# 发送状态变化信号
	state_changed.emit(old_state, new_state)

# 设置目标
func set_target(new_target: ChessPiece) -> void:
	target = new_target

	# 如果有目标且不在攻击状态，切换到攻击状态
	if target and current_state != ChessState.ATTACKING and current_state != ChessState.DEAD:
		change_state(ChessState.ATTACKING)

# 清除目标
func clear_target() -> void:
	target = null

	# 如果在攻击状态，切换回空闲状态
	if current_state == ChessState.ATTACKING:
		change_state(ChessState.IDLE)

# 执行攻击
func _perform_attack() -> void:
	if not target or target.current_state == ChessState.DEAD:
		clear_target()
		return

	# 计算伤害
	var damage = attack_damage
	var is_crit = false
	var trigger_elemental = false

	# 检查暴击
	if randf() < crit_chance:
		damage *= crit_damage
		is_crit = true
		# 设置暴击元数据，供伤害数字管理器使用
		set_meta("last_attack_was_crit", true)
	else:
		# 清除暴击元数据
		if has_meta("last_attack_was_crit"):
			set_meta("last_attack_was_crit", false)

	# 检查元素效果
	if randf() < elemental_effect_chance:
		trigger_elemental = true

	# 造成伤害
	var actual_damage = target.take_damage(damage, "physical", self)

	# 触发攻击效果
	_on_attack(target, actual_damage, is_crit)

	# 触发元素效果
	if trigger_elemental:
		_trigger_elemental_effect(target)

	# 攻击后获得法力值
	gain_mana(10.0, "attack")

# 添加装备
func equip_item(equipment: Equipment) -> bool:
	# 根据装备类型选择槽位
	var slot: String
	match equipment.type:
		"weapon":
			if weapon_slot != null:
				return false
			slot = "weapon"
		"armor":
			if armor_slot != null:
				return false
			slot = "armor"
		"accessory":
			if accessory_slot != null:
				return false
			slot = "accessory"
		_:
			return false

	# 装备到对应槽位
	if equipment.equip_to(self):
		match slot:
			"weapon":
				weapon_slot = equipment
			"armor":
				armor_slot = equipment
			"accessory":
				accessory_slot = equipment

		# 更新视觉效果
		_update_equipment_visuals()
		return true

	return false

# 移除装备
func unequip_item(slot: String) -> Equipment:
	var equipment: Equipment = null

	# 根据槽位获取装备
	match slot:
		"weapon":
			equipment = weapon_slot
			weapon_slot = null
		"armor":
			equipment = armor_slot
			armor_slot = null
		"accessory":
			equipment = accessory_slot
			accessory_slot = null

	if equipment:
		# 卸下装备
		equipment.unequip_from()

		# 更新视觉效果
		_update_equipment_visuals()

		return equipment

	return null

# 添加效果
func add_effect(effect_data) -> void:
	# 获取特效管理器
	var game_manager = get_node_or_null("/root/GameManager")

	# 检查是否为新的效果系统
	if effect_data is BaseEffect:
		# 使用新的效果系统
		if game_manager and game_manager.effect_manager:
			# 设置目标
			effect_data.target = self

			# 添加效果
			game_manager.effect_manager.add_effect(effect_data)
		else:
			# 直接应用效果
			effect_data.target = self
			effect_data.apply()
	else:
		# 兼容旧系统，将字典效果转换为新的效果系统
		if game_manager and game_manager.effect_manager:
			# 使用特效管理器创建效果
			var effect = _convert_dict_to_effect(effect_data)

			# 如果转换成功，添加效果
			if effect:
				# 设置目标
				effect.target = self

				# 添加效果
				game_manager.effect_manager.add_effect(effect)
			else:
				# 旧系统兼容处理
				# 添加效果
				active_effects.append(effect_data)

				# 应用效果
				_apply_effect(effect_data)

				# 如果效果有持续时间，设置定时器
				if effect_data.has("duration") and effect_data.duration > 0:
					var timer = get_tree().create_timer(effect_data.duration)
					timer.timeout.connect(_on_effect_timeout.bind(effect_data))
		else:
			# 旧系统兼容处理
			# 添加效果
			active_effects.append(effect_data)

			# 应用效果
			_apply_effect(effect_data)

			# 如果效果有持续时间，设置定时器
			if effect_data.has("duration") and effect_data.duration > 0:
				var timer = get_tree().create_timer(effect_data.duration)
				timer.timeout.connect(_on_effect_timeout.bind(effect_data))

# 将字典转换为效果对象
func _convert_dict_to_effect(effect_data: Dictionary) -> BaseEffect:
	# 获取特效管理器
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return null

	# 创建效果ID
	var effect_id = effect_data.get("id", "effect_" + str(randi()))

	# 准备参数
	var params = {
		"id": effect_id,
		"name": effect_data.get("name", ""),
		"description": effect_data.get("description", ""),
		"duration": effect_data.get("duration", 0.0),
		"value": effect_data.get("value", 0.0),
		"source": effect_data.get("source", null)
	}

	# 根据效果类型创建不同的效果
	if effect_data.has("is_stun") and effect_data.is_stun:
		# 创建眩晕效果
		params["name"] = effect_data.get("name", "眩晕")
		params["description"] = effect_data.get("description", "无法行动")
		params["duration"] = effect_data.get("duration", 2.0)
		params["status_type"] = StatusEffect.StatusType.STUN

		return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STATUS, params["source"], self, params)

	elif effect_data.has("is_silence") and effect_data.is_silence:
		# 创建沉默效果
		params["name"] = effect_data.get("name", "沉默")
		params["description"] = effect_data.get("description", "无法施放技能")
		params["duration"] = effect_data.get("duration", 3.0)
		params["status_type"] = StatusEffect.StatusType.SILENCE

		return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STATUS, params["source"], self, params)

	elif effect_data.has("is_disarm") and effect_data.is_disarm:
		# 创建缴械效果
		params["name"] = effect_data.get("name", "缴械")
		params["description"] = effect_data.get("description", "无法普通攻击")
		params["duration"] = effect_data.get("duration", 3.0)
		params["status_type"] = StatusEffect.StatusType.DISARM

		return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STATUS, params["source"], self, params)

	elif effect_data.has("is_frozen") and effect_data.is_frozen:
		# 创建冰冻效果
		params["name"] = effect_data.get("name", "冰冻")
		params["description"] = effect_data.get("description", "无法移动")
		params["duration"] = effect_data.get("duration", 2.0)
		params["status_type"] = StatusEffect.StatusType.FROZEN

		return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STATUS, params["source"], self, params)

	elif effect_data.has("damage_per_second"):
		# 创建持续伤害效果
		var dot_type = DotEffect.DotType.BURNING
		var damage_type = "magical"
		var name = "燃烧"

		if effect_data.has("damage_type"):
			damage_type = effect_data.damage_type
			if damage_type == "fire":
				dot_type = DotEffect.DotType.BURNING
				name = "燃烧"
			elif damage_type == "poison":
				dot_type = DotEffect.DotType.POISONED
				name = "中毒"
			else:
				dot_type = DotEffect.DotType.BLEEDING
				name = "流血"

		params["name"] = effect_data.get("name", name)
		params["description"] = effect_data.get("description", "每秒造成伤害")
		params["duration"] = effect_data.get("duration", 3.0)
		params["value"] = effect_data.damage_per_second
		params["damage_type"] = damage_type
		params["dot_type"] = dot_type

		if effect_data.has("tick_interval"):
			params["tick_interval"] = effect_data.tick_interval

		return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.DOT, params["source"], self, params)

	elif effect_data.has("stats"):
		# 检查是增益还是减益
		var is_debuff = false
		for stat_name in effect_data.stats:
			if effect_data.stats[stat_name] < 0:
				is_debuff = true
				break

		if is_debuff:
			# 创建减益效果
			var debuff_type = DebuffEffect.DebuffType.ATTACK
			var value = 0.0

			# 根据属性确定减益类型
			if effect_data.stats.has("attack_damage"):
				debuff_type = DebuffEffect.DebuffType.ATTACK
				value = abs(effect_data.stats.attack_damage)
			elif effect_data.stats.has("armor") or effect_data.stats.has("magic_resist"):
				debuff_type = DebuffEffect.DebuffType.DEFENSE
				value = abs(effect_data.stats.get("armor", effect_data.stats.get("magic_resist", 0.0)))
			elif effect_data.stats.has("attack_speed") or effect_data.stats.has("move_speed"):
				debuff_type = DebuffEffect.DebuffType.SPEED
				value = abs(effect_data.stats.get("attack_speed", effect_data.stats.get("move_speed", 0.0) / 10.0))
			elif effect_data.stats.has("max_health"):
				debuff_type = DebuffEffect.DebuffType.HEALTH
				value = abs(effect_data.stats.max_health)

			params["name"] = effect_data.get("name", "减益")
			params["description"] = effect_data.get("description", "降低属性")
			params["duration"] = effect_data.get("duration", 5.0)
			params["value"] = value
			params["debuff_type"] = debuff_type
			params["stats"] = effect_data.stats

			return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STAT, params["source"], self, params)
		else:
			# 创建增益效果
			var buff_type = BuffEffect.BuffType.ATTACK
			var value = 0.0

			# 根据属性确定增益类型
			if effect_data.stats.has("attack_damage"):
				buff_type = BuffEffect.BuffType.ATTACK
				value = effect_data.stats.attack_damage
			elif effect_data.stats.has("armor") or effect_data.stats.has("magic_resist"):
				buff_type = BuffEffect.BuffType.DEFENSE
				value = effect_data.stats.get("armor", effect_data.stats.get("magic_resist", 0.0))
			elif effect_data.stats.has("attack_speed") or effect_data.stats.has("move_speed"):
				buff_type = BuffEffect.BuffType.SPEED
				value = effect_data.stats.get("attack_speed", effect_data.stats.get("move_speed", 0.0) / 10.0)
			elif effect_data.stats.has("max_health"):
				buff_type = BuffEffect.BuffType.HEALTH
				value = effect_data.stats.max_health

			params["name"] = effect_data.get("name", "增益")
			params["description"] = effect_data.get("description", "提升属性")
			params["duration"] = effect_data.get("duration", 5.0)
			params["value"] = value
			params["buff_type"] = buff_type
			params["stats"] = effect_data.stats

			return game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STAT, params["source"], self, params)

	return null

# 移除效果
func remove_effect(effect_id: String) -> void:
	# 获取特效管理器
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.effect_manager:
		# 使用新的效果系统
		game_manager.effect_manager.remove_effect(effect_id)
		return

	# 兼容旧系统
	# 先尝试使用状态效果管理器
	if status_effect_manager:
		status_effect_manager.remove_effect(effect_id)

	# 查找旧系统效果
	var index = -1

	# 查找效果
	for i in range(active_effects.size()):
		if active_effects[i].id == effect_id:
			index = i
			break

	if index == -1:
		return

	# 移除效果
	var effect_data = active_effects[index]
	active_effects.remove_at(index)

	# 重置属性并重新应用其他效果
	_reset_stats()
	for effect in active_effects:
		_apply_effect(effect)

	# 更新视觉效果
	_update_effect_visuals()

# 获取当前装备
func get_equipped_items() -> Array:
	var items = []
	if weapon_slot:
		items.append(weapon_slot)
	if armor_slot:
		items.append(armor_slot)
	if accessory_slot:
		items.append(accessory_slot)
	return items

# 应用效果
func _apply_effect(effect_data: Dictionary) -> void:
	# 应用效果逻辑
	if effect_data.has("stats"):
		var stats = effect_data.stats

		if stats.has("health"):
			max_health += stats.health
			current_health += stats.health

		if stats.has("attack_damage"):
			attack_damage += stats.attack_damage

		if stats.has("attack_speed"):
			attack_speed += stats.attack_speed

		if stats.has("armor"):
			armor += stats.armor

		if stats.has("magic_resist"):
			magic_resist += stats.magic_resist

		if stats.has("spell_power"):
			spell_power += stats.spell_power

		if stats.has("crit_chance"):
			crit_chance += stats.crit_chance

		if stats.has("crit_damage"):
			crit_damage += stats.crit_damage

		if stats.has("dodge_chance"):
			dodge_chance += stats.dodge_chance

	# 处理召唤物加成效果
	if effect_data.has("is_summon_boost") and effect_data.is_summon_boost:
		# 检查是否为召唤物
		if has_meta("is_summon") and get_meta("is_summon"):
			# 应用召唤物加成
			if effect_data.has("summon_health_boost"):
				var health_boost = max_health * effect_data.summon_health_boost
				max_health += health_boost
				current_health += health_boost

			if effect_data.has("summon_damage_boost"):
				attack_damage += attack_damage * effect_data.summon_damage_boost

	# 处理元素效果
	if effect_data.has("is_elemental_effect") and effect_data.is_elemental_effect:
		# 添加元素效果触发器
		if effect_data.has("elemental_chance"):
			elemental_effect_chance = effect_data.elemental_chance

	# 更新视觉效果
	_update_health_bar()
	_update_effect_visuals()

# 效果超时处理
func _on_effect_timeout(effect_data: Dictionary) -> void:
	remove_effect(effect_data.id)

# 保存基础属性
func _save_base_stats() -> void:
	base_stats = {
		"max_health": max_health,
		"attack_damage": attack_damage,
		"attack_speed": attack_speed,
		"armor": armor,
		"magic_resist": magic_resist,
		"move_speed": move_speed,
		"spell_power": spell_power,
		"crit_chance": crit_chance,
		"crit_damage": crit_damage,
		"dodge_chance": dodge_chance,
		"elemental_effect_chance": elemental_effect_chance,
		"control_resistance": control_resistance
	}

# 重置属性到基础值
func _reset_stats() -> void:
	max_health = base_stats.max_health
	attack_damage = base_stats.attack_damage
	attack_speed = base_stats.attack_speed
	armor = base_stats.armor
	magic_resist = base_stats.magic_resist
	move_speed = base_stats.move_speed
	base_move_speed = base_stats.move_speed  # 保存基础移动速度
	spell_power = base_stats.spell_power
	crit_chance = base_stats.crit_chance
	crit_damage = base_stats.crit_damage
	dodge_chance = base_stats.dodge_chance
	elemental_effect_chance = base_stats.elemental_effect_chance
	control_resistance = base_stats.control_resistance

	# 重置控制效果状态
	is_silenced = false
	is_disarmed = false
	is_frozen = false
	taunted_by = null

	# 确保当前生命值不超过最大生命值
	current_health = min(current_health, max_health)

	# 更新视觉效果
	_update_health_bar()
	_update_visuals()

# 重置棋子
func reset() -> void:
	# 重置状态
	current_state = ChessState.IDLE

	# 重置生命值和法力值
	current_health = max_health
	current_mana = 0

	# 重置目标
	target = null

	# 重置计时器
	attack_timer = 0
	current_cooldown = 0

	# 重置控制效果状态
	is_silenced = false
	is_disarmed = false
	is_frozen = false
	taunted_by = null

	# 重置效果
	active_effects.clear()

	# 清除状态效果 - 由效果系统处理

	# 清除效果系统中的所有效果
	var game_manager = Engine.get_singleton("GameManager")
	if game_manager and game_manager.effect_manager:
		# 清除与该棋子相关的所有效果
		for effect_id in game_manager.effect_manager.active_logical_effects.keys():
			var effect = game_manager.effect_manager.active_logical_effects[effect_id]
			if effect.target == self:
				game_manager.effect_manager.remove_effect(effect_id)

	# 更新显示
	_update_health_bar()
	_update_mana_bar()

	# 重置动画速度
	set_animation_speed(1.0)

# 设置动画速度
func set_animation_speed(speed: float) -> void:
	# 如果有动画播放器，设置其速度
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		anim_player.speed_scale = speed

	# 设置移动速度
	move_speed = base_move_speed * speed

# 初始化视觉组件
func _initialize_visuals() -> void:
	# 组件已在场景中创建，只需设置初始状态
	health_bar.max_value = max_health
	health_bar.value = current_health

	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

	# 更新星级指示器
	_update_star_indicator()

# 更新视觉效果
func _update_visuals() -> void:
	# 更新生命条和法力条
	_update_health_bar()
	_update_mana_bar()

	# 更新星级指示器
	_update_star_indicator()

	# 更新装备视觉效果
	_update_equipment_visuals()

	# 更新效果视觉效果
	_update_effect_visuals()

# 更新生命条
func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

# 更新法力条
func _update_mana_bar() -> void:
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = current_mana

# 更新星级指示器
func _update_star_indicator() -> void:
	# 清除现有星星
	for child in star_indicator.get_children():
		child.queue_free()

	# 添加星星
	for i in range(star_level):
		var star = ColorRect.new()  # 使用ColorRect代替Sprite2D作为占位符

		# 设置星星大小
		star.custom_minimum_size = Vector2(10, 10)

		# 根据星级设置颜色
		if star_level == 1:
			star.color = Color(0.8, 0.8, 0.8, 1)  # 灰色
		elif star_level == 2:
			star.color = Color(0.2, 0.6, 1.0, 1)  # 蓝色
		elif star_level == 3:
			star.color = Color(1.0, 0.8, 0.2, 1)  # 金色

		# 设置位置
		star.position = Vector2(i * 15 - (star_level - 1) * 7.5, -45)
		star_indicator.add_child(star)

		# 添加简单的动画效果
		var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(star, "modulate", Color(1, 1, 1, 0.7), 0.5)
		tween.tween_property(star, "modulate", Color(1, 1, 1, 1), 0.5)

# 更新装备视觉效果
func _update_equipment_visuals() -> void:
	# 清除现有装备视觉效果
	for child in effect_container.get_children():
		if child.has_meta("equipment_visual"):
			child.queue_free()

	# 添加武器视觉效果
	if weapon_slot:
		_add_equipment_visual(weapon_slot, Vector2(-20, 0), Color(0.8, 0.2, 0.2, 0.7))

	# 添加护甲视觉效果
	if armor_slot:
		_add_equipment_visual(armor_slot, Vector2(0, -20), Color(0.2, 0.2, 0.8, 0.7))

	# 添加饰品视觉效果
	if accessory_slot:
		_add_equipment_visual(accessory_slot, Vector2(20, 0), Color(0.8, 0.8, 0.2, 0.7))

# 添加装备视觉效果
func _add_equipment_visual(equipment: Equipment, offset: Vector2, color: Color) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建一个节点来放置装备效果
	var equipment_node = Node2D.new()
	equipment_node.set_meta("equipment_visual", true)
	equipment_node.position = offset
	effect_container.add_child(equipment_node)

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(equipment.type),
		"duration": 1.6,  # 总时间为两个周期
		"buff_type": equipment.type,
		"loop": true  # 循环效果
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.BUFF,
		equipment_node,
		params
	)

# 更新效果视觉效果
func _update_effect_visuals() -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 清除现有效果视觉
	for child in effect_container.get_children():
		if not child.has_meta("equipment_visual"):
			child.queue_free()

	# 添加效果视觉
	var offset = 0
	for effect in active_effects:
		if effect.has("visual"):
			# 创建一个节点来放置效果
			var effect_node = Node2D.new()
			effect_node.position = Vector2(offset, -50)
			effect_container.add_child(effect_node)

			# 获取效果类型
			var effect_type = effect.get("type", "buff")
			var visual_type = game_manager.effect_manager.VisualEffectType.BUFF

			# 根据效果类型选择视觉特效类型
			if effect_type in ["burning", "bleeding", "poisoned"]:
				visual_type = game_manager.effect_manager.VisualEffectType.DOT
			elif effect_type in ["stun", "silence", "disarm", "frozen"]:
				visual_type = game_manager.effect_manager.VisualEffectType.DEBUFF

			# 创建视觉特效参数
			var params = {
				"color": game_manager.effect_manager.get_effect_color(effect_type),
				"duration": 1.0,
				"buff_type": effect_type,
				"loop": true  # 循环效果
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_visual_effect(
				visual_type,
				effect_node,
				params
			)

			offset += 20

# 初始化状态机
func _initialize_state_machine() -> void:
	state_machine = StateMachine.new()
	add_child(state_machine)

	# 注册状态
	# 空闲状态
	state_machine.register_state("idle", {
		"enter": func(): _on_state_idle_enter(),
		"exit": func(): _on_state_idle_exit(),
		"physics_process": func(delta): _on_state_idle_process(delta)
	})

	# 移动状态
	state_machine.register_state("moving", {
		"enter": func(): _on_state_moving_enter(),
		"exit": func(): _on_state_moving_exit(),
		"physics_process": func(delta): _on_state_moving_process(delta)
	})

	# 攻击状态
	state_machine.register_state("attacking", {
		"enter": func(): _on_state_attacking_enter(),
		"exit": func(): _on_state_attacking_exit(),
		"physics_process": func(delta): _on_state_attacking_process(delta)
	})

	# 施法状态
	state_machine.register_state("casting", {
		"enter": func(): _on_state_casting_enter(),
		"exit": func(): _on_state_casting_exit(),
		"physics_process": func(delta): _on_state_casting_process(delta)
	})

	# 眩晕状态
	state_machine.register_state("stunned", {
		"enter": func(): _on_state_stunned_enter(),
		"exit": func(): _on_state_stunned_exit(),
		"physics_process": func(delta): _on_state_stunned_process(delta)
	})

	# 死亡状态
	state_machine.register_state("dead", {
		"enter": func(): _on_state_dead_enter(),
		"exit": func(): _on_state_dead_exit(),
		"physics_process": func(delta): _on_state_dead_process(delta)
	})

	# 设置初始状态
	state_machine.set_initial_state("idle")

# 初始化状态效果相关参数
func _initialize_status_effect_manager() -> void:
	# 设置控制抗性（根据星级提升）
	control_resistance = 0.1 * star_level  # 基础值10%，每星级提升10%

# 连接信号
func _connect_signals() -> void:
	# 连接必要的信号
	pass

# 受伤效果
func _on_damaged(amount: float, damage_type: String, source) -> void:
	# 处理受伤效果
	pass

# 治疗效果
func _on_healed(amount: float, source) -> void:
	# 处理治疗效果
	pass

# 攻击效果
func _on_attack(target: ChessPiece, damage: float, is_crit: bool) -> void:
	# 处理攻击效果
	# 如果是暴击，发送暴击信号
	if is_crit:
		critical_hit.emit(target, damage)

		# 获取特效管理器
		var game_manager = Engine.get_singleton("GameManager")
		if not game_manager or not game_manager.effect_manager:
			return

		# 创建视觉特效参数
		var params = {
			"color": game_manager.effect_manager.get_effect_color("physical"),
			"duration": 0.5,
			"damage_type": "physical",
			"damage_amount": damage,
			"is_critical": true
		}

		# 使用特效管理器创建特效
		game_manager.effect_manager.create_visual_effect(
			game_manager.effect_manager.VisualEffectType.DAMAGE,
			target,
			params
		)

# 闪避效果
func _on_dodge(attacker = null) -> void:
	# 处理闪避效果
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color("dodge"),
		"duration": 0.5,
		"buff_type": "dodge"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.BUFF,
		self,
		params
	)

	# 发送元素效果触发信号
	elemental_effect_triggered.emit(attacker, "dodge")

# 死亡效果
func _on_death() -> void:
	# 处理死亡效果
	pass

# 复活效果
func _on_resurrect() -> void:
	# 处理复活效果
	pass

# 触发元素效果
func _trigger_elemental_effect(target: ChessPiece) -> void:
	# 随机选择一种元素效果
	var effect_type = randi() % 4
	var element_name = ""

	match effect_type:
		0: # 火元素：造成额外的持续伤害
			_apply_fire_effect(target)
			element_name = "fire"
		1: # 冰元素：减速目标
			_apply_ice_effect(target)
			element_name = "ice"
		2: # 雷元素：有几率眼晕目标
			_apply_lightning_effect(target)
			element_name = "lightning"
		3: # 土元素：降低目标护甲
			_apply_earth_effect(target)
			element_name = "earth"

	# 发送元素效果触发信号
	elemental_effect_triggered.emit(target, element_name)

# 应用火元素效果
func _apply_fire_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建持续伤害效果参数
	var params = {
		"id": "fire_effect_" + str(randi()),
		"name": "火元素",
		"description": "每秒造成伤害",
		"duration": 3.0,
		"value": attack_damage * 0.1,
		"damage_type": "fire",
		"dot_type": DotEffect.DotType.BURNING
	}

	# 使用特效管理器创建效果
	game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.DOT, self, target, params)

	# 播放效果
	_play_elemental_effect(target, Color(1.0, 0.3, 0.1, 0.5))

# 火元素效果计时器 - 已由新系统处理
func _on_fire_effect_tick(target: ChessPiece, effect_data: Dictionary) -> void:
	# 此方法保留仅用于兼容旧系统
	pass

# 应用冰元素效果
func _apply_ice_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建减速效果参数
	var params = {
		"id": "ice_effect_" + str(randi()),
		"name": "冰元素",
		"description": "减速目标",
		"duration": 3.0,
		"value": 0.2,  # 减速值
		"debuff_type": DebuffEffect.DebuffType.SPEED
	}

	# 使用特效管理器创建效果
	game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STAT, self, target, params)

	# 播放效果
	_play_elemental_effect(target, Color(0.2, 0.6, 1.0, 0.5))

# 应用雷元素效果
func _apply_lightning_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建眼晕效果参数
	var params = {
		"id": "lightning_effect_" + str(randi()),
		"name": "雷元素",
		"description": "眼晕目标",
		"duration": 1.5,
		"status_type": StatusEffect.StatusType.STUN
	}

	# 使用特效管理器创建效果
	game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STATUS, self, target, params)

	# 播放效果
	_play_elemental_effect(target, Color(1.0, 1.0, 0.2, 0.5))

# 应用土元素效果
func _apply_earth_effect(target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建降低护甲效果参数
	var params = {
		"id": "earth_effect_" + str(randi()),
		"name": "土元素",
		"description": "降低目标护甲",
		"duration": 4.0,
		"value": 15.0,  # 护甲减少值
		"debuff_type": DebuffEffect.DebuffType.DEFENSE
	}

	# 使用特效管理器创建效果
	game_manager.effect_manager.create_and_add_effect(BaseEffect.EffectType.STAT, self, target, params)

	# 播放效果
	_play_elemental_effect(target, Color(0.6, 0.4, 0.2, 0.5))

# 播放元素效果
func _play_elemental_effect(target: ChessPiece, color: Color) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效参数
	var params = {
		"color": color,
		"duration": 0.8,
		"buff_type": "elemental"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.BUFF,
		target,
		params
	)

# ===== 状态处理函数 =====

# 空闲状态进入
func _on_state_idle_enter() -> void:
	# 播放空闲动画
	sprite.modulate = Color(1, 1, 1, 1)

# 空闲状态退出
func _on_state_idle_exit() -> void:
	pass

# 空闲状态处理
func _on_state_idle_process(delta: float) -> void:
	# 自动回蓝
	gain_mana(delta * 5.0)  # 每秒回复5点法力值

	# 如果有目标，切换到移动或攻击状态
	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range * 64:  # 假设一个格子是64像素
			state_machine.change_state("attacking")
		else:
			state_machine.change_state("moving")

# 移动状态进入
func _on_state_moving_enter() -> void:
	# 播放移动动画
	sprite.modulate = Color(0.8, 1.0, 0.8, 1)

# 移动状态退出
func _on_state_moving_exit() -> void:
	pass

# 移动状态处理
func _on_state_moving_process(delta: float) -> void:
	# 自动回蓝
	gain_mana(delta * 5.0)  # 每秒回复5点法力值

	# 如果没有目标，返回空闲状态
	if not target or target.current_state == ChessState.DEAD:
		target = null
		state_machine.change_state("idle")
		return

	# 检查是否被冰冻
	if is_frozen:
		return

	# 检查是否被嘲讽
	if taunted_by and is_instance_valid(taunted_by) and taunted_by.current_state != ChessState.DEAD:
		# 如果被嘲讽，强制将嘲讽源设为目标
		target = taunted_by

	# 移动到目标
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * move_speed * delta

	# 处理移动时的效果（如流血） - 由效果系统处理

	# 检查是否到达攻击范围
	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range * 64:  # 假设一个格子是64像素
		state_machine.change_state("attacking")

# 攻击状态进入
func _on_state_attacking_enter() -> void:
	# 播放攻击动画
	sprite.modulate = Color(1.0, 0.8, 0.8, 1)

	# 重置攻击计时器
	attack_timer = 0

# 攻击状态退出
func _on_state_attacking_exit() -> void:
	pass

# 攻击状态处理
func _on_state_attacking_process(delta: float) -> void:
	# 自动回蓝
	gain_mana(delta * 5.0)  # 每秒回复5点法力值

	# 如果没有目标或目标已死亡，返回空闲状态
	if not target or target.current_state == ChessState.DEAD:
		target = null
		state_machine.change_state("idle")
		return

	# 检查是否被嘲讽
	if taunted_by and is_instance_valid(taunted_by) and taunted_by.current_state != ChessState.DEAD:
		# 如果被嘲讽，强制将嘲讽源设为目标
		if target != taunted_by:
			target = taunted_by
			# 检查是否超出攻击范围
			var taunt_distance = global_position.distance_to(target.global_position)
			if taunt_distance > attack_range * 64:
				state_machine.change_state("moving")
				return

	# 检查是否超出攻击范围
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range * 64:  # 假设一个格子是64像素
		state_machine.change_state("moving")
		return

	# 更新攻击计时器
	if not is_disarmed:  # 检查是否被缴械
		attack_timer += delta
		if attack_timer >= 1.0 / attack_speed:
			attack_timer = 0
			_perform_attack()

	# 检查是否可以释放技能
	if current_mana >= ability_mana_cost and current_cooldown <= 0 and not is_silenced:
		activate_ability()

# 施法状态进入
func _on_state_casting_enter() -> void:
	# 播放施法动画
	sprite.modulate = Color(0.8, 0.8, 1.0, 1)

# 施法状态退出
func _on_state_casting_exit() -> void:
	pass

# 施法状态处理
func _on_state_casting_process(delta: float) -> void:
	# 施法完成后返回攻击或空闲状态
	if target and target.current_state != ChessState.DEAD:
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range * 64:  # 假设一个格子是64像素
			state_machine.change_state("attacking")
		else:
			state_machine.change_state("moving")
	else:
		state_machine.change_state("idle")

# 眩晕状态进入
func _on_state_stunned_enter() -> void:
	# 播放眩晕动画
	sprite.modulate = Color(0.7, 0.7, 0.7, 1)

# 眩晕状态退出
func _on_state_stunned_exit() -> void:
	pass

# 眩晕状态处理
func _on_state_stunned_process(delta: float) -> void:
	# 眩晕状态下不能行动
	pass

# 死亡状态进入
func _on_state_dead_enter() -> void:
	# 播放死亡动画
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

	# 清除目标
	target = null

# 死亡状态退出
func _on_state_dead_exit() -> void:
	pass

# 死亡状态处理
func _on_state_dead_process(delta: float) -> void:
	# 死亡状态下不能行动
	pass

# 检查是否嘲讽中
func is_taunting() -> bool:
	# 检查是否被嘲讽
	return taunted_by != null and is_instance_valid(taunted_by) and taunted_by.current_state != ChessState.DEAD

# 检查是否眩晕中
func is_stunned() -> bool:
	# 检查当前状态是否为眩晕
	return current_state == ChessState.STUNNED

# 播放升星特效
func _play_upgrade_effect(old_star_level: int, new_star_level: int, stat_increases: Dictionary) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建升星特效容器
	var upgrade_effect = Node2D.new()
	upgrade_effect.name = "UpgradeEffect"
	add_child(upgrade_effect)

	# 创建视觉特效参数
	var params = {
		"color": Color(1.0, 0.8, 0.0, 0.5),  # 金色
		"duration": 1.5,
		"buff_type": "level_up"
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.LEVEL_UP,
		upgrade_effect,
		params
	)

	# 创建星级文本
	var star_text = Label.new()
	star_text.text = str(old_star_level) + " → " + str(new_star_level) + " ★"
	star_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_text.size = Vector2(100, 30)
	star_text.position = Vector2(-50, -80)
	upgrade_effect.add_child(star_text)

	# 创建属性提升文本
	var y_offset = -50
	for stat_name in stat_increases:
		var increase = stat_increases[stat_name]
		if increase > 0:
			var stat_label = Label.new()
			var display_name = ""
			match stat_name:
				"health":
					display_name = "生命值"
				"attack":
					display_name = "攻击力"
				"ability":
					display_name = "技能伤害"
				_:
					display_name = stat_name

			stat_label.text = display_name + " +" + str(int(increase))
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stat_label.size = Vector2(100, 20)
			stat_label.position = Vector2(-50, y_offset)
			upgrade_effect.add_child(stat_label)
			y_offset += 20

	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(star_text, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.3)
	tween.tween_property(upgrade_effect, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(upgrade_effect.queue_free)

	# 播放升星音效
	EventBus.audio.emit_event("play_sound", ["upgrade", global_position])
