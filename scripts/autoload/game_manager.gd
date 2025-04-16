extends Node
## 游戏管理器
## 负责游戏全局状态管理和系统协调

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

# 游戏是否已初始化
var _initialized: bool = false

# 系统管理器引用
var map_manager = null
var battle_manager = null
var board_manager = null
var player_manager = null
var economy_manager = null
var shop_manager = null
var chess_manager = null
var equipment_manager = null
var relic_manager = null
var event_manager = null
var curse_manager = null
var story_manager = null
var ui_manager = null
var scene_manager = null
var theme_manager = null
var ui_animator = null
var notification_system = null
var tooltip_system = null
var skin_manager = null
var ability_factory = null
var relic_ui_manager = null
var environment_effect_manager = null
var damage_number_manager = null
var achievement_manager = null
var tutorial_manager = null

func _ready():
	# 连接必要的信号
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.player_died.connect(_on_player_died)
	EventBus.map_completed.connect(_on_map_completed)

	# 初始化UI工具
	var ui_utils = load("res://scripts/ui/ui_utils.gd")
	if ui_utils:
		ui_utils.initialize()

	# 初始化文本工具
	var text_utils = load("res://scripts/ui/text_utils.gd")
	if text_utils:
		text_utils.initialize()

	# 初始化游戏状态
	change_state(GameState.MAIN_MENU)

	# 标记初始化完成
	_initialized = true

## 改变游戏状态
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return

	var old_state = current_state
	current_state = new_state

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
	EventBus.game_state_changed.emit(old_state, new_state)

## 开始新游戏
func start_new_game(difficulty: int = 1) -> void:
	# 设置难度
	difficulty_level = difficulty

	# 重置游戏数据
	current_round = 0

	# 初始化各系统
	_initialize_systems()

	# 切换到地图状态
	change_state(GameState.MAP)

	# 发送游戏开始信号
	EventBus.game_started.emit()

	# 触发自动存档
	EventBus.autosave_triggered.emit()

## 加载存档
func load_game(save_slot: String) -> bool:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager == null:
		EventBus.debug_message.emit("无法获取存档管理器", 2)
		return false

	# 加载存档
	var success = save_manager.load_game(save_slot)
	if success:
		# 切换到地图状态
		change_state(GameState.MAP)

		# 发送游戏开始信号
		EventBus.game_started.emit()

		return true
	else:
		EventBus.debug_message.emit("加载存档失败", 2)
		return false

## 保存游戏
func save_game(save_slot: String = "") -> bool:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager == null:
		EventBus.debug_message.emit("无法获取存档管理器", 2)
		return false

	# 保存游戏
	var success = save_manager.save_game(save_slot)
	if success:
		EventBus.debug_message.emit("游戏已成功保存", 0)
		return true
	else:
		EventBus.debug_message.emit("保存游戏失败", 2)
		return false

## 暂停游戏
func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	EventBus.game_paused.emit(true)

## 恢复游戏
func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	EventBus.game_paused.emit(false)

## 退出游戏
func quit_game() -> void:
	# 获取存档管理器
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		# 触发自动存档
		save_manager.trigger_autosave()
	else:
		# 如果无法获取存档管理器，使用信号
		EventBus.autosave_triggered.emit()

	# 退出游戏
	get_tree().quit()

## 安全地添加子节点
func _safe_add_child(child_node: Node, node_name: String = "") -> void:
	# 使用 call_deferred 延迟添加子节点
	call_deferred("add_child", child_node)

	# 设置节点名称（如果提供）
	if node_name != "":
		child_node.name = node_name

## 初始化所有游戏系统
func _initialize_systems() -> void:
	# 初始化装备管理器
	if equipment_manager == null:
		var equipment_manager_script = load("res://scripts/managers/equipment_manager.gd")
		if equipment_manager_script:
			equipment_manager = equipment_manager_script.new()
			_safe_add_child(equipment_manager, "EquipmentManager")

	# 初始化玩家管理器
	if player_manager == null:
		var player_manager_script = load("res://scripts/managers/player_manager.gd")
		if player_manager_script:
			player_manager = player_manager_script.new()
			_safe_add_child(player_manager, "PlayerManager")

	# 初始化经济管理器
	if economy_manager == null:
		var economy_manager_script = load("res://scripts/managers/economy_manager.gd")
		if economy_manager_script:
			economy_manager = economy_manager_script.new()
			_safe_add_child(economy_manager, "EconomyManager")

	# 初始化商店管理器
	if shop_manager == null:
		var shop_manager_script = load("res://scripts/managers/shop_manager.gd")
		if shop_manager_script:
			shop_manager = shop_manager_script.new()
			_safe_add_child(shop_manager, "ShopManager")

	# 初始化棋盘管理器
	if board_manager == null:
		var board_manager_script = load("res://scripts/managers/board_manager.gd")
		if board_manager_script:
			board_manager = board_manager_script.new()
			_safe_add_child(board_manager, "BoardManager")

	# 初始化战斗管理器
	if battle_manager == null:
		var battle_manager_script = load("res://scripts/managers/battle_manager.gd")
		if battle_manager_script:
			battle_manager = battle_manager_script.new()
			_safe_add_child(battle_manager, "BattleManager")

	# 初始化遗物管理器
	if relic_manager == null:
		var relic_manager_script = load("res://scripts/managers/relic_manager.gd")
		if relic_manager_script:
			relic_manager = relic_manager_script.new()
			_safe_add_child(relic_manager, "RelicManager")

	# 初始化事件管理器
	if event_manager == null:
		var event_manager_script = load("res://scripts/managers/event_manager.gd")
		if event_manager_script:
			event_manager = event_manager_script.new()
			_safe_add_child(event_manager, "EventManager")

	# 初始化诅咒管理器
	if curse_manager == null:
		var curse_manager_script = load("res://scripts/managers/curse_manager.gd")
		if curse_manager_script:
			curse_manager = curse_manager_script.new()
			_safe_add_child(curse_manager, "CurseManager")

	# 初始化剧情管理器
	if story_manager == null:
		var story_manager_script = load("res://scripts/managers/story_manager.gd")
		if story_manager_script:
			story_manager = story_manager_script.new()
			_safe_add_child(story_manager, "StoryManager")

	# 初始化地图管理器
	if map_manager == null:
		var map_manager_script = load("res://scripts/managers/map_manager.gd")
		if map_manager_script:
			map_manager = map_manager_script.new()
			_safe_add_child(map_manager, "MapManager")

	# 初始化UI管理器
	if ui_manager == null:
		var ui_manager_script = load("res://scripts/managers/ui_manager.gd")
		if ui_manager_script:
			ui_manager = ui_manager_script.new()
			_safe_add_child(ui_manager, "UIManager")

	# 初始化场景管理器
	if scene_manager == null:
		var scene_manager_script = load("res://scripts/managers/scene_manager.gd")
		if scene_manager_script:
			scene_manager = scene_manager_script.new()
			_safe_add_child(scene_manager, "SceneManager")

	# 初始化主题管理器
	if theme_manager == null:
		var theme_manager_script = load("res://scripts/managers/theme_manager.gd")
		if theme_manager_script:
			theme_manager = theme_manager_script.new()
			_safe_add_child(theme_manager, "ThemeManager")

	# 初始化UI动画器
	if ui_animator == null:
		var ui_animator_script = load("res://scripts/ui/ui_animator.gd")
		if ui_animator_script:
			ui_animator = ui_animator_script.new()
			_safe_add_child(ui_animator, "UIAnimator")

	# 初始化通知系统
	if notification_system == null:
		var notification_system_script = load("res://scripts/ui/notification_system.gd")
		if notification_system_script:
			notification_system = notification_system_script.new()
			_safe_add_child(notification_system, "NotificationSystem")

	# 初始化工具提示系统
	if tooltip_system == null:
		var tooltip_system_script = load("res://scripts/ui/tooltip_system.gd")
		if tooltip_system_script:
			tooltip_system = tooltip_system_script.new()
			_safe_add_child(tooltip_system, "TooltipSystem")

	# 初始化皮肤管理器
	if skin_manager == null:
		var skin_manager_script = load("res://scripts/managers/skin_manager.gd")
		if skin_manager_script:
			skin_manager = skin_manager_script.new()
			_safe_add_child(skin_manager, "SkinManager")

	# 初始化环境特效管理器
	if environment_effect_manager == null:
		var environment_effect_manager_script = load("res://scripts/managers/environment_effect_manager.gd")
		if environment_effect_manager_script:
			environment_effect_manager = environment_effect_manager_script.new()
			_safe_add_child(environment_effect_manager, "EnvironmentEffectManager")

	# 初始化伤害数字管理器
	if damage_number_manager == null:
		var damage_number_manager_script = load("res://scripts/ui/damage_number_manager.gd")
		if damage_number_manager_script:
			damage_number_manager = damage_number_manager_script.new()
			_safe_add_child(damage_number_manager, "DamageNumberManager")

	# 初始化成就管理器
	if achievement_manager == null:
		var achievement_manager_script = load("res://scripts/managers/achievement_manager.gd")
		if achievement_manager_script:
			achievement_manager = achievement_manager_script.new()
			_safe_add_child(achievement_manager, "AchievementManager")

	# 初始化教程管理器
	if tutorial_manager == null:
		var tutorial_manager_script = load("res://scripts/managers/tutorial_manager.gd")
		if tutorial_manager_script:
			tutorial_manager = tutorial_manager_script.new()
			_safe_add_child(tutorial_manager, "TutorialManager")

	# 初始化技能工厂
	if ability_factory == null:
		var ability_factory_script = load("res://scripts/game/abilities/ability_factory.gd")
		if ability_factory_script:
			ability_factory = ability_factory_script.new()
			_safe_add_child(ability_factory, "AbilityFactory")

	# 初始化遗物UI管理器
	if relic_ui_manager == null:
		var relic_ui_manager_script = load("res://scripts/ui/relic/relic_ui_manager.gd")
		if relic_ui_manager_script:
			relic_ui_manager = relic_ui_manager_script.new()
			_safe_add_child(relic_ui_manager, "RelicUIManager")

	# 发送系统初始化完成信号
	EventBus.debug_message.emit("游戏系统初始化完成", 0)

## 进入主菜单状态
func _enter_main_menu_state() -> void:
	# 使用场景管理器加载主菜单场景
	if scene_manager:
		scene_manager.load_scene("main_menu", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var main_menu_scene = load("res://scenes/main_menu/main_menu.tscn")
		if main_menu_scene:
			get_tree().change_scene_to_packed(main_menu_scene)

## 进入地图状态
func _enter_map_state() -> void:
	# 使用场景管理器加载地图场景
	if scene_manager:
		scene_manager.load_scene("map", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var map_scene = load("res://scenes/map/map_scene.tscn")
		if map_scene:
			get_tree().change_scene_to_packed(map_scene)

## 进入战斗状态
func _enter_battle_state() -> void:
	# 使用场景管理器加载战斗场景
	if scene_manager:
		scene_manager.load_scene("battle", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var battle_scene = load("res://scenes/battle/battle_scene.tscn")
		if battle_scene:
			get_tree().change_scene_to_packed(battle_scene)

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
	# 使用场景管理器加载商店场景
	if scene_manager:
		scene_manager.load_scene("shop", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var shop_scene = load("res://scenes/shop/shop_scene.tscn")
		if shop_scene:
			get_tree().change_scene_to_packed(shop_scene)

## 退出商店状态
func _exit_shop_state() -> void:
	# 保存商店状态
	if shop_manager:
		shop_manager.reset()

## 进入事件状态
func _enter_event_state() -> void:
	# 使用场景管理器加载事件场景
	if scene_manager:
		scene_manager.load_scene("event", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var event_scene = load("res://scenes/event/event_scene.tscn")
		if event_scene:
			get_tree().change_scene_to_packed(event_scene)

## 退出事件状态
func _exit_event_state() -> void:
	# 清理事件状态
	if event_manager:
		event_manager.clear_current_event()

## 进入游戏结束状态
func _enter_game_over_state() -> void:
	# 使用场景管理器加载游戏结束场景
	if scene_manager:
		scene_manager.load_scene("game_over", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var game_over_scene = load("res://scenes/main_menu/game_over.tscn")
		if game_over_scene:
			get_tree().change_scene_to_packed(game_over_scene)

	# 发送游戏结束信号
	EventBus.game_ended.emit(false)

## 进入胜利状态
func _enter_victory_state() -> void:
	# 使用场景管理器加载胜利场景
	if scene_manager:
		scene_manager.load_scene("victory", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var victory_scene = load("res://scenes/main_menu/victory.tscn")
		if victory_scene:
			get_tree().change_scene_to_packed(victory_scene)

	# 发送游戏结束信号
	EventBus.game_ended.emit(true)

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
	# 使用场景管理器加载祭坛场景
	if scene_manager:
		scene_manager.load_scene("altar", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var altar_scene = load("res://scenes/altar/altar_scene.tscn")
		if altar_scene:
			get_tree().change_scene_to_packed(altar_scene)

## 退出祭坛状态
func _exit_altar_state() -> void:
	# 清理祭坛状态
	pass

## 进入铁匠铺状态
func _enter_blacksmith_state() -> void:
	# 使用场景管理器加载铁匠铺场景
	if scene_manager:
		scene_manager.load_scene("blacksmith", true)
	else:
		# 如果场景管理器不可用，使用传统方式
		var blacksmith_scene = load("res://scenes/blacksmith/blacksmith_scene.tscn")
		if blacksmith_scene:
			get_tree().change_scene_to_packed(blacksmith_scene)

## 退出铁匠铺状态
func _exit_blacksmith_state() -> void:
	# 清理铁匠铺状态
	pass
