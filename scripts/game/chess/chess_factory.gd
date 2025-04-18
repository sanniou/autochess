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
func create_chess_piece(chess_id: String, star_level: int = 1, is_player_piece: bool = true) -> ChessPiece:
	# 检查棋子类型是否存在
	if not _chess_piece_types.has(chess_id):
		push_error("未知的棋子类型: " + chess_id)
		return null

	# 获取棋子数据
	var chess_data = _chess_piece_types[chess_id].duplicate()

	# 设置星级和所属
	chess_data["star_level"] = star_level
	chess_data["is_player_piece"] = is_player_piece

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

	# 发送创建信号
	var EventBus = Engine.get_singleton("EventBus")
	if EventBus:
		EventBus.chess.emit_event("chess_piece_created", [chess_piece])

	return chess_piece

## 释放棋子回对象池
func release_chess_piece(chess_piece: ChessPiece) -> void:
	if _chess_pool and chess_piece:
		_chess_pool.release_object("chess_pieces", chess_piece)

## 合并棋子升级
func merge_chess_pieces(pieces: Array) -> ChessPiece:
	if pieces.size() < 3:
		push_error("合并棋子需要至少3个相同棋子")
		return null

	# 检查棋子是否相同
	var first_piece = pieces[0]
	var chess_id = first_piece.get_id()
	var star_level = first_piece.get_property("star_level")

	for piece in pieces:
		if piece.get_id() != chess_id or piece.get_property("star_level") != star_level:
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
	var upgraded_piece = create_chess_piece(chess_id, star_level + 1, first_piece.get_property("is_player_piece"))

	# 设置升级后棋子的位置
	upgraded_piece.global_position = position

	# 释放原棋子
	for piece in pieces:
		release_chess_piece(piece)

	# 发送合并完成信号
	var EventBus = Engine.get_singleton("EventBus")
	if EventBus:
		EventBus.chess.emit_event("chess_pieces_merged", [pieces, upgraded_piece])

	return upgraded_piece

## 播放合并动画
func _play_merge_animation(pieces: Array, target_position: Vector2) -> void:
	# 创建动画
	for piece in pieces:
		var tween = piece.create_tween()
		tween.tween_property(piece, "global_position", target_position, 0.3)
		tween.tween_property(piece, "scale", Vector2(0.5, 0.5), 0.2)
		tween.tween_property(piece, "modulate", Color(1, 1, 1, 0), 0.2)

	# 播放合成音效
	var EventBus = Engine.get_singleton("EventBus")
	if EventBus:
		EventBus.audio.emit_event("play_sound", ["combine", target_position])
