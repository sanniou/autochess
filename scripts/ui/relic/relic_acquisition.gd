extends Control
## 遗物获取动画
## 显示获取遗物的动画效果

# 引用
@onready var animation_player = $AnimationPlayer
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var texture_rect = $Panel/VBoxContainer/TextureRect
@onready var name_label = $Panel/VBoxContainer/NameLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel

# 当前遗物
var relic = null

# 初始化
func _ready():
	# 默认隐藏
	modulate.a = 0

# 设置遗物数据
func set_relic_data(relic_data) -> void:
	relic = relic_data
	
	# 设置遗物名称
	name_label.text = relic.display_name
	
	# 设置遗物图标
	if relic.icon:
		texture_rect.texture = relic.icon
	
	# 设置遗物描述
	description_label.text = relic.description
	
	# 根据稀有度设置颜色和标题
	match relic.rarity:
		0: # 普通
			name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			title_label.text = "获得普通遗物!"
		1: # 稀有
			name_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0, 1.0))
			title_label.text = "获得稀有遗物!"
		2: # 史诗
			name_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0, 1.0))
			title_label.text = "获得史诗遗物!"
		3: # 传说
			name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
			title_label.text = "获得传说遗物!"

# 播放动画
func play_animation() -> void:
	# 播放获取动画
	animation_player.play("acquisition")
	
	# 播放音效
	match relic.rarity:
		0: # 普通
			GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("relic_common"))
		1: # 稀有
			GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("relic_rare"))
		2: # 史诗
			GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("relic_epic"))
		3: # 传说
			GlobalEventBus.audio.dispatch_event(AudioEvents.PlaySoundEvent.new("relic_legendary"))
