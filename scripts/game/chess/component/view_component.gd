extends Component
class_name ViewComponent
## 视图组件
## 管理棋子的视觉表现

# 信号
signal animation_started(animation_name)
signal animation_finished(animation_name)
signal effect_added(effect)
signal effect_removed(effect)

# 视图引用
var sprite: Sprite2D = null
var animation_player: AnimationPlayer = null
var health_bar: ProgressBar = null
var mana_bar: ProgressBar = null
var star_indicator: Node2D = null
var effect_container: Node2D = null

# 视图属性
var current_animation: String = "idle"
var animation_speed: float = 1.0
var visual_effects: Array = []
var is_flipped: bool = false

# 初始化
func _init(p_owner = null, p_name: String = "ViewComponent"):
	super._init(p_owner, p_name)
	priority = 50  # 中等优先级

# 初始化组件
func initialize() -> void:
	# 查找视图组件
	_find_view_components()

	# 连接信号
	_connect_signals()

	# 初始化视图
	_initialize_view()

	super.initialize()

# 查找视图组件
func _find_view_components() -> void:
	# 查找精灵
	sprite = owner.get_node_or_null("Sprite2D")

	# 查找动画播放器
	animation_player = owner.get_node_or_null("AnimationPlayer")

	# 查找生命条
	health_bar = owner.get_node_or_null("HealthBar")

	# 查找法力条
	mana_bar = owner.get_node_or_null("ManaBar")

	# 查找星级指示器
	star_indicator = owner.get_node_or_null("StarIndicator")

	# 查找效果容器
	effect_container = owner.get_node_or_null("EffectContainer")

	# 如果没有效果容器，创建一个
	if not effect_container and owner is Node2D:
		effect_container = Node2D.new()
		effect_container.name = "EffectContainer"
		owner.add_child(effect_container)

# 连接信号
func _connect_signals() -> void:
	# 连接动画播放器信号
	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)

	# 连接属性组件信号
	var attribute_component = owner.get_component("AttributeComponent")
	if attribute_component:
		attribute_component.attribute_changed.connect(_on_attribute_changed)

	# 连接状态组件信号
	var state_component = owner.get_component("StateComponent")
	if state_component:
		state_component.state_changed.connect(_on_state_changed)

	# 连接目标组件信号
	var target_component = owner.get_component("TargetComponent")
	if target_component:
		target_component.target_changed.connect(_on_target_changed)

# 初始化视图
func _initialize_view() -> void:
	# 更新生命条
	_update_health_bar()

	# 更新法力条
	_update_mana_bar()

	# 更新星级指示器
	_update_star_indicator()

	# 播放默认动画
	play_animation("idle")

# 更新组件
func _process_update(delta: float) -> void:
	# 更新视觉效果
	_update_visual_effects(delta)

	# 更新朝向
	_update_facing()

# 播放动画
func play_animation(animation_name: String) -> void:
	# 如果没有动画播放器，不做任何操作
	if not animation_player:
		return

	# 如果动画相同且正在播放，不做任何操作
	if current_animation == animation_name and animation_player.is_playing():
		return

	# 保存当前动画
	current_animation = animation_name

	# 检查动画是否存在
	if not animation_player.has_animation(animation_name):
		# 如果没有指定的动画，播放默认动画
		if animation_player.has_animation("idle"):
			animation_name = "idle"
		else:
			return

	# 播放动画
	animation_player.play(animation_name, -1, animation_speed)

	# 发送动画开始信号
	animation_started.emit(animation_name)

# 设置动画速度
func set_animation_speed(speed: float) -> void:
	animation_speed = speed

	# 更新当前动画速度
	if animation_player and animation_player.is_playing():
		animation_player.speed_scale = animation_speed

# 添加视觉效果
func add_visual_effect(effect_name_or_path: String, params: Dictionary = {}) -> Node:
	# 效果实例
	var effect_instance = null

	# 获取视觉效果管理器
	var visual_manager = GameManager.get_manager("VisualManager")
	if not visual_manager:
		push_error("ViewComponent: 无法获取视觉效果管理器")
		return null

	# 准备参数
	var effect_params = params.duplicate()

	# 设置效果容器
	if effect_container:
		effect_params["parent"] = effect_container
	else:
		effect_params["parent"] = owner

	# 判断是效果名称还是路径
	if effect_name_or_path.begins_with("res://"):
		# 是路径，使用创建场景效果
		effect_instance = visual_manager.create_scene_effect(effect_name_or_path, Vector2.ZERO, effect_params)
	else:
		# 是效果名称，使用创建效果
		effect_instance = visual_manager.create_effect(effect_name_or_path, Vector2.ZERO, effect_params)

	# 检查效果是否创建成功
	if not effect_instance:
		push_error("ViewComponent: 创建视觉效果失败: " + effect_name_or_path)
		return null

	# 添加到效果列表
	visual_effects.append(effect_instance)

	# 添加到LOD系统
	_add_to_lod_system(effect_instance)

	# 发送效果添加信号
	effect_added.emit(effect_instance)

	return effect_instance

# 移除视觉效果
func remove_visual_effect(effect: Node) -> void:
	# 从效果列表移除
	visual_effects.erase(effect)

	# 检查效果是否有效
	if effect and is_instance_valid(effect):
		# 从LOD系统移除
		_remove_from_lod_system(effect)

		# 获取视觉效果管理器
		var visual_manager = GameManager.get_manager("VisualManager")
		if visual_manager:
			# 使用VisualManager移除效果
			visual_manager.remove_effect(effect)
		else:
			# 如果无法获取VisualManager，则直接移除
			if effect.is_inside_tree():
				effect.get_parent().remove_child(effect)
			effect.queue_free()

	# 发送效果移除信号
	effect_removed.emit(effect)

# 清除所有视觉效果
func clear_visual_effects() -> void:
	# 复制效果列表，因为我们将在遍历过程中修改它
	var effects_to_clear = visual_effects.duplicate()

	# 移除所有效果
	for effect in effects_to_clear:
		remove_visual_effect(effect)

	# 清空效果列表
	visual_effects.clear()

# 设置精灵翻转
func set_sprite_flip(flip: bool) -> void:
	is_flipped = flip

	# 更新精灵翻转
	if sprite:
		sprite.flip_h = flip

# 更新生命条
func _update_health_bar() -> void:
	if not health_bar:
		return

	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return

	# 获取生命值
	var current_health = attribute_component.get_attribute("current_health")
	var max_health = attribute_component.get_attribute("max_health")

	# 更新生命条
	health_bar.max_value = max_health
	health_bar.value = current_health

	# 更新生命条颜色
	var health_percent = current_health / max_health
	var health_color = Color(1, 0, 0)  # 红色（低生命值）

	if health_percent > 0.7:
		health_color = Color(0, 1, 0)  # 绿色（高生命值）
	elif health_percent > 0.3:
		health_color = Color(1, 1, 0)  # 黄色（中等生命值）

	# 设置生命条颜色
	if health_bar.has_node("Fill"):
		health_bar.get_node("Fill").modulate = health_color

# 更新法力条
func _update_mana_bar() -> void:
	if not mana_bar:
		return

	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return

	# 获取法力值
	var current_mana = attribute_component.get_attribute("current_mana")
	var max_mana = attribute_component.get_attribute("max_mana")

	# 更新法力条
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

# 更新星级指示器
func _update_star_indicator() -> void:
	if not star_indicator:
		return

	# 获取星级
	var star_level = 1

	# 从属性组件获取星级
	var attribute_component = owner.get_component("AttributeComponent")
	if attribute_component:
		star_level = attribute_component.get_attribute("star_level", 1)

	# 更新星级指示器
	for i in range(star_indicator.get_child_count()):
		var star = star_indicator.get_child(i)
		star.visible = i < star_level

# 更新视觉效果
func _update_visual_effects(delta: float) -> void:
	# 更新所有效果
	for effect in visual_effects:
		if effect and is_instance_valid(effect) and effect.has_method("update"):
			effect.update(delta)

# 更新朝向
func _update_facing() -> void:
	# 获取目标组件
	var target_component = owner.get_component("TargetComponent")
	if not target_component or not target_component.has_target():
		return

	# 获取目标
	var target = target_component.get_target()

	# 获取目标位置
	var target_pos = Vector2.ZERO
	if target.has_method("get_global_position"):
		target_pos = target.get_global_position()
	elif target is Node2D:
		target_pos = target.global_position

	# 获取自身位置
	var self_pos = Vector2.ZERO
	if owner.has_method("get_global_position"):
		self_pos = owner.get_global_position()
	elif owner is Node2D:
		self_pos = owner.global_position

	# 计算方向
	var direction = target_pos - self_pos

	# 更新朝向
	if direction.x < 0:
		set_sprite_flip(true)
	else:
		set_sprite_flip(false)

# 属性变化回调
func _on_attribute_changed(attribute_name: String, old_value, new_value) -> void:
	# 更新生命条和法力条
	if attribute_name == "current_health" or attribute_name == "max_health":
		_update_health_bar()
	elif attribute_name == "current_mana" or attribute_name == "max_mana":
		_update_mana_bar()
	elif attribute_name == "star_level":
		_update_star_indicator()

# 状态变化回调
func _on_state_changed(old_state: int, new_state: int) -> void:
	# 获取状态组件
	var state_component = owner.get_component("StateComponent")
	if not state_component:
		return

	# 获取状态名称
	var state_name = state_component.get_state_name(new_state)

	# 播放对应动画
	play_animation(state_name)

# 目标变化回调
func _on_target_changed(old_target, new_target) -> void:
	# 更新朝向
	_update_facing()

# 动画完成回调
func _on_animation_finished(animation_name: String) -> void:
	# 发送动画完成信号
	animation_finished.emit(animation_name)

	# 如果是攻击动画，播放空闲动画
	if animation_name == "attack":
		play_animation("idle")

	# 如果是施法动画，播放空闲动画
	if animation_name == "cast":
		play_animation("idle")

	# 如果是受击动画，播放空闲动画
	if animation_name == "hit":
		play_animation("idle")

# 添加到LOD系统
func _add_to_lod_system(effect: Node) -> void:
	# 获取LOD系统
	var lod_system = _get_lod_system()
	if lod_system and effect:
		# 根据效果类型设置重要性
		var importance = 0.5  # 默认重要性
		var type = "effect"

		if effect is CPUParticles2D:
			type = "particle"
			importance = 0.3
		elif effect is AnimatedSprite2D:
			type = "sprite"
			importance = 0.4

		# 添加到LOD系统
		lod_system.add_object(effect, type)
		lod_system.set_object_importance(effect, importance)

# 从LOD系统移除
func _remove_from_lod_system(effect: Node) -> void:
	# 获取LOD系统
	var lod_system = _get_lod_system()
	if lod_system and effect:
		# 从LOD系统移除
		lod_system.remove_object(effect)

# 获取LOD系统
func _get_lod_system() -> AnimationLODSystem:
	# 尝试从动画管理器获取LOD系统
	var animation_manager = GameManager.animation_manager
	if animation_manager and animation_manager.has_node("AnimationLODSystem"):
		return animation_manager.get_node("AnimationLODSystem")

	return null
