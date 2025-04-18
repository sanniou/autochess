extends BaseEffect
class_name VisualEffect
## 视觉效果类
## 显示视觉效果

# 视觉效果类型
enum VisualType {
	PARTICLE,   # 粒子效果
	SPRITE,     # 精灵效果
	ANIMATION,  # 动画效果
	DEFAULT     # 默认效果
}

# 视觉效果属性
var visual_type: int = VisualType.PARTICLE  # 视觉效果类型
var visual_path: String = ""                # 视觉效果资源路径

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_duration: float = 0.0, p_visual_type: int = VisualType.PARTICLE,
		p_visual_path: String = "", p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.VISUAL, p_name, p_description,
			p_duration, 0.0, p_source, p_target, false)  # 视觉效果默认为非减益
	visual_type = p_visual_type
	visual_path = p_visual_path

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target):
		return

	# 获取特效管理器
	var game_manager = target.get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建视觉特效
	var effect_type = game_manager.effect_manager.VisualEffectType.BUFF
	var params = {}

	# 根据视觉效果类型设置参数
	match visual_type:
		VisualType.PARTICLE:
			effect_type = game_manager.effect_manager.VisualEffectType.BUFF
			params["buff_type"] = "visual"
			params["duration"] = duration
		VisualType.SPRITE:
			effect_type = game_manager.effect_manager.VisualEffectType.BUFF
			params["buff_type"] = "visual"
			params["duration"] = duration
			params["visual_path"] = visual_path
		VisualType.ANIMATION:
			effect_type = game_manager.effect_manager.VisualEffectType.BUFF
			params["buff_type"] = "visual"
			params["duration"] = duration
			params["visual_path"] = visual_path
		_:
			effect_type = game_manager.effect_manager.VisualEffectType.BUFF
			params["buff_type"] = "visual"
			params["duration"] = duration

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(effect_type, target, params)

	# 发送效果应用信号
	EventBus.battle.emit_event("ability_effect_applied", [source, target, "visual", 0])



# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["visual_type"] = visual_type
	data["visual_path"] = visual_path
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> VisualEffect:
	return VisualEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("visual_type", VisualType.PARTICLE),
		data.get("visual_path", ""),
		source,
		target
	)
