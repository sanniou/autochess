extends "res://scripts/managers/core/base_manager.gd"
class_name DamageNumberManager
## 伤害数字管理器
## 负责显示战斗中的伤害数字、治疗数字和状态文本

# 伤害数字场景
var damage_number_scene = preload("res://scenes/battle/damage_number.tscn")

# 文字类型
enum TextType {
	DAMAGE,       # 伤害
	CRITICAL,     # 暴击伤害
	HEAL,         # 治疗
	BUFF,         # 增益
	DEBUFF,       # 减益
	IMMUNE,       # 免疫
	RESIST,       # 抵抗
	MISS,         # 闪避
	MANA_GAIN,    # 获得法力
	LEVEL_UP      # 升级
}

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

# 文字颜色
const TEXT_COLORS = {
	TextType.DAMAGE: Color(1.0, 0.3, 0.3),      # 红色
	TextType.CRITICAL: Color(1.0, 0.1, 0.1),    # 深红色
	TextType.HEAL: Color(0.3, 1.0, 0.3),        # 绿色
	TextType.BUFF: Color(0.3, 0.7, 1.0),        # 蓝色
	TextType.DEBUFF: Color(1.0, 0.5, 0.0),      # 橙色
	TextType.IMMUNE: Color(0.8, 0.8, 0.8),      # 灰色
	TextType.RESIST: Color(0.7, 0.7, 0.7),      # 浅灰色
	TextType.MISS: Color(0.9, 0.9, 0.9),        # 白色
	TextType.MANA_GAIN: Color(0.3, 0.3, 1.0),   # 蓝色
	TextType.LEVEL_UP: Color(1.0, 0.8, 0.0)     # 金色
}

# 文字大小
const TEXT_SIZES = {
	TextType.DAMAGE: 16,
	TextType.CRITICAL: 20,
	TextType.HEAL: 16,
	TextType.BUFF: 14,
	TextType.DEBUFF: 14,
	TextType.IMMUNE: 14,
	TextType.RESIST: 14,
	TextType.MISS: 14,
	TextType.MANA_GAIN: 12,
	TextType.LEVEL_UP: 18
}

# 文字前缀
const TEXT_PREFIXES = {
	TextType.DAMAGE: "",
	TextType.CRITICAL: "暴击! ",
	TextType.HEAL: "+",
	TextType.BUFF: "+",
	TextType.DEBUFF: "-",
	TextType.IMMUNE: "免疫",
	TextType.RESIST: "抵抗",
	TextType.MISS: "闪避",
	TextType.MANA_GAIN: "+",
	TextType.LEVEL_UP: "升级!"
}

# 文字后缀
const TEXT_SUFFIXES = {
	TextType.DAMAGE: "",
	TextType.CRITICAL: "",
	TextType.HEAL: "",
	TextType.BUFF: "",
	TextType.DEBUFF: "",
	TextType.IMMUNE: "",
	TextType.RESIST: "",
	TextType.MISS: "",
	TextType.MANA_GAIN: " 法力",
	TextType.LEVEL_UP: ""
}

# 字体
var _font: Font = null

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "DamageNumberManager"

	# 原 _ready 函数的内容
	# 加载默认字体
	_font = ThemeDB.fallback_font

	# 连接信号
	_connect_signals()

# 连接信号
func _connect_signals() -> void:
	# 连接伤害信号
	EventBus.battle.connect_event("damage_dealt", _on_damage_dealt)

	# 连接治疗信号
	EventBus.battle.connect_event("heal_received", _on_heal_received)

	# 连接状态效果信号
	EventBus.status_effect.connect_event("status_effect_added", _on_status_effect_added)
	EventBus.status_effect.connect_event("status_effect_resisted", _on_status_effect_resisted)

	# 连接法力值信号
	EventBus.battle.connect_event("mana_changed", _on_mana_changed)

	# 连接升级信号
	EventBus.chess.connect_event("chess_piece_upgraded", _on_chess_piece_upgraded)

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

# 创建浮动文字
func create_floating_text(position: Vector2, text: String, type: TextType) -> void:
	# 创建标签
	var damage_number = damage_number_scene.instantiate()

	# 设置文本
	var display_text = TEXT_PREFIXES[type] + text + TEXT_SUFFIXES[type]

	# 设置颜色和大小
	var color = TEXT_COLORS[type]
	var size = TEXT_SIZES[type]

	# 设置位置
	damage_number.position = position

	# 设置状态文本属性
	damage_number.set_status(display_text, color, size)

	# 添加到场景
	add_child(damage_number)

# 伤害事件处理
func _on_damage_dealt(source: ChessPieceEntity, target: ChessPieceEntity, amount: float, damage_type: String) -> void:
	# 检查是否是暴击
	var is_crit = false
	if source and source.has_meta("last_attack_was_crit"):
		is_crit = source.get_meta("last_attack_was_crit")

	# 显示伤害数字
	if is_crit:
		create_floating_text(target.global_position, str(int(amount)), TextType.CRITICAL)
		# 发送暴击信号
		EventBus.battle.emit_event("critical_hit", [source, target, amount])
	else:
		show_damage(target.global_position, amount, damage_type, false)

# 治疗事件处理
func _on_heal_received(target: ChessPieceEntity, amount: float, source = null) -> void:
	# 显示治疗数字
	show_heal(target.global_position, amount)

# 状态效果添加事件处理
func _on_status_effect_added(target: ChessPieceEntity, effect_id: String, effect_data: Dictionary) -> void:
	# 检查效果类型
	var effect_type = TextType.BUFF
	if effect_data.has("is_debuff") and effect_data.is_debuff:
		effect_type = TextType.DEBUFF

	# 获取效果名称
	var effect_name = effect_id
	if effect_data.has("name"):
		effect_name = effect_data.name

	# 显示效果文本
	create_floating_text(target.global_position, effect_name, effect_type)

# 状态效果抵抗事件处理
func _on_status_effect_resisted(target: ChessPieceEntity, effect_id: String) -> void:
	# 显示抵抗文本
	create_floating_text(target.global_position, "", TextType.RESIST)

# 法力值变化事件处理
func _on_mana_changed(piece: ChessPieceEntity, old_value: float, new_value: float, source: String) -> void:
	# 只处理获得法力的情况
	if new_value > old_value and source != "init":
		var amount = new_value - old_value
		create_floating_text(piece.global_position, str(int(amount)), TextType.MANA_GAIN)

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece: ChessPieceEntity, new_level: int) -> void:
	# 显示升级文本
	create_floating_text(piece.global_position, "", TextType.LEVEL_UP)

# 获取伤害类型颜色
func get_damage_color(damage_type: String) -> Color:
	if DAMAGE_COLORS.has(damage_type):
		return DAMAGE_COLORS[damage_type]
	return Color.WHITE

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写重置方法
func _do_reset() -> void:
	# 移除所有伤害数字
	for child in get_children():
		if child.is_in_group("damage_numbers"):
			child.queue_free()

	_log_info("伤害数字管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开信号连接
	EventBus.battle.disconnect_event("damage_dealt", _on_damage_dealt)
	EventBus.battle.disconnect_event("heal_received", _on_heal_received)
	EventBus.status_effect.disconnect_event("status_effect_added", _on_status_effect_added)
	EventBus.status_effect.disconnect_event("status_effect_resisted", _on_status_effect_resisted)
	EventBus.battle.disconnect_event("mana_changed", _on_mana_changed)
	EventBus.chess.disconnect_event("chess_piece_upgraded", _on_chess_piece_upgraded)

	# 移除所有伤害数字
	for child in get_children():
		if child.is_in_group("damage_numbers"):
			child.queue_free()

	_log_info("伤害数字管理器清理完成")