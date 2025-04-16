extends Control
## 主菜单场景
## 游戏的入口点，提供开始游戏、继续游戏、设置等选项

# 游戏版本
const GAME_VERSION = "1.0.0"

# 是否已加载存档
var _saves_loaded = false

func _ready():
	# 设置版本标签
	$Version.text = "Version: " + GAME_VERSION

	# 设置标题
	$Title.text = "Auto Chess"

	# 设置按钮文本
	$MenuButtons/StartButton.text = "Start Game"
	$MenuButtons/ContinueButton.text = "Continue"
	$MenuButtons/SettingsButton.text = "Settings"
	$MenuButtons/AchievementsButton.text = "Achievements"
	$MenuButtons/QuitButton.text = "Quit"

	# 检查是否有存档
	_check_saves()

	# 播放主菜单音乐
	AudioManager.play_music("main_menu.ogg")

## 检查是否有存档
func _check_saves() -> void:
	var saves = SaveManager.get_save_list()
	$MenuButtons/ContinueButton.disabled = saves.size() == 0
	_saves_loaded = true

## 开始新游戏按钮处理
func _on_start_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 显示难度选择对话框
	# 这里应该创建一个难度选择对话框
	# 暂时直接开始新游戏
	GameManager.start_new_game(2)  # 普通难度

## 继续游戏按钮处理
func _on_continue_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	if not _saves_loaded:
		_check_saves()
		return

	# 显示存档选择对话框
	# 这里应该创建一个存档选择对话框
	# 暂时直接加载最后一个存档
	var saves = SaveManager.get_save_list()
	if saves.size() > 0:
		SaveManager.load_game(saves[0].name)

## 设置按钮处理
func _on_settings_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 显示设置对话框
	# 这里应该创建一个设置对话框
	# 暂时不做任何操作
	pass

## 成就按钮处理
func _on_achievements_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 显示成就界面
	# 这里应该创建一个成就界面
	# 暂时不做任何操作
	pass

## 退出按钮处理
func _on_quit_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	# 退出游戏
	GameManager.quit_game()
