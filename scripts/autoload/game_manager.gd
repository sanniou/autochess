extends "res://scripts/managers/core/base_manager.gd"
## 游戏管理器
## 负责游戏全局状态管理和系统协调
## 提供管理器注册系统，统一管理各系统组件

# 游戏状态枚举
enum GameState {
	NONE,           # 初始状态
	MAIN_MENU,      # 主菜单
	MAP,            # 地图界面
	BATTLE,         # 战斗界面
	SHOP,           # 商店界面
	EVENT,          # 事件界面
	ALTAR,          # 祭坛界面
	BLACKSMITH,     # 铁匠铺界面
	GAME_OVER,      # 游戏结束
	VICTORY         # 游戏胜利
}

# 当前游戏状态
var current_state: int = GameState.NONE

# 游戏是否暂停
var is_paused: bool = false

# 当前游戏回合
var current_round: int = 0

# 当前游戏难度
var difficulty_level: int = 1

# 存档相关参数
var save_params: Dictionary = {}

# 祭坛相关参数
var altar_params: Dictionary = {}

# 铁匠铺相关参数
var blacksmith_params: Dictionary = {}

# 管理器字典，用于存储所有注册的管理器
var _managers: Dictionary = {}

# 系统管理器引用
var state_manager: StateManager = null
var network_manager: NetworkManager = null
var sync_manager: SyncManager = null
var stats_manager: StatsManager = null

var map_manager: MapManager = null
var player_manager: PlayerManager = null
var board_manager: BoardManager = null
var battle_manager: BattleManager = null
var economy_manager: EconomyManager = null
var shop_manager: ShopManager = null
var chess_manager: ChessManager = null
var equipment_manager: EquipmentManager = null
var relic_manager: RelicManager = null
var event_manager: EventManager = null
var curse_manager: CurseManager = null
var story_manager: StoryManager = null
var synergy_manager: SynergyManager = null

var ui_manager: UIManager = null
# scene_manager 现在是 Autoload 节点
var theme_manager: ThemeManager = null
var hud_manager: HUDManager = null

var ui_animator: UIAnimator = null
var notification_system: NotificationSystem = null
var tooltip_system: TooltipSystem = null
var skin_manager: SkinManager = null
var environment_effect_manager: EnvironmentEffectManager = null
var damage_number_manager: DamageNumberManager = null
var achievement_manager: AchievementManager = null
var tutorial_manager: TutorialManager = null
var ability_factory: AbilityFactory = null
var relic_ui_manager: RelicUiManager = null
var effect_manager: EffectManager = null
var test_manager: TestManager = null

# 初始化
func _ready() -> void:
	# 初始化管理器
	initialize()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "GameManager"
	# 添加依赖
	add_dependency("SaveManager")

	# 初始化管理器字典
	_managers.clear()

	# 连接必要的信号
	EventBus.game.connect_event("game_started", _on_game_started)
	EventBus.game.connect_event("game_ended", _on_game_ended)
	EventBus.game.connect_event("player_died", _on_player_died)
	EventBus.map.connect_event("map_completed", _on_map_completed)

	# 注册所有管理器
	_register_all_managers()

	# 初始化所有管理器
	_initialize_all_managers()

	# 初始化游戏状态
	change_state(GameState.MAIN_MENU)

## 注册管理器
func register_manager(manager_name: String, manager_instance) -> bool:
	# 检查管理器名称是否有效
	if manager_name.is_empty():
		_log_error("无效的管理器名称")
		return false

	# 检查管理器实例是否有效
	if not is_instance_valid(manager_instance):
		_log_error("无效的管理器实例: " + manager_name)
		return false

	# 检查管理器是否已注册
	if _managers.has(manager_name):
		_log_error("管理器已注册: " + manager_name)
		return false

	# 注册管理器
	_managers[manager_name] = manager_instance

	# 更新管理器引用
	_update_manager_reference(manager_name, manager_instance)

	_log_info("管理器注册成功: " + manager_name)
	return true

## 获取管理器
func get_manager(manager_name: String):
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		_log_error("管理器不存在: " + manager_name)
		return null

	# 返回管理器实例
	return _managers[manager_name]

## 检查管理器是否存在
func has_manager(manager_name: String) -> bool:
	return _managers.has(manager_name)

## 注册所有管理器
func _register_all_managers() -> void:
	# 注册工具类
	var utils = get_node_or_null("/root/Utils")
	if utils:
		register_manager("Utils", utils)

	# 注册核心管理器
	# SceneManager 现在是 Autoload 节点
	_register_manager("UIManager", "res://scripts/ui/ui_manager.gd")
	_register_manager("ThemeManager", "res://scripts/managers/ui/theme_manager.gd")
	_register_manager("HUDManager", "res://scripts/managers/ui/hud_manager.gd")

	# 注册系统管理器
	_register_manager("StateManager", "res://scripts/managers/system/state_manager.gd")
	_register_manager("NetworkManager", "res://scripts/managers/system/network_manager.gd")
	_register_manager("SyncManager", "res://scripts/managers/system/sync_manager.gd")
	_register_manager("StatsManager", "res://scripts/managers/game/stats_manager.gd")

	# 注册游戏系统管理器
	_register_manager("MapManager", "res://scripts/managers/game/map_manager.gd")
	_register_manager("PlayerManager", "res://scripts/managers/game/player_manager.gd")
	_register_manager("BoardManager", "res://scripts/managers/game/board_manager.gd")
	_register_manager("BattleManager", "res://scripts/managers/game/battle_manager.gd")
	_register_manager("EconomyManager", "res://scripts/managers/game/economy_manager.gd")
	_register_manager("ShopManager", "res://scripts/managers/game/shop_manager.gd")
	_register_manager("ChessManager", "res://scripts/managers/game/chess_manager.gd")
	_register_manager("EquipmentManager", "res://scripts/managers/game/equipment_manager.gd")
	_register_manager("RelicManager", "res://scripts/managers/game/relic_manager.gd")
	_register_manager("EventManager", "res://scripts/managers/game/event_manager.gd")
	_register_manager("CurseManager", "res://scripts/managers/game/curse_manager.gd")
	_register_manager("StoryManager", "res://scripts/managers/game/story_manager.gd")
	_register_manager("SynergyManager", "res://scripts/managers/game/synergy_manager_new.gd")

	# 注册其他管理器
	_register_manager("NotificationSystem", "res://scripts/managers/ui/notification_system.gd")
	_register_manager("TooltipSystem", "res://scripts/managers/ui/tooltip_system.gd")
	_register_manager("SkinManager", "res://scripts/managers/game/skin_manager.gd")
	_register_manager("EnvironmentEffectManager", "res://scripts/managers/game/environment_effect_manager.gd")
	_register_manager("DamageNumberManager", "res://scripts/managers/game/damage_number_manager.gd")
	_register_manager("AchievementManager", "res://scripts/managers/game/achievement_manager.gd")
	_register_manager("TutorialManager", "res://scripts/managers/game/tutorial_manager.gd")
	_register_manager("AbilityFactory", "res://scripts/managers/game/ability_factory.gd")
	_register_manager("RelicUIManager", "res://scripts/managers/ui/relic_ui_manager.gd")
	_register_manager("EffectManager", "res://scripts/managers/game/effect_manager.gd")
	# ChessFactory 已被 ChessManager 替代

	# 注册测试管理器
	_register_manager("TestManager", "res://scripts/managers/test/test_manager.gd")

## 注册单个管理器
func _register_manager(manager_name: String, script_path: String) -> void:
	if not FileAccess.file_exists(script_path):
		_log_error("管理器脚本不存在: " + script_path)
		return

	var manager_script = load(script_path)
	if manager_script:
		var manager_instance = manager_script.new()
		add_child(manager_instance)
		manager_instance.name = manager_name

		# 直接注册管理器，不需要再调用_update_manager_reference
		register_manager(manager_name, manager_instance)
	else:
		_log_error("无法加载管理器脚本: " + script_path)

## 更新管理器引用
func _update_manager_reference(manager_name: String, manager_instance) -> void:
	# 根据管理器名称更新对应的引用变量
	match manager_name:
		# 系统管理器
		"StateManager": state_manager = manager_instance
		"NetworkManager": network_manager = manager_instance
		"SyncManager": sync_manager = manager_instance
		"StatsManager": stats_manager = manager_instance

		# 游戏管理器
		"MapManager": map_manager = manager_instance
		"PlayerManager": player_manager = manager_instance
		"BoardManager": board_manager = manager_instance
		"BattleManager": battle_manager = manager_instance
		"EconomyManager": economy_manager = manager_instance
		"ShopManager": shop_manager = manager_instance
		"ChessManager": chess_manager = manager_instance
		"EquipmentManager": equipment_manager = manager_instance
		"RelicManager": relic_manager = manager_instance
		"EventManager": event_manager = manager_instance
		"CurseManager": curse_manager = manager_instance
		"StoryManager": story_manager = manager_instance
		"SynergyManager": synergy_manager = manager_instance

		"UIManager": ui_manager = manager_instance
		# "SceneManager": 现在是 Autoload 节点
		"ThemeManager": theme_manager = manager_instance
		"HUDManager": hud_manager = manager_instance

		"UIAnimator": ui_animator = manager_instance
		"NotificationSystem": notification_system = manager_instance
		"TooltipSystem": tooltip_system = manager_instance
		"SkinManager": skin_manager = manager_instance
		"EnvironmentEffectManager": environment_effect_manager = manager_instance
		"DamageNumberManager": damage_number_manager = manager_instance
		"AchievementManager": achievement_manager = manager_instance
		"TutorialManager": tutorial_manager = manager_instance
		"AbilityFactory": ability_factory = manager_instance
		"RelicUIManager": relic_ui_manager = manager_instance
		"EffectManager": effect_manager = manager_instance
		"TestManager": test_manager = manager_instance

## 改变游戏状态
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return

	var old_state = current_state
	current_state = new_state

	# 使用 StateManager 更新状态
	if state_manager:
		state_manager.dispatch(
			state_manager.create_action("SET_GAME_STATE", {"state": new_state}))

	# 处理状态退出逻辑
	match old_state:
		GameState.BATTLE:
			_exit_battle_state()
		GameState.SHOP:
			_exit_shop_state()
		GameState.EVENT:
			_exit_event_state()
		GameState.ALTAR:
			_exit_altar_state()
		GameState.BLACKSMITH:
			_exit_blacksmith_state()

	# 处理状态进入逻辑
	match new_state:
		GameState.MAIN_MENU:
			_enter_main_menu_state()
		GameState.MAP:
			_enter_map_state()
		GameState.BATTLE:
			_enter_battle_state()
		GameState.SHOP:
			_enter_shop_state()
		GameState.EVENT:
			_enter_event_state()
		GameState.ALTAR:
			_enter_altar_state()
		GameState.BLACKSMITH:
			_enter_blacksmith_state()
		GameState.GAME_OVER:
			_enter_game_over_state()
		GameState.VICTORY:
			_enter_victory_state()

	# 发送状态变更信号
	EventBus.game.emit_event("game_state_changed", [old_state, new_state])

## 初始化所有管理器
func _initialize_all_managers() -> void:
	# 按照类型顺序初始化管理器
	# 1. 先初始化系统管理器
	_initialize_manager(MC.ManagerNames.STATE_MANAGER)
	_initialize_manager(MC.ManagerNames.NETWORK_MANAGER)
	_initialize_manager(MC.ManagerNames.SYNC_MANAGER)
	_initialize_manager(MC.ManagerNames.STATS_MANAGER)

	# 2. 然后初始化游戏管理器
	_initialize_manager(MC.ManagerNames.MAP_MANAGER)
	_initialize_manager(MC.ManagerNames.PLAYER_MANAGER)
	_initialize_manager(MC.ManagerNames.BOARD_MANAGER)
	_initialize_manager(MC.ManagerNames.BATTLE_MANAGER)
	_initialize_manager(MC.ManagerNames.ECONOMY_MANAGER)
	_initialize_manager(MC.ManagerNames.SHOP_MANAGER)
	_initialize_manager(MC.ManagerNames.CHESS_MANAGER)
	_initialize_manager(MC.ManagerNames.EQUIPMENT_MANAGER)
	_initialize_manager(MC.ManagerNames.RELIC_MANAGER)
	_initialize_manager(MC.ManagerNames.EVENT_MANAGER)
	_initialize_manager(MC.ManagerNames.CURSE_MANAGER)
	_initialize_manager(MC.ManagerNames.STORY_MANAGER)
	_initialize_manager(MC.ManagerNames.SYNERGY_MANAGER)

	# 3. 最后初始化UI管理器
	_initialize_manager(MC.ManagerNames.UI_MANAGER)
	_initialize_manager(MC.ManagerNames.THEME_MANAGER)
	_initialize_manager(MC.ManagerNames.HUD_MANAGER)
	_initialize_manager(MC.ManagerNames.NOTIFICATION_SYSTEM)
	_initialize_manager(MC.ManagerNames.TOOLTIP_SYSTEM)
	_initialize_manager(MC.ManagerNames.SKIN_MANAGER)
	_initialize_manager(MC.ManagerNames.ENVIRONMENT_EFFECT_MANAGER)
	_initialize_manager(MC.ManagerNames.DAMAGE_NUMBER_MANAGER)
	_initialize_manager(MC.ManagerNames.ACHIEVEMENT_MANAGER)
	_initialize_manager(MC.ManagerNames.TUTORIAL_MANAGER)
	_initialize_manager(MC.ManagerNames.ABILITY_FACTORY)
	_initialize_manager(MC.ManagerNames.RELIC_UI_MANAGER)
	_initialize_manager(MC.ManagerNames.EFFECT_MANAGER)
	_initialize_manager(MC.ManagerNames.TEST_MANAGER)

## 初始化单个管理器
func _initialize_manager(manager_name: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		_log_error("管理器不存在: " + manager_name)
		return false

	# 获取管理器实例
	var manager = _managers[manager_name]

	# 如果是BaseManager的子类，调用initialize方法
	if manager is BaseManager:
		if not manager.initialize():
			_log_error("管理器初始化失败: " + manager_name)
			return false
		_log_info("管理器初始化成功: " + manager_name)
		return true
	# 对于非BaseManager子类，如果有initialize方法，调用它
	elif manager.has_method("initialize"):
		manager.initialize()
		_log_info("管理器初始化成功: " + manager_name)
		return true

	return true

## 重置所有管理器
func _reset_all_managers() -> void:
	# 按照与初始化相反的顺序重置管理器
	# 1. 先重置UI管理器
	_reset_manager(MC.ManagerNames.TEST_MANAGER)
	_reset_manager(MC.ManagerNames.EFFECT_MANAGER)
	_reset_manager(MC.ManagerNames.RELIC_UI_MANAGER)
	_reset_manager(MC.ManagerNames.ABILITY_FACTORY)
	_reset_manager(MC.ManagerNames.TUTORIAL_MANAGER)
	_reset_manager(MC.ManagerNames.ACHIEVEMENT_MANAGER)
	_reset_manager(MC.ManagerNames.DAMAGE_NUMBER_MANAGER)
	_reset_manager(MC.ManagerNames.ENVIRONMENT_EFFECT_MANAGER)
	_reset_manager(MC.ManagerNames.SKIN_MANAGER)
	_reset_manager(MC.ManagerNames.TOOLTIP_SYSTEM)
	_reset_manager(MC.ManagerNames.NOTIFICATION_SYSTEM)
	_reset_manager(MC.ManagerNames.HUD_MANAGER)
	_reset_manager(MC.ManagerNames.THEME_MANAGER)
	_reset_manager(MC.ManagerNames.UI_MANAGER)

	# 2. 然后重置游戏管理器
	_reset_manager(MC.ManagerNames.SYNERGY_MANAGER)
	_reset_manager(MC.ManagerNames.STORY_MANAGER)
	_reset_manager(MC.ManagerNames.CURSE_MANAGER)
	_reset_manager(MC.ManagerNames.EVENT_MANAGER)
	_reset_manager(MC.ManagerNames.RELIC_MANAGER)
	_reset_manager(MC.ManagerNames.EQUIPMENT_MANAGER)
	_reset_manager(MC.ManagerNames.CHESS_MANAGER)
	_reset_manager(MC.ManagerNames.SHOP_MANAGER)
	_reset_manager(MC.ManagerNames.ECONOMY_MANAGER)
	_reset_manager(MC.ManagerNames.BATTLE_MANAGER)
	_reset_manager(MC.ManagerNames.BOARD_MANAGER)
	_reset_manager(MC.ManagerNames.PLAYER_MANAGER)
	_reset_manager(MC.ManagerNames.MAP_MANAGER)

	# 3. 最后重置系统管理器
	_reset_manager(MC.ManagerNames.STATS_MANAGER)
	_reset_manager(MC.ManagerNames.SYNC_MANAGER)
	_reset_manager(MC.ManagerNames.NETWORK_MANAGER)
	_reset_manager(MC.ManagerNames.STATE_MANAGER)

## 重置单个管理器
func _reset_manager(manager_name: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		_log_error("管理器不存在: " + manager_name)
		return false

	# 获取管理器实例
	var manager = _managers[manager_name]

	# 如果是BaseManager的子类，调用reset方法
	if manager is BaseManager:
		if not manager.reset():
			_log_error("管理器重置失败: " + manager_name)
			return false
		_log_info("管理器重置成功: " + manager_name)
		return true
	# 对于非BaseManager子类，如果有reset方法，调用它
	elif manager.has_method("reset"):
		manager.reset()
		_log_info("管理器重置成功: " + manager_name)
		return true

	return true

## 开始新游戏
func start_new_game(difficulty: int = 1) -> void:
	# 设置难度
	difficulty_level = difficulty

	# 重置游戏数据
	current_round = 0

	# 重置所有管理器
	_reset_all_managers()

	# 切换到地图状态
	change_state(GameState.MAP)

	# 发送游戏开始信号
	EventBus.game.emit_event("game_started", [])

	# 触发自动存档
	EventBus.save.emit_event("autosave_triggered", [])

## 加载存档
func load_game(save_slot: String) -> bool:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")

	# 加载存档
	var success = save_manager.load_game(save_slot)
	if success:
		# 切换到地图状态
		change_state(GameState.MAP)

		# 发送游戏开始信号
		EventBus.game.emit_event("game_started", [])

		return true
	else:
		_log_error("加载存档失败")
		return false

## 保存游戏
func save_game(save_slot: String = "") -> bool:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")

	# 保存游戏
	var success = save_manager.save_game(save_slot)
	if success:
		EventBus.debug.emit_event("debug_message", ["游戏已成功保存", 0])
		return true
	else:
		EventBus.debug.emit_event("debug_message", ["保存游戏失败", 2])
		return false

## 暂停游戏
func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	EventBus.game.emit_event("game_paused", [true])

## 恢复游戏
func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	EventBus.game.emit_event("game_paused", [false])

## 退出游戏
func quit_game() -> void:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		# 触发自动存档
		save_manager.trigger_autosave()
	else:
		# 如果无法获取存档管理器，使用信号
		EventBus.save.emit_event("autosave_triggered", [])

	# 退出游戏
	get_tree().quit()





## 进入主菜单状态
func _enter_main_menu_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("main_menu", true)

## 进入地图状态
func _enter_map_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("map", true)

## 进入战斗状态
func _enter_battle_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("battle", true)

	# 通知战斗系统开始战斗
	if battle_manager:
		battle_manager.start_battle()

## 退出战斗状态
func _exit_battle_state() -> void:
	# 通知战斗系统结束战斗
	if battle_manager:
		battle_manager.end_battle()

## 进入商店状态
func _enter_shop_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("shop", true)

## 退出商店状态
func _exit_shop_state() -> void:
	# 保存商店状态
	if shop_manager:
		shop_manager.reset()

## 进入事件状态
func _enter_event_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("event", true)

## 退出事件状态
func _exit_event_state() -> void:
	# 清理事件状态
	if event_manager:
		event_manager.clear_current_event()

## 进入游戏结束状态
func _enter_game_over_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("game_over", true)

	# 发送游戏结束信号
	EventBus.game.emit_event("game_ended", [false])

## 进入胜利状态
func _enter_victory_state() -> void:
	# 使用 Autoload 的 SceneManager
	SceneManager.load_scene("victory", true)

	# 发送游戏结束信号
	EventBus.game.emit_event("game_ended", [true])

## 游戏开始事件处理
func _on_game_started() -> void:
	# 记录游戏开始时间等信息
	pass

## 游戏结束事件处理
func _on_game_ended(win: bool) -> void:
	# 记录游戏结束数据
	# 解锁相关成就
	pass

## 玩家死亡事件处理
func _on_player_died() -> void:
	change_state(GameState.GAME_OVER)

## 地图完成事件处理
func _on_map_completed() -> void:
	change_state(GameState.VICTORY)

## 进入祭坛状态
func _enter_altar_state() -> void:
	# 加载祭坛场景
	SceneManager.load_scene("altar", true)

## 退出祭坛状态
func _exit_altar_state() -> void:
	# 清理祭坛状态
	pass

## 进入铁匠铺状态
func _enter_blacksmith_state() -> void:
	# 加载铁匠铺场景
	SceneManager.load_scene("blacksmith", true)

## 退出铁匠铺状态
func _exit_blacksmith_state() -> void:
	# 清理铁匠铺状态
	pass

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])
