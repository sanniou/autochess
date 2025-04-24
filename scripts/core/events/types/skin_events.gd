extends RefCounted
class_name SkinEvents
## 皮肤事件类型
## 定义与皮肤系统相关的事件

## 皮肤变更事件
class SkinChangedEvent extends BusEvent:
	## 皮肤类型
	var skin_type: String
	
	## 旧皮肤ID
	var old_skin_id: String
	
	## 新皮肤ID
	var new_skin_id: String
	
	## 初始化
	func _init(p_skin_type: String, p_old_skin_id: String, p_new_skin_id: String):
		skin_type = p_skin_type
		old_skin_id = p_old_skin_id
		new_skin_id = p_new_skin_id
	
	## 获取事件类型
	func get_type() -> String:
		return "skin.skin_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "SkinChangedEvent[skin_type=%s, old_skin_id=%s, new_skin_id=%s]" % [
			skin_type, old_skin_id, new_skin_id
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = SkinChangedEvent.new(skin_type, old_skin_id, new_skin_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 皮肤解锁事件
class SkinUnlockedEvent extends BusEvent:
	## 皮肤类型
	var skin_type: String
	
	## 皮肤ID
	var skin_id: String
	
	## 初始化
	func _init(p_skin_type: String, p_skin_id: String):
		skin_type = p_skin_type
		skin_id = p_skin_id
	
	## 获取事件类型
	func get_type() -> String:
		return "skin.skin_unlocked"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "SkinUnlockedEvent[skin_type=%s, skin_id=%s]" % [
			skin_type, skin_id
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = SkinUnlockedEvent.new(skin_type, skin_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋子皮肤变更事件
class ChessSkinChangedEvent extends BusEvent:
	## 棋子ID
	var chess_id: String
	
	## 旧皮肤ID
	var old_skin_id: String
	
	## 新皮肤ID
	var new_skin_id: String
	
	## 初始化
	func _init(p_chess_id: String, p_old_skin_id: String, p_new_skin_id: String):
		chess_id = p_chess_id
		old_skin_id = p_old_skin_id
		new_skin_id = p_new_skin_id
	
	## 获取事件类型
	func get_type() -> String:
		return "skin.chess_skin_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ChessSkinChangedEvent[chess_id=%s, old_skin_id=%s, new_skin_id=%s]" % [
			chess_id, old_skin_id, new_skin_id
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = ChessSkinChangedEvent.new(chess_id, old_skin_id, new_skin_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 棋盘皮肤变更事件
class BoardSkinChangedEvent extends BusEvent:
	## 旧皮肤ID
	var old_skin_id: String
	
	## 新皮肤ID
	var new_skin_id: String
	
	## 初始化
	func _init(p_old_skin_id: String, p_new_skin_id: String):
		old_skin_id = p_old_skin_id
		new_skin_id = p_new_skin_id
	
	## 获取事件类型
	func get_type() -> String:
		return "skin.board_skin_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BoardSkinChangedEvent[old_skin_id=%s, new_skin_id=%s]" % [
			old_skin_id, new_skin_id
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = BoardSkinChangedEvent.new(old_skin_id, new_skin_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## UI皮肤变更事件
class UISkinChangedEvent extends BusEvent:
	## 旧皮肤ID
	var old_skin_id: String
	
	## 新皮肤ID
	var new_skin_id: String
	
	## 初始化
	func _init(p_old_skin_id: String, p_new_skin_id: String):
		old_skin_id = p_old_skin_id
		new_skin_id = p_new_skin_id
	
	## 获取事件类型
	func get_type() -> String:
		return "skin.ui_skin_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "UISkinChangedEvent[old_skin_id=%s, new_skin_id=%s]" % [
			old_skin_id, new_skin_id
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = UISkinChangedEvent.new(old_skin_id, new_skin_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
