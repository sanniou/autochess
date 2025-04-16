extends WeatherEffect
class_name RainEffect
## 雨天特效
## 实现雨天的视觉和音效

# 雨滴纹理
var rain_texture = preload("res://assets/images/vfx/rain_drop.png")

# 雨滴溅落特效场景
var splash_scene = preload("res://scenes/vfx/rain_splash.tscn")

# 雨滴溅落特效池
var splash_pool = []

# 雨滴溅落计时器
var splash_timer = null

# 初始化
func _ready():
	super._ready()
	
	# 创建雨滴溅落计时器
	splash_timer = Timer.new()
	splash_timer.wait_time = 0.1
	splash_timer.autostart = true
	splash_timer.timeout.connect(_on_splash_timer_timeout)
	add_child(splash_timer)
	
	# 初始化溅落特效池
	_initialize_splash_pool()

# 创建粒子系统
func _create_particles() -> void:
	# 创建雨滴粒子
	particles = CPUParticles2D.new()
	particles.name = "RainParticles"
	particles.amount = 500
	particles.lifetime = 1.0
	particles.texture = rain_texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(1000, 10)
	particles.direction = Vector2(0.2, 1)
	particles.spread = 5
	particles.gravity = Vector2(0, 980)
	particles.initial_velocity_min = 400
	particles.initial_velocity_max = 600
	particles.scale_amount = 0.5
	particles.scale_amount_random = 0.2
	particles.color = Color(0.7, 0.7, 0.9, 0.8)
	add_child(particles)
	
	# 创建雾气粒子
	var fog_particles = CPUParticles2D.new()
	fog_particles.name = "FogParticles"
	fog_particles.amount = 50
	fog_particles.lifetime = 5.0
	fog_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog_particles.emission_rect_extents = Vector2(1000, 10)
	fog_particles.direction = Vector2(1, 0)
	fog_particles.spread = 10
	fog_particles.gravity = Vector2(0, 0)
	fog_particles.initial_velocity_min = 20
	fog_particles.initial_velocity_max = 40
	fog_particles.scale_amount = 100.0
	fog_particles.scale_amount_random = 50.0
	fog_particles.color = Color(0.8, 0.8, 0.9, 0.1)
	add_child(fog_particles)

# 初始化溅落特效池
func _initialize_splash_pool() -> void:
	# 预创建一些溅落特效
	for i in range(20):
		var splash = splash_scene.instantiate()
		splash.visible = false
		add_child(splash)
		splash_pool.append(splash)

# 获取音效路径
func _get_sound_path() -> String:
	return "res://assets/audio/sfx/weather/rain.ogg"

# 设置强度
func _set_intensity(value: float) -> void:
	if particles:
		# 调整雨滴数量
		particles.amount = int(500 * value)
		
		# 调整雨滴速度
		particles.initial_velocity_min = 400 * value
		particles.initial_velocity_max = 600 * value
		
		# 调整雨滴大小
		particles.scale_amount = 0.5 * value
	
	# 调整溅落特效频率
	if splash_timer:
		splash_timer.wait_time = 0.1 / value

# 设置风向
func _set_wind_direction(direction: Vector2) -> void:
	if particles:
		# 调整雨滴方向
		particles.direction = Vector2(direction.x, 1).normalized()

# 设置风力
func _set_wind_strength(strength: float) -> void:
	if particles:
		# 调整雨滴初速度
		particles.initial_velocity_min = 400 * (1 + strength * 0.5)
		particles.initial_velocity_max = 600 * (1 + strength * 0.5)

# 溅落计时器超时处理
func _on_splash_timer_timeout() -> void:
	# 创建随机位置的溅落特效
	var viewport_size = get_viewport_rect().size
	var x = randf_range(0, viewport_size.x)
	var y = viewport_size.y - 10
	
	# 从池中获取一个溅落特效
	var splash = _get_splash_from_pool()
	if splash:
		splash.position = Vector2(x, y)
		splash.play()

# 从池中获取一个溅落特效
func _get_splash_from_pool() -> Node:
	# 查找一个不可见的溅落特效
	for splash in splash_pool:
		if not splash.visible:
			return splash
	
	# 如果没有可用的，创建一个新的
	var new_splash = splash_scene.instantiate()
	add_child(new_splash)
	splash_pool.append(new_splash)
	return new_splash
