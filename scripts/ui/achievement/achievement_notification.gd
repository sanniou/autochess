extends Control
class_name AchievementNotification
## 成就解锁通知
## 显示成就解锁的通知

# 显示时间
@export var display_time: float = 5.0

# 成就数据
var achievement_id: String = ""
var achievement_data: Dictionary = {}

# 引用
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var name_label = $Panel/VBoxContainer/NameLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel
@onready var icon = $Panel/VBoxContainer/HBoxContainer/Icon
@onready var animation_player = $AnimationPlayer

# 初始化
func _ready() -> void:
	# 设置初始状态
	modulate.a = 0.0
	
	# 更新UI
	_update_ui()
	
	# 播放显示动画
	_play_show_animation()
	
	# 设置自动隐藏计时器
	var timer = get_tree().create_timer(display_time)
	timer.timeout.connect(_on_hide_timer_timeout)

# 设置成就数据
func set_achievement_data(id: String, data: Dictionary) -> void:
	achievement_id = id
	achievement_data = data
	
	# 如果已经准备好，更新UI
	if is_inside_tree():
		_update_ui()

# 更新UI
func _update_ui() -> void:
	# 设置标题
	title_label.text = tr("ui.achievement.unlocked")
	
	# 设置成就名称
	name_label.text = achievement_data.get("name", "")
	
	# 设置成就描述
	description_label.text = achievement_data.get("description", "")
	
	# 设置成就图标
	var icon_path = achievement_data.get("icon_path", "")
	if icon_path != "":
		var texture = load(icon_path)
		if texture:
			icon.texture = texture

# 播放显示动画
func _play_show_animation() -> void:
	# 播放音效
	_play_unlock_sound()
	
	# 创建显示动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 播放图标动画
	if animation_player:
		animation_player.play("unlock")

# 播放隐藏动画
func _play_hide_animation() -> void:
	# 创建隐藏动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)

# 播放解锁音效
func _play_unlock_sound() -> void:
	# 获取音频管理器
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("achievement_unlock.ogg")

# 隐藏计时器超时处理
func _on_hide_timer_timeout() -> void:
	_play_hide_animation()
