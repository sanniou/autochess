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

# Obsolete state-specific parameter variables (Removed)
# var altar_params: Dictionary = {}
# var blacksmith_params: Dictionary = {}
# var shop_params: Dictionary = {}
# var event_params: Dictionary = {}
# var battle_params: Dictionary = {} # Assuming battle_params was also a member to be removed

# 状态机
var game_state_machine: GameStateMachine = null
const ConcreteGameStates = {
	GameState.NONE: "res://scripts/game_states/none_gs.gd",
	GameState.MAIN_MENU: "res://scripts/game_states/main_menu_gs.gd",
	GameState.MAP: "res://scripts/game_states/map_gs.gd",
	GameState.BATTLE: "res://scripts/game_states/battle_gs.gd",
	GameState.SHOP: "res://scripts/game_states/shop_gs.gd",
	GameState.EVENT: "res://scripts/game_states/event_gs.gd",
	GameState.ALTAR: "res://scripts/game_states/altar_gs.gd",
	GameState.BLACKSMITH: "res://scripts/game_states/blacksmith_gs.gd",
	GameState.GAME_OVER: "res://scripts/game_states/game_over_gs.gd",
	GameState.VICTORY: "res://scripts/game_states/victory_gs.gd"
}

# 管理器字典，用于存储所有注册的管理器
var _managers: Dictionary = {}

# 系统管理器引用
var config_manager: ConfigManager = null  # 配置管理器
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

# var ui_throttle_manager = null # Removed
var ui_manager: UIManager = null
# scene_manager 现在是 Autoload 节点
# var theme_manager: ThemeManager = null # Removed
var hud_manager: HUDManager = null

var animation_manager: AnimationManager = null
# var ui_animator: UIAnimator = null # Removed
# var notification_system: NotificationSystem = null # Removed
#var tooltip_system: TooltipSystem = null # MODIFIED
var skin_manager: SkinManager = null
var environment_effect_manager: EnvironmentEffectManager = null
var damage_number_manager: DamageNumberManager = null
var achievement_manager: AchievementManager = null
#var tutorial_manager: TutorialManager = null # MODIFIED
var ability_factory: AbilityFactory = null
# var relic_ui_manager: RelicUiManager = null # Removed
var game_effect_manager: GameEffectManager = null  # 游戏效果管理器，负责管理所有影响游戏状态的效果
var visual_manager: VisualManager = null  # 视觉效果管理器，负责管理所有视觉效果

var save_manager: SaveManager = null

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

	# 初始化状态机
	self.game_state_machine = GameStateMachine.new(self)
	add_child(self.game_state_machine)
	for state_enum_key in ConcreteGameStates:
		var state_script_path = ConcreteGameStates[state_enum_key]
		var state_script = load(state_script_path)
		if state_script:
			var state_instance = state_script.new()
			self.game_state_machine.add_state(state_enum_key, state_instance)
		else:
			push_error("Failed to load state script: " + state_script_path)
	
	set_process_unhandled_input(true) # For game_state_machine.process_input

	# 连接必要的信号
	GlobalEventBus.game.add_class_listener(GameEvents.GameStartedEvent, _on_game_started)
	GlobalEventBus.game.add_class_listener(GameEvents.GameEndedEvent, _on_game_ended)
	GlobalEventBus.game.add_class_listener(GameEvents.PlayerDiedEvent, _on_player_died)
	GlobalEventBus.map.add_class_listener(MapEvents.MapCompletedEvent, _on_map_completed)

	# 注册所有管理器
	_register_all_managers()
	save_manager=SaveManager

	# 初始化所有管理器
	_initialize_all_managers()

	# 初始化游戏状态
	self.game_state_machine.set_initial_state(GameState.MAIN_MENU, {})
	self.current_state = GameState.MAIN_MENU # Keep current_state synced for GameStateChangedEvent

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
	# Instantiate ConfigManager (DI Pilot)
	var config_manager_script = load("res://scripts/managers/system/config_manager.gd")
	var config_manager_instance = config_manager_script.new()
	# No dependencies to inject into ConfigManager's constructor for now.
	
	# Add as child and set name (consistent with old _register_manager)
	add_child(config_manager_instance)
	config_manager_instance.name = "ConfigManager" 
	
	# Store in _managers dictionary and set direct-access property
	_managers["ConfigManager"] = config_manager_instance
	if self.has_method("_update_manager_reference"): # Check if using this pattern
		_update_manager_reference("ConfigManager", config_manager_instance)
	else: # Fallback if _update_manager_reference is removed or changed
		self.config_manager = config_manager_instance 

	# 注册工具类
	var utils = get_node_or_null("/root/Utils")
	if utils:
		register_manager("Utils", utils)

	# 注册核心管理器
	# SceneManager 现在是 Autoload 节点
	# _register_manager("UIThrottleManager", "res://scripts/managers/ui/ui_throttle_manager.gd") # Removed
	_register_manager("UIManager", "res://scripts/ui/ui_manager.gd")
	# _register_manager("ThemeManager", "res://scripts/managers/ui/theme_manager.gd") # Removed
	_register_manager("HUDManager", "res://scripts/managers/ui/hud_manager.gd")

	# 注册系统管理器
	# _register_manager("ConfigManager", "res://scripts/managers/system/config_manager.gd")  # Removed, instantiated above
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

	## 注册其他管理器
	#_register_manager("AnimationManager", "res://scripts/managers/game/animation_manager.gd")
	# _register_manager("NotificationSystem", "res://scripts/managers/ui/notification_system.gd") # Removed
	# _register_manager("TooltipSystem", "res://scripts/managers/ui/tooltip_system.gd") # Removed
	_register_manager("SkinManager", "res://scripts/managers/game/skin_manager.gd")
	_register_manager("EnvironmentEffectManager", "res://scripts/managers/game/environment_effect_manager.gd")
	_register_manager("DamageNumberManager", "res://scripts/managers/game/damage_number_manager.gd")
	_register_manager("AchievementManager", "res://scripts/managers/game/achievement_manager.gd")
	_register_manager("TutorialManager", "res://scripts/managers/game/tutorial_manager.gd")
	_register_manager("AbilityFactory", "res://scripts/managers/game/ability_factory.gd")
	# _register_manager("RelicUIManager", "res://scripts/managers/ui/relic_ui_manager.gd") # Removed
	_register_manager("EffectManager", "res://scripts/managers/game/effect_manager.gd")

	# 注册新的效果系统
	_register_manager("GameEffectManager", "res://scripts/game/effects/game_effect_manager.gd")
	_register_manager("VisualManager", "res://scripts/visual/visual_manager.gd")
#

## 注册单个管理器
func _register_manager(manager_name: String, script_path: String) -> void:
	_log_error("注册管理器脚本: " + script_path)
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
		# 核心管理器
		# "UIThrottleManager": ui_throttle_manager = manager_instance # Removed
		"UIManager": ui_manager = manager_instance
		# "ThemeManager": theme_manager = manager_instance # Removed
		"HUDManager": hud_manager = manager_instance

		# 系统管理器
		"ConfigManager": config_manager = manager_instance  # 配置管理器
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

		# 其他管理器
		"AnimationManager": animation_manager = manager_instance
		# "UIAnimator": ui_animator = manager_instance # Removed
		# "NotificationSystem": notification_system = manager_instance # Removed
		# "TooltipSystem": tooltip_system = manager_instance # Removed
		"SkinManager": skin_manager = manager_instance
		"EnvironmentEffectManager": environment_effect_manager = manager_instance
		"DamageNumberManager": damage_number_manager = manager_instance
		"AchievementManager": achievement_manager = manager_instance
		# "TutorialManager": tutorial_manager = manager_instance # MODIFIED
		"AbilityFactory": ability_factory = manager_instance
		# "RelicUIManager": relic_ui_manager = manager_instance # Removed
		"GameEffectManager": game_effect_manager = manager_instance
		"VisualManager": visual_manager = manager_instance

## 改变游戏状态
func change_state(new_state_enum: int, params: Dictionary = {}) -> void:
	if new_state_enum == current_state and not params.has("force_reentry"): # Allow forcing reentry if needed
		return

	var old_current_state_key = current_state # Store for GameStateChangedEvent
	self.current_state = new_state_enum # Update for GameStateChangedEvent and for external queries

	# Use StateManager to update global state store if it exists
	if state_manager:
		state_manager.dispatch(
			state_manager.create_action("SET_GAME_STATE", {"state": new_state_enum}))
	
	# Delegate to the new GameStateMachine
	if game_state_machine:
		game_state_machine.change_state(new_state_enum, params)
	else:
		push_error("GameStateMachine not initialized!")

	# The GameStateChangedEvent is preserved for compatibility with existing systems.
	# The actual state entry/exit logic and specific GameFlowEvent dispatches
	# are now handled by the individual state classes and the GameStateMachine.
	GlobalEventBus.game.dispatch_event(GameEvents.GameStateChangedEvent.new(old_current_state_key, new_state_enum))

## 初始化所有管理器
func _initialize_all_managers() -> void:
	# 按照类型顺序初始化管理器
	# 1. 先初始化配置管理器，确保它在其他管理器之前初始化
	_initialize_manager("ConfigManager")

	# 2. 然后初始化其他系统管理器
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
	# _initialize_manager("UIThrottleManager") # Removed
	_initialize_manager(MC.ManagerNames.UI_MANAGER)
	# _initialize_manager(MC.ManagerNames.THEME_MANAGER) # Removed
	_initialize_manager(MC.ManagerNames.HUD_MANAGER)
	# _initialize_manager("UIAnimator") # Removed: UIAnimator is part of UIManager
	_initialize_manager("AnimationManager")
	# _initialize_manager(MC.ManagerNames.NOTIFICATION_SYSTEM) # Removed
	# _initialize_manager(MC.ManagerNames.TOOLTIP_SYSTEM) # Removed
	_initialize_manager(MC.ManagerNames.SKIN_MANAGER)
	_initialize_manager(MC.ManagerNames.ENVIRONMENT_EFFECT_MANAGER)
	_initialize_manager(MC.ManagerNames.DAMAGE_NUMBER_MANAGER)
	_initialize_manager(MC.ManagerNames.ACHIEVEMENT_MANAGER)
	_initialize_manager(MC.ManagerNames.TUTORIAL_MANAGER)
	_initialize_manager(MC.ManagerNames.ABILITY_FACTORY)
	# _initialize_manager(MC.ManagerNames.RELIC_UI_MANAGER) # Removed

	# 初始化新的效果系统
	_initialize_manager(MC.ManagerNames.GAME_EFFECT_MANAGER)
	_initialize_manager(MC.ManagerNames.VISUAL_MANAGER)

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
	# 2. 然后重置UI管理器
	# 重置新的效果系统
	_reset_manager(MC.ManagerNames.VISUAL_MANAGER)
	_reset_manager(MC.ManagerNames.GAME_EFFECT_MANAGER)
	# _reset_manager(MC.ManagerNames.RELIC_UI_MANAGER) # Removed
	_reset_manager(MC.ManagerNames.ABILITY_FACTORY)
	_reset_manager(MC.ManagerNames.TUTORIAL_MANAGER)
	_reset_manager(MC.ManagerNames.ACHIEVEMENT_MANAGER)
	_reset_manager(MC.ManagerNames.DAMAGE_NUMBER_MANAGER)
	_reset_manager(MC.ManagerNames.ENVIRONMENT_EFFECT_MANAGER)
	_reset_manager(MC.ManagerNames.SKIN_MANAGER)
	# _reset_manager(MC.ManagerNames.TOOLTIP_SYSTEM) # Removed
	# _reset_manager(MC.ManagerNames.NOTIFICATION_SYSTEM) # Removed
	# _reset_manager("UIAnimator") # Removed: UIAnimator is part of UIManager
	_reset_manager(MC.ManagerNames.HUD_MANAGER)
	# _reset_manager(MC.ManagerNames.THEME_MANAGER) # Removed
	_reset_manager(MC.ManagerNames.UI_MANAGER)
	# _reset_manager("UIThrottleManager") # Removed

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

	# 3. 然后重置系统管理器
	_reset_manager(MC.ManagerNames.STATS_MANAGER)
	_reset_manager(MC.ManagerNames.SYNC_MANAGER)
	_reset_manager(MC.ManagerNames.NETWORK_MANAGER)
	_reset_manager(MC.ManagerNames.STATE_MANAGER)

	# 4. 最后重置配置管理器，确保它在所有其他管理器之后重置
	_reset_manager("ConfigManager")  # 注意：这里没有使用MC.ManagerNames常量，因为还没有定义CONFIG_MANAGER常量

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
	GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new())

	# 触发自动存档
	GlobalEventBus.save.dispatch_event(SaveEvents.AutosaveTriggeredEvent.new())

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
		GlobalEventBus.game.dispatch_event(GameEvents.GameStartedEvent.new())

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
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("游戏已成功保存", 0))
		return true
	else:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("保存游戏失败", 2))
		return false

## 暂停游戏
func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	GlobalEventBus.game.dispatch_event(GameEvents.GamePausedEvent.new(true))

## 恢复游戏
func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	GlobalEventBus.game.dispatch_event(GameEvents.GamePausedEvent.new(false))

## 退出游戏
func quit_game() -> void:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		# 触发自动存档
		save_manager.trigger_autosave()
	else:
		# 如果无法获取存档管理器，使用信号
		GlobalEventBus.save.dispatch_event(SaveEvents.AutosaveTriggeredEvent.new())

	# 退出游戏
	get_tree().quit()

# Obsolete helper state methods removed
# _enter_main_menu_state, _enter_map_state, _enter_battle_state, _exit_battle_state,
# _enter_shop_state, _exit_shop_state, _enter_event_state, _exit_event_state,
# _enter_altar_state, _exit_altar_state, _enter_blacksmith_state, _exit_blacksmith_state,
# _enter_game_over_state, _enter_victory_state

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

# 重写清理方法
func _do_cleanup() -> void:
	# 调用父类的清理方法
	super()

	# 断开连接的信号
	GlobalEventBus.game.remove_class_listener(GameEvents.GameStartedEvent, _on_game_started)
	GlobalEventBus.game.remove_class_listener(GameEvents.GameEndedEvent, _on_game_ended)
	GlobalEventBus.game.remove_class_listener(GameEvents.PlayerDiedEvent, _on_player_died)
	GlobalEventBus.map.remove_class_listener(MapEvents.MapCompletedEvent, _on_map_completed)

	_log_info("GameManager 清理完成")

# Process Methods for State Machine
func _physics_process(delta: float) -> void:
	if game_state_machine:
		game_state_machine.process_physics(delta)

func _unhandled_input(event: InputEvent) -> void:
	if game_state_machine:
		game_state_machine.process_input(event)
