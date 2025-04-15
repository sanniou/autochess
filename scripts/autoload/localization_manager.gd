extends Node
## 本地化管理器
## 负责游戏文本的多语言支持

# 支持的语言
enum Language {
	ZH_CN,  # 简体中文
	# 未来可以添加更多语言
}

# 语言代码映射
const LANGUAGE_CODES = {
	Language.ZH_CN: "zh_CN"
}

# 当前语言
var current_language: int = Language.ZH_CN

# 翻译数据
var translations = {}

# 语言文件路径
const TRANSLATION_PATH = "res://data/localization/"

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

func _ready():
	# 加载默认语言
	load_language(current_language)

	# 连接信号
	EventBus.language_changed.connect(_on_language_changed)

## 加载指定语言
func load_language(language: int) -> void:
	if not LANGUAGE_CODES.has(language):
		EventBus.debug_message.emit("不支持的语言: " + str(language), 2)
		return

	var language_code = LANGUAGE_CODES[language]
	var file_path = TRANSLATION_PATH + language_code + ".json"

	if not FileAccess.file_exists(file_path):
		EventBus.debug_message.emit("语言文件不存在: " + file_path, 2)

		# 如果是调试模式，创建一个空的语言文件
		if OS.is_debug_build():
			_create_empty_language_file(language_code)

		return

	# 使用 ConfigManager 加载语言文件
	var translation_data = config_manager.load_json(file_path)
	if translation_data.is_empty():
		EventBus.debug_message.emit("无法加载语言文件: " + file_path, 2)
		return

	translations = translation_data
	current_language = language

	EventBus.debug_message.emit("已加载语言: " + language_code, 0)
	EventBus.language_changed.emit(language_code)

## 切换语言
func change_language(language: int) -> void:
	if language == current_language:
		return

	load_language(language)

## 获取翻译文本
func tr(key: String, params: Array = []) -> String:
	if not translations.has(key):
		EventBus.debug_message.emit("翻译键不存在: " + key, 1)
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
	var result = config_manager.save_json(file_path, basic_translations)
	if result:
		EventBus.debug_message.emit("创建了基本语言文件: " + file_path, 1)
	else:
		EventBus.debug_message.emit("无法创建语言文件: " + file_path, 2)

## 语言变更处理
func _on_language_changed(new_language: String) -> void:
	# 通知UI更新
	pass
