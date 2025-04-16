extends Node2D
class_name DamageNumberManager
## 伤害数字管理器
## 负责显示战斗中的伤害数字

# 伤害数字场景
var damage_number_scene = preload("res://scenes/battle/damage_number.tscn")

# 伤害类型颜色
const DAMAGE_COLORS = {
	"physical": Color(1.0, 0.3, 0.3),  # 物理伤害 - 红色
	"magical": Color(0.5, 0.3, 1.0),   # 魔法伤害 - 紫色
	"fire": Color(1.0, 0.5, 0.0),      # 火焰伤害 - 橙色
	"ice": Color(0.3, 0.7, 1.0),       # 冰冻伤害 - 浅蓝色
	"lightning": Color(1.0, 0.9, 0.0), # 闪电伤害 - 黄色
	"poison": Color(0.0, 0.8, 0.0),    # 毒素伤害 - 绿色
	"true": Color(1.0, 1.0, 1.0),      # 真实伤害 - 白色
	"heal": Color(0.0, 1.0, 0.5)       # 治疗 - 浅绿色
}

# 初始化
func _ready():
	pass

# 显示伤害数字
func show_damage(position: Vector2, amount: float, damage_type: String = "physical", is_critical: bool = false) -> void:
	# 创建伤害数字实例
	var damage_number = damage_number_scene.instantiate()
	
	# 设置伤害数字属性
	damage_number.position = position
	damage_number.set_damage(amount, damage_type, is_critical)
	
	# 添加到场景
	add_child(damage_number)

# 显示治疗数字
func show_heal(position: Vector2, amount: float, is_critical: bool = false) -> void:
	show_damage(position, amount, "heal", is_critical)

# 显示经验值数字
func show_exp(position: Vector2, amount: float) -> void:
	# 创建伤害数字实例
	var damage_number = damage_number_scene.instantiate()
	
	# 设置经验值数字属性
	damage_number.position = position
	damage_number.set_exp(amount)
	
	# 添加到场景
	add_child(damage_number)

# 显示金币数字
func show_gold(position: Vector2, amount: float) -> void:
	# 创建伤害数字实例
	var damage_number = damage_number_scene.instantiate()
	
	# 设置金币数字属性
	damage_number.position = position
	damage_number.set_gold(amount)
	
	# 添加到场景
	add_child(damage_number)

# 显示状态文本
func show_status(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	# 创建伤害数字实例
	var damage_number = damage_number_scene.instantiate()
	
	# 设置状态文本属性
	damage_number.position = position
	damage_number.set_status(text, color)
	
	# 添加到场景
	add_child(damage_number)

# 获取伤害类型颜色
func get_damage_color(damage_type: String) -> Color:
	if DAMAGE_COLORS.has(damage_type):
		return DAMAGE_COLORS[damage_type]
	return Color.WHITE
