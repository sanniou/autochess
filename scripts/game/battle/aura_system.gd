extends Node
class_name AuraSystem
## 光环系统
## 处理棋子之间的光环效果和增益

# 光环类型
enum AuraType {
	BUFF,      # 增益光环
	DEBUFF     # 减益光环
}

# 光环范围形状
enum AuraShape {
	CIRCLE,    # 圆形范围
	SQUARE,    # 方形范围
	ROW,       # 行范围
	COLUMN     # 列范围
}

# 光环数据结构
class AuraData:
	var source: ChessPiece           # 光环来源
	var type: int = AuraType.BUFF    # 光环类型
	var shape: int = AuraShape.CIRCLE # 光环形状
	var range: float = 1.0           # 光环范围
	var effects: Array = []          # 光环效果
	var affected_pieces: Array = []  # 受影响的棋子
	var id: String = ""              # 光环唯一ID
	var visual_effect: Node2D = null  # 光环视觉效果
	var is_active: bool = true        # 光环是否激活
	var condition: Callable = null    # 光环触发条件
	var synergy_required: String = "" # 所需羁绊
	var synergy_level: int = 0        # 羁绊等级

	func _init(source_piece: ChessPiece, aura_id: String, aura_type: int, aura_shape: int, aura_range: float, aura_effects: Array):
		source = source_piece
		id = aura_id
		type = aura_type
		shape = aura_shape
		range = aura_range
		effects = aura_effects
		affected_pieces = []

		# 创建光环视觉效果
		_create_visual_effect()

# 活跃的光环
var active_auras: Array = []

# 引用
@onready var board_manager = get_node("/root/GameManager/BoardManager")

# 初始化
func _ready():
	# 连接信号
	EventBus.battle.connect_event("battle_started", _on_battle_started)
	EventBus.battle.connect_event("battle_ended", _on_battle_ended)
	EventBus.chess.connect_event("chess_piece_moved", _on_chess_piece_moved)
	EventBus.battle.connect_event("unit_died", _on_unit_died)

# 更新所有光环
func update_all_auras() -> void:
	# 清除所有光环效果
	_clear_all_aura_effects()

	# 重新应用所有光环
	for aura in active_auras:
		update_aura(aura)

# 更新单个光环
func update_aura(aura: AuraData) -> void:
	# 移除旧的影响
	for piece in aura.affected_pieces:
		if is_instance_valid(piece):
			_remove_aura_effects(aura, piece)

	# 清空受影响棋子列表
	aura.affected_pieces.clear()

	# 获取光环范围内的棋子
	var pieces_in_range = _get_pieces_in_aura_range(aura)

	# 应用光环效果
	for piece in pieces_in_range:
		if _can_affect_piece(aura, piece):
			_apply_aura_effects(aura, piece)
			aura.affected_pieces.append(piece)

# 添加光环
func add_aura(source: ChessPiece, aura_id: String, aura_type: int, aura_shape: int, aura_range: float, aura_effects: Array) -> AuraData:
	# 检查是否已存在相同ID的光环
	for aura in active_auras:
		if aura.id == aura_id and aura.source == source:
			# 更新现有光环
			aura.type = aura_type
			aura.shape = aura_shape
			aura.range = aura_range
			aura.effects = aura_effects
			update_aura(aura)
			return aura

	# 创建新光环
	var new_aura = AuraData.new(source, aura_id, aura_type, aura_shape, aura_range, aura_effects)

	# 创建光环视觉效果
	new_aura.visual_effect = _create_visual_effect()

	# 根据光环类型调整颜色
	if new_aura.visual_effect:
		var sprite = new_aura.visual_effect.get_child(0) if new_aura.visual_effect.get_child_count() > 0 else null
		if sprite and sprite is Sprite2D:
			if aura_type == AuraType.BUFF:
				sprite.modulate = Color(0.5, 0.8, 1.0, 0.3) # 蓝色增益光环
			else:
				sprite.modulate = Color(1.0, 0.5, 0.5, 0.3) # 红色减益光环

	# 添加到棋子上
	if source and is_instance_valid(source):
		if new_aura.visual_effect:
			source.add_child(new_aura.visual_effect)
			# 调整大小和位置
			new_aura.visual_effect.scale = Vector2(aura_range, aura_range)
			new_aura.visual_effect.position = Vector2.ZERO

	active_auras.append(new_aura)
	update_aura(new_aura)

	return new_aura

# 移除光环
func remove_aura(source: ChessPiece, aura_id: String) -> void:
	for i in range(active_auras.size() - 1, -1, -1):
		var aura = active_auras[i]
		if aura.id == aura_id and aura.source == source:
			# 移除光环效果
			for piece in aura.affected_pieces:
				if is_instance_valid(piece):
					_remove_aura_effects(aura, piece)

			# 移除光环
			active_auras.remove_at(i)
			break

# 移除棋子的所有光环
func remove_all_auras_from_piece(piece: ChessPiece) -> void:
	for i in range(active_auras.size() - 1, -1, -1):
		var aura = active_auras[i]
		if aura.source == piece:
			# 移除光环效果
			for affected in aura.affected_pieces:
				if is_instance_valid(affected):
					_remove_aura_effects(aura, affected)

			# 移除光环
			active_auras.remove_at(i)

# 获取光环范围内的棋子
func _get_pieces_in_aura_range(aura: AuraData) -> Array:
	var result = []

	# 获取光环源的格子
	var source_cell = board_manager._find_cell_with_piece(aura.source)
	if not source_cell:
		return result

	# 根据光环形状获取范围内的格子
	var cells_in_range = []
	match aura.shape:
		AuraShape.CIRCLE:
			cells_in_range = _get_cells_in_circle(source_cell, aura.range)
		AuraShape.SQUARE:
			cells_in_range = _get_cells_in_square(source_cell, aura.range)
		AuraShape.ROW:
			cells_in_range = _get_cells_in_row(source_cell)
		AuraShape.COLUMN:
			cells_in_range = _get_cells_in_column(source_cell)

	# 获取格子中的棋子
	for cell in cells_in_range:
		if cell.current_piece and cell.current_piece != aura.source:
			result.append(cell.current_piece)

	return result

# 获取圆形范围内的格子
func _get_cells_in_circle(center_cell: BoardCell, radius: float) -> Array:
	var result = []

	for row in board_manager.cells:
		for cell in row:
			var distance = Vector2(center_cell.grid_position).distance_to(Vector2(cell.grid_position))
			if distance <= radius:
				result.append(cell)

	return result

# 获取方形范围内的格子
func _get_cells_in_square(center_cell: BoardCell, radius: float) -> Array:
	var result = []
	var center_pos = center_cell.grid_position
	var range_int = int(radius)

	for y in range(center_pos.y - range_int, center_pos.y + range_int + 1):
		for x in range(center_pos.x - range_int, center_pos.x + range_int + 1):
			var pos = Vector2i(x, y)
			if board_manager.is_valid_cell(pos):
				result.append(board_manager.get_cell(pos))

	return result

# 获取同一行的格子
func _get_cells_in_row(center_cell: BoardCell) -> Array:
	var result = []
	var row_index = center_cell.grid_position.y

	if row_index >= 0 and row_index < board_manager.cells.size():
		result = board_manager.cells[row_index].duplicate()

	return result

# 获取同一列的格子
func _get_cells_in_column(center_cell: BoardCell) -> Array:
	var result = []
	var col_index = center_cell.grid_position.x

	for row in board_manager.cells:
		if col_index >= 0 and col_index < row.size():
			result.append(row[col_index])

	return result

# 检查是否可以影响棋子
func _can_affect_piece(aura: AuraData, piece: ChessPiece) -> bool:
	# 不能影响自己
	if piece == aura.source:
		return false

	# 根据光环类型检查阵营
	match aura.type:
		AuraType.BUFF:
			# 增益光环只影响友方
			return piece.is_player_piece == aura.source.is_player_piece
		AuraType.DEBUFF:
			# 减益光环只影响敌方
			return piece.is_player_piece != aura.source.is_player_piece

	return false

# 应用光环效果
func _apply_aura_effects(aura: AuraData, piece: ChessPiece) -> void:
	for effect in aura.effects:
		var effect_copy = effect.duplicate()
		effect_copy.id = "aura_%s_%s" % [aura.id, piece.get_instance_id()]
		effect_copy.source = aura.source

		# 添加效果
		piece.add_effect(effect_copy)

# 移除光环效果
func _remove_aura_effects(aura: AuraData, piece: ChessPiece) -> void:
	var effect_id = "aura_%s_%s" % [aura.id, piece.get_instance_id()]
	piece.remove_effect(effect_id)

# 清除所有光环效果
func _clear_all_aura_effects() -> void:
	for aura in active_auras:
		for piece in aura.affected_pieces:
			if is_instance_valid(piece):
				_remove_aura_effects(aura, piece)
		aura.affected_pieces.clear()

		# 移除光环视觉效果
		if aura.visual_effect and is_instance_valid(aura.visual_effect):
			aura.visual_effect.queue_free()
			aura.visual_effect = null

# 棋子移动事件处理
func _on_chess_piece_moved(_piece: ChessPiece, _from_pos: Vector2i, _to_pos: Vector2i) -> void:
	# 更新所有光环
	update_all_auras()

# 棋子死亡事件处理
func _on_unit_died(piece: ChessPiece) -> void:
	# 移除死亡棋子的所有光环
	remove_all_auras_from_piece(piece)

	# 更新所有光环
	update_all_auras()

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 初始化所有光环
	_initialize_auras()

# 战斗结束事件处理
func _on_battle_ended(_result) -> void:
	# 清除所有光环
	_clear_all_aura_effects()
	active_auras.clear()

# 初始化所有光环
func _initialize_auras() -> void:
	# 清除现有光环
	_clear_all_aura_effects()
	active_auras.clear()

	# 获取所有棋子
	var all_pieces = board_manager.pieces

	# 检查每个棋子的光环能力
	for piece in all_pieces:
		# 检查棋子是否有光环效果
		for effect in piece.active_effects:
			if effect.has("is_aura") and effect.is_aura:
				# 添加光环
				var aura_id = effect.get("id", "aura_%s" % piece.get_instance_id())
				var aura_type = effect.get("aura_type", AuraType.BUFF)
				var aura_shape = effect.get("aura_shape", AuraShape.CIRCLE)
				var aura_range = effect.get("aura_range", 1.0)
				var aura_effects = effect.get("aura_effects", [])

				# 检查是否有羁绊要求
				var synergy_required = effect.get("synergy_required", "")
				var synergy_level = effect.get("synergy_level", 0)

				var aura = add_aura(piece, aura_id, aura_type, aura_shape, aura_range, aura_effects)

				# 设置羁绊要求
				if synergy_required != "" and synergy_level > 0:
					aura.synergy_required = synergy_required
					aura.synergy_level = synergy_level

					# 检查羁绊是否激活
					var synergy_manager = get_node("/root/GameManager/SynergyManager")
					if synergy_manager:
						var active_level = synergy_manager.get_synergy_level(synergy_required)
						aura.is_active = active_level >= synergy_level

# 创建光环视觉效果
func _create_visual_effect() -> Node2D:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		# 如果没有特效管理器，创建基本的光环效果
		var visual = Node2D.new()

		# 创建光环精灵
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://assets/images/vfx/aura_circle.png") # 光环纹理占位
		sprite.modulate = Color(0.5, 0.8, 1.0, 0.3) # 默认蓝色光环
		visual.add_child(sprite)

		return visual

	# 创建光环容器
	var visual = Node2D.new()

	# 创建视觉特效参数
	var params = {
		"color": Color(0.5, 0.8, 1.0, 0.3),  # 默认蓝色光环
		"duration": 0.0,  # 持续存在
		"buff_type": "aura",
		"loop": true  # 循环效果
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.BUFF,
		visual,
		params
	)

	return visual
