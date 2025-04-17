extends Control
## 战斗测试场景
## 用于测试战斗系统的功能

# 棋盘引用
@onready var board = $ChessBoard
@onready var status_label = $StatusLabel
@onready var effect_buttons = $EffectButtons

# 棋子场景
var chess_piece_scene = preload("res://scenes/chess/chess_piece.tscn")

# 当前选中的棋子
var selected_piece: ChessPiece = null

# 棋子数据
var test_pieces = [
	{
		"id": "warrior",
		"name": "战士",
		"description": "近战物理攻击单位",
		"cost": 1,
		"health": 100,
		"attack_damage": 10,
		"attack_speed": 1.0,
		"attack_range": 1,
		"armor": 5,
		"magic_resist": 0,
		"move_speed": 300,
		"synergies": ["fighter", "human"],
		"ability": {
			"name": "英勇打击",
			"description": "对目标造成物理伤害并短暂眩晕",
			"damage": 20,
			"cooldown": 8.0,
			"range": 1,
			"type": "damage"
		}
	},
	{
		"id": "archer",
		"name": "弓箭手",
		"description": "远程物理攻击单位",
		"cost": 2,
		"health": 80,
		"attack_damage": 15,
		"attack_speed": 0.8,
		"attack_range": 3,
		"armor": 0,
		"magic_resist": 0,
		"move_speed": 280,
		"synergies": ["ranger", "elf"],
		"ability": {
			"name": "穿透射击",
			"description": "对直线上的敌人造成物理伤害",
			"damage": 30,
			"cooldown": 10.0,
			"range": 4,
			"type": "chain"
		}
	},
	{
		"id": "mage",
		"name": "法师",
		"description": "远程魔法攻击单位",
		"cost": 3,
		"health": 70,
		"attack_damage": 8,
		"attack_speed": 0.7,
		"attack_range": 4,
		"armor": 0,
		"magic_resist": 10,
		"move_speed": 270,
		"synergies": ["mage", "human"],
		"ability": {
			"name": "火球术",
			"description": "对范围内的敌人造成魔法伤害",
			"damage": 40,
			"cooldown": 12.0,
			"range": 3,
			"type": "area_damage"
		}
	},
	{
		"id": "tank",
		"name": "坦克",
		"description": "近战防御单位",
		"cost": 3,
		"health": 150,
		"attack_damage": 5,
		"attack_speed": 0.6,
		"attack_range": 1,
		"armor": 15,
		"magic_resist": 15,
		"move_speed": 250,
		"synergies": ["guardian", "orc"],
		"ability": {
			"name": "嘲讽",
			"description": "嘲讽周围敌人，迫使他们攻击自己",
			"damage": 0,
			"cooldown": 15.0,
			"range": 2,
			"type": "taunt"
		}
	}
]

func _ready():
	# 初始化测试
	_initialize_test()

	# 更新状态标签
	_update_status_label()

# 初始化测试
func _initialize_test():
	# 连接信号
	EventBus.connect("board_initialized", _on_board_initialized)
	EventBus.connect("chess_piece_moved", _on_chess_piece_moved)
	EventBus.connect("chess_piece_upgraded", _on_chess_piece_upgraded)
	EventBus.connect("chess_piece_ability_activated", _on_chess_piece_ability_activated)
	EventBus.connect("unit_died", _on_unit_died)

	# 初始化效果按钮
	_initialize_effect_buttons()

# 初始化效果按钮
func _initialize_effect_buttons():
	# 禁用所有效果按钮，直到选择棋子
	for button in effect_buttons.get_children():
		button.disabled = true

# 添加棋子按钮处理
func _on_add_piece_button_pressed():
	# 随机选择一个棋子类型
	var piece_data = test_pieces[randi() % test_pieces.size()]

	# 创建棋子
	var piece = chess_piece_scene.instantiate()
	piece.initialize(piece_data)

	# 随机选择一个空格子
	var empty_cells = _get_empty_cells()
	if empty_cells.size() > 0:
		var cell = empty_cells[randi() % empty_cells.size()]
		cell.place_piece(piece)
		print("添加棋子: %s 到位置 %s" % [piece_data.name, cell.grid_position])

		# 连接棋子信号
		piece.connect("pressed", _on_chess_piece_pressed.bind(piece))
	else:
		print("没有空格子可放置棋子")
		piece.queue_free()

	# 更新状态标签
	_update_status_label()

# 移除棋子按钮处理
func _on_remove_piece_button_pressed():
	# 随机选择一个有棋子的格子
	var occupied_cells = _get_occupied_cells()
	if occupied_cells.size() > 0:
		var cell = occupied_cells[randi() % occupied_cells.size()]
		var piece = cell.remove_piece()
		if piece:
			print("移除棋子: %s 从位置 %s" % [piece.display_name, cell.grid_position])
			piece.queue_free()

			# 如果移除的是当前选中的棋子，清除选择
			if piece == selected_piece:
				selected_piece = null
				_update_effect_buttons()
	else:
		print("没有棋子可移除")

	# 更新状态标签
	_update_status_label()

# 重置棋盘按钮处理
func _on_reset_board_button_pressed():
	board.reset_board()
	selected_piece = null
	_update_effect_buttons()
	print("棋盘已重置")

	# 更新状态标签
	_update_status_label()

# 开始战斗按钮处理
func _on_start_battle_button_pressed():
	EventBus.battle.battle_started.emit()
	print("战斗开始")

	# 更新状态标签
	_update_status_label()

# 结束战斗按钮处理
func _on_end_battle_button_pressed():
	EventBus.battle.battle_ended.emit(true)  # 假设玩家获胜
	print("战斗结束")

	# 更新状态标签
	_update_status_label()

# 棋盘初始化事件处理
func _on_board_initialized():
	print("棋盘已初始化")

# 棋子移动事件处理
func _on_chess_piece_moved(piece, from_pos, to_pos):
	print("棋子移动: %s 从 %s 到 %s" % [piece.display_name, from_pos, to_pos])

# 棋子升级事件处理
func _on_chess_piece_upgraded(piece):
	print("棋子升级: %s 到 %d 星" % [piece.display_name, piece.star_level])

# 棋子技能激活事件处理
func _on_chess_piece_ability_activated(piece, target):
	print("棋子技能激活: %s 对 %s 使用了 %s" % [piece.display_name, target.display_name if target else "无目标", piece.ability_name])

# 单位死亡事件处理
func _on_unit_died(unit):
	print("单位死亡: %s" % unit.display_name)

	# 如果死亡的是当前选中的棋子，清除选择
	if unit == selected_piece:
		selected_piece = null
		_update_effect_buttons()

	# 更新状态标签
	_update_status_label()

# 棋子点击事件处理
func _on_chess_piece_pressed(piece):
	selected_piece = piece
	print("选中棋子: %s" % piece.display_name)

	# 更新效果按钮
	_update_effect_buttons()

# 更新效果按钮状态
func _update_effect_buttons():
	for button in effect_buttons.get_children():
		button.disabled = (selected_piece == null)

# 眩晕效果按钮处理
func _on_stun_button_pressed():
	if selected_piece:
		# 添加眩晕效果
		var effect_data = {
			"id": "test_stun_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.STUN,
			"duration": 3.0,
			"value": 1.0,
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加眩晕效果到: %s" % selected_piece.display_name)

# 沉默效果按钮处理
func _on_silence_button_pressed():
	if selected_piece:
		# 添加沉默效果
		var effect_data = {
			"id": "test_silence_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.SILENCE,
			"duration": 5.0,
			"value": 1.0,
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加沉默效果到: %s" % selected_piece.display_name)

# 减速效果按钮处理
func _on_slow_button_pressed():
	if selected_piece:
		# 添加减速效果
		var effect_data = {
			"id": "test_slow_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.SLOW,
			"duration": 4.0,
			"value": 0.3,  # 减速30%
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加减速效果到: %s" % selected_piece.display_name)

# 缴械效果按钮处理
func _on_disarm_button_pressed():
	if selected_piece:
		# 添加缴械效果
		var effect_data = {
			"id": "test_disarm_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.DISARM,
			"duration": 3.0,
			"value": 1.0,
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加缴械效果到: %s" % selected_piece.display_name)

# 嘲讽效果按钮处理
func _on_taunt_button_pressed():
	if selected_piece:
		# 添加嘲讽效果
		var effect_data = {
			"id": "test_taunt_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.TAUNT,
			"duration": 4.0,
			"value": 1.0,
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加嘲讽效果到: %s" % selected_piece.display_name)

# 增益效果按钮处理
func _on_buff_button_pressed():
	if selected_piece:
		# 添加增益效果
		var effect_data = {
			"id": "test_buff_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.BUFF,
			"duration": 10.0,
			"value": 1.0,
			"source": self
		}

		# 设置增益属性
		effect_data.source.set_meta("buff_stats", {
			"attack_damage": 10.0,
			"attack_speed": 0.2,
			"armor": 5.0,
			"magic_resist": 5.0
		})

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加增益效果到: %s" % selected_piece.display_name)

# 减益效果按钮处理
func _on_debuff_button_pressed():
	if selected_piece:
		# 添加减益效果
		var effect_data = {
			"id": "test_debuff_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.DEBUFF,
			"duration": 8.0,
			"value": 1.0,
			"source": self
		}

		# 设置减益属性
		effect_data.source.set_meta("debuff_stats", {
			"attack_damage": 5.0,
			"attack_speed": 0.1,
			"armor": 3.0,
			"magic_resist": 3.0
		})

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加减益效果到: %s" % selected_piece.display_name)

# 冰冻效果按钮处理
func _on_frozen_button_pressed():
	if selected_piece:
		# 添加冰冻效果
		var effect_data = {
			"id": "test_frozen_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.FROZEN,
			"duration": 4.0,
			"value": 1.0,
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加冰冻效果到: %s" % selected_piece.display_name)

# 燃烧效果按钮处理
func _on_burning_button_pressed():
	if selected_piece:
		# 添加燃烧效果
		var effect_data = {
			"id": "test_burning_" + str(randi()),
			"type": StatusEffectManager.StatusEffectType.BURNING,
			"duration": 5.0,
			"value": 10.0,  # 每秒造成10点伤害
			"source": self
		}

		if selected_piece.status_effect_manager:
			selected_piece.status_effect_manager.add_effect(effect_data)
			print("添加燃烧效果到: %s" % selected_piece.display_name)

# 清除效果按钮处理
func _on_clear_effects_button_pressed():
	if selected_piece and selected_piece.status_effect_manager:
		selected_piece.status_effect_manager.clear_all_effects()
		print("清除所有效果: %s" % selected_piece.display_name)

# 获取所有空格子
func _get_empty_cells() -> Array:
	var empty_cells = []

	# 检查棋盘格子
	for row in board.cells:
		for cell in row:
			if cell.is_playable and not cell.current_piece:
				empty_cells.append(cell)

	# 检查备战区格子
	for cell in board.bench_cells:
		if cell.is_playable and not cell.current_piece:
			empty_cells.append(cell)

	return empty_cells

# 获取所有有棋子的格子
func _get_occupied_cells() -> Array:
	var occupied_cells = []

	# 检查棋盘格子
	for row in board.cells:
		for cell in row:
			if cell.current_piece:
				occupied_cells.append(cell)

	# 检查备战区格子
	for cell in board.bench_cells:
		if cell.current_piece:
			occupied_cells.append(cell)

	return occupied_cells

# 更新状态标签
func _update_status_label():
	var total_pieces = _get_occupied_cells().size()
	var status_text = "棋盘状态: %d 个棋子" % total_pieces

	if selected_piece:
		status_text += "\n选中: %s (生命: %.1f/%.1f, 法力: %.1f/%.1f)" % [
			selected_piece.display_name,
			selected_piece.current_health,
			selected_piece.max_health,
			selected_piece.current_mana,
			selected_piece.max_mana
		]

	status_label.text = status_text
