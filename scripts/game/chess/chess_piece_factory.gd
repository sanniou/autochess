extends Node
class_name ChessPieceFactory
## 棋子工厂
## 负责创建和初始化棋子

# 棋子场景路径
var chess_piece_scene_path: String = "res://scenes/game/chess/chess_piece_entity.tscn"

# 对象池名称
const CHESS_POOL_NAME = "chess_piece_pool"

# 初始化
func _init():
	# 初始化对象池
	_initialize_object_pool()

# 初始化对象池
func _initialize_object_pool() -> void:
	# 检查对象池是否已存在
	if not ObjectPool._pools.has(CHESS_POOL_NAME):
		# 加载棋子场景
		var chess_piece_scene = load(chess_piece_scene_path)
		if chess_piece_scene:
			# 创建对象池
			ObjectPool.create_pool(
				CHESS_POOL_NAME,
				chess_piece_scene,
				20,  # 初始大小
				10,  # 增长大小
				100  # 最大大小
			)

			# 设置对象池自动调整参数
			ObjectPool.set_auto_resize_settings({
				"enabled": true,
				"check_interval": 2.0,
				"usage_threshold": 0.7,
				"min_grow_size": 5,
				"max_grow_size": 20,
				"shrink_threshold": 0.3,
				"shrink_interval": 20.0,
				"min_pool_size": 10
			})

# 创建棋子
func create_chess_piece(chess_data: Dictionary) -> ChessPieceEntity:
	# 尝试从对象池获取棋子
	var chess_piece = ObjectPool.get_object(CHESS_POOL_NAME) as ChessPieceEntity

	# 如果对象池无法提供实例，创建新棋子
	if not chess_piece:
		# 加载棋子场景
		var chess_piece_scene = load(chess_piece_scene_path)
		if not chess_piece_scene:
			return null

		# 实例化棋子
		chess_piece = chess_piece_scene.instantiate() as ChessPieceEntity

	# 初始化棋子
	_initialize_chess_piece(chess_piece, chess_data)

	return chess_piece

# 回收棋子
func recycle_chess_piece(chess_piece: ChessPieceEntity) -> void:
	if not chess_piece:
		return

	# 重置棋子
	chess_piece.reset()

	# 如果对象池存在，将棋子返回到池
	if ObjectPool._pools.has(CHESS_POOL_NAME):
		# 从场景树移除
		if chess_piece.is_inside_tree():
			chess_piece.get_parent().remove_child(chess_piece)

		# 返回到对象池
		ObjectPool.release_object(CHESS_POOL_NAME, chess_piece)
	else:
		# 如果对象池不存在，直接销毁棋子
		if chess_piece.is_inside_tree():
			chess_piece.get_parent().remove_child(chess_piece)

		chess_piece.queue_free()

# 预热对象池
func warm_pool(count: int) -> void:
	# 检查对象池是否存在
	if not ObjectPool._pools.has(CHESS_POOL_NAME):
		_initialize_object_pool()

	# 获取当前池大小
	var current_size = ObjectPool._pools[CHESS_POOL_NAME].size()

	# 设置新的池大小
	var new_size = max(current_size, count)
	ObjectPool.set_pool_size(CHESS_POOL_NAME, new_size)

# 清空对象池
func clear_pool() -> void:
	# 检查对象池是否存在
	if ObjectPool._pools.has(CHESS_POOL_NAME):
		ObjectPool.clear_pool(CHESS_POOL_NAME)

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
