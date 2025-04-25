extends RefCounted
class_name BoardEvents
## 棋盘事件类型
## 定义与棋盘系统相关的事件

## 棋盘初始化事件
class BoardInitializedEvent extends BusEvent:
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
	func clone() ->BusEvent:
		var event = BoardInitializedEvent.new(board_id, board_size)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子放置事件
class PiecePlacedEvent extends BusEvent:
	## 棋子
	var piece
	
	## 位置
	var position: BoardCell
	
	## 初始化
	func _init(p_piece, p_position: BoardCell):
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
	func clone() ->BusEvent:
		var event = PiecePlacedEvent.new(piece, position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子移除事件
class PieceRemovedEvent extends BusEvent:
	## 棋子
	var piece
	
	## 位置
	var position: BoardCell
	
	## 初始化
	func _init(p_piece, p_position: BoardCell):
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
	func clone() ->BusEvent:
		var event = PieceRemovedEvent.new(piece, position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子移动事件
class PieceMovedEvent extends BusEvent:
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
	func clone() ->BusEvent:
		var event = PieceMovedEvent.new(piece, from_position, to_position)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘锁定事件
class BoardLockedEvent extends BusEvent:
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
	func clone() ->BusEvent:
		var event = BoardLockedEvent.new(board_id, is_locked)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘重置事件
class BoardResetEvent extends BusEvent:
	## 棋盘ID
	var board_id: String
	
	## 初始化
	func _init(p_board_id: String):
		board_id = p_board_id


## 棋盘战斗开始事件
class BoardBattleStartedEvent extends BusEvent:	
	## 初始化
	func _init():
		pass

## 棋盘战斗结束事件
class BoardBattleEndedEvent extends BusEvent:
	var reslut: Dictionary
	## 初始化
	func _init(reslut:Dictionary):
		self.reslut=reslut
		
class CellClickedEvent extends BusEvent:
	var cell: BoardCell
	## 初始化
	func _init(cell: BoardCell):
		self.cell=cell

class CellHoveredEvent extends BusEvent:

	var cell:BoardCell
	
	## 初始化
	func _init(cell:BoardCell):
		self.cell=cell

class CellExitedEvent extends BusEvent:

	var cell:BoardCell
	
	## 初始化
	func _init(cell:BoardCell):
		self.cell=cell
	

class PiecePlacedOnBoardEvent extends BusEvent:

	var piece
	
	## 初始化
	func _init(piece):
		self.piece=piece
	
class PieceRemovedFromBoardEvent extends BusEvent:

	var piece
	
	## 初始化
	func _init(piece):
		self.piece=piece

class PiecePlacedOnBenchEvent extends BusEvent:

	var piece
	
	## 初始化
	func _init(piece):
		self.piece=piece

class PieceRemovedFromBenchEvent extends BusEvent:

	var piece
	
	## 初始化
	func _init(piece):
		self.piece=piece
	
