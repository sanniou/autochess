extends Node2D
class_name ChessPieceView
## 棋子视图
## 负责棋子的视觉表现

# 视觉组件引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var star_indicator: Node2D = $StarIndicator
@onready var effect_container: Node2D = $EffectContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 配置
var config = {
	"star_colors": [
		Color(1.0, 1.0, 1.0),  # 1星 - 白色
		Color(0.0, 0.8, 0.0),  # 2星 - 绿色
		Color(0.0, 0.0, 1.0)   # 3星 - 蓝色
	],
	"health_bar_colors": [
		Color(0.0, 1.0, 0.0),  # 满血 - 绿色
		Color(1.0, 1.0, 0.0),  # 中血 - 黄色
		Color(1.0, 0.0, 0.0)   # 低血 - 红色
	],
	"mana_bar_color": Color(0.0, 0.5, 1.0)  # 蓝色
}

# 信号
signal animation_finished(animation_name)

# 初始化
func _ready():
	# 初始化视觉组件
	_initialize_visuals()
	
	# 连接信号
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

# 初始化视觉组件
func _initialize_visuals() -> void:
	# 创建效果容器
	if not effect_container:
		effect_container = Node2D.new()
		effect_container.name = "EffectContainer"
		add_child(effect_container)
	
	# 创建星级指示器
	if not star_indicator:
		star_indicator = Node2D.new()
		star_indicator.name = "StarIndicator"
		add_child(star_indicator)
	
	# 创建生命值条
	if not health_bar:
		health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = 100
		health_bar.size = Vector2(60, 8)
		health_bar.position = Vector2(-30, -40)
		add_child(health_bar)
	
	# 创建法力值条
	if not mana_bar:
		mana_bar = ProgressBar.new()
		mana_bar.name = "ManaBar"
		mana_bar.min_value = 0
		mana_bar.max_value = 100
		mana_bar.value = 0
		mana_bar.size = Vector2(60, 6)
		mana_bar.position = Vector2(-30, -30)
		add_child(mana_bar)

# 初始化
func initialize(data: ChessPieceData) -> void:
	# 设置精灵纹理
	_load_sprite_texture(data.id)
	
	# 更新星级
	update_star_level(data.star_level)
	
	# 更新生命值条
	update_health_bar(data.current_health, data.max_health)
	
	# 更新法力值条
	update_mana_bar(data.current_mana, data.max_mana)

# 加载精灵纹理
func _load_sprite_texture(piece_id: String) -> void:
	if not sprite:
		return
	
	# 构建纹理路径
	var texture_path = "res://assets/images/chess/" + piece_id + ".png"
	
	# 加载纹理
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		# 使用默认纹理
		sprite.texture = load("res://assets/images/chess/default.png")

# 更新星级
func update_star_level(star_level: int) -> void:
	if not star_indicator:
		return
	
	# 清除现有星星
	for child in star_indicator.get_children():
		child.queue_free()
	
	# 添加新星星
	for i in range(star_level):
		var star = Sprite2D.new()
		star.texture = load("res://assets/images/ui/star.png")
		star.position = Vector2(i * 15 - (star_level - 1) * 7.5, -50)
		star.scale = Vector2(0.5, 0.5)
		
		# 设置星星颜色
		if star_level <= config.star_colors.size():
			star.modulate = config.star_colors[star_level - 1]
		
		star_indicator.add_child(star)

# 更新生命值条
func update_health_bar(current_health: float, max_health: float) -> void:
	if not health_bar:
		return
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# 根据生命值百分比设置颜色
	var health_percent = current_health / max_health
	if health_percent > 0.7:
		health_bar.modulate = config.health_bar_colors[0]  # 满血 - 绿色
	elif health_percent > 0.3:
		health_bar.modulate = config.health_bar_colors[1]  # 中血 - 黄色
	else:
		health_bar.modulate = config.health_bar_colors[2]  # 低血 - 红色

# 更新法力值条
func update_mana_bar(current_mana: float, max_mana: float) -> void:
	if not mana_bar:
		return
	
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
	mana_bar.modulate = config.mana_bar_color

# 播放动画
func play_animation(animation_name: String) -> void:
	if not animation_player:
		return
	
	# 检查动画是否存在
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	else:
		# 播放默认动画
		match animation_name:
			"idle":
				_play_idle_animation()
			"move":
				_play_move_animation()
			"attack":
				_play_attack_animation()
			"cast":
				_play_cast_animation()
			"stunned":
				_play_stunned_animation()
			"death":
				_play_death_animation()

# 播放空闲动画
func _play_idle_animation() -> void:
	if not sprite:
		return
	
	# 重置精灵状态
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.rotation = 0
	
	# 创建轻微浮动动画
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -2, 1.0)
	tween.tween_property(sprite, "position:y", 2, 1.0)
	tween.set_loops()

# 播放移动动画
func _play_move_animation() -> void:
	if not sprite:
		return
	
	# 设置移动状态
	sprite.modulate = Color(0.8, 1.0, 0.8, 1)
	
	# 创建轻微摇摆动画
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", 0.1, 0.3)
	tween.tween_property(sprite, "rotation", -0.1, 0.3)
	tween.set_loops()

# 播放攻击动画
func _play_attack_animation() -> void:
	if not sprite:
		return
	
	# 重置精灵状态
	sprite.modulate = Color(1, 1, 1, 1)
	
	# 创建攻击动画
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(func(): animation_finished.emit("attack"))

# 播放施法动画
func _play_cast_animation() -> void:
	if not sprite:
		return
	
	# 设置施法状态
	sprite.modulate = Color(0.8, 0.8, 1.0, 1)
	
	# 创建施法动画
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(sprite, "rotation", 0.2, 0.2)
	tween.tween_property(sprite, "rotation", -0.2, 0.2)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(sprite, "rotation", 0, 0.1)
	tween.tween_callback(func(): animation_finished.emit("cast"))

# 播放眩晕动画
func _play_stunned_animation() -> void:
	if not sprite:
		return
	
	# 设置眩晕状态
	sprite.modulate = Color(0.7, 0.7, 0.7, 1)
	
	# 创建眩晕动画
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", 0.3, 0.2)
	tween.tween_property(sprite, "rotation", -0.3, 0.2)
	tween.set_loops()

# 播放死亡动画
func _play_death_animation() -> void:
	if not sprite:
		return
	
	# 设置死亡状态
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	# 创建死亡动画
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.8, 0.8), 0.5)
	tween.tween_property(sprite, "rotation", PI, 0.5)
	tween.tween_callback(func(): animation_finished.emit("death"))

# 更新状态
func update_state(state_name: String) -> void:
	# 根据状态更新视觉效果
	match state_name:
		"idle":
			sprite.modulate = Color(1, 1, 1, 1)
		"moving":
			sprite.modulate = Color(0.8, 1.0, 0.8, 1)
		"attacking":
			sprite.modulate = Color(1, 1, 1, 1)
		"casting":
			sprite.modulate = Color(0.8, 0.8, 1.0, 1)
		"stunned":
			sprite.modulate = Color(0.7, 0.7, 0.7, 1)
		"dead":
			sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

# 动画完成回调
func _on_animation_finished(animation_name: String) -> void:
	# 发送动画完成信号
	animation_finished.emit(animation_name)
