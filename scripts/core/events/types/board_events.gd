extends RefCounted
class_name BoardEvents
## 棋盘事件类型
## 定义与棋盘系统相关的事件

## 棋盘初始化事件
class BoardInitializedEvent extends Event:
	## 棋盘ID
	var board_id: String
	
	## 棋盘尺寸
	var board_size: Vector2
	
	## 初始化
	func _init(p_board_id: String, p_board_size: Vector2):
		board_id = p_board_id
		board_size = p_board_size
	
	## 获取事件类型
	func get_type() -> String:
		return "board.board_initialized"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardInitializedEvent[board_id=%s, board_size=%s]" % [
			board_id, board_size
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = BoardInitializedEvent.new(board_id, board_size)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子放置事件
class PiecePlacedEvent extends Event:
	## 棋子
	var piece
	
	## 位置
	var position: Vector2
	
	## 初始化
	func _init(p_piece, p_position: Vector2):
		piece = p_piece
		position = p_position
		source = p_piece
	
	## 获取事件类型
	func get_type() -> String:
		return "board.piece_placed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PiecePlacedEvent[piece=%s, position=%s]" % [
			piece, position
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = PiecePlacedEvent.new(piece, position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子移除事件
class PieceRemovedEvent extends Event:
	## 棋子
	var piece
	
	## 位置
	var position: Vector2
	
	## 初始化
	func _init(p_piece, p_position: Vector2):
		piece = p_piece
		position = p_position
		source = p_piece
	
	## 获取事件类型
	func get_type() -> String:
		return "board.piece_removed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PieceRemovedEvent[piece=%s, position=%s]" % [
			piece, position
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = PieceRemovedEvent.new(piece, position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子移动事件
class PieceMovedEvent extends Event:
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
		source = p_piece
	
	## 获取事件类型
	func get_type() -> String:
		return "board.piece_moved"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PieceMovedEvent[piece=%s, from=%s, to=%s]" % [
			piece, from_position, to_position
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = PieceMovedEvent.new(piece, from_position, to_position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘锁定事件
class BoardLockedEvent extends Event:
	## 棋盘ID
	var board_id: String
	
	## 是否锁定
	var is_locked: bool
	
	## 初始化
	func _init(p_board_id: String, p_is_locked: bool):
		board_id = p_board_id
		is_locked = p_is_locked
	
	## 获取事件类型
	func get_type() -> String:
		return "board.board_locked"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardLockedEvent[board_id=%s, is_locked=%s]" % [
			board_id, is_locked
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = BoardLockedEvent.new(board_id, is_locked)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘重置事件
class BoardResetEvent extends Event:
	## 棋盘ID
	var board_id: String
	
	## 初始化
	func _init(p_board_id: String):
		board_id = p_board_id
	
	## 获取事件类型
	func get_type() -> String:
		return "board.board_reset"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardResetEvent[board_id=%s]" % [board_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = BoardResetEvent.new(board_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘战斗开始事件
class BoardBattleStartedEvent extends Event:
	## 棋盘ID
	var board_id: String
	
	## 战斗ID
	var battle_id: String
	
	## 初始化
	func _init(p_board_id: String, p_battle_id: String):
		board_id = p_board_id
		battle_id = p_battle_id
	
	## 获取事件类型
	func get_type() -> String:
		return "board.board_battle_started"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardBattleStartedEvent[board_id=%s, battle_id=%s]" % [
			board_id, battle_id
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = BoardBattleStartedEvent.new(board_id, battle_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘战斗结束事件
class BoardBattleEndedEvent extends Event:
	## 棋盘ID
	var board_id: String
	
	## 战斗ID
	var battle_id: String
	
	## 是否胜利
	var is_victory: bool
	
	## 初始化
	func _init(p_board_id: String, p_battle_id: String, p_is_victory: bool):
		board_id = p_board_id
		battle_id = p_battle_id
		is_victory = p_is_victory
	
	## 获取事件类型
	func get_type() -> String:
		return "board.board_battle_ended"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardBattleEndedEvent[board_id=%s, battle_id=%s, is_victory=%s]" % [
			board_id, battle_id, is_victory
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = BoardBattleEndedEvent.new(board_id, battle_id, is_victory)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
