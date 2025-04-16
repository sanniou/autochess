extends Control

# 引用
@onready var object_container = $ObjectContainer
@onready var pool_option = $ControlPanel/VBoxContainer/PoolContainer/PoolOption
@onready var count_spin_box = $ControlPanel/VBoxContainer/CountContainer/CountSpinBox
@onready var create_pool_button = $ControlPanel/VBoxContainer/CreatePoolButton
@onready var spawn_spin_box = $ControlPanel/VBoxContainer/SpawnContainer/SpawnSpinBox
@onready var spawn_objects_button = $ControlPanel/VBoxContainer/SpawnObjectsButton
@onready var release_all_button = $ControlPanel/VBoxContainer/ReleaseAllButton
@onready var resize_spin_box = $ControlPanel/VBoxContainer/ResizeContainer/ResizeSpinBox
@onready var resize_pool_button = $ControlPanel/VBoxContainer/ResizePoolButton
@onready var pool_size_label = $InfoPanel/VBoxContainer/PoolSizeLabel
@onready var active_objects_label = $InfoPanel/VBoxContainer/ActiveObjectsLabel
@onready var total_requests_label = $InfoPanel/VBoxContainer/TotalRequestsLabel
@onready var failed_requests_label = $InfoPanel/VBoxContainer/FailedRequestsLabel
@onready var usage_rate_label = $InfoPanel/VBoxContainer/UsageRateLabel
@onready var auto_resizes_label = $InfoPanel/VBoxContainer/AutoResizesLabel
@onready var back_button = $BackButton

# 对象池
var object_pool = null

# 对象类型
var object_types = ["sprite", "particle", "label", "button", "panel"]

# 当前选择的对象池
var current_pool = ""

# 活动对象
var active_objects = []

# 统计数据
var total_requests = 0
var failed_requests = 0
var auto_resizes = 0

# 初始化
func _ready():
    # 获取对象池
    object_pool = get_node_or_null("/root/ObjectPool")
    if not object_pool:
        # 创建临时对象池
        object_pool = ObjectPool.new()
        add_child(object_pool)
    
    # 连接按钮信号
    create_pool_button.pressed.connect(_on_create_pool_button_pressed)
    spawn_objects_button.pressed.connect(_on_spawn_objects_button_pressed)
    release_all_button.pressed.connect(_on_release_all_button_pressed)
    resize_pool_button.pressed.connect(_on_resize_pool_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 连接对象池信号
    object_pool.pool_created.connect(_on_pool_created)
    object_pool.pool_resized.connect(_on_pool_resized)
    object_pool.auto_resize.connect(_on_auto_resize)
    
    # 初始化选项
    _initialize_options()
    
    # 更新UI
    _update_ui()

# 初始化选项
func _initialize_options():
    # 初始化对象池选项
    for object_type in object_types:
        pool_option.add_item(object_type)

# 创建对象池按钮处理
func _on_create_pool_button_pressed():
    # 获取选择的对象类型
    var object_type = object_types[pool_option.selected]
    
    # 获取对象池大小
    var pool_size = int(count_spin_box.value)
    
    # 创建对象池
    _create_pool(object_type, pool_size)
    
    # 更新当前选择的对象池
    current_pool = object_type
    
    # 更新UI
    _update_ui()

# 生成对象按钮处理
func _on_spawn_objects_button_pressed():
    # 检查是否选择了对象池
    if current_pool.is_empty():
        return
    
    # 获取生成数量
    var spawn_count = int(spawn_spin_box.value)
    
    # 生成对象
    _spawn_objects(spawn_count)
    
    # 更新UI
    _update_ui()

# 释放所有对象按钮处理
func _on_release_all_button_pressed():
    # 释放所有活动对象
    _release_all_objects()
    
    # 更新UI
    _update_ui()

# 调整对象池大小按钮处理
func _on_resize_pool_button_pressed():
    # 检查是否选择了对象池
    if current_pool.is_empty():
        return
    
    # 获取新大小
    var new_size = int(resize_spin_box.value)
    
    # 调整对象池大小
    object_pool.resize_pool(current_pool, new_size)
    
    # 更新UI
    _update_ui()

# 对象池创建处理
func _on_pool_created(pool_id, size):
    # 更新UI
    _update_ui()

# 对象池调整大小处理
func _on_pool_resized(pool_id, old_size, new_size):
    # 更新UI
    _update_ui()

# 自动调整大小处理
func _on_auto_resize(pool_id, old_size, new_size):
    # 增加自动调整计数
    auto_resizes += 1
    
    # 更新UI
    _update_ui()

# 创建对象池
func _create_pool(object_type: String, pool_size: int) -> void:
    # 根据对象类型创建不同的对象池
    match object_type:
        "sprite":
            object_pool.create_pool(object_type, pool_size, _create_sprite_instance)
        "particle":
            object_pool.create_pool(object_type, pool_size, _create_particle_instance)
        "label":
            object_pool.create_pool(object_type, pool_size, _create_label_instance)
        "button":
            object_pool.create_pool(object_type, pool_size, _create_button_instance)
        "panel":
            object_pool.create_pool(object_type, pool_size, _create_panel_instance)

# 生成对象
func _spawn_objects(count: int) -> void:
    # 生成指定数量的对象
    for i in range(count):
        # 获取对象
        var object = object_pool.get_object(current_pool)
        
        # 增加请求计数
        total_requests += 1
        
        # 如果获取失败，增加失败计数
        if not object:
            failed_requests += 1
            continue
        
        # 设置对象位置
        _set_object_position(object)
        
        # 添加到活动对象
        active_objects.append(object)

# 释放所有对象
func _release_all_objects() -> void:
    # 释放所有活动对象
    for object in active_objects:
        object_pool.release_object(current_pool, object)
    
    # 清空活动对象
    active_objects.clear()

# 设置对象位置
func _set_object_position(object) -> void:
    # 生成随机位置
    var position = Vector2(
        randf_range(50, object_container.size.x - 50),
        randf_range(50, object_container.size.y - 50)
    )
    
    # 设置位置
    object.position = position

# 创建精灵实例
func _create_sprite_instance() -> Sprite2D:
    var sprite = Sprite2D.new()
    
    # 设置纹理
    var texture = load("res://assets/textures/test_sprite.png")
    if texture:
        sprite.texture = texture
    else:
        # 创建默认纹理
        var default_texture = ImageTexture.new()
        var image = Image.new()
        image.create(32, 32, false, Image.FORMAT_RGBA8)
        image.fill(Color(1, 1, 1, 1))
        default_texture.create_from_image(image)
        sprite.texture = default_texture
    
    # 设置随机颜色
    sprite.modulate = Color(randf(), randf(), randf(), 1.0)
    
    # 添加到容器
    object_container.add_child(sprite)
    
    return sprite

# 创建粒子实例
func _create_particle_instance() -> CPUParticles2D:
    var particles = CPUParticles2D.new()
    
    # 设置粒子属性
    particles.amount = 20
    particles.lifetime = 1.0
    particles.explosiveness = 0.2
    particles.randomness = 0.5
    particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 5.0
    particles.direction = Vector2(0, -1)
    particles.spread = 45.0
    particles.gravity = Vector2(0, 98)
    particles.initial_velocity_min = 50.0
    particles.initial_velocity_max = 100.0
    particles.scale_amount_min = 2.0
    particles.scale_amount_max = 4.0
    particles.color = Color(randf(), randf(), randf(), 1.0)
    
    # 添加到容器
    object_container.add_child(particles)
    
    return particles

# 创建标签实例
func _create_label_instance() -> Label:
    var label = Label.new()
    
    # 设置标签属性
    label.text = "测试标签"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # 设置随机颜色
    label.add_theme_color_override("font_color", Color(randf(), randf(), randf(), 1.0))
    
    # 添加到容器
    object_container.add_child(label)
    
    return label

# 创建按钮实例
func _create_button_instance() -> Button:
    var button = Button.new()
    
    # 设置按钮属性
    button.text = "测试按钮"
    button.size = Vector2(100, 40)
    
    # 添加到容器
    object_container.add_child(button)
    
    return button

# 创建面板实例
func _create_panel_instance() -> Panel:
    var panel = Panel.new()
    
    # 设置面板属性
    panel.size = Vector2(100, 100)
    
    # 添加到容器
    object_container.add_child(panel)
    
    return panel

# 更新UI
func _update_ui():
    # 更新对象池大小标签
    if not current_pool.is_empty():
        var pool_size = object_pool.get_pool_size(current_pool)
        pool_size_label.text = "对象池大小: " + str(pool_size)
    else:
        pool_size_label.text = "对象池大小: 0"
    
    # 更新活动对象标签
    active_objects_label.text = "活动对象: " + str(active_objects.size())
    
    # 更新总请求数标签
    total_requests_label.text = "总请求数: " + str(total_requests)
    
    # 更新失败请求数标签
    failed_requests_label.text = "失败请求数: " + str(failed_requests)
    
    # 更新使用率标签
    if not current_pool.is_empty():
        var pool_size = object_pool.get_pool_size(current_pool)
        var usage_rate = 0.0
        if pool_size > 0:
            usage_rate = float(active_objects.size()) / pool_size * 100.0
        usage_rate_label.text = "使用率: " + str(int(usage_rate)) + "%"
    else:
        usage_rate_label.text = "使用率: 0%"
    
    # 更新自动调整次数标签
    auto_resizes_label.text = "自动调整次数: " + str(auto_resizes)

# 返回按钮处理
func _on_back_button_pressed():
    # 释放所有对象
    _release_all_objects()
    
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
