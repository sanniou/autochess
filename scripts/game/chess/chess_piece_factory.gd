extends Node
class_name ChessPieceFactory
## 棋子工厂
## 负责创建和初始化棋子

# 棋子场景路径
var chess_piece_scene_path: String = "res://scenes/game/chess/chess_piece.tscn"

# 棋子对象池
var chess_piece_pool: Array = []

# 初始化
func _init():
	pass

# 创建棋子
func create_chess_piece(chess_data: Dictionary) -> ChessPieceEntity:
	# 尝试从对象池获取棋子
	var chess_piece = _get_from_pool()
	
	# 如果对象池为空，创建新棋子
	if not chess_piece:
		chess_piece = _create_new_chess_piece()
	
	# 初始化棋子
	_initialize_chess_piece(chess_piece, chess_data)
	
	return chess_piece

# 回收棋子
func recycle_chess_piece(chess_piece: ChessPieceEntity) -> void:
	# 重置棋子
	chess_piece.reset()
	
	# 添加到对象池
	chess_piece_pool.append(chess_piece)
	
	# 从场景树移除
	if chess_piece.get_parent():
		chess_piece.get_parent().remove_child(chess_piece)

# 预热对象池
func warm_pool(count: int) -> void:
	for i in range(count):
		var chess_piece = _create_new_chess_piece()
		chess_piece_pool.append(chess_piece)

# 清空对象池
func clear_pool() -> void:
	for chess_piece in chess_piece_pool:
		if chess_piece and is_instance_valid(chess_piece):
			chess_piece.queue_free()
	
	chess_piece_pool.clear()

# 从对象池获取棋子
func _get_from_pool() -> ChessPieceEntity:
	if chess_piece_pool.is_empty():
		return null
	
	return chess_piece_pool.pop_back()

# 创建新棋子
func _create_new_chess_piece() -> ChessPieceEntity:
	# 加载棋子场景
	var chess_piece_scene = load(chess_piece_scene_path)
	if not chess_piece_scene:
		# 如果场景不存在，创建新节点
		var chess_piece = ChessPieceEntity.new()
		return chess_piece
	
	# 实例化棋子
	var chess_piece = chess_piece_scene.instantiate()
	
	return chess_piece

# 初始化棋子
func _initialize_chess_piece(chess_piece: ChessPieceEntity, chess_data: Dictionary) -> void:
	# 初始化棋子数据
	chess_piece.initialize_from_data(chess_data)
	
	# 设置棋子位置
	if chess_data.has("position"):
		chess_piece.position = chess_data.position
	
	# 设置棋子旋转
	if chess_data.has("rotation"):
		chess_piece.rotation = chess_data.rotation
	
	# 设置棋子缩放
	if chess_data.has("scale"):
		chess_piece.scale = chess_data.scale
	
	# 设置棋子可见性
	if chess_data.has("visible"):
		chess_piece.visible = chess_data.visible

# 从配置创建棋子
func create_from_config(config_id: String, is_player_piece: bool = true) -> ChessPieceEntity:
	# 获取棋子配置
	var chess_config = GameManager.chess_manager.get_chess_config(config_id)
	if not chess_config:
		return null
	
	# 创建棋子数据
	var chess_data = {
		"id": config_id,
		"name": chess_config.name,
		"description": chess_config.description,
		"level": 1,
		"is_player_piece": is_player_piece,
		"attributes": chess_config.attributes,
		"ability": chess_config.ability,
		"synergies": chess_config.synergies
	}
	
	# 创建棋子
	return create_chess_piece(chess_data)

# 创建随机棋子
func create_random_chess(tier: int = 1, is_player_piece: bool = true) -> ChessPieceEntity:
	# 获取指定等级的棋子配置
	var configs = GameManager.chess_manager.get_chess_configs_by_tier(tier)
	if configs.is_empty():
		return null
	
	# 随机选择一个配置
	var config_id = configs[randi() % configs.size()]
	
	# 创建棋子
	return create_from_config(config_id, is_player_piece)
