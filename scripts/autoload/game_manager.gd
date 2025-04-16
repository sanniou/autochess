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
var skin_system = null
var ability_factory = null
var relic_ui_manager = null

func _ready():
	# 连接必要的信号
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.player_died.connect(_on_player_died)
	EventBus.map_completed.connect(_on_map_completed)

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
	# 触发自动存档
	EventBus.autosave_triggered.emit()

	# 退出游戏
	get_tree().quit()

## 初始化所有游戏系统
func _initialize_systems() -> void:
	# 初始化装备管理器
	if equipment_manager == null:
		equipment_manager = EquipmentManager.new()
		add_child(equipment_manager)
		equipment_manager.name = "EquipmentManager"

	# 初始化玩家管理器
	if player_manager == null:
		player_manager = PlayerManager.new()
		add_child(player_manager)
		player_manager.name = "PlayerManager"

	# 初始化经济管理器
	if economy_manager == null:
		economy_manager = EconomyManager.new()
		add_child(economy_manager)
		economy_manager.name = "EconomyManager"

	# 初始化商店管理器
	if shop_manager == null:
		shop_manager = ShopManager.new()
		add_child(shop_manager)
		shop_manager.name = "ShopManager"

	# 初始化棋盘管理器
	if board_manager == null:
		board_manager = BoardManager.new()
		add_child(board_manager)
		board_manager.name = "BoardManager"

	# 初始化战斗管理器
	if battle_manager == null:
		battle_manager = BattleManager.new()
		add_child(battle_manager)
		battle_manager.name = "BattleManager"

	# 初始化遗物管理器
	if relic_manager == null:
		relic_manager = RelicManager.new()
		add_child(relic_manager)
		relic_manager.name = "RelicManager"

	# 初始化事件管理器
	if event_manager == null:
		event_manager = EventManager.new()
		add_child(event_manager)
		event_manager.name = "EventManager"

	# 初始化诅咒管理器
	if curse_manager == null:
		curse_manager = CurseManager.new()
		add_child(curse_manager)
		curse_manager.name = "CurseManager"

	# 初始化剧情管理器
	if story_manager == null:
		story_manager = StoryManager.new()
		add_child(story_manager)
		story_manager.name = "StoryManager"

	# 初始化地图管理器
	if map_manager == null:
		map_manager = MapManager.new()
		add_child(map_manager)
		map_manager.name = "MapManager"

	# 初始化UI管理器
	if ui_manager == null:
		ui_manager = UIManager.new()
		add_child(ui_manager)
		ui_manager.name = "UIManager"

	# 初始化场景管理器
	if scene_manager == null:
		scene_manager = SceneManager.new()
		add_child(scene_manager)
		scene_manager.name = "SceneManager"

	# 初始化主题管理器
	if theme_manager == null:
		theme_manager = ThemeManager.new()
		add_child(theme_manager)
		theme_manager.name = "ThemeManager"

	# 初始化UI动画器
	if ui_animator == null:
		ui_animator = UIAnimator.new()
		add_child(ui_animator)
		ui_animator.name = "UIAnimator"

	# 初始化通知系统
	if notification_system == null:
		notification_system = NotificationSystem.new()
		add_child(notification_system)
		notification_system.name = "NotificationSystem"

	# 初始化工具提示系统
	if tooltip_system == null:
		tooltip_system = TooltipSystem.new()
		add_child(tooltip_system)
		tooltip_system.name = "TooltipSystem"

	# 初始化皮肤系统
	if skin_system == null:
		skin_system = SkinSystem.new()
		add_child(skin_system)
		skin_system.name = "SkinSystem"

	# 初始化技能工厂
	if ability_factory == null:
		ability_factory = AbilityFactory.new()
		add_child(ability_factory)
		ability_factory.name = "AbilityFactory"

	# 初始化遗物UI管理器
	if relic_ui_manager == null:
		relic_ui_manager = load("res://scripts/ui/relic/relic_ui_manager.gd").new()
		add_child(relic_ui_manager)
		relic_ui_manager.name = "RelicUIManager"

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
