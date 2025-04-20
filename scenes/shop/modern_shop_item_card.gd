extends Panel
## 现代化商店物品卡片
## 提供更好的用户体验和视觉效果

# 信号
signal item_clicked(item_data)

# 变量
var item_data: Dictionary = {}
var is_hovering: bool = false
var shine_tween: Tween = null
var glow_tween: Tween = null

# 节点引用
@onready var icon_texture = $VBoxContainer/MarginContainer/IconPanel/IconTexture
@onready var name_label = $VBoxContainer/NameLabel
@onready var price_label = $VBoxContainer/PriceContainer/HBoxContainer/PriceLabel
@onready var rarity_indicator = $VBoxContainer/MarginContainer/IconPanel/RarityIndicator
@onready var type_badge = $VBoxContainer/MarginContainer/IconPanel/TypeBadge
@onready var type_label = $VBoxContainer/MarginContainer/IconPanel/TypeBadge/TypeLabel
@onready var glow_effect = $VBoxContainer/MarginContainer/IconPanel/GlowEffect
@onready var shine_effect = $ShineEffect
@onready var tooltip_panel = $TooltipPanel
@onready var animation_player = $AnimationPlayer
@onready var buy_button = $VBoxContainer/BuyButton

# 初始化
func _ready():
	# 设置初始状态
	tooltip_panel.visible = false
	glow_effect.visible = false
	
	# 设置动画
	_setup_animations()

# 设置动画
func _setup_animations():
	# 创建卡片出现动画
	var appear_anim = Animation.new()
	appear_anim.length = 0.3
	
	# 缩放动画
	var scale_track = appear_anim.add_track(Animation.TYPE_VALUE)
	appear_anim.track_set_path(scale_track, ":scale")
	appear_anim.track_insert_key(scale_track, 0.0, Vector2(0.8, 0.8))
	appear_anim.track_insert_key(scale_track, 0.3, Vector2(1.0, 1.0))
	
	# 透明度动画
	var alpha_track = appear_anim.add_track(Animation.TYPE_VALUE)
	appear_anim.track_set_path(alpha_track, ":modulate")
	appear_anim.track_insert_key(alpha_track, 0.0, Color(1, 1, 1, 0))
	appear_anim.track_insert_key(alpha_track, 0.3, Color(1, 1, 1, 1))
	
	# 添加动画到动画播放器
	animation_player.add_animation("appear", appear_anim)
	
	# 创建闪光动画
	var shine_anim = Animation.new()
	shine_anim.length = 1.0
	
	# 闪光效果动画
	var shine_track = shine_anim.add_track(Animation.TYPE_VALUE)
	shine_anim.track_set_path(shine_track, "ShineEffect:color")
	shine_anim.track_insert_key(shine_track, 0.0, Color(1, 1, 1, 0))
	shine_anim.track_insert_key(shine_track, 0.5, Color(1, 1, 1, 0.3))
	shine_anim.track_insert_key(shine_track, 1.0, Color(1, 1, 1, 0))
	
	# 添加动画到动画播放器
	animation_player.add_animation("shine", shine_anim)

# 初始化物品数据
func initialize(data: Dictionary):
	item_data = data
	
	# 设置物品图标
	var icon_path = data.get("icon_path", "")
	if not icon_path.is_empty():
		icon_texture.texture = load(icon_path)
	else:
		icon_texture.texture = null
	
	# 设置物品名称
	name_label.text = data.get("name", "未知物品")
	
	# 设置物品价格
	price_label.text = str(data.get("cost", 0))
	
	# 设置稀有度指示器颜色
	var rarity = data.get("rarity", 0)
	match rarity:
		0: # 普通
			rarity_indicator.color = Color(0.8, 0.8, 0.8)
		1: # 稀有
			rarity_indicator.color = Color(0.2, 0.6, 1)
		2: # 史诗
			rarity_indicator.color = Color(0.8, 0.2, 1)
		3: # 传说
			rarity_indicator.color = Color(1, 0.8, 0.2)
	
	# 设置类型标签
	var type = data.get("type", "")
	match type:
		"weapon":
			type_label.text = "W"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.8, 0.2, 0.2, 0.8))
		"armor":
			type_label.text = "A"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.2, 0.2, 0.8, 0.8))
		"accessory":
			type_label.text = "S"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.2, 0.8, 0.2, 0.8))
		"chess_piece":
			type_label.text = "C"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.8, 0.8, 0.2, 0.8))
		"relic":
			type_label.text = "R"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.8, 0.2, 0.8, 0.8))
		_:
			type_label.text = "?"
			type_badge.add_theme_color_override("panel_bg_color", Color(0.5, 0.5, 0.5, 0.8))
	
	# 设置工具提示内容
	$TooltipPanel/VBoxContainer/TitleLabel.text = data.get("name", "未知物品")
	
	var type_text = "类型: "
	match type:
		"weapon":
			type_text += "武器"
		"armor":
			type_text += "防具"
		"accessory":
			type_text += "饰品"
		"chess_piece":
			type_text += "棋子"
		"relic":
			type_text += "遗物"
		_:
			type_text += "未知"
	$TooltipPanel/VBoxContainer/TypeLabel.text = type_text
	
	var rarity_text = "稀有度: "
	var rarity_color = Color(1, 1, 1)
	match rarity:
		0:
			rarity_text += "普通"
			rarity_color = Color(0.8, 0.8, 0.8)
		1:
			rarity_text += "稀有"
			rarity_color = Color(0.2, 0.6, 1)
		2:
			rarity_text += "史诗"
			rarity_color = Color(0.8, 0.2, 1)
		3:
			rarity_text += "传说"
			rarity_color = Color(1, 0.8, 0.2)
		_:
			rarity_text += "未知"
	$TooltipPanel/VBoxContainer/RarityLabel.text = rarity_text
	$TooltipPanel/VBoxContainer/RarityLabel.add_theme_color_override("font_color", rarity_color)
	
	$TooltipPanel/VBoxContainer/DescriptionLabel.text = data.get("description", "无描述")
	
	# 设置属性文本
	var stats_text = "属性: "
	var stats = data.get("stats", {})
	if not stats.is_empty():
		var stat_strings = []
		for stat_name in stats:
			var value = stats[stat_name]
			var stat_string = ""
			match stat_name:
				"health":
					stat_string = "+" + str(value) + " 生命值"
				"attack_damage":
					stat_string = "+" + str(value) + " 攻击力"
				"attack_speed":
					stat_string = "+" + str(value) + "% 攻击速度"
				"armor":
					stat_string = "+" + str(value) + " 护甲"
				"magic_resist":
					stat_string = "+" + str(value) + " 魔法抗性"
				"spell_power":
					stat_string = "+" + str(value) + " 法术强度"
				"move_speed":
					stat_string = "+" + str(value) + " 移动速度"
				"crit_chance":
					stat_string = "+" + str(value) + "% 暴击几率"
				"crit_damage":
					stat_string = "+" + str(value) + "% 暴击伤害"
				"dodge_chance":
					stat_string = "+" + str(value) + "% 闪避几率"
				_:
					stat_string = "+" + str(value) + " " + stat_name
			stat_strings.append(stat_string)
		stats_text += ", ".join(stat_strings)
	else:
		stats_text += "无"
	$TooltipPanel/VBoxContainer/StatsLabel.text = stats_text
	
	# 播放出现动画
	animation_player.play("appear")
	
	# 如果是高稀有度物品，添加闪光效果
	if rarity >= 2:
		shine_effect.visible = true
		_start_shine_effect()

# 开始闪光效果
func _start_shine_effect():
	# 停止之前的动画
	if shine_tween:
		shine_tween.kill()
	
	# 创建新的动画
	shine_tween = create_tween()
	shine_tween.set_loops()
	shine_tween.set_trans(Tween.TRANS_SINE)
	shine_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 设置闪光效果
	shine_effect.color = Color(1, 1, 1, 0)
	shine_tween.tween_property(shine_effect, "color", Color(1, 1, 1, 0.3), 1.0)
	shine_tween.tween_property(shine_effect, "color", Color(1, 1, 1, 0), 1.0)

# 开始发光效果
func _start_glow_effect():
	# 停止之前的动画
	if glow_tween:
		glow_tween.kill()
	
	# 创建新的动画
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	
	# 设置发光效果
	glow_effect.visible = true
	glow_effect.color = Color(0.5, 0.5, 1, 0.1)
	glow_tween.tween_property(glow_effect, "color", Color(0.5, 0.5, 1, 0.3), 0.5)
	glow_tween.tween_property(glow_effect, "color", Color(0.5, 0.5, 1, 0.1), 0.5)

# 停止发光效果
func _stop_glow_effect():
	if glow_tween:
		glow_tween.kill()
	glow_effect.visible = false

# 显示工具提示
func _show_tooltip():
	# 计算工具提示位置
	var global_rect = get_global_rect()
	var tooltip_size = tooltip_panel.size
	
	var tooltip_pos = Vector2(
		global_rect.position.x + global_rect.size.x + 10,
		global_rect.position.y
	)
	
	# 确保工具提示不会超出屏幕
	var viewport_size = get_viewport_rect().size
	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = global_rect.position.x - tooltip_size.x - 10
	
	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = viewport_size.y - tooltip_size.y
	
	# 设置工具提示位置
	tooltip_panel.global_position = tooltip_pos
	
	# 显示工具提示
	tooltip_panel.visible = true

# 隐藏工具提示
func _hide_tooltip():
	tooltip_panel.visible = false

# 信号处理函数
func _on_mouse_entered():
	is_hovering = true
	_start_glow_effect()
	_show_tooltip()

func _on_mouse_exited():
	is_hovering = false
	_stop_glow_effect()
	_hide_tooltip()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_clicked.emit(item_data)

func _on_buy_button_pressed():
	# 发送购买信号
	item_clicked.emit(item_data)
