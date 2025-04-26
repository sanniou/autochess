extends RefCounted
class_name LocalizationEvents
## 本地化事件类型
## 定义与本地化系统相关的事件

## 语言变更事件
class LanguageChangedEvent extends BusEvent:
	## 语言代码
	var language_code: String
	
	## 语言名称
	var language_name: String
	
	## 初始化
	func _init(p_language_code: String, p_language_name: String):
		language_code = p_language_code
		language_name = p_language_name
	
	## 获取事件类型
	static func get_type() -> String:
		return "localization.language_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "LanguageChangedEvent[language_code=%s, language_name=%s]" % [
			language_code, language_name
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = LanguageChangedEvent.new(language_code, language_name)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 请求语言代码事件
class RequestLanguageCodeEvent extends BusEvent:
	## 初始化
	func _init():
		pass
	
	## 获取事件类型
	static func get_type() -> String:
		return "localization.request_language_code"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RequestLanguageCodeEvent[]"
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = RequestLanguageCodeEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 请求字体事件
class RequestFontEvent extends BusEvent:
	## 字体名称
	var font_name: String
	
	## 字体大小
	var font_size: int
	
	## 初始化
	func _init(p_font_name: String, p_font_size: int):
		font_name = p_font_name
		font_size = p_font_size
	
	## 获取事件类型
	static func get_type() -> String:
		return "localization.request_font"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RequestFontEvent[font_name=%s, font_size=%d]" % [
			font_name, font_size
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = RequestFontEvent.new(font_name, font_size)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 字体加载事件
class FontLoadedEvent extends BusEvent:
	## 字体名称
	var font_name: String
	
	## 字体大小
	var font_size: int
	
	## 字体资源
	var font_resource
	
	## 初始化
	func _init(p_font_name: String, p_font_size: int, p_font_resource):
		font_name = p_font_name
		font_size = p_font_size
		font_resource = p_font_resource
	
	## 获取事件类型
	static func get_type() -> String:
		return "localization.font_loaded"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "FontLoadedEvent[font_name=%s, font_size=%d]" % [
			font_name, font_size
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = FontLoadedEvent.new(font_name, font_size, font_resource)
		event.timestamp = timestamp
		event.canceled = canceled

		return event
