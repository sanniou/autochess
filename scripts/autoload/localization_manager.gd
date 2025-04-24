extends "res://scripts/managers/core/base_manager.gd"
## 本地化管理器
## 负责游戏文本的多语言支持

# 信号
signal language_changed(language_code)
signal translations_loaded(language_code)
signal font_changed(font_name)

# 支持的语言
enum Language {
	ZH_CN,  # 简体中文
	EN_US,  # 英语（美国）
	JA_JP,  # 日语
	KO_KR,  # 韩语
	RU_RU,  # 俄语
	DE_DE,  # 德语
	FR_FR,  # 法语
	ES_ES,  # 西班牙语
	PT_BR,  # 葡萄牙语（巴西）
	IT_IT,  # 意大利语
	ZH_TW   # 繁体中文
}

# 语言代码映射
const LANGUAGE_CODES = {
	Language.ZH_CN: "zh_CN",
	Language.EN_US: "en_US",
	Language.JA_JP: "ja_JP",
	Language.KO_KR: "ko_KR",
	Language.RU_RU: "ru_RU",
	Language.DE_DE: "de_DE",
	Language.FR_FR: "fr_FR",
	Language.ES_ES: "es_ES",
	Language.PT_BR: "pt_BR",
	Language.IT_IT: "it_IT",
	Language.ZH_TW: "zh_TW"
}

# 语言名称映射
const LANGUAGE_NAMES = {
	Language.ZH_CN: "简体中文",
	Language.EN_US: "English (US)",
	Language.JA_JP: "日本語",
	Language.KO_KR: "한국어",
	Language.RU_RU: "Русский",
	Language.DE_DE: "Deutsch",
	Language.FR_FR: "Français",
	Language.ES_ES: "Español",
	Language.PT_BR: "Português (Brasil)",
	Language.IT_IT: "Italiano",
	Language.ZH_TW: "繁體中文"
}

# 语言字体映射
const LANGUAGE_FONTS = {
	Language.ZH_CN: "NotoSansSC-Regular.ttf",
	Language.EN_US: "NotoSans-Regular.ttf",
	Language.JA_JP: "NotoSansJP-Regular.ttf",
	Language.KO_KR: "NotoSansKR-Regular.ttf",
	Language.RU_RU: "NotoSans-Regular.ttf",
	Language.DE_DE: "NotoSans-Regular.ttf",
	Language.FR_FR: "NotoSans-Regular.ttf",
	Language.ES_ES: "NotoSans-Regular.ttf",
	Language.PT_BR: "NotoSans-Regular.ttf",
	Language.IT_IT: "NotoSans-Regular.ttf",
	Language.ZH_TW: "NotoSansTC-Regular.ttf"
}

# 当前语言
var current_language: int = Language.ZH_CN

# 翻译数据
var translations = {}

# 语言文件路径
const TRANSLATION_PATH = "res://data/localization/"

# 当前字体
var current_font = null

# 本地化设置
var localization_settings = {
	"fallback_language": Language.ZH_CN,
	"auto_detect_language": true,
	"use_system_language": true,
	"use_custom_fonts": true,
	"text_direction": TextDirection.LEFT_TO_RIGHT
}

# 文本方向
enum TextDirection {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT
}

# 初始化
func _ready() -> void:
	# 初始化管理器
	initialize()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "LocalizationManager"
	# 添加依赖
	add_dependency("ConfigManager")

	# 延迟初始化，确保其他单例已经准备好
	call_deferred("_deferred_init")

	# 调试信息
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("本地化管理器已创建", 0))

## 延迟初始化
func _deferred_init() -> void:

	# 连接信号
	EventBus.localization.connect_event("request_language_code", _on_request_language_code)
	EventBus.localization.connect_event("font_loaded", _on_font_loaded, CONNECT_ONE_SHOT)
	

	# 检测系统语言
	if localization_settings.auto_detect_language and localization_settings.use_system_language:
		_detect_system_language()

	# 加载默认语言
	load_language(current_language)

	# 预加载其他语言
	_preload_languages()

	# 加载字体
	if localization_settings.use_custom_fonts:
		_load_font(current_language)

	# 连接信号
	EventBus.localization.connect_event("language_changed", _on_language_changed)

	# 标记初始化完成
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("本地化管理器初始化完成", 0))

	# 通知其他系统当前语言
	EventBus.localization.emit_event("language_changed", [get_current_language_code()])

## 检测系统语言
func _detect_system_language() -> void:
	# 获取系统语言代码
	var system_locale = OS.get_locale()

	# 将系统语言代码转换为游戏支持的语言
	var detected_language = localization_settings.fallback_language

	# 检查系统语言是否支持
	for lang in LANGUAGE_CODES:
		var lang_code = LANGUAGE_CODES[lang]
		if system_locale.begins_with(lang_code.substr(0, 2)):
			detected_language = lang
			break

	# 设置当前语言
	current_language = detected_language
	EventBus.debug.emit_event("debug_message", ["检测到系统语言: " + LANGUAGE_NAMES[current_language], 0])

## 加载指定语言
func load_language(language: int) -> void:
	if not LANGUAGE_CODES.has(language):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("不支持的语言: " + str(language), 2))
		return

	var language_code = LANGUAGE_CODES[language]
	var file_path = TRANSLATION_PATH + language_code + ".json"

	if not FileAccess.file_exists(file_path):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("语言文件不存在: " + file_path, 2))

		# 尝试加载后备语言
		if language != localization_settings.fallback_language:
			GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("尝试加载后备语言", 1))
			load_language(localization_settings.fallback_language)
			return

		# 如果是调试模式，创建一个空的语言文件
		if OS.is_debug_build():
			_create_empty_language_file(language_code)

		return

	# 使用 ConfigManager 加载语言文件
	var translation_data = GameManager.config_manager.load_json(file_path)
	if translation_data.is_empty():
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法加载语言文件: " + file_path, 2))

		# 尝试加载后备语言
		if language != localization_settings.fallback_language:
			GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("尝试加载后备语言", 1))
			load_language(localization_settings.fallback_language)
		return

	translations = translation_data
	current_language = language

	# 加载字体
	if localization_settings.use_custom_fonts:
		_load_font(language)

	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("已加载语言: " + language_code, 0))

	# 发送翻译加载信号
	translations_loaded.emit(language_code)

	# 发送语言变化信号
	language_changed.emit(language_code)

## 切换语言
func change_language(language: int) -> void:
	if language == current_language:
		return

	load_language(language)

## 获取翻译文本
func translate(key: String, params: Array = [], fallback_data: Dictionary = {}) -> String:
	# 检查翻译是否存在
	if not translations.has(key):
		# 如果提供了回退数据，尝试使用回退数据
		if not fallback_data.is_empty():
			# 如果是棋子或装备的名称
			if key.begins_with("game.chess.") or key.begins_with("game.equipment."):
				# 如果是描述
				if key.ends_with(".description") and fallback_data.has("description"):
					return fallback_data.description
				# 如果是名称
				elif fallback_data.has("name"):
					return fallback_data.name
				# 如果没有名称，使用 ID
				elif fallback_data.has("id"):
					return fallback_data.id

		# 记录翻译键不存在的警告
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("翻译键不存在: " + key, 1))
		return key

	var text = translations[key]

	# 处理参数替换
	for i in range(params.size()):
		var param_placeholder = "{" + str(i) + "}"
		text = text.replace(param_placeholder, str(params[i]))

	return text

## 获取当前语言代码
func get_current_language_code() -> String:
	return LANGUAGE_CODES[current_language]

## 获取当前语言名称
func get_current_language_name() -> String:
	return LANGUAGE_NAMES[current_language]

## 获取所有支持的语言
func get_supported_languages() -> Dictionary:
	var languages = {}
	for lang in LANGUAGE_NAMES:
		languages[lang] = LANGUAGE_NAMES[lang]
	return languages

## 获取文本方向
func get_text_direction() -> int:
	return localization_settings.text_direction

## 设置文本方向
func set_text_direction(direction: int) -> void:
	localization_settings.text_direction = direction

## 加载字体
func _load_font(language: int) -> void:
	if not LANGUAGE_FONTS.has(language):
		return

	# 获取字体名称
	var font_name = LANGUAGE_FONTS[language]

	# 通过EventBus请求字体
	# 使用call_deferred避免在同一帧内连接和断开信号
	call_deferred("_request_font", font_name)

## 请求字体
func _request_font(font_name: String) -> void:
	# 通过EventBus请求字体
	EventBus.localization.emit_event("request_font", [font_name])
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("请求字体: " + font_name, 0))

## 处理字体加载完成
func _on_font_loaded(font_name: String, font_data) -> void:
	# 设置当前字体
	if font_data:
		current_font = font_data

		# 发送字体变化信号
		font_changed.emit(font_name)
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("字体加载完成: " + font_name, 0))
	else:
		# 如果字体管理器无法加载字体，尝试使用传统方式加载
		_load_font_traditional(font_name)

## 使用传统方式加载字体
func _load_font_traditional(font_name: String) -> void:
	# 如果没有字体管理器或加载失败，使用传统方式加载
	var font_path = "res://assets/fonts/" + font_name
	if not FileAccess.file_exists(font_path):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("字体文件不存在: " + font_path, 1))
		return

	# 加载字体
	var font = FontFile.new()
	var err = font.load_dynamic_font(font_path)
	if err != OK:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法加载字体: " + font_path, 2))
		return

	# 设置当前字体
	current_font = font

	# 发送字体变化信号
	font_changed.emit(font_name)
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("使用传统方式加载字体: " + font_name, 0))

## 创建空的语言文件（仅在调试模式下）
func _create_empty_language_file(language_code: String) -> void:
	var dir_path = TRANSLATION_PATH
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file_path = dir_path + language_code + ".json"

	# 创建基本的翻译条目
	var basic_translations = {
		"ui.main_menu.start": "开始游戏",
		"ui.main_menu.continue": "继续游戏",
		"ui.main_menu.settings": "设置",
		"ui.main_menu.quit": "退出游戏",
		"ui.battle.start": "开始战斗",
		"ui.battle.skip": "跳过战斗",
		"ui.battle.victory": "胜利",
		"ui.battle.defeat": "失败",
		"ui.shop.refresh": "刷新商店",
		"ui.shop.buy": "购买",
		"ui.shop.sell": "出售",
		"ui.map.select_path": "选择路径",
		"ui.settings.audio": "音频",
		"ui.settings.graphics": "图形",
		"ui.settings.gameplay": "游戏",
		"ui.settings.language": "语言",
		"ui.settings.back": "返回",
		"ui.settings.apply": "应用",
		"ui.common.confirm": "确认",
		"ui.common.cancel": "取消",
		"ui.common.yes": "是",
		"ui.common.no": "否",
		"ui.common.ok": "确定",
		"ui.common.loading": "加载中...",
		"ui.common.saving": "保存中...",
		"game.chess.upgrade": "升级",
		"game.chess.sell": "出售",
		"game.chess.move": "移动",
		"game.chess.star1": "一星",
		"game.chess.star2": "二星",
		"game.chess.star3": "三星",
		"game.equipment.equip": "装备",
		"game.equipment.unequip": "卸下",
		"game.equipment.combine": "合成",
		"game.relic.acquire": "获得遗物",
		"game.relic.effect": "效果",
		"game.event.choice": "选择",
		"game.event.reward": "奖励",
		"game.event.penalty": "惩罚",
		"game.battle.round": "回合",
		"game.battle.prepare": "准备阶段",
		"game.battle.fighting": "战斗阶段",
		"game.battle.damage": "伤害",
		"game.battle.heal": "治疗",
		"game.player.level": "等级",
		"game.player.gold": "金币",
		"game.player.health": "生命值",
		"game.player.experience": "经验",
		"game.difficulty.easy": "简单",
		"game.difficulty.normal": "普通",
		"game.difficulty.hard": "困难",
		"error.save_failed": "保存失败",
		"error.load_failed": "加载失败",
		"error.config_not_found": "配置文件不存在"
	}

	# 使用 ConfigManager 保存语言文件
	var result = GameManager.config_manager.save_json(file_path, basic_translations)
	if result:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("创建了基本语言文件: " + file_path, 1))
	else:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法创建语言文件: " + file_path, 2))

## 预加载语言
func _preload_languages() -> void:
	# 预加载常用语言
	var preload_languages = [Language.ZH_CN, Language.EN_US]

	# 如果当前语言不在预加载列表中，添加到列表
	if not preload_languages.has(current_language):
		preload_languages.append(current_language)

	# 预加载语言
	for lang in preload_languages:
		if lang != current_language:  # 当前语言已经加载
			_preload_language(lang)

## 预加载单个语言
func _preload_language(language: int) -> void:
	if not LANGUAGE_CODES.has(language):
		return

	var language_code = LANGUAGE_CODES[language]
	var file_path = TRANSLATION_PATH + language_code + ".json"

	if not FileAccess.file_exists(file_path):
		return

	# 使用线程异步加载
	var thread = Thread.new()
	thread.start(Callable(self, "_load_language_thread").bind(file_path, language_code))

	# 在下一帧等待线程完成
	call_deferred("_wait_for_thread", thread)

## 线程加载语言文件
func _load_language_thread(file_path: String, language_code: String) -> void:
	# 使用 ConfigManager 加载语言文件
	var translation_data = GameManager.config_manager.load_json(file_path)
	if not translation_data.is_empty():
		# 将翻译数据存储到缓存
		var cache_key = "translation_" + language_code
		# 使用call_deferred在主线程中发送信号
		call_deferred("_emit_preload_complete", language_code)



## 语言变更处理
func _on_language_changed(new_language: String) -> void:
	# 通知UI更新
	pass

## 响应语言代码请求
func _on_request_language_code() -> void:
	# 发送当前语言代码
	if _initialized:
		EventBus.localization.emit_event("language_changed", [get_current_language_code()])

## 等待线程完成
func _wait_for_thread(thread: Thread) -> void:
	# 等待线程完成
	if thread.is_started():
		thread.wait_to_finish()

## 设置语言（通过语言代码字符串）
func set_language(language_code: String) -> void:
	# 确保初始化完成
	if not _initialized:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("本地化管理器尚未初始化完成，将在初始化后设置语言", 1))
		call_deferred("set_language", language_code)
		return

	# 查找对应的语言枚举值
	for lang in LANGUAGE_CODES:
		if LANGUAGE_CODES[lang] == language_code:
			# 切换到该语言
			change_language(lang)
			return

	# 如果找不到对应的语言，使用默认语言
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("不支持的语言代码: " + language_code, 1))
	change_language(localization_settings.fallback_language)



## 确保初始化完成
func ensure_initialized() -> void:
	if not _initialized:
		_deferred_init()

## 在主线程中发送预加载完成信号
func _emit_preload_complete(language_code: String) -> void:
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("预加载语言完成: " + language_code, 0))
