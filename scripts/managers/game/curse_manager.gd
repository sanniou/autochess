extends "res://scripts/managers/core/base_manager.gd"
class_name CurseManager
## 诅咒管理器
## 负责管理游戏中的诅咒效果

# 当前激活的诅咒
var active_curses = {}  # {诅咒类型: {duration: 剩余回合, effect: 效果}}

# 诅咒效果配置
var curse_effects = {
	"mirror": {
		"name": "镜像诅咒",
		"description": "每次战斗开始时，随机一个棋子的攻击力和生命值互换",
		"effect": "swap_stats"
	},
	"greed": {
		"name": "贪婪诅咒",
		"description": "每次获得金币时，有30%概率减少1金币",
		"effect": "reduce_gold"
	},
	"weakness": {
		"name": "虚弱诅咒",
		"description": "所有棋子的攻击力降低15%",
		"effect": "reduce_attack"
	},
	"fragility": {
		"name": "脆弱诅咒",
		"description": "所有棋子的生命值降低15%",
		"effect": "reduce_health"
	},
	"confusion": {
		"name": "混乱诅咒",
		"description": "每次战斗开始时，有25%概率随机交换两个棋子的位置",
		"effect": "swap_positions"
	}
}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "CurseManager"

	# 原 _ready 函数的内容
	# 连接信号
	EventBus.battle.connect_event("battle_round_started", _on_battle_round_started)
	EventBus.economy.connect_event("gold_changed", _on_gold_changed)
	EventBus.battle.connect_event("battle_started", _on_battle_started)

# 应用诅咒
func apply_curse(curse_type: String, duration: int) -> bool:
	# 检查诅咒类型是否有效
	if not curse_effects.has(curse_type):
		EventBus.debug.emit_event("debug_message", ["无效的诅咒类型: " + curse_type, 2])
		return false

	# 获取诅咒效果
	var effect = curse_effects[curse_type]

	# 添加或更新诅咒
	active_curses[curse_type] = {
		"duration": duration,
		"effect": effect
	}

	# 发送诅咒应用信号
	EventBus.debug.emit_event("debug_message", ["应用诅咒: " + effect.name + ", 持续" + str(duration) + "回合", 0])

	# 立即应用持续性诅咒效果
	_apply_persistent_curse_effects()

	return true

# 移除诅咒
func remove_curse(curse_type: String) -> bool:
	# 检查诅咒是否存在
	if not active_curses.has(curse_type):
		return false

	# 获取诅咒效果
	var curse_data = active_curses[curse_type]
	var effect = curse_data.effect

	# 移除诅咒
	active_curses.erase(curse_type)

	# 发送诅咒移除信号
	EventBus.debug.emit_event("debug_message", ["移除诅咒: " + effect.name, 0])

	# 移除持续性诅咒效果
	_remove_persistent_curse_effects(curse_type)

	return true

# 获取所有激活的诅咒
func get_active_curses() -> Dictionary:
	return active_curses.duplicate()

# 检查诅咒是否激活
func is_curse_active(curse_type: String) -> bool:
	return active_curses.has(curse_type)

# 获取诅咒剩余回合数
func get_curse_duration(curse_type: String) -> int:
	if active_curses.has(curse_type):
		return active_curses[curse_type].duration
	return 0

# 回合开始事件处理
func _on_battle_round_started(round_number: int) -> void:
	# 更新诅咒持续时间
	_update_curse_durations()

	# 应用回合开始诅咒效果
	_apply_round_start_curse_effects()

# 更新诅咒持续时间
func _update_curse_durations() -> void:
	var curses_to_remove = []

	# 遍历所有诅咒
	for curse_type in active_curses:
		# 减少持续时间
		active_curses[curse_type].duration -= 1

		# 检查是否到期
		if active_curses[curse_type].duration <= 0:
			curses_to_remove.append(curse_type)

	# 移除到期的诅咒
	for curse_type in curses_to_remove:
		remove_curse(curse_type)

# 应用回合开始诅咒效果
func _apply_round_start_curse_effects() -> void:
	# 遍历所有诅咒
	for curse_type in active_curses:
		var effect_type = active_curses[curse_type].effect.effect

		match effect_type:
			"swap_stats":
				_apply_mirror_curse()

# 应用持续性诅咒效果
func _apply_persistent_curse_effects() -> void:
	# 遍历所有诅咒
	for curse_type in active_curses:
		var effect_type = active_curses[curse_type].effect.effect

		match effect_type:
			"reduce_attack":
				_apply_weakness_curse()
			"reduce_health":
				_apply_fragility_curse()

# 移除持续性诅咒效果
func _remove_persistent_curse_effects(curse_type: String) -> void:
	if not curse_effects.has(curse_type):
		return

	var effect_type = curse_effects[curse_type].effect

	match effect_type:
		"reduce_attack":
			_remove_weakness_curse()
		"reduce_health":
			_remove_fragility_curse()

# 金币变化事件处理
func _on_gold_changed(old_amount: int, new_amount: int) -> void:
	# 检查是否是增加金币
	if new_amount > old_amount and is_curse_active("greed"):
		# 应用贪婪诅咒效果
		_apply_greed_curse(old_amount, new_amount)

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 应用战斗开始诅咒效果
	if is_curse_active("confusion"):
		_apply_confusion_curse()

# 应用镜像诅咒效果
func _apply_mirror_curse() -> void:
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 获取所有玩家棋子
	var player_pieces = board_manager.get_all_player_pieces()
	if player_pieces.is_empty():
		return

	# 随机选择一个棋子
	var random_piece = player_pieces[randi() % player_pieces.size()]

	# 交换攻击力和生命值
	var attack = random_piece.attack_damage
	var health = random_piece.current_health

	random_piece.attack_damage = health
	random_piece.current_health = attack
	random_piece.max_health = attack

	# 发送诅咒效果应用信号
	EventBus.debug.emit_event("debug_message", ["镜像诅咒效果: 交换了" + random_piece.name + "的攻击力和生命值", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.curse.mirror_applied"), random_piece.name])

# 应用贪婪诅咒效果
func _apply_greed_curse(old_amount: int, new_amount: int) -> void:
	var player_manager = GameManager.player_manager
	if not player_manager:
		return

	# 30%概率触发
	if randf() < 0.3:
		# 减少1金币
		var player = player_manager.get_current_player()
		if player:
			player.gold -= 1

			# 发送诅咒效果应用信号
			EventBus.debug.emit_event("debug_message", ["贪婪诅咒效果: 减少1金币", 0])
			EventBus.ui.emit_event("show_toast", [tr("ui.curse.greed_applied")])

# 应用虚弱诅咒效果
func _apply_weakness_curse() -> void:
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 获取所有玩家棋子
	var player_pieces = board_manager.get_all_player_pieces()

	# 降低所有棋子的攻击力
	for piece in player_pieces:
		var original_attack = piece.attack_damage
		piece.attack_damage = int(original_attack * 0.85)

	# 发送诅咒效果应用信号
	EventBus.debug.emit_event("debug_message", ["虚弱诅咒效果: 所有棋子攻击力降低15%", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.curse.weakness_applied")])

# 移除虚弱诅咒效果
func _remove_weakness_curse() -> void:
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 获取所有玩家棋子
	var player_pieces = board_manager.get_all_player_pieces()

	# 恢复所有棋子的攻击力
	for piece in player_pieces:
		var current_attack = piece.attack_damage
		piece.attack_damage = int(current_attack / 0.85)

	# 发送诅咒效果移除信号
	EventBus.debug.emit_event("debug_message", ["虚弱诅咒效果已移除", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.curse.weakness_removed")])

# 应用脆弱诅咒效果
func _apply_fragility_curse() -> void:
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 获取所有玩家棋子
	var player_pieces = board_manager.get_all_player_pieces()

	# 降低所有棋子的生命值
	for piece in player_pieces:
		var original_health = piece.max_health
		piece.max_health = int(original_health * 0.85)
		piece.current_health = min(piece.current_health, piece.max_health)

	# 发送诅咒效果应用信号
	EventBus.debug.emit_event("debug_message", ["脆弱诅咒效果: 所有棋子生命值降低15%", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.curse.fragility_applied")])

# 移除脆弱诅咒效果
func _remove_fragility_curse() -> void:
	var board_manager = GameManager.board_manager
	if not board_manager:
		return

	# 获取所有玩家棋子
	var player_pieces = board_manager.get_all_player_pieces()

	# 恢复所有棋子的生命值
	for piece in player_pieces:
		var current_health = piece.max_health
		var new_max_health = int(current_health / 0.85)
		var health_diff = new_max_health - current_health

		piece.max_health = new_max_health
		piece.current_health += health_diff

	# 发送诅咒效果移除信号
	EventBus.debug.emit_event("debug_message", ["脆弱诅咒效果已移除", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.curse.fragility_removed")])

# 应用混乱诅咒效果
func _apply_confusion_curse() -> void:
	# 25%概率触发
	if randf() < 0.25:
		var board_manager = GameManager.board_manager
		if not board_manager:
			return

		# 获取所有玩家棋子
		var player_pieces = board_manager.get_all_player_pieces()
		if player_pieces.size() < 2:
			return

		# 随机选择两个棋子
		var index1 = randi() % player_pieces.size()
		var index2 = randi() % player_pieces.size()

		# 确保选择不同的棋子
		while index1 == index2:
			index2 = randi() % player_pieces.size()

		var piece1 = player_pieces[index1]
		var piece2 = player_pieces[index2]

		# 交换位置
		var pos1 = piece1.board_position
		var pos2 = piece2.board_position

		board_manager.move_piece(piece1, pos2)
		board_manager.move_piece(piece2, pos1)

		# 发送诅咒效果应用信号
		EventBus.debug.emit_event("debug_message", ["混乱诅咒效果: 交换了" + piece1.name + "和" + piece2.name + "的位置", 0])
		EventBus.ui.emit_event("show_toast", [tr("ui.curse.confusion_applied"), [piece1.name, piece2.name]])


# 重写重置方法
func _do_reset() -> void:
	# 移除所有诅咒
	var curse_types = active_curses.keys()
	for curse_type in curse_types:
		remove_curse(curse_type)

	active_curses.clear()

	_log_info("诅咒管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.battle.disconnect_event("battle_round_started", _on_battle_round_started)
	EventBus.economy.disconnect_event("gold_changed", _on_gold_changed)
	EventBus.battle.disconnect_event("battle_started", _on_battle_started)

	# 移除所有诅咒
	var curse_types = active_curses.keys()
	for curse_type in curse_types:
		remove_curse(curse_type)

	active_curses.clear()

	_log_info("诅咒管理器清理完成")
