extends Node
class_name ManagerAccessor
## 管理器访问器
## 提供统一的管理器访问接口，简化管理器获取过程

# 游戏管理器引用
var _game_manager = null

# 初始化
func _init():
	# 等待一帧，确保GameManager已经初始化
	await Engine.get_main_loop().process_frame
	
	# 获取GameManager引用
	_game_manager = Engine.get_singleton("GameManager")
	
	if not _game_manager:
		push_error("无法获取GameManager引用")

# 获取管理器
func get_manager(manager_name: String):
	if not _game_manager:
		push_error("GameManager未初始化")
		return null
		
	return _game_manager.get_manager(manager_name)

# 检查管理器是否存在
func has_manager(manager_name: String) -> bool:
	if not _game_manager:
		return false
		
	return _game_manager.has_manager(manager_name)

# 以下是常用管理器的快捷访问方法

# 获取地图管理器
func get_map_manager():
	return get_manager("MapManager")

# 获取玩家管理器
func get_player_manager():
	return get_manager("PlayerManager")

# 获取棋盘管理器
func get_board_manager():
	return get_manager("BoardManager")

# 获取战斗管理器
func get_battle_manager():
	return get_manager("BattleManager")

# 获取经济管理器
func get_economy_manager():
	return get_manager("EconomyManager")

# 获取商店管理器
func get_shop_manager():
	return get_manager("ShopManager")

# 获取装备管理器
func get_equipment_manager():
	return get_manager("EquipmentManager")

# 获取遗物管理器
func get_relic_manager():
	return get_manager("RelicManager")

# 获取事件管理器
func get_event_manager():
	return get_manager("EventManager")

# 获取诅咒管理器
func get_curse_manager():
	return get_manager("CurseManager")

# 获取剧情管理器
func get_story_manager():
	return get_manager("StoryManager")

# 获取羁绊管理器
func get_synergy_manager():
	return get_manager("SynergyManager")

# 获取UI管理器
func get_ui_manager():
	return get_manager("UIManager")

# 获取主题管理器
func get_theme_manager():
	return get_manager("ThemeManager")

# 获取HUD管理器
func get_hud_manager():
	return get_manager("HUDManager")

# 获取UI动画器
func get_ui_animator():
	return get_manager("UIAnimator")

# 获取通知系统
func get_notification_system():
	return get_manager("NotificationSystem")

# 获取提示系统
func get_tooltip_system():
	return get_manager("TooltipSystem")

# 获取皮肤管理器
func get_skin_manager():
	return get_manager("SkinManager")

# 获取环境效果管理器
func get_environment_effect_manager():
	return get_manager("EnvironmentEffectManager")

# 获取伤害数字管理器
func get_damage_number_manager():
	return get_manager("DamageNumberManager")

# 获取成就管理器
func get_achievement_manager():
	return get_manager("AchievementManager")

# 获取教程管理器
func get_tutorial_manager():
	return get_manager("TutorialManager")

# 获取技能工厂
func get_ability_factory():
	return get_manager("AbilityFactory")

# 获取遗物UI管理器
func get_relic_ui_manager():
	return get_manager("RelicUIManager")

# 获取效果管理器
func get_effect_manager():
	return get_manager("EffectManager")

# 获取棋子工厂
func get_chess_factory():
	return get_manager("ChessFactory")
