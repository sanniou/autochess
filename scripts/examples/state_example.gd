extends Node
## 状态管理示例
## 展示如何使用状态管理系统

# 当前玩家状态
var player_state = {}

# 当前游戏状态
var game_state = {}

# 当前UI状态
var ui_state = {}

# 初始化
func _ready():
	# 订阅状态变更
	GameManager.state_manager.subscribe("player", self, "_on_player_state_changed")
	GameManager.state_manager.subscribe("game", self, "_on_game_state_changed")
	GameManager.state_manager.subscribe("ui", self, "_on_ui_state_changed")
	
	# 获取初始状态
	player_state = GameManager.state_manager.get_state_section("player")
	game_state = GameManager.state_manager.get_state_section("game")
	ui_state = GameManager.state_manager.get_state_section("ui")
	
	# 更新UI
	_update_ui()

# 清理
func _exit_tree():
	# 取消订阅状态变更
	GameManager.state_manager.unsubscribe_all(self)

# 处理输入
func _input(event):
	# 示例：按下空格键增加金币
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_add_gold(10)
	
	# 示例：按下回车键切换游戏暂停状态
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_toggle_pause()
	
	# 示例：按下Tab键显示通知
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_show_notification("这是一个测试通知", "info")

# 添加金币
func _add_gold(amount: int):
	# 创建动作
	var action = GameManager.state_manager.create_action("CHANGE_GOLD", {"amount": amount})
	
	# 分发动作
	GameManager.state_manager.dispatch(action)
	
	# 显示通知
	_show_notification("获得 " + str(amount) + " 金币", "success")

# 切换游戏暂停状态
func _toggle_pause():
	# 创建动作
	var action = GameManager.state_manager.create_action("SET_PAUSED", {"is_paused": not game_state.is_paused})
	
	# 分发动作
	GameManager.state_manager.dispatch(action)

# 显示通知
func _show_notification(message: String, type: String = "info"):
	# 创建动作
	var action = GameManager.state_manager.create_action("ADD_NOTIFICATION", {"message": message, "type": type})
	
	# 分发动作
	GameManager.state_manager.dispatch(action)

# 玩家状态变更处理
func _on_player_state_changed(new_state):
	# 更新玩家状态
	player_state = new_state
	
	# 更新UI
	_update_ui()
	
	# 检查玩家生命值
	if player_state.health <= 0 and not game_state.is_game_over:
		# 游戏结束
		var action = GameManager.state_manager.create_action("SET_GAME_OVER", {"is_game_over": true, "win": false})
		GameManager.state_manager.dispatch(action)

# 游戏状态变更处理
func _on_game_state_changed(new_state):
	# 更新游戏状态
	game_state = new_state
	
	# 更新UI
	_update_ui()
	
	# 处理游戏结束
	if game_state.is_game_over:
		if game_state.win:
			_show_notification("游戏胜利！", "success")
		else:
			_show_notification("游戏失败！", "error")

# UI状态变更处理
func _on_ui_state_changed(new_state):
	# 更新UI状态
	ui_state = new_state
	
	# 更新UI
	_update_ui()

# 更新UI
func _update_ui():
	# 这里应该更新UI元素
	# 例如：更新生命值、金币、经验等
	
	# 打印当前状态（仅用于演示）
	print("玩家状态：生命值 = " + str(player_state.health) + ", 金币 = " + str(player_state.gold))
	print("游戏状态：暂停 = " + str(game_state.is_paused) + ", 游戏结束 = " + str(game_state.is_game_over))
	print("UI状态：当前屏幕 = " + ui_state.current_screen + ", 打开窗口数 = " + str(ui_state.open_windows.size()))
