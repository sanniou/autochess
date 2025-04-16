extends Control
class_name AchievementPanel
## 成就面板
## 显示所有成就及其解锁状态

# 成就项场景
const ACHIEVEMENT_ITEM_SCENE = preload("res://scenes/ui/achievement/achievement_item.tscn")

# 成就分类
enum AchievementCategory {
	ALL,
	GAMEPLAY,
	COLLECTION,
	CHALLENGE,
	HIDDEN
}

# 当前选中的分类
var current_category: int = AchievementCategory.ALL

# 引用
@onready var achievement_manager = get_node("/root/GameManager/AchievementManager")
@onready var achievement_container = $ScrollContainer/AchievementContainer
@onready var category_buttons = {
	AchievementCategory.ALL: $CategoryPanel/HBoxContainer/AllButton,
	AchievementCategory.GAMEPLAY: $CategoryPanel/HBoxContainer/GameplayButton,
	AchievementCategory.COLLECTION: $CategoryPanel/HBoxContainer/CollectionButton,
	AchievementCategory.CHALLENGE: $CategoryPanel/HBoxContainer/ChallengeButton,
	AchievementCategory.HIDDEN: $CategoryPanel/HBoxContainer/HiddenButton
}
@onready var close_button = $CloseButton
@onready var progress_bar = $ProgressPanel/ProgressBar
@onready var progress_label = $ProgressPanel/ProgressLabel

# 初始化
func _ready() -> void:
	# 连接信号
	_connect_signals()
	
	# 加载成就列表
	_load_achievements()
	
	# 更新进度显示
	_update_progress_display()

# 连接信号
func _connect_signals() -> void:
	# 连接分类按钮信号
	for category in category_buttons:
		category_buttons[category].pressed.connect(_on_category_button_pressed.bind(category))
	
	# 连接关闭按钮信号
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 连接成就管理器信号
	if achievement_manager:
		achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
		achievement_manager.achievement_progress_updated.connect(_on_achievement_progress_updated)

# 加载成就列表
func _load_achievements() -> void:
	# 清空容器
	for child in achievement_container.get_children():
		child.queue_free()
	
	# 获取所有成就
	var achievements = achievement_manager.get_all_achievements()
	
	# 获取已解锁的成就
	var unlocked_achievements = achievement_manager.get_unlocked_achievements()
	
	# 按分类筛选成就
	var filtered_achievements = {}
	
	for id in achievements:
		var achievement = achievements[id]
		
		# 检查是否符合当前分类
		if _should_show_achievement(achievement, current_category):
			filtered_achievements[id] = achievement
	
	# 按解锁状态排序
	var sorted_achievements = _sort_achievements(filtered_achievements, unlocked_achievements)
	
	# 创建成就项
	for id in sorted_achievements:
		var achievement = sorted_achievements[id]
		
		# 创建成就项
		var achievement_item = ACHIEVEMENT_ITEM_SCENE.instantiate()
		achievement_container.add_child(achievement_item)
		
		# 设置成就数据
		achievement_item.set_achievement_data(id, achievement)
		
		# 设置解锁状态
		var is_unlocked = unlocked_achievements.has(id)
		achievement_item.set_unlocked(is_unlocked)
		
		# 设置进度
		var progress = achievement_manager.get_achievement_progress(id)
		var max_progress = achievement_manager.get_achievement_max_progress(id)
		achievement_item.set_progress(progress, max_progress)

# 更新进度显示
func _update_progress_display() -> void:
	# 获取所有成就
	var achievements = achievement_manager.get_all_achievements()
	
	# 获取已解锁的成就
	var unlocked_achievements = achievement_manager.get_unlocked_achievements()
	
	# 计算解锁进度
	var total_achievements = achievements.size()
	var unlocked_count = unlocked_achievements.size()
	var progress_percentage = float(unlocked_count) / float(total_achievements) if total_achievements > 0 else 0.0
	
	# 更新进度条
	progress_bar.value = progress_percentage * 100
	
	# 更新进度文本
	progress_label.text = tr("ui.achievement.progress").format({
		"unlocked": unlocked_count,
		"total": total_achievements,
		"percentage": int(progress_percentage * 100)
	})

# 检查成就是否应该显示
func _should_show_achievement(achievement: Dictionary, category: int) -> bool:
	# 如果是全部分类，显示所有非隐藏成就
	if category == AchievementCategory.ALL:
		return not achievement.get("hidden", false)
	
	# 如果是隐藏分类，只显示隐藏成就
	if category == AchievementCategory.HIDDEN:
		return achievement.get("hidden", false)
	
	# 如果是其他分类，检查成就类型
	var achievement_category = _get_achievement_category(achievement)
	return achievement_category == category and not achievement.get("hidden", false)

# 获取成就分类
func _get_achievement_category(achievement: Dictionary) -> int:
	# 根据成就要求确定分类
	if achievement.has("requirements"):
		var requirements = achievement.requirements
		
		if requirements.has("type"):
			match requirements.type:
				"chess", "equipment", "relic", "synergy":
					return AchievementCategory.COLLECTION
				"battle", "victory", "streak":
					return AchievementCategory.CHALLENGE
				_:
					return AchievementCategory.GAMEPLAY
	
	# 默认为游戏玩法分类
	return AchievementCategory.GAMEPLAY

# 排序成就
func _sort_achievements(achievements: Dictionary, unlocked_achievements: Dictionary) -> Dictionary:
	# 创建已解锁和未解锁的成就列表
	var unlocked = {}
	var locked = {}
	
	for id in achievements:
		if unlocked_achievements.has(id):
			unlocked[id] = achievements[id]
		else:
			locked[id] = achievements[id]
	
	# 合并列表，先显示未解锁的，再显示已解锁的
	var sorted = {}
	for id in locked:
		sorted[id] = locked[id]
	
	for id in unlocked:
		sorted[id] = unlocked[id]
	
	return sorted

# 分类按钮点击处理
func _on_category_button_pressed(category: int) -> void:
	# 设置当前分类
	current_category = category
	
	# 更新按钮状态
	for cat in category_buttons:
		category_buttons[cat].disabled = cat == category
	
	# 重新加载成就列表
	_load_achievements()

# 关闭按钮点击处理
func _on_close_button_pressed() -> void:
	# 隐藏面板
	visible = false

# 成就解锁事件处理
func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	# 重新加载成就列表
	_load_achievements()
	
	# 更新进度显示
	_update_progress_display()

# 成就进度更新事件处理
func _on_achievement_progress_updated(achievement_id: String, progress: float, max_progress: float) -> void:
	# 查找对应的成就项
	for child in achievement_container.get_children():
		if child.achievement_id == achievement_id:
			# 更新进度
			child.set_progress(progress, max_progress)
			break
