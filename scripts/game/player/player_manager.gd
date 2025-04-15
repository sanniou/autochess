extends Node
class_name PlayerManager
## 玩家管理器
## 管理玩家实例和相关操作

# 当前玩家
var current_player: Player = null

# AI对手列表
var ai_opponents: Array = []

# 当前对手
var current_opponent: Player = null

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var chess_factory = get_node("/root/GameManager/ChessFactory")
@onready var equipment_manager = get_node("/root/GameManager/EquipmentManager")
@onready var relic_manager = get_node("/root/GameManager/RelicManager")

func _ready():
	# 连接信号
	EventBus.game_started.connect(_on_game_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.chess_piece_created.connect(_on_chess_piece_created)
	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.equipment_created.connect(_on_equipment_created)
	EventBus.relic_acquired.connect(_on_relic_acquired)

# 初始化玩家
func initialize_player(player_name: String = "玩家") -> void:
	current_player = Player.new(player_name)
	
	# 发送玩家初始化信号
	EventBus.debug_message.emit("玩家初始化完成", 0)

# 初始化AI对手
func initialize_ai_opponents(count: int = 7) -> void:
	ai_opponents.clear()
	
	# 创建AI对手
	for i in range(count):
		var ai_player = Player.new("AI对手 " + str(i+1))
		ai_opponents.append(ai_player)
	
	# 发送AI初始化信号
	EventBus.debug_message.emit("AI对手初始化完成", 0)

# 选择当前对手
func select_opponent() -> Player:
	if ai_opponents.size() == 0:
		return null
	
	# 随机选择一个对手
	var index = randi() % ai_opponents.size()
	current_opponent = ai_opponents[index]
	
	return current_opponent

# 获取当前玩家
func get_current_player() -> Player:
	return current_player

# 获取当前对手
func get_current_opponent() -> Player:
	return current_opponent

# 购买棋子
func purchase_chess_piece(piece_id: String) -> ChessPiece:
	if current_player == null:
		return null
	
	# 获取棋子配置
	var piece_config = config_manager.get_chess_piece(piece_id)
	if piece_config == null:
		return null
	
	# 检查金币是否足够
	if current_player.gold < piece_config.cost:
		return null
	
	# 创建棋子实例
	var piece = chess_factory.create_chess_piece(piece_id)
	if piece == null:
		return null
	
	# 扣除金币
	if current_player.spend_gold(piece_config.cost):
		# 添加到玩家棋子列表
		if current_player.add_chess_piece(piece):
			# 发送棋子购买信号
			EventBus.chess_piece_created.emit(piece)
			return piece
	
	return null

# 出售棋子
func sell_chess_piece(piece: ChessPiece) -> bool:
	if current_player == null or piece == null:
		return false
	
	return current_player.sell_chess_piece(piece)

# 购买装备
func purchase_equipment(equipment_id: String) -> Equipment:
	if current_player == null:
		return null
	
	# 获取装备配置
	var equipment_config = config_manager.get_equipment(equipment_id)
	if equipment_config == null:
		return null
	
	# 检查金币是否足够
	var cost = 3  # 装备固定价格为3金币
	if current_player.gold < cost:
		return null
	
	# 获取装备实例
	var equipment = equipment_manager.get_equipment(equipment_id)
	if equipment == null:
		return null
	
	# 扣除金币
	if current_player.spend_gold(cost):
		# 添加到玩家装备列表
		if current_player.add_equipment(equipment):
			return equipment
	
	return null

# 购买经验
func purchase_exp(amount: int = 4, cost: int = 4) -> bool:
	if current_player == null:
		return false
	
	return current_player.buy_exp(amount, cost)

# 刷新商店
func refresh_shop(cost: int = 2) -> bool:
	if current_player == null:
		return false
	
	# 检查金币是否足够
	if current_player.gold < cost:
		return false
	
	# 扣除金币
	if current_player.spend_gold(cost):
		# 发送商店刷新请求信号
		EventBus.shop_refresh_requested.emit(current_player.level)
		return true
	
	return false

# 回合开始处理
func on_round_start() -> void:
	if current_player == null:
		return
	
	current_player.on_round_start()
	
	# 自动刷新商店
	EventBus.shop_refresh_requested.emit(current_player.level)

# 战斗结束处理
func _on_battle_ended(result: Dictionary) -> void:
	if current_player == null:
		return
	
	if result.win:
		# 玩家胜利
		current_player.on_battle_win()
	else:
		# 玩家失败
		var damage = result.damage if result.has("damage") else 10
		current_player.on_battle_loss(damage)

# 游戏开始事件处理
func _on_game_started() -> void:
	# 初始化玩家
	initialize_player()
	
	# 初始化AI对手
	initialize_ai_opponents()

# 棋子创建事件处理
func _on_chess_piece_created(piece: ChessPiece) -> void:
	# 这里可以处理棋子创建后的逻辑
	pass

# 物品购买事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 这里可以处理物品购买后的逻辑
	pass

# 装备创建事件处理
func _on_equipment_created(equipment: Equipment) -> void:
	# 这里可以处理装备创建后的逻辑
	pass

# 遗物获取事件处理
func _on_relic_acquired(relic) -> void:
	# 这里可以处理遗物获取后的逻辑
	pass

# 获取玩家存档数据
func get_save_data() -> Dictionary:
	if current_player == null:
		return {}
	
	return current_player.get_save_data()

# 从存档数据加载
func load_from_save_data(data: Dictionary) -> void:
	if current_player == null:
		initialize_player()
	
	current_player.load_from_save_data(data)

# 重置管理器
func reset() -> void:
	if current_player != null:
		current_player.reset()
	
	ai_opponents.clear()
	current_opponent = null
