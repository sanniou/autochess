extends "res://scripts/managers/core/base_manager.gd"
class_name RelicUiManager
## 遗物UI管理器
## 负责管理遗物UI的显示和交互

# 遗物面板场景
const RELIC_PANEL_SCENE = preload("res://scenes/ui/relic/relic_panel.tscn")

# 遗物提示场景
const RELIC_TOOLTIP_SCENE = preload("res://scenes/ui/relic/relic_tooltip.tscn")

# 遗物获取动画场景
const RELIC_ACQUISITION_SCENE = preload("res://scenes/ui/relic/relic_acquisition.tscn")

# 当前遗物面板
var relic_panel = null

# 当前遗物提示
var relic_tooltip = null

# 遗物管理器引用
var relic_manager = null

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "RelicUiManager"

	# 原 _ready 函数的内容
	# 获取遗物管理器引用
	relic_manager = get_node_or_null("/root/GameManager/RelicManager")

	# 连接信号
	GlobalEventBus.relic.add_listener("relic_acquired", _on_relic_acquired)
	GlobalEventBus.relic.add_listener("show_relic_info", _on_show_relic_info)
	GlobalEventBus.relic.add_listener("hide_relic_info", _on_hide_relic_info)
	GlobalEventBus.game.add_listener("game_state_changed", _on_game_state_changed)

	## 显示遗物面板
func show_relic_panel() -> void:
	# 如果面板已存在，直接显示
	if relic_panel and is_instance_valid(relic_panel):
		relic_panel.visible = true
		return

	# 创建遗物面板
	relic_panel = RELIC_PANEL_SCENE.instantiate()
	add_child(relic_panel)

	# 初始化面板
	relic_panel.visible = true

## 隐藏遗物面板
func hide_relic_panel() -> void:
	if relic_panel and is_instance_valid(relic_panel):
		relic_panel.visible = false

## 显示遗物提示
func show_relic_tooltip(relic_data, position: Vector2) -> void:
	# 如果提示已存在，更新数据
	if relic_tooltip and is_instance_valid(relic_tooltip):
		relic_tooltip.set_relic_data(relic_data)
		relic_tooltip.position = position
		relic_tooltip.visible = true
		return

	# 创建遗物提示
	relic_tooltip = RELIC_TOOLTIP_SCENE.instantiate()
	add_child(relic_tooltip)

	# 设置数据和位置
	relic_tooltip.set_relic_data(relic_data)
	relic_tooltip.position = position
	relic_tooltip.visible = true

## 隐藏遗物提示
func hide_relic_tooltip() -> void:
	if relic_tooltip and is_instance_valid(relic_tooltip):
		relic_tooltip.visible = false

## 播放遗物获取动画
func play_relic_acquisition_animation(relic_data) -> void:
	# 创建遗物获取动画
	var acquisition_anim = RELIC_ACQUISITION_SCENE.instantiate()
	add_child(acquisition_anim)

	# 设置遗物数据
	acquisition_anim.set_relic_data(relic_data)

	# 播放动画
	acquisition_anim.play_animation()

## 遗物获取事件处理
func _on_relic_acquired(relic_data) -> void:
	# 播放获取动画
	play_relic_acquisition_animation(relic_data)

	# 更新遗物面板
	if relic_panel and is_instance_valid(relic_panel):
		relic_panel._initialize_relic_list()

## 显示遗物信息事件处理
func _on_show_relic_info(relic_data) -> void:
	# 显示遗物面板
	show_relic_panel()

	# 显示遗物详细信息
	if relic_panel and is_instance_valid(relic_panel):
		relic_panel._on_show_relic_info(relic_data)

## 隐藏遗物信息事件处理
func _on_hide_relic_info() -> void:
	# 隐藏遗物提示
	hide_relic_tooltip()

## 游戏状态变化事件处理
func _on_game_state_changed(old_state, new_state) -> void:
	# 根据游戏状态显示或隐藏遗物面板
	match new_state:
		GameManager.GameState.MAP:
			# 在地图界面可以查看遗物
			if relic_panel and is_instance_valid(relic_panel):
				relic_panel.visible = false  # 默认隐藏，点击按钮时显示
		GameManager.GameState.BATTLE:
			# 战斗中隐藏遗物面板
			hide_relic_panel()
		GameManager.GameState.SHOP:
			# 商店中可以查看遗物
			if relic_panel and is_instance_valid(relic_panel):
				relic_panel.visible = false  # 默认隐藏，点击按钮时显示


# 重写重置方法
func _do_reset() -> void:
	# 隐藏遗物面板
	hide_relic_panel()

	# 隐藏遗物提示
	hide_relic_tooltip()

	_log_info("遗物UI管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开信号连接
	GlobalEventBus.relic.remove_listener("relic_acquired", _on_relic_acquired)
	GlobalEventBus.relic.remove_listener("show_relic_info", _on_show_relic_info)
	GlobalEventBus.relic.remove_listener("hide_relic_info", _on_hide_relic_info)
	GlobalEventBus.game.remove_listener("game_state_changed", _on_game_state_changed)

	# 清理遗物面板
	if relic_panel and is_instance_valid(relic_panel):
		relic_panel.queue_free()
		relic_panel = null

	# 清理遗物提示
	if relic_tooltip and is_instance_valid(relic_tooltip):
		relic_tooltip.queue_free()
		relic_tooltip = null

	# 重置遗物管理器引用
	relic_manager = null

	_log_info("遗物UI管理器清理完成")
