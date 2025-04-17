extends Node
class_name ChessFactory
## 棋子工厂
## 负责创建和管理棋子实例

# 棋子场景路径
const CHESS_PIECE_SCENE = "res://scenes/chess/chess_piece.tscn"

# 棋子类型映射
var _chess_piece_types = {}

# 对象池
var _chess_pool = null

# 技能工厂引用
var ability_factory = null

# 初始化
func _ready():
	# 注册棋子类型
	_register_chess_types()

	# 初始化对象池
	_initialize_pool()

	# 获取技能工厂引用
	ability_factory = get_node_or_null("/root/GameManager/AbilityFactory")

## 注册棋子类型
func _register_chess_types() -> void:
	# 从配置中加载棋子类型
	var chess_configs = ConfigManager.get_all_chess_pieces()

	for chess_id in chess_configs:
		var chess_model = chess_configs[chess_id] as ChessPieceConfig
		_chess_piece_types[chess_id] = chess_model.get_data()

## 初始化对象池
func _initialize_pool() -> void:
	# 获取对象池引用
	_chess_pool = get_node("/root/ObjectPool")

	if _chess_pool:
		# 创建棋子对象池
		var chess_scene = load(CHESS_PIECE_SCENE)
		if chess_scene:
			_chess_pool.create_pool("chess_pieces", chess_scene, 10, 5, 50)
		else:
			push_error("无法加载棋子场景: " + CHESS_PIECE_SCENE)
	else:
		push_error("无法获取对象池引用")

## 创建棋子
func create_chess_piece(chess_id: String, star_level: int = 1, is_player_piece: bool = true) -> Node2D:
	# 检查棋子类型是否存在
	if not _chess_piece_types.has(chess_id):
		push_error("未知的棋子类型: " + chess_id)
		return null

	# 获取棋子数据
	var chess_data = _chess_piece_types[chess_id]

	# 从对象池获取棋子实例
	var chess_piece = null
	if _chess_pool:
		chess_piece = _chess_pool.get_object("chess_pieces")

	# 如果对象池无法提供实例，直接实例化
	if not chess_piece:
		var chess_scene = load(CHESS_PIECE_SCENE)
		if chess_scene:
			chess_piece = chess_scene.instantiate()
		else:
			push_error("无法加载棋子场景: " + CHESS_PIECE_SCENE)
			return null

	# 初始化棋子
	chess_piece.initialize(chess_data)

	# 如果有技能工厂并且棋子有技能，使用技能工厂创建技能
	if ability_factory and chess_data.has("ability") and chess_data.ability.has("type"):
		chess_piece.ability = ability_factory.create_ability(chess_data.ability, chess_piece)

	# 设置星级
	if star_level > 1:
		for i in range(star_level - 1):
			chess_piece.upgrade()

	# 设置所属
	chess_piece.is_player_piece = is_player_piece

	# 发送创建信号
	EventBus.chess.emit_event("chess_piece_created", [chess_piece])

	return chess_piece

## 创建随机棋子
func create_random_chess_piece(cost_range: Array = [], star_level: int = 1, is_player_piece: bool = true) -> Node2D:
	# 筛选符合条件的棋子
	var valid_chess_ids = []

	for chess_id in _chess_piece_types:
		var chess_data = _chess_piece_types[chess_id]

		# 检查费用范围
		if cost_range.size() == 2:
			if chess_data.cost < cost_range[0] or chess_data.cost > cost_range[1]:
				continue

		valid_chess_ids.append(chess_id)

	# 如果没有符合条件的棋子，返回null
	if valid_chess_ids.size() == 0:
		push_error("没有符合条件的棋子")
		return null

	# 随机选择一个棋子
	var random_index = randi() % valid_chess_ids.size()
	var random_chess_id = valid_chess_ids[random_index]

	# 创建棋子
	return create_chess_piece(random_chess_id, star_level, is_player_piece)

## 创建特定羁绊的棋子
func create_synergy_chess_piece(synergy: String, cost_range: Array = [], star_level: int = 1, is_player_piece: bool = true) -> Node2D:
	# 筛选符合条件的棋子
	var valid_chess_ids = []

	for chess_id in _chess_piece_types:
		var chess_data = _chess_piece_types[chess_id]

		# 检查羁绊
		if not synergy in chess_data.synergies:
			continue

		# 检查费用范围
		if cost_range.size() == 2:
			if chess_data.cost < cost_range[0] or chess_data.cost > cost_range[1]:
				continue

		valid_chess_ids.append(chess_id)

	# 如果没有符合条件的棋子，返回null
	if valid_chess_ids.size() == 0:
		push_error("没有符合条件的棋子")
		return null

	# 随机选择一个棋子
	var random_index = randi() % valid_chess_ids.size()
	var random_chess_id = valid_chess_ids[random_index]

	# 创建棋子
	return create_chess_piece(random_chess_id, star_level, is_player_piece)

## 创建敌方棋子组合
func create_enemy_chess_set(difficulty: int, round_number: int) -> Array:
	# 根据难度和回合数生成敌方棋子组合
	var enemy_chess_set = []

	# 获取难度配置
	var difficulty_config = ConfigManager.get_difficulty_config(difficulty)
	if not difficulty_config:
		push_error("无法获取难度配置: " + str(difficulty))
		return enemy_chess_set

	# 计算敌方棋子数量和强度
	var enemy_count = _calculate_enemy_count(round_number)
	var enemy_strength = _calculate_enemy_strength(round_number, difficulty_config)

	# 生成敌方棋子
	for i in range(enemy_count):
		var cost_range = _calculate_cost_range(enemy_strength)
		var star_level = _calculate_star_level(enemy_strength)

		var enemy_piece = create_random_chess_piece(cost_range, star_level, false)
		if enemy_piece:
			enemy_chess_set.append(enemy_piece)

	return enemy_chess_set

## 计算敌方棋子数量
func _calculate_enemy_count(round_number: int) -> int:
	# 基础数量为3
	var base_count = 3

	# 每5回合增加1个棋子，最多9个
	var additional_count = min(round_number / 5, 6)

	return base_count + additional_count

## 计算敌方棋子强度
func _calculate_enemy_strength(round_number: int, difficulty_config: DifficultyConfig) -> float:
	# 基础强度
	var base_strength = 1.0

	# 回合加成
	var round_bonus = round_number * 0.1

	# 难度加成
	var difficulty_multiplier = difficulty_config.get_enemy_damage_multiplier()

	return base_strength + round_bonus * difficulty_multiplier

## 计算费用范围
func _calculate_cost_range(strength: float) -> Array:
	var min_cost = 1
	var max_cost = 1

	if strength < 1.5:
		max_cost = 2
	elif strength < 2.0:
		min_cost = 1
		max_cost = 3
	elif strength < 2.5:
		min_cost = 2
		max_cost = 4
	elif strength < 3.0:
		min_cost = 3
		max_cost = 5
	else:
		min_cost = 3
		max_cost = 5

	return [min_cost, max_cost]

## 计算星级
func _calculate_star_level(strength: float) -> int:
	var star_level = 1

	# 根据强度计算星级概率
	var star2_chance = min(0.1 + (strength - 1.0) * 0.2, 0.5)
	var star3_chance = max(0.0, (strength - 2.0) * 0.1)

	# 随机决定星级
	var roll = randf()
	if roll < star3_chance:
		star_level = 3
	elif roll < star3_chance + star2_chance:
		star_level = 2

	return star_level

## 释放棋子回对象池
func release_chess_piece(chess_piece: Node2D) -> void:
	if _chess_pool and chess_piece:
		_chess_pool.release_object("chess_pieces", chess_piece)

## 合并棋子升级
func merge_chess_pieces(pieces: Array) -> Node2D:
	if pieces.size() < 3:
		push_error("合并棋子需要至少3个相同棋子")
		return null

	# 检查棋子是否相同
	var first_piece = pieces[0]
	var chess_id = first_piece.id
	var star_level = first_piece.star_level

	for piece in pieces:
		if piece.id != chess_id or piece.star_level != star_level:
			push_error("合并棋子必须是相同类型和星级")
			return null

	# 如果已经是3星，无法再升级
	if star_level >= 3:
		push_error("3星棋子无法再升级")
		return null

	# 获取棋子的位置
	var position = first_piece.global_position

	# 创建合并动画
	_play_merge_animation(pieces, position)

	# 创建升级后的棋子
	var upgraded_piece = create_chess_piece(chess_id, star_level + 1, first_piece.is_player_piece)

	# 设置升级后棋子的位置
	upgraded_piece.global_position = position

	# 继承装备
	for i in range(min(pieces.size(), 3)):
		var piece = pieces[i]
		for equipment in piece.equipment_slots:
			if upgraded_piece.equipment_slots.size() < 3:  # 最多3个装备
				upgraded_piece.equip_item(equipment)

	# 释放原棋子
	for piece in pieces:
		release_chess_piece(piece)

	# 发送合并完成信号
	EventBus.chess.emit_event("chess_pieces_merged", [pieces, upgraded_piece])

	return upgraded_piece

## 播放合并动画
func _play_merge_animation(pieces: Array, target_position: Vector2) -> void:
	# 创建合并动画容器
	var merge_effect = Node2D.new()
	merge_effect.name = "MergeEffect"
	merge_effect.global_position = target_position
	get_tree().root.add_child(merge_effect)

	# 创建光环
	var light_ring = ColorRect.new()
	light_ring.color = Color(1.0, 0.8, 0.0, 0.5) # 金色
	light_ring.size = Vector2(120, 120)
	light_ring.position = Vector2(-60, -60)
	merge_effect.add_child(light_ring)

	# 创建合并文本
	var merge_text = Label.new()
	merge_text.text = "合并升星"
	merge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	merge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	merge_text.size = Vector2(120, 30)
	merge_text.position = Vector2(-60, -90)
	merge_effect.add_child(merge_text)

	# 创建合并动画
	var tween = merge_effect.create_tween()
	tween.tween_property(light_ring, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(light_ring, "scale", Vector2(1.0, 1.0), 0.3)
	tween.parallel().tween_property(merge_text, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.3)
	tween.tween_property(merge_effect, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(merge_effect.queue_free)

	# 播放合并音效
	EventBus.audio.emit_event("play_sound", ["merge", target_position])

## 获取棋子配置
func get_chess_config(chess_id: String) -> Dictionary:
	if _chess_piece_types.has(chess_id):
		return _chess_piece_types[chess_id]
	return {}

## 获取所有棋子配置
func get_all_chess_configs() -> Dictionary:
	return _chess_piece_types

## 获取特定费用的棋子
func get_chess_by_cost(cost: int) -> Array:
	var result = []

	for chess_id in _chess_piece_types:
		var chess_data = _chess_piece_types[chess_id]
		if chess_data.cost == cost:
			result.append(chess_id)

	return result

## 获取特定羁绊的棋子
func get_chess_by_synergy(synergy: String) -> Array:
	var result = []

	for chess_id in _chess_piece_types:
		var chess_data = _chess_piece_types[chess_id]
		if synergy in chess_data.synergies:
			result.append(chess_id)

	return result
