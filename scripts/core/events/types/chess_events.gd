extends RefCounted
class_name ChessEvents
## 棋子事件类型
## 定义与棋子相关的事件

## 棋子创建事件
class ChessPieceCreatedEvent extends Event:
	## 棋子
	var piece
	
	## 初始化
	func _init(p_piece):
		piece = p_piece
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_created"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceCreatedEvent[piece=%s]" % [piece]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceCreatedEvent.new(piece)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子升级事件
class ChessPieceUpgradedEvent extends Event:
	## 棋子
	var piece
	
	## 旧等级
	var old_level: int
	
	## 新等级
	var new_level: int
	
	## 初始化
	func _init(p_piece, p_old_level: int, p_new_level: int):
		piece = p_piece
		old_level = p_old_level
		new_level = p_new_level
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_upgraded"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceUpgradedEvent[piece=%s, old_level=%d, new_level=%d]" % [
			piece, old_level, new_level
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceUpgradedEvent.new(piece, old_level, new_level)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子出售事件
class ChessPieceSoldEvent extends Event:
	## 棋子
	var piece
	
	## 金币数量
	var gold_amount: int
	
	## 初始化
	func _init(p_piece, p_gold_amount: int):
		piece = p_piece
		gold_amount = p_gold_amount
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_sold"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceSoldEvent[piece=%s, gold_amount=%d]" % [piece, gold_amount]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceSoldEvent.new(piece, gold_amount)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子移动事件
class ChessPieceMovedEvent extends Event:
	## 棋子
	var piece
	
	## 起始位置
	var from_position: Vector2
	
	## 目标位置
	var to_position: Vector2
	
	## 初始化
	func _init(p_piece, p_from_position: Vector2, p_to_position: Vector2):
		piece = p_piece
		from_position = p_from_position
		to_position = p_to_position
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_moved"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceMovedEvent[piece=%s, from=%s, to=%s]" % [
			piece, from_position, to_position
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceMovedEvent.new(piece, from_position, to_position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子目标变化事件
class ChessPieceTargetChangedEvent extends Event:
	## 棋子
	var piece
	
	## 旧目标
	var old_target
	
	## 新目标
	var new_target
	
	## 初始化
	func _init(p_piece, p_old_target, p_new_target):
		piece = p_piece
		old_target = p_old_target
		new_target = p_new_target
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_target_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceTargetChangedEvent[piece=%s, old_target=%s, new_target=%s]" % [
			piece, old_target, new_target
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceTargetChangedEvent.new(piece, old_target, new_target)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子目标丢失事件
class ChessPieceTargetLostEvent extends Event:
	## 棋子
	var piece
	
	## 旧目标
	var old_target
	
	## 初始化
	func _init(p_piece, p_old_target):
		piece = p_piece
		old_target = p_old_target
		source = piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_target_lost"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceTargetLostEvent[piece=%s, old_target=%s]" % [piece, old_target]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceTargetLostEvent.new(piece, old_target)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子受伤事件
class ChessPieceDamagedEvent extends Event:
	## 棋子
	var piece
	
	## 伤害来源
	var source_entity
	
	## 伤害数值
	var amount: float
	
	## 伤害类型
	var damage_type: String
	
	## 是否暴击
	var is_critical: bool
	
	## 初始化
	func _init(p_piece, p_source_entity, p_amount: float, p_damage_type: String, p_is_critical: bool = false):
		piece = p_piece
		source_entity = p_source_entity
		amount = p_amount
		damage_type = p_damage_type
		is_critical = p_is_critical
		source = p_source_entity
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_damaged"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceDamagedEvent[piece=%s, source=%s, amount=%.1f, type=%s, critical=%s]" % [
			piece, source_entity, amount, damage_type, is_critical
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceDamagedEvent.new(piece, source_entity, amount, damage_type, is_critical)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子治疗事件
class ChessPieceHealedEvent extends Event:
	## 棋子
	var piece
	
	## 治疗来源
	var source_entity
	
	## 治疗数值
	var amount: float
	
	## 初始化
	func _init(p_piece, p_source_entity, p_amount: float):
		piece = p_piece
		source_entity = p_source_entity
		amount = p_amount
		source = p_source_entity
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_healed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceHealedEvent[piece=%s, source=%s, amount=%.1f]" % [
			piece, source_entity, amount
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceHealedEvent.new(piece, source_entity, amount)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子闪避事件
class ChessPieceDodgedEvent extends Event:
	## 棋子
	var piece
	
	## 攻击来源
	var source_entity
	
	## 初始化
	func _init(p_piece, p_source_entity):
		piece = p_piece
		source_entity = p_source_entity
		source = p_piece
	
	## 获取事件类型
	func get_type() -> String:
		return "chess.chess_piece_dodged"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessPieceDodgedEvent[piece=%s, source=%s]" % [piece, source_entity]
	
	## 克隆事件
	func clone() -> Event:
		var event = ChessPieceDodgedEvent.new(piece, source_entity)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
