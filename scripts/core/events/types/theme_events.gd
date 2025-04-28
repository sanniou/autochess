extends RefCounted
class_name ThemeEvents
## 主题事件类型
## 定义与主题系统相关的事件

## 主题变更事件
class ThemeChangedEvent extends BusEvent:
	## 主题ID
	var theme_id: String
	
	## 主题数据
	var theme_data: Dictionary
	
	## 初始化
	func _init(p_theme_id: String, p_theme_data: Dictionary = {}):
		theme_id = p_theme_id
		theme_data = p_theme_data
	
	## 获取事件类型
	static func get_type() -> String:
		return "ui.theme_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ThemeChangedEvent[theme_id=%s]" % [theme_id]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = ThemeChangedEvent.new(theme_id, theme_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 地图主题变更事件
class MapThemeChangedEvent extends BusEvent:
	## 主题ID
	var theme_id: String
	
	## 节点颜色
	var node_colors: Dictionary
	
	## 连接颜色
	var connection_colors: Dictionary
	
	## 背景颜色
	var background_color: Color
	
	## 初始化
	func _init(p_theme_id: String, p_node_colors: Dictionary, p_connection_colors: Dictionary, p_background_color: Color):
		theme_id = p_theme_id
		node_colors = p_node_colors
		connection_colors = p_connection_colors
		background_color = p_background_color
	
	## 获取事件类型
	static func get_type() -> String:
		return "ui.map_theme_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapThemeChangedEvent[theme_id=%s]" % [theme_id]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = MapThemeChangedEvent.new(theme_id, node_colors.duplicate(true), connection_colors.duplicate(true), background_color)
		event.timestamp = timestamp
		event.canceled = canceled
		return event
