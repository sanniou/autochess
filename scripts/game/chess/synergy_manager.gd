extends Node
class_name SynergyManager
## 羁绊管理器
## 负责处理棋子之间的羁绊效果和加成

# 当前激活的羁绊 {羁绊类型: 激活等级}
var _active_synergies = {}

# 羁绊配置
var _synergy_configs = {}

# 初始化
func _ready():
	# 加载羁绊配置
	_load_synergy_configs()
	
	# 连接信号
	EventBus.chess_piece_created.connect(_on_chess_piece_created)
	EventBus.chess_piece_sold.connect(_on_chess_piece_sold)
	EventBus.chess_piece_upgraded.connect(_on_chess_piece_upgraded)

## 加载羁绊配置
func _load_synergy_configs() -> void:
	_synergy_configs = ConfigManager.get_all_synergies()

## 棋子创建事件处理
func _on_chess_piece_created(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 棋子出售事件处理
func _on_chess_piece_sold(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 棋子升级事件处理
func _on_chess_piece_upgraded(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 更新所有羁绊状态
func _update_synergies() -> void:
	# 获取所有棋子
	var all_pieces = _get_all_chess_pieces()
	
	# 统计羁绊数量
	var synergy_counts = {}
	for piece in all_pieces:
		for synergy in piece.synergies:
			if not synergy_counts.has(synergy):
				synergy_counts[synergy] = 0
			synergy_counts[synergy] += 1
	
	# 检查羁绊激活状态
	var new_active_synergies = {}
	
	for synergy in synergy_counts:
		var count = synergy_counts[synergy]
		var config = _synergy_configs[synergy]
		
		if not config:
			continue
		
		# 检查满足的等级
		var max_level = 0
		for level in config.levels:
			if count >= level.count:
				max_level = level.level
		
		if max_level > 0:
			new_active_synergies[synergy] = max_level
	
	# 比较新旧羁绊状态
	_compare_synergy_changes(new_active_synergies)

## 比较羁绊变化并应用效果
func _compare_synergy_changes(new_synergies: Dictionary) -> void:
	# 检查新增或升级的羁绊
	for synergy in new_synergies:
		var new_level = new_synergies[synergy]
		
		if _active_synergies.has(synergy):
			var old_level = _active_synergies[synergy]
			if new_level > old_level:
				# 羁绊升级
				_upgrade_synergy(synergy, old_level, new_level)
		else:
			# 新激活羁绊
			_activate_synergy(synergy, new_level)
	
	# 检查移除或降级的羁绊
	for synergy in _active_synergies:
		if not new_synergies.has(synergy):
			# 羁绊失效
			_deactivate_synergy(synergy, _active_synergies[synergy])
		elif new_synergies[synergy] < _active_synergies[synergy]:
			# 羁绊降级
			_downgrade_synergy(synergy, _active_synergies[synergy], new_synergies[synergy])
	
	# 更新当前激活羁绊
	_active_synergies = new_synergies

## 激活羁绊
func _activate_synergy(synergy: String, level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return
	
	# 获取对应等级的效果
	var effect = _get_synergy_effect(synergy, level)
	if not effect:
		return
	
	# 应用效果给所有符合条件的棋子
	var all_pieces = _get_all_chess_pieces()
	for piece in all_pieces:
		if synergy in piece.synergies:
			piece.add_effect(effect)
	
	# 发送羁绊激活信号
	EventBus.synergy_activated.emit(synergy, level)

## 升级羁绊
func _upgrade_synergy(synergy: String, old_level: int, new_level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return
	
	# 移除旧效果
	var old_effect = _get_synergy_effect(synergy, old_level)
	if old_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(old_effect.id)
	
	# 添加新效果
	var new_effect = _get_synergy_effect(synergy, new_level)
	if new_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.add_effect(new_effect)
	
	# 发送羁绊升级信号
	EventBus.synergy_activated.emit(synergy, new_level)

## 降级羁绊
func _downgrade_synergy(synergy: String, old_level: int, new_level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return
	
	# 移除旧效果
	var old_effect = _get_synergy_effect(synergy, old_level)
	if old_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(old_effect.id)
	
	# 添加新效果
	var new_effect = _get_synergy_effect(synergy, new_level)
	if new_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.add_effect(new_effect)
	
	# 发送羁绊降级信号
	EventBus.synergy_activated.emit(synergy, new_level)

## 取消激活羁绊
func _deactivate_synergy(synergy: String, level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return
	
	# 移除效果
	var effect = _get_synergy_effect(synergy, level)
	if effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(effect.id)
	
	# 发送羁绊失效信号
	EventBus.synergy_deactivated.emit(synergy)

## 获取羁绊效果
func _get_synergy_effect(synergy: String, level: int) -> Dictionary:
	var config = _synergy_configs[synergy]
	if not config:
		return {}
	
	# 查找对应等级的效果
	for lvl in config.levels:
		if lvl.level == level:
			var effect = lvl.effect.duplicate(true)
			effect.id = "synergy_%s_%d" % [synergy, level]
			return effect
	
	return {}

## 获取所有棋子
func _get_all_chess_pieces() -> Array:
	var pieces = []
	
	# 获取玩家棋子
	var player_pieces = get_tree().get_nodes_in_group("player_chess_pieces")
	pieces.append_array(player_pieces)
	
	# 获取场上棋子（如果有）
	var board_pieces = get_tree().get_nodes_in_group("board_chess_pieces")
	pieces.append_array(board_pieces)
	
	return pieces

## 获取当前激活的羁绊
func get_active_synergies() -> Dictionary:
	return _active_synergies

## 获取特定羁绊的激活等级
func get_synergy_level(synergy: String) -> int:
	if _active_synergies.has(synergy):
		return _active_synergies[synergy]
	return 0

## 获取羁绊配置
func get_synergy_config(synergy: String) -> Dictionary:
	if _synergy_configs.has(synergy):
		return _synergy_configs[synergy]
	return {}

## 获取所有羁绊配置
func get_all_synergy_configs() -> Dictionary:
	return _synergy_configs

## 重置羁绊管理器
func reset() -> void:
	# 取消所有激活的羁绊
	for synergy in _active_synergies:
		_deactivate_synergy(synergy, _active_synergies[synergy])
	
	_active_synergies = {}
