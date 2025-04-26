extends RefCounted
class_name SkinEvents
## 皮肤事件类型
## 定义与皮肤系统相关的事件

# 皮肤变更事件
class ChangeSkinEvent extends BusEvent:
	var skin_type: String
	var skin_id: String

	func _init(p_skin_type: String, p_skin_id: String):
		skin_type = p_skin_type
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.change_skin"

# 皮肤解锁事件
class UnlockSkinEvent extends BusEvent:
	var skin_type: String
	var skin_id: String

	func _init(p_skin_type: String, p_skin_id: String):
		skin_type = p_skin_type
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.unlock_skin"

# 皮肤预览事件
class PreviewSkinEvent extends BusEvent:
	var skin_type: String
	var skin_id: String

	func _init(p_skin_type: String, p_skin_id: String):
		skin_type = p_skin_type
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.preview_skin"

# 皮肤已解锁事件
class SkinUnlockedEvent extends BusEvent:
	var skin_type: String
	var skin_id: String

	func _init(p_skin_id: String, p_skin_type: String):
		skin_id = p_skin_id
		skin_type = p_skin_type

	static func get_type() -> String:
		return "skin.skin_unlocked"

# 棋子皮肤变更事件
class ChessSkinChangedEvent extends BusEvent:
	var new_skin_id: String

	func _init(p_new_skin_id: String):
		new_skin_id = p_new_skin_id

	static func get_type() -> String:
		return "skin.chess_skin_changed"

# 棋盘皮肤变更事件
class BoardSkinChangedEvent extends BusEvent:
	var new_skin_id: String

	func _init(p_new_skin_id: String):
		new_skin_id = p_new_skin_id

	static func get_type() -> String:
		return "skin.board_skin_changed"

# UI皮肤变更事件
class UISkinChangedEvent extends BusEvent:
	var new_skin_id: String

	func _init(p_new_skin_id: String):
		new_skin_id = p_new_skin_id

	static func get_type() -> String:
		return "skin.ui_skin_changed"

# 棋子皮肤预览事件
class ChessSkinPreviewEvent extends BusEvent:
	var skin_id: String

	func _init(p_skin_id: String):
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.chess_skin_preview"

# 棋盘皮肤预览事件
class BoardSkinPreviewEvent extends BusEvent:
	var skin_id: String

	func _init(p_skin_id: String):
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.board_skin_preview"

# UI皮肤预览事件
class UISkinPreviewEvent extends BusEvent:
	var skin_id: String

	func _init(p_skin_id: String):
		skin_id = p_skin_id

	static func get_type() -> String:
		return "skin.ui_skin_preview"

# 棋子皮肤应用事件
class ChessSkinAppliedEvent extends BusEvent:
	var skin_id: String
	var texture_overrides: Dictionary

	func _init(p_skin_id: String, p_texture_overrides: Dictionary):
		skin_id = p_skin_id
		texture_overrides = p_texture_overrides

	static func get_type() -> String:
		return "skin.chess_skin_applied"

# 棋盘皮肤应用事件
class BoardSkinAppliedEvent extends BusEvent:
	var skin_id: String
	var board_texture: String
	var cell_textures: Dictionary

	func _init(p_skin_id: String, p_board_texture: String, p_cell_textures: Dictionary):
		skin_id = p_skin_id
		board_texture = p_board_texture
		cell_textures = p_cell_textures

	static func get_type() -> String:
		return "skin.board_skin_applied"

# UI皮肤应用事件
class UISkinAppliedEvent extends BusEvent:
	var skin_id: String
	var theme_path: String
	var color_scheme: Dictionary

	func _init(p_skin_id: String, p_theme_path: String, p_color_scheme: Dictionary):
		skin_id = p_skin_id
		theme_path = p_theme_path
		color_scheme = p_color_scheme

	static func get_type() -> String:
		return "skin.ui_skin_applied"
