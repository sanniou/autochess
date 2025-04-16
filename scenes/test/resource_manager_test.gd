extends Control

# 引用
@onready var resource_container = $ResourceContainer
@onready var grid_container = $ResourceContainer/GridContainer
@onready var resource_type_option = $ControlPanel/VBoxContainer/ResourceTypeContainer/ResourceTypeOption
@onready var count_spin_box = $ControlPanel/VBoxContainer/CountContainer/CountSpinBox
@onready var load_resources_button = $ControlPanel/VBoxContainer/LoadResourcesButton
@onready var unload_resources_button = $ControlPanel/VBoxContainer/UnloadResourcesButton
@onready var preload_option = $ControlPanel/VBoxContainer/PreloadContainer/PreloadOption
@onready var preload_group_button = $ControlPanel/VBoxContainer/PreloadGroupButton
@onready var unload_group_button = $ControlPanel/VBoxContainer/UnloadGroupButton
@onready var loaded_resources_label = $InfoPanel/VBoxContainer/LoadedResourcesLabel
@onready var cached_resources_label = $InfoPanel/VBoxContainer/CachedResourcesLabel
@onready var memory_usage_label = $InfoPanel/VBoxContainer/MemoryUsageLabel
@onready var load_time_label = $InfoPanel/VBoxContainer/LoadTimeLabel
@onready var cache_hits_label = $InfoPanel/VBoxContainer/CacheHitsLabel
@onready var cache_misses_label = $InfoPanel/VBoxContainer/CacheMissesLabel
@onready var back_button = $BackButton

# 资源管理器
var resource_manager = null

# 资源类型
var resource_types = ["texture", "sound", "font", "scene", "material"]

# 预加载组
var preload_groups = ["ui", "battle", "map", "character", "effect"]

# 已加载资源
var loaded_resources = []

# 统计数据
var cache_hits = 0
var cache_misses = 0
var total_load_time = 0

# 初始化
func _ready():
    # 获取资源管理器
    resource_manager = get_node_or_null("/root/ResourceManager")
    if not resource_manager:
        # 创建临时资源管理器
        resource_manager = ResourceManager.new()
        add_child(resource_manager)
    
    # 连接按钮信号
    load_resources_button.pressed.connect(_on_load_resources_button_pressed)
    unload_resources_button.pressed.connect(_on_unload_resources_button_pressed)
    preload_group_button.pressed.connect(_on_preload_group_button_pressed)
    unload_group_button.pressed.connect(_on_unload_group_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    
    # 连接资源管理器信号
    resource_manager.resource_loaded.connect(_on_resource_loaded)
    resource_manager.resource_unloaded.connect(_on_resource_unloaded)
    resource_manager.cache_hit.connect(_on_cache_hit)
    resource_manager.cache_miss.connect(_on_cache_miss)
    
    # 初始化选项
    _initialize_options()
    
    # 更新UI
    _update_ui()

# 初始化选项
func _initialize_options():
    # 初始化资源类型选项
    for resource_type in resource_types:
        resource_type_option.add_item(resource_type)
    
    # 初始化预加载组选项
    for group in preload_groups:
        preload_option.add_item(group)

# 加载资源按钮处理
func _on_load_resources_button_pressed():
    # 获取选择的资源类型
    var resource_type = resource_types[resource_type_option.selected]
    
    # 获取加载数量
    var count = int(count_spin_box.value)
    
    # 加载资源
    _load_resources(resource_type, count)
    
    # 更新UI
    _update_ui()

# 卸载资源按钮处理
func _on_unload_resources_button_pressed():
    # 卸载所有已加载资源
    _unload_resources()
    
    # 更新UI
    _update_ui()

# 预加载资源组按钮处理
func _on_preload_group_button_pressed():
    # 获取选择的预加载组
    var group = preload_groups[preload_option.selected]
    
    # 预加载资源组
    _preload_resource_group(group)
    
    # 更新UI
    _update_ui()

# 卸载资源组按钮处理
func _on_unload_group_button_pressed():
    # 获取选择的预加载组
    var group = preload_groups[preload_option.selected]
    
    # 卸载资源组
    resource_manager.unload_resource_group(group)
    
    # 更新UI
    _update_ui()

# 资源加载处理
func _on_resource_loaded(resource_path, resource, load_time):
    # 增加总加载时间
    total_load_time += load_time
    
    # 更新UI
    _update_ui()

# 资源卸载处理
func _on_resource_unloaded(resource_path):
    # 更新UI
    _update_ui()

# 缓存命中处理
func _on_cache_hit(resource_path):
    # 增加缓存命中计数
    cache_hits += 1
    
    # 更新UI
    _update_ui()

# 缓存未命中处理
func _on_cache_miss(resource_path):
    # 增加缓存未命中计数
    cache_misses += 1
    
    # 更新UI
    _update_ui()

# 加载资源
func _load_resources(resource_type: String, count: int) -> void:
    # 清空网格容器
    for child in grid_container.get_children():
        child.queue_free()
    
    # 清空已加载资源
    loaded_resources.clear()
    
    # 根据资源类型加载不同的资源
    match resource_type:
        "texture":
            _load_textures(count)
        "sound":
            _load_sounds(count)
        "font":
            _load_fonts(count)
        "scene":
            _load_scenes(count)
        "material":
            _load_materials(count)

# 卸载资源
func _unload_resources() -> void:
    # 清空网格容器
    for child in grid_container.get_children():
        child.queue_free()
    
    # 卸载所有已加载资源
    for resource_path in loaded_resources:
        resource_manager.unload_resource(resource_path)
    
    # 清空已加载资源
    loaded_resources.clear()

# 预加载资源组
func _preload_resource_group(group: String) -> void:
    # 根据组名预加载不同的资源组
    match group:
        "ui":
            _preload_ui_resources()
        "battle":
            _preload_battle_resources()
        "map":
            _preload_map_resources()
        "character":
            _preload_character_resources()
        "effect":
            _preload_effect_resources()

# 加载纹理
func _load_textures(count: int) -> void:
    # 纹理路径模板
    var texture_paths = [
        "res://assets/textures/test_sprite.png",
        "res://assets/textures/effects/particle.png",
        "res://assets/textures/effects/smoke.png",
        "res://assets/textures/effects/fire.png",
        "res://assets/textures/effects/spark.png"
    ]
    
    # 加载指定数量的纹理
    for i in range(count):
        # 随机选择纹理路径
        var path_index = randi() % texture_paths.size()
        var texture_path = texture_paths[path_index]
        
        # 加载纹理
        var texture = resource_manager.load_resource(texture_path)
        
        # 如果加载成功，创建精灵并添加到网格
        if texture:
            var sprite = TextureRect.new()
            sprite.texture = texture
            sprite.expand = true
            sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            sprite.custom_minimum_size = Vector2(64, 64)
            grid_container.add_child(sprite)
            
            # 添加到已加载资源
            loaded_resources.append(texture_path)

# 加载声音
func _load_sounds(count: int) -> void:
    # 声音路径模板
    var sound_paths = [
        "res://assets/sounds/effects/hit.wav",
        "res://assets/sounds/effects/explosion.wav",
        "res://assets/sounds/effects/pickup.wav",
        "res://assets/sounds/effects/powerup.wav",
        "res://assets/sounds/effects/laser.wav"
    ]
    
    # 加载指定数量的声音
    for i in range(count):
        # 随机选择声音路径
        var path_index = randi() % sound_paths.size()
        var sound_path = sound_paths[path_index]
        
        # 加载声音
        var sound = resource_manager.load_resource(sound_path)
        
        # 如果加载成功，创建音频播放器并添加到网格
        if sound:
            var audio_player = AudioStreamPlayer.new()
            audio_player.stream = sound
            
            var button = Button.new()
            button.text = "播放声音"
            button.custom_minimum_size = Vector2(64, 64)
            button.pressed.connect(func(): audio_player.play())
            
            var container = VBoxContainer.new()
            container.add_child(button)
            container.add_child(audio_player)
            
            grid_container.add_child(container)
            
            # 添加到已加载资源
            loaded_resources.append(sound_path)

# 加载字体
func _load_fonts(count: int) -> void:
    # 字体路径模板
    var font_paths = [
        "res://assets/fonts/default_font.tres",
        "res://assets/fonts/title_font.tres",
        "res://assets/fonts/ui_font.tres",
        "res://assets/fonts/damage_font.tres",
        "res://assets/fonts/dialog_font.tres"
    ]
    
    # 加载指定数量的字体
    for i in range(count):
        # 随机选择字体路径
        var path_index = randi() % font_paths.size()
        var font_path = font_paths[path_index]
        
        # 加载字体
        var font = resource_manager.load_resource(font_path)
        
        # 如果加载成功，创建标签并添加到网格
        if font:
            var label = Label.new()
            label.text = "字体示例"
            label.add_theme_font_override("font", font)
            label.custom_minimum_size = Vector2(64, 64)
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            
            grid_container.add_child(label)
            
            # 添加到已加载资源
            loaded_resources.append(font_path)

# 加载场景
func _load_scenes(count: int) -> void:
    # 场景路径模板
    var scene_paths = [
        "res://scenes/ui/popup.tscn",
        "res://scenes/ui/toast.tscn",
        "res://scenes/ui/button.tscn",
        "res://scenes/ui/panel.tscn",
        "res://scenes/ui/dialog.tscn"
    ]
    
    # 加载指定数量的场景
    for i in range(count):
        # 随机选择场景路径
        var path_index = randi() % scene_paths.size()
        var scene_path = scene_paths[path_index]
        
        # 加载场景
        var scene = resource_manager.load_resource(scene_path)
        
        # 如果加载成功，创建场景实例并添加到网格
        if scene:
            var instance = scene.instantiate()
            
            var container = CenterContainer.new()
            container.custom_minimum_size = Vector2(64, 64)
            container.add_child(instance)
            
            grid_container.add_child(container)
            
            # 添加到已加载资源
            loaded_resources.append(scene_path)

# 加载材质
func _load_materials(count: int) -> void:
    # 材质路径模板
    var material_paths = [
        "res://assets/materials/default_material.tres",
        "res://assets/materials/glow_material.tres",
        "res://assets/materials/water_material.tres",
        "res://assets/materials/fire_material.tres",
        "res://assets/materials/ice_material.tres"
    ]
    
    # 加载指定数量的材质
    for i in range(count):
        # 随机选择材质路径
        var path_index = randi() % material_paths.size()
        var material_path = material_paths[path_index]
        
        # 加载材质
        var material = resource_manager.load_resource(material_path)
        
        # 如果加载成功，创建精灵并应用材质
        if material:
            var sprite = ColorRect.new()
            sprite.material = material
            sprite.custom_minimum_size = Vector2(64, 64)
            
            grid_container.add_child(sprite)
            
            # 添加到已加载资源
            loaded_resources.append(material_path)

# 预加载UI资源
func _preload_ui_resources() -> void:
    # UI资源路径
    var ui_resources = [
        "res://assets/textures/ui/button.png",
        "res://assets/textures/ui/panel.png",
        "res://assets/textures/ui/checkbox.png",
        "res://assets/textures/ui/slider.png",
        "res://assets/fonts/ui_font.tres"
    ]
    
    # 预加载资源组
    resource_manager.preload_resource_group("ui", ui_resources)

# 预加载战斗资源
func _preload_battle_resources() -> void:
    # 战斗资源路径
    var battle_resources = [
        "res://assets/textures/effects/explosion.png",
        "res://assets/textures/effects/hit.png",
        "res://assets/textures/effects/slash.png",
        "res://assets/sounds/effects/hit.wav",
        "res://assets/sounds/effects/explosion.wav"
    ]
    
    # 预加载资源组
    resource_manager.preload_resource_group("battle", battle_resources)

# 预加载地图资源
func _preload_map_resources() -> void:
    # 地图资源路径
    var map_resources = [
        "res://assets/textures/map/tile1.png",
        "res://assets/textures/map/tile2.png",
        "res://assets/textures/map/tile3.png",
        "res://assets/textures/map/decoration1.png",
        "res://assets/textures/map/decoration2.png"
    ]
    
    # 预加载资源组
    resource_manager.preload_resource_group("map", map_resources)

# 预加载角色资源
func _preload_character_resources() -> void:
    # 角色资源路径
    var character_resources = [
        "res://assets/textures/characters/warrior.png",
        "res://assets/textures/characters/mage.png",
        "res://assets/textures/characters/archer.png",
        "res://assets/textures/characters/healer.png",
        "res://assets/textures/characters/tank.png"
    ]
    
    # 预加载资源组
    resource_manager.preload_resource_group("character", character_resources)

# 预加载特效资源
func _preload_effect_resources() -> void:
    # 特效资源路径
    var effect_resources = [
        "res://assets/textures/effects/fire.png",
        "res://assets/textures/effects/ice.png",
        "res://assets/textures/effects/lightning.png",
        "res://assets/textures/effects/smoke.png",
        "res://assets/textures/effects/sparkle.png"
    ]
    
    # 预加载资源组
    resource_manager.preload_resource_group("effect", effect_resources)

# 更新UI
func _update_ui():
    # 更新已加载资源标签
    loaded_resources_label.text = "已加载资源: " + str(loaded_resources.size())
    
    # 更新缓存资源标签
    cached_resources_label.text = "缓存资源: " + str(resource_manager.get_cache_size())
    
    # 更新内存使用标签
    memory_usage_label.text = "内存使用: " + str(resource_manager.get_memory_usage()) + " MB"
    
    # 更新加载时间标签
    load_time_label.text = "加载时间: " + str(total_load_time) + " ms"
    
    # 更新缓存命中标签
    cache_hits_label.text = "缓存命中: " + str(cache_hits)
    
    # 更新缓存未命中标签
    cache_misses_label.text = "缓存未命中: " + str(cache_misses)

# 返回按钮处理
func _on_back_button_pressed():
    # 卸载所有资源
    _unload_resources()
    
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
