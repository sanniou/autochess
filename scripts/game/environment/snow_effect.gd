extends WeatherEffect
class_name SnowEffect
## 雪天特效
## 实现雪天的视觉和音效

# 雪花纹理
var snow_texture = preload("res://assets/images/vfx/snowflake.png")

# 初始化
func _ready():
	super._ready()

# 创建粒子系统
func _create_particles() -> void:
	# 创建雪花粒子
	particles = CPUParticles2D.new()
	particles.name = "SnowParticles"
	particles.amount = 300
	particles.lifetime = 5.0
	particles.texture = snow_texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(1000, 10)
	particles.direction = Vector2(0.1, 1)
	particles.spread = 10
	particles.gravity = Vector2(0, 20)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.angular_velocity_min = -90
	particles.angular_velocity_max = 90
	particles.scale_amount = 0.3
	particles.scale_amount_random = 0.2
	particles.color = Color(1, 1, 1, 0.8)
	add_child(particles)
	
	# 创建雾气粒子
	var fog_particles = CPUParticles2D.new()
	fog_particles.name = "FogParticles"
	fog_particles.amount = 30
	fog_particles.lifetime = 8.0
	fog_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog_particles.emission_rect_extents = Vector2(1000, 10)
	fog_particles.direction = Vector2(1, 0)
	fog_particles.spread = 10
	fog_particles.gravity = Vector2(0, 0)
	fog_particles.initial_velocity_min = 10
	fog_particles.initial_velocity_max = 20
	fog_particles.scale_amount = 150.0
	fog_particles.scale_amount_random = 50.0
	fog_particles.color = Color(0.9, 0.9, 1.0, 0.05)
	add_child(fog_particles)

# 获取音效路径
func _get_sound_path() -> String:
	return "res://assets/audio/sfx/weather/snow.ogg"

# 设置强度
func _set_intensity(value: float) -> void:
	if particles:
		# 调整雪花数量
		particles.amount = int(300 * value)
		
		# 调整雪花速度
		particles.initial_velocity_min = 50 * value
		particles.initial_velocity_max = 100 * value
		
		# 调整雪花大小
		particles.scale_amount = 0.3 * value

# 设置风向
func _set_wind_direction(direction: Vector2) -> void:
	if particles:
		# 调整雪花方向
		particles.direction = Vector2(direction.x, 1).normalized()

# 设置风力
func _set_wind_strength(strength: float) -> void:
	if particles:
		# 调整雪花初速度
		particles.initial_velocity_min = 50 * (1 + strength * 0.5)
		particles.initial_velocity_max = 100 * (1 + strength * 0.5)
