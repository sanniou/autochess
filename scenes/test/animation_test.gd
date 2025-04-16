extends Control

# 引用
@onready var animation_container = $AnimationContainer
@onready var effect_container = $AnimationContainer/EffectContainer
@onready var test_sprite = $AnimationContainer/TestSprite
@onready var effect_option = $ControlPanel/VBoxContainer/EffectContainer/EffectOption
@onready var play_effect_button = $ControlPanel/VBoxContainer/PlayEffectButton
@onready var animation_option = $ControlPanel/VBoxContainer/AnimationContainer/AnimationOption
@onready var play_animation_button = $ControlPanel/VBoxContainer/PlayAnimationButton
@onready var damage_button = $ControlPanel/VBoxContainer/DamageButton
@onready var floating_text_button = $ControlPanel/VBoxContainer/FloatingTextButton
@onready var active_effects_label = $InfoPanel/VBoxContainer/ActiveEffectsLabel
@onready var active_animations_label = $InfoPanel/VBoxContainer/ActiveAnimationsLabel
@onready var status_label = $InfoPanel/VBoxContainer/StatusLabel
@onready var back_button = $BackButton

# 动画管理器
var animation_manager = null

# 特效管理器
var effect_animator = null

# 伤害数字管理器
var damage_number_manager = null

# 浮动文字管理器
var floating_text_manager = null

# 特效类型
var effect_types = ["explosion", "fire", "ice", "lightning", "smoke", "sparkle", "heal", "buff", "debuff"]

# 动画类型
var animation_types = ["attack", "hit", "death", "victory", "defeat", "levelup", "cast", "jump", "spin"]

# 活动特效
var active_effects = []

# 活动动画
var active_animations = []

# 初始化
func _ready():
    # 创建动画管理器
    animation_manager = AnimationManager.new()
    add_child(animation_manager)
    
    # 创建特效管理器
    effect_animator = EffectAnimator.new()
    effect_container.add_child(effect_animator)
    
    # 创建伤害数字管理器
    damage_number_manager = DamageNumberManager.new()
    add_child(damage_number_manager)
    
    # 创建浮动文字管理器
    floating_text_manager = FloatingTextManager.new()
    add_child(floating_text_manager)
    
    # 连接按钮信号
    play_effect_button.pressed.connect(_on_play_effect_button_pressed)
    play_animation_button.pressed.connect(_on_play_animation_button_pressed)
    damage_button.pressed.connect(_on_damage_button_pressed)
    floating_text_button.pressed.connect(_on_floating_text_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 连接特效信号
    effect_animator.animation_started.connect(_on_effect_started)
    effect_animator.animation_completed.connect(_on_effect_completed)
    
    # 连接动画信号
    animation_manager.animation_started.connect(_on_animation_started)
    animation_manager.animation_completed.connect(_on_animation_completed)
    
    # 初始化选项
    _initialize_options()
    
    # 加载测试精灵
    _load_test_sprite()

# 初始化选项
func _initialize_options():
    # 初始化特效选项
    for effect_type in effect_types:
        effect_option.add_item(effect_type)
    
    # 初始化动画选项
    for animation_type in animation_types:
        animation_option.add_item(animation_type)

# 加载测试精灵
func _load_test_sprite():
    # 加载测试纹理
    var texture = load("res://assets/textures/test_sprite.png")
    if texture:
        test_sprite.texture = texture
    else:
        # 创建默认纹理
        var default_texture = ImageTexture.new()
        var image = Image.new()
        image.create(64, 64, false, Image.FORMAT_RGBA8)
        image.fill(Color(1, 1, 1, 1))
        default_texture.create_from_image(image)
        test_sprite.texture = default_texture

# 播放特效按钮处理
func _on_play_effect_button_pressed():
    # 获取选择的特效类型
    var effect_type = effect_types[effect_option.selected]
    
    # 播放特效
    var effect_id = _play_effect(effect_type)
    
    # 更新状态
    status_label.text = "状态: 播放特效 - " + effect_type

# 播放动画按钮处理
func _on_play_animation_button_pressed():
    # 获取选择的动画类型
    var animation_type = animation_types[animation_option.selected]
    
    # 播放动画
    var animation_id = _play_animation(animation_type)
    
    # 更新状态
    status_label.text = "状态: 播放动画 - " + animation_type

# 显示伤害数字按钮处理
func _on_damage_button_pressed():
    # 生成随机伤害值
    var damage = randi_range(10, 1000)
    
    # 生成随机位置
    var position = Vector2(
        randf_range(100, animation_container.size.x - 100),
        randf_range(100, animation_container.size.y - 100)
    )
    
    # 随机伤害类型
    var damage_types = ["physical", "magical", "true", "fire", "ice", "poison"]
    var damage_type = damage_types[randi() % damage_types.size()]
    
    # 随机是否暴击
    var is_crit = randf() < 0.3
    
    # 显示伤害数字
    damage_number_manager.show_damage(position, damage, damage_type, is_crit)
    
    # 更新状态
    status_label.text = "状态: 显示伤害数字 - " + str(damage)

# 显示浮动文字按钮处理
func _on_floating_text_button_pressed():
    # 生成随机文本
    var texts = ["回复生命值!", "获得护盾!", "增加攻击力!", "减少防御!", "眩晕!", "沉默!", "免疫!"]
    var text = texts[randi() % texts.size()]
    
    # 生成随机位置
    var position = Vector2(
        randf_range(100, animation_container.size.x - 100),
        randf_range(100, animation_container.size.y - 100)
    )
    
    # 随机颜色
    var colors = [Color.GREEN, Color.RED, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.CYAN]
    var color = colors[randi() % colors.size()]
    
    # 显示浮动文字
    floating_text_manager.show_text(position, text, color)
    
    # 更新状态
    status_label.text = "状态: 显示浮动文字 - " + text

# 特效开始处理
func _on_effect_started(effect_id):
    # 添加到活动特效
    active_effects.append(effect_id)
    
    # 更新标签
    active_effects_label.text = "活动特效: " + str(active_effects.size())

# 特效完成处理
func _on_effect_completed(effect_id):
    # 从活动特效中移除
    active_effects.erase(effect_id)
    
    # 更新标签
    active_effects_label.text = "活动特效: " + str(active_effects.size())
    
    # 如果没有活动特效和动画，更新状态
    if active_effects.is_empty() and active_animations.is_empty():
        status_label.text = "状态: 空闲"

# 动画开始处理
func _on_animation_started(animation_id):
    # 添加到活动动画
    active_animations.append(animation_id)
    
    # 更新标签
    active_animations_label.text = "活动动画: " + str(active_animations.size())

# 动画完成处理
func _on_animation_completed(animation_id):
    # 从活动动画中移除
    active_animations.erase(animation_id)
    
    # 更新标签
    active_animations_label.text = "活动动画: " + str(active_animations.size())
    
    # 如果没有活动特效和动画，更新状态
    if active_effects.is_empty() and active_animations.is_empty():
        status_label.text = "状态: 空闲"

# 播放特效
func _play_effect(effect_type: String) -> String:
    # 生成随机位置
    var position = Vector2(
        randf_range(100, animation_container.size.x - 100),
        randf_range(100, animation_container.size.y - 100)
    )
    
    # 根据特效类型播放不同的特效
    var effect_id = ""
    
    match effect_type:
        "explosion":
            effect_id = effect_animator.play_effect("explosion", position, {
                "scale": Vector2(2, 2),
                "duration": 1.0
            })
        "fire":
            effect_id = effect_animator.play_effect("fire", position, {
                "scale": Vector2(1.5, 1.5),
                "duration": 2.0
            })
        "ice":
            effect_id = effect_animator.play_effect("ice", position, {
                "scale": Vector2(1.5, 1.5),
                "duration": 1.5
            })
        "lightning":
            effect_id = effect_animator.play_effect("lightning", position, {
                "scale": Vector2(1, 2),
                "duration": 0.8
            })
        "smoke":
            effect_id = effect_animator.play_effect("smoke", position, {
                "scale": Vector2(2, 2),
                "duration": 3.0
            })
        "sparkle":
            effect_id = effect_animator.play_effect("sparkle", position, {
                "scale": Vector2(1, 1),
                "duration": 1.2
            })
        "heal":
            effect_id = effect_animator.play_effect("heal", position, {
                "scale": Vector2(1.5, 1.5),
                "duration": 1.5,
                "color": Color(0, 1, 0, 0.8)
            })
        "buff":
            effect_id = effect_animator.play_effect("buff", position, {
                "scale": Vector2(1.5, 1.5),
                "duration": 1.5,
                "color": Color(1, 1, 0, 0.8)
            })
        "debuff":
            effect_id = effect_animator.play_effect("debuff", position, {
                "scale": Vector2(1.5, 1.5),
                "duration": 1.5,
                "color": Color(1, 0, 0, 0.8)
            })
    
    return effect_id

# 播放动画
func _play_animation(animation_type: String) -> String:
    # 根据动画类型播放不同的动画
    var animation_id = ""
    
    match animation_type:
        "attack":
            animation_id = animation_manager.play_animation(test_sprite, "attack", {
                "duration": 0.5,
                "distance": 50,
                "direction": Vector2.RIGHT
            })
        "hit":
            animation_id = animation_manager.play_animation(test_sprite, "hit", {
                "duration": 0.3,
                "shake_amount": 5
            })
        "death":
            animation_id = animation_manager.play_animation(test_sprite, "death", {
                "duration": 1.0,
                "fade_out": true
            })
        "victory":
            animation_id = animation_manager.play_animation(test_sprite, "victory", {
                "duration": 1.0,
                "jump_height": 30
            })
        "defeat":
            animation_id = animation_manager.play_animation(test_sprite, "defeat", {
                "duration": 1.0,
                "fall_down": true
            })
        "levelup":
            animation_id = animation_manager.play_animation(test_sprite, "levelup", {
                "duration": 1.0,
                "scale_up": 1.5
            })
        "cast":
            animation_id = animation_manager.play_animation(test_sprite, "cast", {
                "duration": 0.8,
                "glow_color": Color(0, 0.5, 1, 0.8)
            })
        "jump":
            animation_id = animation_manager.play_animation(test_sprite, "jump", {
                "duration": 0.6,
                "height": 50
            })
        "spin":
            animation_id = animation_manager.play_animation(test_sprite, "spin", {
                "duration": 0.8,
                "rotations": 2
            })
    
    return animation_id

# 返回按钮处理
func _on_back_button_pressed():
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
