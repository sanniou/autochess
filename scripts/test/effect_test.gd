extends Node2D
## 效果系统测试场景
## 用于测试游戏效果和视觉效果系统

# 测试目标
@onready var test_target = $TestTarget

# 当前活动的游戏效果
var active_game_effects = []

# 当前活动的视觉效果
var active_visual_effects = []

# 初始化
func _ready() -> void:
	# 设置测试目标
	var sprite = test_target.get_node("Sprite2D")
	if sprite:
		# 尝试加载测试目标纹理
		if ResourceLoader.exists("res://assets/textures/test/test_target.png"):
			sprite.texture = load("res://assets/textures/test/test_target.png")
		else:
			# 如果没有测试目标纹理，使用默认图标
			sprite.texture = get_theme_icon("Node", "EditorIcons")
	
	# 连接输入事件
	test_target.input_event.connect(_on_test_target_input_event)

# 处理输入事件
func _on_test_target_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# 检查是否是鼠标点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 在点击位置创建随机效果
		_create_random_effect(test_target.global_position)

# 创建随机效果
func _create_random_effect(position: Vector2) -> void:
	# 随机选择效果类型
	var effect_type = randi() % 3
	
	match effect_type:
		0:  # 游戏效果
			_create_random_game_effect(position)
		1:  # 视觉效果
			_create_random_visual_effect(position)
		2:  # 组合效果
			_create_random_combined_effect(position)

# 创建随机游戏效果
func _create_random_game_effect(position: Vector2) -> void:
	# 检查GameManager和GameEffectManager是否可用
	if not GameManager or not GameManager.game_effect_manager:
		print("GameEffectManager不可用")
		return
	
	# 随机选择游戏效果类型
	var effect_types = [
		"status",    # 状态效果
		"damage",    # 伤害效果
		"heal",      # 治疗效果
		"stat_mod",  # 属性修改效果
		"dot",       # 持续伤害效果
		"hot",       # 持续治疗效果
		"shield"     # 护盾效果
	]
	
	var effect_type = effect_types[randi() % effect_types.size()]
	var effect = null
	
	match effect_type:
		"status":
			# 创建随机状态效果
			var status_types = [0, 1, 2, 3, 4, 5]  # 眩晕、沉默、缴械、定身、嘲讽、冰冻
			var status_type = status_types[randi() % status_types.size()]
			var duration = randf_range(2.0, 5.0)
			
			effect = GameManager.game_effect_manager.create_status_effect(
				self,           # 源
				test_target,    # 目标
				status_type,    # 状态类型
				duration,       # 持续时间
				{
					"visual_effect": true,
					"visual_params": {
						"duration": duration
					}
				}
			)
		
		"damage":
			# 创建随机伤害效果
			var damage_types = ["physical", "magical", "fire", "ice", "lightning", "poison"]
			var damage_type = damage_types[randi() % damage_types.size()]
			var damage_value = randf_range(10.0, 50.0)
			var is_critical = randf() < 0.3  # 30%几率暴击
			
			effect = GameManager.game_effect_manager.create_damage_effect(
				self,           # 源
				test_target,    # 目标
				damage_value,   # 伤害值
				damage_type,    # 伤害类型
				{
					"is_critical": is_critical,
					"visual_effect": true,
					"visual_params": {
						"duration": 0.8
					}
				}
			)
		
		"heal":
			# 创建随机治疗效果
			var heal_value = randf_range(10.0, 50.0)
			var is_critical = randf() < 0.3  # 30%几率暴击
			
			effect = GameManager.game_effect_manager.create_heal_effect(
				self,           # 源
				test_target,    # 目标
				heal_value,     # 治疗值
				{
					"is_critical": is_critical,
					"visual_effect": true,
					"visual_params": {
						"duration": 0.8
					}
				}
			)
		
		"stat_mod":
			# 创建随机属性修改效果
			var stat_types = ["attack", "defense", "speed", "critical_chance"]
			var stat_type = stat_types[randi() % stat_types.size()]
			var stat_value = randf_range(5.0, 20.0)
			var is_debuff = randf() < 0.5  # 50%几率是减益
			var duration = randf_range(3.0, 8.0)
			
			var stats = {}
			stats[stat_type] = is_debuff ? -stat_value : stat_value
			
			effect = GameManager.game_effect_manager.create_stat_effect(
				self,           # 源
				test_target,    # 目标
				stats,          # 属性修改
				duration,       # 持续时间
				is_debuff,      # 是否减益
				{
					"visual_effect": true,
					"visual_params": {
						"duration": duration
					}
				}
			)
		
		"dot":
			# 创建随机持续伤害效果
			var dot_types = [0, 1, 2]  # 燃烧、中毒、流血
			var dot_type = dot_types[randi() % dot_types.size()]
			var damage_per_second = randf_range(5.0, 15.0)
			var duration = randf_range(3.0, 8.0)
			var damage_types = ["fire", "poison", "physical"]
			var damage_type = damage_types[dot_type]  # 根据DOT类型选择伤害类型
			
			effect = GameManager.game_effect_manager.create_dot_effect(
				self,               # 源
				test_target,        # 目标
				dot_type,           # DOT类型
				damage_per_second,  # 每秒伤害
				duration,           # 持续时间
				damage_type,        # 伤害类型
				{
					"tick_interval": 1.0,
					"visual_effect": true,
					"visual_params": {
						"duration": duration
					}
				}
			)
		
		"hot":
			# 创建随机持续治疗效果
			var heal_per_second = randf_range(5.0, 15.0)
			var duration = randf_range(3.0, 8.0)
			
			effect = GameManager.game_effect_manager.create_hot_effect(
				self,               # 源
				test_target,        # 目标
				heal_per_second,    # 每秒治疗
				duration,           # 持续时间
				{
					"tick_interval": 1.0,
					"visual_effect": true,
					"visual_params": {
						"duration": duration
					}
				}
			)
		
		"shield":
			# 创建随机护盾效果
			var shield_amount = randf_range(20.0, 100.0)
			var duration = randf_range(5.0, 10.0)
			var damage_reduction = randf_range(0.0, 0.3)  # 0-30%伤害减免
			var reflect_percent = randf_range(0.0, 0.2)   # 0-20%伤害反弹
			
			effect = GameManager.game_effect_manager.create_shield_effect(
				self,               # 源
				test_target,        # 目标
				shield_amount,      # 护盾值
				duration,           # 持续时间
				{
					"damage_reduction": damage_reduction,
					"reflect_percent": reflect_percent,
					"visual_effect": true,
					"visual_params": {
						"duration": duration
					}
				}
			)
	
	# 如果创建了效果，添加到活动效果列表
	if effect:
		active_game_effects.append(effect)
		print("创建游戏效果: " + effect_type)

# 创建随机视觉效果
func _create_random_visual_effect(position: Vector2) -> void:
	# 检查GameManager和VisualManager是否可用
	if not GameManager or not GameManager.visual_manager:
		print("VisualManager不可用")
		return
	
	# 随机选择视觉效果类型
	var effect_types = [
		"particle",       # 粒子效果
		"sprite",         # 精灵效果
		"damage_number",  # 伤害数字
		"heal_number",    # 治疗数字
		"status_icon"     # 状态图标
	]
	
	var effect_type = effect_types[randi() % effect_types.size()]
	var effect_id = ""
	
	match effect_type:
		"particle":
			# 创建随机粒子效果
			var particle_types = ["fire", "smoke", "sparkle", "heal", "blood", "explosion"]
			var particle_type = particle_types[randi() % particle_types.size()]
			var duration = randf_range(0.5, 2.0)
			
			effect_id = GameManager.visual_manager.create_particle_effect(
				position,
				particle_type,
				{
					"amount": randi_range(8, 20),
					"duration": duration,
					"explosiveness": randf_range(0.0, 0.9),
					"randomness": randf_range(0.0, 0.9)
				}
			)
		
		"sprite":
			# 创建随机精灵效果
			var texture_paths = [
				"res://assets/textures/effects/hit.png",
				"res://assets/textures/effects/critical.png",
				"res://assets/textures/effects/heal.png",
				"res://assets/textures/effects/shield.png"
			]
			var texture_path = texture_paths[randi() % texture_paths.size()]
			var duration = randf_range(0.5, 1.5)
			
			effect_id = GameManager.visual_manager.create_sprite_effect(
				position,
				texture_path,
				{
					"duration": duration,
					"fade_in": 0.1,
					"fade_out": 0.3,
					"scale": Vector2(randf_range(0.8, 2.0), randf_range(0.8, 2.0))
				}
			)
		
		"damage_number":
			# 创建随机伤害数字
			var damage_value = randf_range(10.0, 100.0)
			var is_critical = randf() < 0.3  # 30%几率暴击
			
			effect_id = GameManager.visual_manager.create_damage_number(
				position,
				damage_value,
				is_critical,
				{
					"color": Color(1.0, 0.0, 0.0, 1.0),  # 红色
					"duration": 1.0,
					"move_distance": Vector2(0, -50)
				}
			)
		
		"heal_number":
			# 创建随机治疗数字
			var heal_value = randf_range(10.0, 100.0)
			var is_critical = randf() < 0.3  # 30%几率暴击
			
			effect_id = GameManager.visual_manager.create_heal_number(
				position,
				heal_value,
				is_critical,
				{
					"color": Color(0.0, 1.0, 0.0, 1.0),  # 绿色
					"duration": 1.0,
					"move_distance": Vector2(0, -50)
				}
			)
		
		"status_icon":
			# 创建随机状态图标
			var status_types = ["stun", "silence", "disarm", "root", "taunt", "frozen", "burning", "poisoned", "bleeding"]
			var status_type = status_types[randi() % status_types.size()]
			var duration = randf_range(1.0, 3.0)
			
			effect_id = GameManager.visual_manager.create_status_icon(
				position + Vector2(0, -30),  # 在目标上方显示
				status_type,
				duration,
				{
					"scale": Vector2(1.0, 1.0),
					"fade_in": 0.2,
					"fade_out": 0.2
				}
			)
	
	# 如果创建了效果，添加到活动效果列表
	if not effect_id.is_empty():
		active_visual_effects.append(effect_id)
		print("创建视觉效果: " + effect_type + ", ID: " + effect_id)

# 创建随机组合效果
func _create_random_combined_effect(position: Vector2) -> void:
	# 检查GameManager和VisualManager是否可用
	if not GameManager or not GameManager.visual_manager:
		print("VisualManager不可用")
		return
	
	# 随机选择组合效果类型
	var effect_types = [
		"damage",    # 伤害效果
		"critical",  # 暴击效果
		"heal",      # 治疗效果
		"stun",      # 眩晕效果
		"burning",   # 燃烧效果
		"shield",    # 护盾效果
		"explosion", # 爆炸效果
		"buff",      # 增益效果
		"debuff"     # 减益效果
	]
	
	var effect_type = effect_types[randi() % effect_types.size()]
	var effect_id = GameManager.visual_manager.create_combined_effect(
		position,
		effect_type,
		{
			"scale": Vector2(randf_range(0.8, 1.5), randf_range(0.8, 1.5))
		}
	)
	
	# 如果创建了效果，添加到活动效果列表
	if not effect_id.is_empty():
		active_visual_effects.append(effect_id)
		print("创建组合效果: " + effect_type + ", ID: " + effect_id)

# 游戏效果按钮点击
func _on_game_effect_button_pressed() -> void:
	_create_random_game_effect(test_target.global_position)

# 视觉效果按钮点击
func _on_visual_effect_button_pressed() -> void:
	_create_random_visual_effect(test_target.global_position)

# 组合效果按钮点击
func _on_combined_effect_button_pressed() -> void:
	_create_random_combined_effect(test_target.global_position)

# 清除按钮点击
func _on_clear_button_pressed() -> void:
	# 清除所有游戏效果
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.clear_target_effects(test_target)
		active_game_effects.clear()
	
	# 清除所有视觉效果
	if GameManager and GameManager.visual_manager:
		for effect_id in active_visual_effects:
			GameManager.visual_manager.cancel_effect(effect_id)
		active_visual_effects.clear()
	
	print("已清除所有效果")

# 返回按钮点击
func _on_back_button_pressed() -> void:
	# 清除所有效果
	_on_clear_button_pressed()
	
	# 返回主菜单
	if GameManager:
		GameManager.change_state(GameManager.GameState.MAIN_MENU)
