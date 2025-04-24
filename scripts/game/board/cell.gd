extends Area2D
class_name BoardCell
## 棋盘格子类
## 管理棋子的放置、移动和战斗交互

# 信号
signal piece_placed(piece)  # 棋子放置信号
signal piece_removed(piece) # 棋子移除信号
signal cell_clicked(cell)   # 格子点击信号
signal cell_hovered(cell)   # 格子悬停信号
signal cell_exited(cell)    # 格子离开信号

# 格子属性
var grid_position: Vector2i = Vector2i.ZERO  # 格子坐标
var current_piece = null                    # 当前棋子
var is_highlighted: bool = false            # 是否高亮
var is_playable: bool = true                # 是否可放置棋子
var cell_type: String = "normal"            # 格子类型(normal/spawn/blocked/bench/special)
var special_effect: String = ""             # 特殊效果(如buff/debuff区域)
var effect_value: float = 0.0               # 特殊效果值

# 视觉组件
@onready var highlight_sprite: Sprite2D = $HighlightSprite
@onready var base_sprite: Sprite2D = $BaseSprite
@onready var effect_sprite: Sprite2D = $EffectSprite
@onready var label: Label = $Label

# 鼠标交互
var is_hovered: bool = false

func _ready():
	# 初始化视觉组件
	_initialize_visuals()

	# 连接信号
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# 初始化视觉组件
func _initialize_visuals():
	# 组件已在场景中创建，只需设置初始状态
	highlight_sprite.visible = false
	effect_sprite.visible = false
	label.visible = false

# 放置棋子
func place_piece(piece) -> bool:
	# 检查棋子类型
	if not (piece is ChessPieceEntity or piece is ChessPieceEntity):
		push_error("无法识别的棋子类型")
		return false

	if not is_playable or current_piece != null:
		return false

	current_piece = piece

	# 设置棋子的棋盘位置
	if piece is ChessPieceEntity:
		piece.board_position = grid_position
		piece.position = position
		piece.is_player_piece = (cell_type == "spawn")  # 出生点棋子属于玩家
	#elif piece is ChessPieceAdapter:
		#piece.board_position = grid_position
		#piece.position = position
		#piece.is_player_piece = (cell_type == "spawn")
	elif piece is ChessPieceEntity:
		var target_component = piece.get_component("TargetComponent")
		if target_component:
			target_component.set_board_position(grid_position)

		piece.position = position
		piece.is_player_piece = (cell_type == "spawn")

	# 应用格子特殊效果
	if not special_effect.is_empty():
		_apply_cell_effect(piece)

	# 发送信号
	piece_placed.emit(piece)
	GlobalEventBus.board.dispatch_event(BoardEvents.PiecePlacedEvent.new(piece, self))

	return true

# 移除棋子
func remove_piece():
	if current_piece == null:
		return null

	var piece = current_piece
	current_piece = null

	# 设置棋子的棋盘位置
	if piece is ChessPieceEntity:
		piece.board_position = Vector2i(-1, -1)
	#elif piece is ChessPieceAdapter:
		#piece.board_position = Vector2i(-1, -1)
	elif piece is ChessPieceEntity:
		var target_component = piece.get_component("TargetComponent")
		if target_component:
			target_component.set_board_position(Vector2i(-1, -1))

	# 移除格子特殊效果
	if not special_effect.is_empty():
		_remove_cell_effect(piece)

	# 发送信号
	piece_removed.emit(piece)
	GlobalEventBus.board.dispatch_event(BoardEvents.PieceRemovedEvent.new(piece, self))

	return piece

# 高亮格子
func highlight(enable: bool, color: Color = Color.YELLOW, highlight_type: String = "default"):
	is_highlighted = enable
	highlight_sprite.visible = enable
	highlight_sprite.modulate = color

	# 根据高亮类型添加不同的视觉效果
	if enable:
		# 移除之前的高亮效果
		for child in get_children():
			if child.name.begins_with("HighlightEffect"):
				child.queue_free()

		# 创建新的高亮效果
		match highlight_type:
			"valid":
				# 有效放置高亮 - 添加脉动效果
				var pulse_effect = ColorRect.new()
				pulse_effect.name = "HighlightEffectPulse"
				pulse_effect.color = color
				pulse_effect.size = Vector2(64, 64)
				pulse_effect.position = Vector2(-32, -32)
				add_child(pulse_effect)

				# 创建脉动动画
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(pulse_effect, "modulate:a", 0.2, 0.8)
				tween.tween_property(pulse_effect, "modulate:a", 0.5, 0.8)

			"warning":
				# 警告放置高亮 - 添加边框效果
				var border_effect = ColorRect.new()
				border_effect.name = "HighlightEffectBorder"
				border_effect.color = Color(0, 0, 0, 0)
				border_effect.size = Vector2(64, 64)
				border_effect.position = Vector2(-32, -32)
				add_child(border_effect)

				# 创建边框
				var border_width = 3

				# 上边框
				var top_border = ColorRect.new()
				top_border.color = color
				top_border.size = Vector2(64, border_width)
				top_border.position = Vector2(0, 0)
				border_effect.add_child(top_border)

				# 右边框
				var right_border = ColorRect.new()
				right_border.color = color
				right_border.size = Vector2(border_width, 64)
				right_border.position = Vector2(64 - border_width, 0)
				border_effect.add_child(right_border)

				# 下边框
				var bottom_border = ColorRect.new()
				bottom_border.color = color
				bottom_border.size = Vector2(64, border_width)
				bottom_border.position = Vector2(0, 64 - border_width)
				border_effect.add_child(bottom_border)

				# 左边框
				var left_border = ColorRect.new()
				left_border.color = color
				left_border.size = Vector2(border_width, 64)
				left_border.position = Vector2(0, 0)
				border_effect.add_child(left_border)

				# 创建闪烁动画
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(border_effect, "modulate:a", 0.5, 0.5)
				tween.tween_property(border_effect, "modulate:a", 1.0, 0.5)

			_:
				# 默认高亮 - 仅显示高亮精灵
				pass
	else:
		# 移除所有高亮效果
		for child in get_children():
			if child.name.begins_with("HighlightEffect"):
				child.queue_free()

# 输入事件处理
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cell_clicked.emit(self)

# 鼠标进入事件处理
func _on_mouse_entered():
	is_hovered = true
	cell_hovered.emit(self)

	# 显示格子信息
	_show_cell_info(true)

# 鼠标离开事件处理
func _on_mouse_exited():
	is_hovered = false
	cell_exited.emit(self)

	# 隐藏格子信息
	_show_cell_info(false)

# 设置格子类型
func set_cell_type(type: String, texture: Texture2D = null):
	cell_type = type
	match type:
		"normal":
			is_playable = true
			base_sprite.modulate = Color(0.8, 0.8, 0.8)
		"spawn":
			is_playable = true
			base_sprite.modulate = Color(0.5, 0.8, 0.5)
		"blocked":
			is_playable = false
			base_sprite.modulate = Color(0.8, 0.5, 0.5)
		"bench":
			is_playable = true
			base_sprite.modulate = Color(0.7, 0.7, 0.9)
		"special":
			is_playable = true
			base_sprite.modulate = Color(0.9, 0.7, 0.9)

	# 设置高亮和效果精灵的纹理
	if texture:
		base_sprite.texture = texture
		highlight_sprite.texture = texture
		effect_sprite.texture = texture

	# 更新视觉效果
	_update_visuals()

# 获取相邻格子
func get_adjacent_cells(board_manager) -> Array:
	var adjacent = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for dir in directions:
		var pos = grid_position + dir
		if board_manager.is_valid_cell(pos):
			adjacent.append(board_manager.get_cell(pos))

	return adjacent

# 获取攻击范围内的格子
func get_attack_range_cells(board_manager, range: int) -> Array:
	var cells = []

	for x in range(-range, range + 1):
		for y in range(-range, range + 1):
			var pos = grid_position + Vector2i(x, y)
			if board_manager.is_valid_cell(pos) and (x != 0 or y != 0):
				cells.append(board_manager.get_cell(pos))

	return cells

# 判断是否有敌方棋子
func has_enemy_piece(is_player: bool) -> bool:
	if current_piece == null:
		return false

	var is_player_piece = false

	# 检查棋子类型
	if current_piece is ChessPieceEntity:
		is_player_piece = current_piece.is_player_piece
	#elif current_piece is ChessPieceAdapter:
		#is_player_piece = current_piece.is_player_piece
	elif current_piece is ChessPieceEntity:
		is_player_piece = current_piece.is_player_piece

	return is_player_piece != is_player

# 判断是否有友方棋子
func has_ally_piece(is_player: bool) -> bool:
	if current_piece == null:
		return false

	var is_player_piece = false

	# 检查棋子类型
	if current_piece is ChessPieceEntity:
		is_player_piece = current_piece.is_player_piece
	#elif current_piece is ChessPieceAdapter:
		#is_player_piece = current_piece.is_player_piece
	elif current_piece is ChessPieceEntity:
		is_player_piece = current_piece.is_player_piece

	return is_player_piece == is_player

# 设置特殊效果
func set_special_effect(effect: String, value: float = 0.0):
	special_effect = effect
	effect_value = value

	# 更新视觉效果
	_update_special_effect()

	# 如果已有棋子，应用效果
	if current_piece:
		_apply_cell_effect(current_piece)

# 清除特殊效果
func clear_special_effect():
	# 如果已有棋子，移除效果
	if current_piece and not special_effect.is_empty():
		_remove_cell_effect(current_piece)

	special_effect = ""
	effect_value = 0.0

	# 更新视觉效果
	_update_special_effect()

# 应用格子效果
func _apply_cell_effect(piece):
	# 检查棋子类型
	if piece is ChessPieceEntity:
		_apply_cell_effect_to_chess_piece(piece)
	#elif piece is ChessPieceAdapter:
		#_apply_cell_effect_to_adapter(piece)
	elif piece is ChessPieceEntity:
		_apply_cell_effect_to_entity(piece)

# 应用格子效果到旧棋子
func _apply_cell_effect_to_chess_piece(piece: ChessPieceEntity):
	match special_effect:
		"attack_buff":
			piece.attack_damage += effect_value
		"health_buff":
			piece.max_health += effect_value
			piece.current_health += effect_value
		"armor_buff":
			piece.armor += effect_value
		"speed_buff":
			piece.attack_speed += effect_value
		"damage_zone":
			# 持续伤害区域，在战斗系统中处理
			pass

# 应用格子效果到适配器
#func _apply_cell_effect_to_adapter(piece: ChessPieceAdapter):
	#match special_effect:
		#"attack_buff":
			#piece.attack_damage += effect_value
		#"health_buff":
			#piece.max_health += effect_value
			#piece.current_health += effect_value
		#"armor_buff":
			#piece.armor += effect_value
		#"speed_buff":
			#piece.attack_speed += effect_value
		#"damage_zone":
			## 持续伤害区域，在战斗系统中处理
			#pass

# 应用格子效果到新棋子实体
func _apply_cell_effect_to_entity(piece: ChessPieceEntity):
	# 获取属性组件
	var attribute_component = piece.get_component("AttributeComponent")
	if not attribute_component:
		return

	match special_effect:
		"attack_buff":
			attribute_component.add_attribute_modifier("attack_damage", {
				"value": effect_value,
				"type": "add",
				"duration": -1,  # 永久修改器
				"source": "cell_effect"
			})
		"health_buff":
			attribute_component.add_attribute_modifier("max_health", {
				"value": effect_value,
				"type": "add",
				"duration": -1,
				"source": "cell_effect"
			})
			attribute_component.add_health(effect_value)
		"armor_buff":
			attribute_component.add_attribute_modifier("armor", {
				"value": effect_value,
				"type": "add",
				"duration": -1,
				"source": "cell_effect"
			})
		"speed_buff":
			attribute_component.add_attribute_modifier("attack_speed", {
				"value": effect_value,
				"type": "add",
				"duration": -1,
				"source": "cell_effect"
			})
		"damage_zone":
			# 持续伤害区域，在战斗系统中处理
			pass

# 移除格子效果
func _remove_cell_effect(piece):
	# 检查棋子类型
	if piece is ChessPieceEntity:
		_remove_cell_effect_from_chess_piece(piece)
	#elif piece is ChessPieceAdapter:
		#_remove_cell_effect_from_adapter(piece)
	elif piece is ChessPieceEntity:
		_remove_cell_effect_from_entity(piece)

# 移除格子效果从旧棋子
func _remove_cell_effect_from_chess_piece(piece: ChessPieceEntity):
	match special_effect:
		"attack_buff":
			piece.attack_damage -= effect_value
		"health_buff":
			piece.max_health -= effect_value
			piece.current_health = min(piece.current_health, piece.max_health)
		"armor_buff":
			piece.armor -= effect_value
		"speed_buff":
			piece.attack_speed -= effect_value

# 移除格子效果从适配器
#func _remove_cell_effect_from_adapter(piece: ChessPieceAdapter):
	#match special_effect:
		#"attack_buff":
			#piece.attack_damage -= effect_value
		#"health_buff":
			#piece.max_health -= effect_value
			#piece.current_health = min(piece.current_health, piece.max_health)
		#"armor_buff":
			#piece.armor -= effect_value
		#"speed_buff":
			#piece.attack_speed -= effect_value

# 移除格子效果从新棋子实体
func _remove_cell_effect_from_entity(piece: ChessPieceEntity):
	# 获取属性组件
	var attribute_component = piece.get_component("AttributeComponent")
	if not attribute_component:
		return

	# 移除所有来自格子效果的修改器
	attribute_component.remove_modifiers_by_source("cell_effect")

# 更新特殊效果视觉
func _update_special_effect():
	effect_sprite.visible = not special_effect.is_empty()

	if not special_effect.is_empty():
		# 根据效果类型设置不同的纹理和颜色
		match special_effect:
			"attack_buff":
				effect_sprite.modulate = Color(1.0, 0.5, 0.5, 0.3)
			"health_buff":
				effect_sprite.modulate = Color(0.5, 1.0, 0.5, 0.3)
			"armor_buff":
				effect_sprite.modulate = Color(0.5, 0.5, 1.0, 0.3)
			"speed_buff":
				effect_sprite.modulate = Color(1.0, 1.0, 0.5, 0.3)
			"damage_zone":
				effect_sprite.modulate = Color(1.0, 0.3, 0.3, 0.3)

# 更新视觉效果
func _update_visuals():
	# 更新特殊效果
	_update_special_effect()

# 显示/隐藏格子信息
func _show_cell_info(show: bool):
	label.visible = show

	if show:
		var info_text = str(grid_position.x) + "," + str(grid_position.y)

		if not special_effect.is_empty():
			info_text += "\n" + special_effect
			if effect_value != 0:
				info_text += ": " + str(effect_value)

		label.text = info_text
