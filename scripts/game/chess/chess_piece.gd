extends Node2D
class_name ChessPiece
## 棋子基类
## 定义棋子的基本属性和行为

# 信号
signal health_changed(old_value, new_value)
signal mana_changed(old_value, new_value)
signal state_changed(old_state, new_state)
signal ability_activated(target)
signal died

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
var crit_chance: float = 0.0       # 暴击几率
var crit_damage: float = 1.5       # 暴击伤害
var dodge_chance: float = 0.0      # 闪避几率
var spell_power: float = 0.0       # 法术强度

# 技能属性
var ability_name: String = ""      # 技能名称
var ability_description: String = "" # 技能描述
var ability_damage: float = 0.0    # 技能伤害
var ability_cooldown: float = 0.0  # 技能冷却时间
var ability_range: float = 0.0     # 技能范围
var ability_mana_cost: float = 100.0 # 技能法力消耗
var current_cooldown: float = 0.0  # 当前冷却时间

# 装备和效果
var weapon_slot: Equipment = null  # 武器槽
var armor_slot: Equipment = null   # 护甲槽
var accessory_slot: Equipment = null # 饰品槽
var active_effects: Array = []     # 激活的效果

# 位置和目标
var board_position: Vector2i = Vector2i(-1, -1)  # 棋盘位置
var target: ChessPiece = null      # 当前目标
var attack_timer: float = 0.0      # 攻击计时器

# 当前状态
var current_state: int = ChessState.IDLE

# 视觉组件引用
var sprite: Sprite2D
var health_bar: ProgressBar
var mana_bar: ProgressBar
var star_indicator: Node2D
var effect_container: Node2D

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
	
	# 保存基础属性
	_save_base_stats()
	
	# 连接信号
	_connect_signals()

# 物理更新
func _physics_process(delta):
	# 更新状态机
	if state_machine:
		state_machine.physics_process(delta)
	
	# 更新冷却时间
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown < 0:
			current_cooldown = 0
	
	# 更新攻击计时器
	if current_state == ChessState.ATTACKING:
		attack_timer += delta
		if attack_timer >= 1.0 / attack_speed:
			attack_timer = 0
			_perform_attack()
	
	# 自动回蓝
	if current_state != ChessState.DEAD and current_mana < max_mana:
		gain_mana(delta * 10.0)  # 每秒回复10点法力值

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
	
	# 设置技能属性
	if piece_data.has("ability"):
		ability_name = piece_data.ability.name
		ability_description = piece_data.ability.description
		ability_damage = piece_data.ability.damage
		ability_cooldown = piece_data.ability.cooldown
		ability_range = piece_data.ability.range
	
	# 保存基础属性
	_save_base_stats()
	
	# 更新视觉效果
	_update_visuals()

# 升级棋子
func upgrade() -> void:
	if star_level >= 3:
		return
	
	star_level += 1
	
	# 根据星级提升属性
	var multiplier = 1.0
	if star_level == 2:
		multiplier = 1.8
	elif star_level == 3:
		multiplier = 3.0
	
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	ability_damage *= multiplier
	
	# 更新视觉效果
	_update_visuals()
	
	# 发送升级信号
	EventBus.chess_piece_upgraded.emit(self)

# 受到伤害
func take_damage(amount: float, damage_type: String = "physical", source = null) -> float:
	if current_state == ChessState.DEAD:
		return 0
	
	# 检查闪避
	if randf() < dodge_chance:
		# 触发闪避效果
		_on_dodge()
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
	gain_mana(actual_damage * 0.1)
	
	# 发送伤害信号
	EventBus.damage_dealt.emit(source, self, actual_damage, damage_type)
	
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
	
	# 触发治疗效果
	_on_healed(amount, source)
	
	return current_health - old_health

# 获得法力值
func gain_mana(amount: float) -> float:
	if current_state == ChessState.DEAD:
		return 0
	
	var old_mana = current_mana
	current_mana = min(current_mana + amount, max_mana)
	
	# 更新法力值显示
	mana_changed.emit(old_mana, current_mana)
	_update_mana_bar()
	
	# 检查是否可以释放技能
	if current_mana >= ability_mana_cost and current_cooldown <= 0:
		activate_ability()
	
	return current_mana - old_mana

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
	if current_state == ChessState.DEAD or current_cooldown > 0 or current_mana < ability_mana_cost:
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
	
	# 发送技能激活信号
	ability_activated.emit(target)
	EventBus.chess_piece_ability_activated.emit(self, target)
	
	return true

# 执行技能（子类重写）
func _perform_ability() -> void:
	# 基础实现，子类应该重写此方法
	pass

# 死亡
func die() -> void:
	if current_state == ChessState.DEAD:
		return
	
	# 切换到死亡状态
	change_state(ChessState.DEAD)
	
	# 发送死亡信号
	died.emit()
	EventBus.unit_died.emit(self)
	
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
	
	# 处理状态变化
	match new_state:
		ChessState.IDLE:
			# 重置攻击计时器
			attack_timer = 0
		ChessState.ATTACKING:
			# 开始攻击计时器
			attack_timer = 0
		ChessState.CASTING:
			# 播放施法动画
			pass
		ChessState.STUNNED:
			# 应用眩晕效果
			pass
		ChessState.DEAD:
			# 应用死亡效果
			pass
	
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
	
	# 检查暴击
	if randf() < crit_chance:
		damage *= crit_damage
		is_crit = true
	
	# 造成伤害
	var actual_damage = target.take_damage(damage, "physical", self)
	
	# 触发攻击效果
	_on_attack(target, actual_damage, is_crit)
	
	# 攻击后获得法力值
	gain_mana(10.0)

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
func add_effect(effect_data: Dictionary) -> void:
	# 添加效果
	active_effects.append(effect_data)
	
	# 应用效果
	_apply_effect(effect_data)
	
	# 如果效果有持续时间，设置定时器
	if effect_data.has("duration") and effect_data.duration > 0:
		var timer = get_tree().create_timer(effect_data.duration)
		timer.timeout.connect(_on_effect_timeout.bind(effect_data))

# 移除效果
func remove_effect(effect_id: String) -> void:
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
		"dodge_chance": dodge_chance
	}

# 重置属性到基础值
func _reset_stats() -> void:
	max_health = base_stats.max_health
	attack_damage = base_stats.attack_damage
	attack_speed = base_stats.attack_speed
	armor = base_stats.armor
	magic_resist = base_stats.magic_resist
	move_speed = base_stats.move_speed
	spell_power = base_stats.spell_power
	crit_chance = base_stats.crit_chance
	crit_damage = base_stats.crit_damage
	dodge_chance = base_stats.dodge_chance
	
	# 确保当前生命值不超过最大生命值
	current_health = min(current_health, max_health)
	
	# 更新视觉效果
	_update_health_bar()
	_update_visuals()

# 初始化视觉组件
func _initialize_visuals() -> void:
	# 创建精灵
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# 创建生命条
	health_bar = ProgressBar.new()
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.size = Vector2(50, 5)
	health_bar.position = Vector2(-25, -40)
	add_child(health_bar)
	
	# 创建法力条
	mana_bar = ProgressBar.new()
	mana_bar.max_value = 100
	mana_bar.value = 0
	mana_bar.size = Vector2(50, 3)
	mana_bar.position = Vector2(-25, -35)
	add_child(mana_bar)
	
	# 创建星级指示器
	star_indicator = Node2D.new()
	add_child(star_indicator)
	
	# 创建效果容器
	effect_container = Node2D.new()
	add_child(effect_container)

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
		var star = Sprite2D.new()
		# 这里应该设置星星的纹理
		star.position = Vector2(i * 10 - (star_level - 1) * 5, -45)
		star_indicator.add_child(star)

# 更新装备视觉效果
func _update_equipment_visuals() -> void:
	# 实现装备视觉效果更新
	pass

# 更新效果视觉效果
func _update_effect_visuals() -> void:
	# 清除现有效果视觉
	for child in effect_container.get_children():
		child.queue_free()
	
	# 添加效果视觉
	var offset = 0
	for effect in active_effects:
		if effect.has("visual"):
			var effect_sprite = Sprite2D.new()
			# 设置效果纹理
			effect_sprite.position = Vector2(offset, -50)
			effect_container.add_child(effect_sprite)
			offset += 10

# 初始化状态机
func _initialize_state_machine() -> void:
	state_machine = StateMachine.new()
	add_child(state_machine)
	
	# 注册状态
	# 这里应该创建并注册各种状态
	
	# 设置初始状态
	state_machine.set_initial_state("idle")

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
	pass

# 闪避效果
func _on_dodge() -> void:
	# 处理闪避效果
	pass

# 死亡效果
func _on_death() -> void:
	# 处理死亡效果
	pass

# 复活效果
func _on_resurrect() -> void:
	# 处理复活效果
	pass
