extends Resource
class_name Ability
## 技能基类
## 定义技能的基本属性和行为

# 技能属性
var id: String = ""                # 技能ID
var name: String = ""              # 技能名称
var description: String = ""       # 技能描述
var icon: Texture2D = null         # 技能图标
var cooldown: float = 10.0         # 技能冷却时间
var mana_cost: float = 100.0       # 技能法力消耗
var damage: float = 0.0            # 技能伤害
var range: float = 0.0             # 技能范围
var duration: float = 0.0          # 技能持续时间
var target_type: String = "enemy"  # 技能目标类型(enemy/ally/self/area)

# 技能所有者
var owner: ChessPiece = null

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	# 设置技能属性
	id = ability_data.get("id", "")
	name = ability_data.get("name", "")
	description = ability_data.get("description", "")
	cooldown = ability_data.get("cooldown", 10.0)
	mana_cost = ability_data.get("mana_cost", 100.0)
	damage = ability_data.get("damage", 0.0)
	range = ability_data.get("range", 0.0)
	duration = ability_data.get("duration", 0.0)
	target_type = ability_data.get("target_type", "enemy")
	
	# 设置所有者
	owner = owner_piece

# 激活技能
func activate(target = null) -> bool:
	# 检查是否可以激活
	if not can_activate():
		return false
	
	# 消耗法力
	if not owner.spend_mana(mana_cost):
		return false
	
	# 执行技能效果
	_execute_effect(target)
	
	# 设置冷却
	owner.current_cooldown = cooldown
	
	return true

# 检查是否可以激活
func can_activate() -> bool:
	if owner == null:
		return false
	
	if owner.current_state == ChessPiece.ChessState.DEAD:
		return false
	
	if owner.current_mana < mana_cost:
		return false
	
	if owner.current_cooldown > 0:
		return false
	
	return true

# 获取技能目标
func get_target() -> ChessPiece:
	if owner == null:
		return null
	
	match target_type:
		"enemy":
			return _find_enemy_target()
		"ally":
			return _find_ally_target()
		"self":
			return owner
		"area":
			return null  # 区域技能没有特定目标
	
	return null

# 查找敌方目标
func _find_enemy_target() -> ChessPiece:
	# 默认使用所有者的当前目标
	if owner.target and owner.target.current_state != ChessPiece.ChessState.DEAD:
		return owner.target
	
	# 如果没有当前目标，查找最近的敌人
	var board_manager = owner.get_node("/root/GameManager/BoardManager")
	if board_manager:
		return board_manager.find_attack_target(owner)
	
	return null

# 查找友方目标
func _find_ally_target() -> ChessPiece:
	# 查找生命值最低的友方
	var board_manager = owner.get_node("/root/GameManager/BoardManager")
	if board_manager:
		var allies = board_manager.get_ally_pieces(owner.is_player_piece)
		var lowest_health_ally = null
		var lowest_health = INF
		
		for ally in allies:
			if ally.current_state != ChessPiece.ChessState.DEAD and ally.current_health < lowest_health:
				lowest_health = ally.current_health
				lowest_health_ally = ally
		
		return lowest_health_ally
	
	return null

# 执行技能效果（子类重写）
func _execute_effect(target = null) -> void:
	# 基础实现，子类应该重写此方法
	pass
