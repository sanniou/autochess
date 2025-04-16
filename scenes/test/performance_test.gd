extends Control
## 性能测试场景
## 用于测试性能监控系统

# 引用
@onready var particle_container = $ParticleContainer
@onready var sprite_container = $SpriteContainer
@onready var node_container = $NodeContainer
@onready var particle_count_label = $TestControls/ParticleControls/ParticleCountLabel
@onready var sprite_count_label = $TestControls/SpriteControls/SpriteCountLabel
@onready var node_count_label = $TestControls/NodeControls/NodeCountLabel
@onready var memory_usage_label = $TestControls/MemoryControls/MemoryUsageLabel
@onready var fps_label = $TestControls/FPSLabel

# 性能监控器
var performance_monitor = null

# 对象池
var object_pool = null

# 计数器
var particle_count = 0
var sprite_count = 0
var node_count = 0

# 纹理
var textures = []

# 初始化
func _ready() -> void:
	# 获取性能监控器
	performance_monitor = get_node_or_null("/root/PerformanceMonitor")
	
	# 获取对象池
	object_pool = get_node_or_null("/root/ObjectPool")
	
	# 加载纹理
	_load_textures()
	
	# 更新标签
	_update_labels()

# 处理
func _process(delta: float) -> void:
	# 更新FPS标签
	if performance_monitor:
		var data = performance_monitor.get_performance_data()
		fps_label.text = "FPS: " + str(int(data.fps))
		memory_usage_label.text = "内存使用: " + str(int(data.memory_total)) + " MB"

# 加载纹理
func _load_textures() -> void:
	var texture_paths = [
		"res://assets/textures/effects/particle.png",
		"res://assets/textures/effects/smoke.png",
		"res://assets/textures/effects/fire.png",
		"res://assets/textures/effects/spark.png",
		"res://assets/textures/effects/star.png"
	]
	
	for path in texture_paths:
		var texture = load(path)
		if texture:
			textures.append(texture)
	
	# 如果没有加载到纹理，创建一个默认纹理
	if textures.is_empty():
		var default_texture = ImageTexture.new()
		var image = Image.new()
		image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 1, 1, 1))
		default_texture.create_from_image(image)
		textures.append(default_texture)

# 更新标签
func _update_labels() -> void:
	particle_count_label.text = "粒子数量: " + str(particle_count)
	sprite_count_label.text = "精灵数量: " + str(sprite_count)
	node_count_label.text = "节点数量: " + str(node_count)

# 添加粒子按钮处理
func _on_add_particles_button_pressed() -> void:
	var count = $TestControls/ParticleControls/ParticleCountSpinBox.value
	_add_particles(count)

# 清除粒子按钮处理
func _on_clear_particles_button_pressed() -> void:
	_clear_particles()

# 添加精灵按钮处理
func _on_add_sprites_button_pressed() -> void:
	var count = $TestControls/SpriteControls/SpriteCountSpinBox.value
	_add_sprites(count)

# 清除精灵按钮处理
func _on_clear_sprites_button_pressed() -> void:
	_clear_sprites()

# 添加节点按钮处理
func _on_add_nodes_button_pressed() -> void:
	var count = $TestControls/NodeControls/NodeCountSpinBox.value
	_add_nodes(count)

# 清除节点按钮处理
func _on_clear_nodes_button_pressed() -> void:
	_clear_nodes()

# 清除所有按钮处理
func _on_clear_all_button_pressed() -> void:
	_clear_particles()
	_clear_sprites()
	_clear_nodes()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 添加粒子
func _add_particles(count: int) -> void:
	for i in range(count):
		var particles = CPUParticles2D.new()
		particles.position = Vector2(randf_range(0, 1024), randf_range(0, 600))
		particles.amount = randi_range(10, 50)
		particles.lifetime = randf_range(1.0, 3.0)
		particles.explosiveness = randf_range(0.0, 0.5)
		particles.randomness = randf_range(0.0, 0.5)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = randf_range(5.0, 20.0)
		particles.direction = Vector2(0, -1)
		particles.spread = randf_range(0.0, 180.0)
		particles.gravity = Vector2(0, randf_range(0.0, 98.0))
		particles.initial_velocity_min = randf_range(10.0, 50.0)
		particles.initial_velocity_max = randf_range(50.0, 100.0)
		particles.scale_amount_min = randf_range(1.0, 3.0)
		particles.scale_amount_max = randf_range(3.0, 5.0)
		particles.color = Color(randf(), randf(), randf(), randf_range(0.5, 1.0))
		
		# 设置纹理
		if not textures.is_empty():
			particles.texture = textures[randi() % textures.size()]
		
		particles.emitting = true
		particle_container.add_child(particles)
	
	# 更新计数
	particle_count += count
	_update_labels()

# 清除粒子
func _clear_particles() -> void:
	for child in particle_container.get_children():
		child.queue_free()
	
	# 更新计数
	particle_count = 0
	_update_labels()

# 添加精灵
func _add_sprites(count: int) -> void:
	for i in range(count):
		var sprite = Sprite2D.new()
		sprite.position = Vector2(randf_range(0, 1024), randf_range(0, 600))
		sprite.scale = Vector2(randf_range(0.5, 2.0), randf_range(0.5, 2.0))
		sprite.rotation = randf_range(0, TAU)
		sprite.modulate = Color(randf(), randf(), randf(), randf_range(0.5, 1.0))
		
		# 设置纹理
		if not textures.is_empty():
			sprite.texture = textures[randi() % textures.size()]
		
		sprite_container.add_child(sprite)
	
	# 更新计数
	sprite_count += count
	_update_labels()

# 清除精灵
func _clear_sprites() -> void:
	for child in sprite_container.get_children():
		child.queue_free()
	
	# 更新计数
	sprite_count = 0
	_update_labels()

# 添加节点
func _add_nodes(count: int) -> void:
	for i in range(count):
		var node = Node.new()
		node.name = "TestNode_" + str(node_count + i)
		node_container.add_child(node)
	
	# 更新计数
	node_count += count
	_update_labels()

# 清除节点
func _clear_nodes() -> void:
	for child in node_container.get_children():
		child.queue_free()
	
	# 更新计数
	node_count = 0
	_update_labels()

# 生成性能报告按钮处理
func _on_generate_report_button_pressed() -> void:
	if performance_monitor:
		var report = performance_monitor.get_performance_report()
		$ReportDialog/ReportText.text = report
		$ReportDialog.visible = true

# 关闭报告对话框按钮处理
func _on_close_report_button_pressed() -> void:
	$ReportDialog.visible = false

# 切换性能监控按钮处理
func _on_toggle_monitor_button_pressed() -> void:
	var debug_manager = get_node_or_null("/root/DebugManager")
	if debug_manager:
		debug_manager.execute_command("toggle_performance")
