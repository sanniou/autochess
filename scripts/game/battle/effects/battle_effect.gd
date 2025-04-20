extends Resource
class_name BattleEffect
## 战斗效果基类
## 所有战斗效果的基类，定义了效果的基本接口

# 效果类型枚举
enum EffectType {
	STATUS,     # 状态效果（眩晕、沉默等）
	DAMAGE,     # 伤害效果
	HEAL,       # 治疗效果
	STAT_MOD,   # 属性修改效果
	DOT,        # 持续伤害效果
	HOT,        # 持续治疗效果
	SHIELD,     # 护盾效果
	AURA,       # 光环效果
	TRIGGER,    # 触发效果
	MOVEMENT,   # 移动效果
	VISUAL,     # 视觉效果
	SOUND       # 音效
}

# 效果属性
var id: String = ""              # 效果唯一ID
var name: String = ""            # 效果名称
var description: String = ""     # 效果描述
var icon_path: String = ""       # 效果图标路径
var effect_type: int = EffectType.STATUS  # 效果类型
var duration: float = 0.0        # 效果持续时间
var remaining_time: float = 0.0  # 剩余时间
var is_permanent: bool = false   # 是否永久效果
var is_stackable: bool = false   # 是否可叠加
var stack_count: int = 1         # 叠加层数
var max_stacks: int = 1          # 最大叠加层数
var source = null                # 效果来源
var target = null                # 效果目标
var params: Dictionary = {}      # 效果参数
var tags: Array = []             # 效果标签
var priority: int = 0            # 效果优先级
var visual_effect = null         # 视觉效果引用
var is_active: bool = false      # 是否激活
var is_expired: bool = false     # 是否已过期
var created_at: int = 0          # 创建时间戳

# 信号
signal effect_applied(effect)
signal effect_removed(effect)
signal effect_updated(effect)
signal effect_expired(effect)
signal stack_added(effect, old_stack, new_stack)

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, effect_type_value: int = EffectType.STATUS,
		effect_source = null, effect_target = null, effect_params: Dictionary = {}) -> void:
	id = effect_id if not effect_id.is_empty() else _generate_id()
	name = effect_name
	description = effect_description
	effect_type = effect_type_value
	duration = effect_duration
	remaining_time = duration
	source = effect_source
	target = effect_target
	params = effect_params
	created_at = Time.get_ticks_msec()

	# 设置是否永久效果
	is_permanent = duration <= 0

	# 设置是否可叠加
	is_stackable = params.get("stackable", false)
	max_stacks = params.get("max_stacks", 1)

	# 设置优先级
	priority = params.get("priority", 0)

	# 设置标签
	if params.has("tags"):
		tags = params.tags

# 应用效果
func apply() -> bool:
	if not target or not is_instance_valid(target):
		return false

	# 标记为激活
	is_active = true

	# 创建视觉效果
	_create_visual_effect()

	# 发送效果应用信号
	effect_applied.emit(self)

	return true

# 移除效果
func remove() -> bool:
	if not is_active:
		return false

	# 标记为非激活
	is_active = false

	# 移除视觉效果
	_remove_visual_effect()

	# 发送效果移除信号
	effect_removed.emit(self)

	return true

# 更新效果
func update(delta: float) -> bool:
	if not is_active or is_expired:
		return false

	# 如果是永久效果，不更新时间
	if is_permanent:
		return true

	# 更新剩余时间
	remaining_time -= delta

	# 检查是否过期
	if remaining_time <= 0:
		expire()
		return false

	# 发送效果更新信号
	effect_updated.emit(self)

	return true

# 效果过期
func expire() -> void:
	if is_expired:
		return

	# 标记为过期
	is_expired = true

	# 移除效果
	remove()

	# 发送效果过期信号
	effect_expired.emit(self)

# 添加叠加层数
func add_stack(count: int = 1) -> bool:
	if not is_stackable or stack_count >= max_stacks:
		return false

	var old_stack = stack_count
	stack_count = min(stack_count + count, max_stacks)

	# 发送叠加层数变化信号
	stack_added.emit(self, old_stack, stack_count)

	return true

# 获取效果数据
func get_data() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"icon_path": icon_path,
		"effect_type": effect_type,
		"duration": duration,
		"remaining_time": remaining_time,
		"is_permanent": is_permanent,
		"is_stackable": is_stackable,
		"stack_count": stack_count,
		"max_stacks": max_stacks,
		"params": params,
		"tags": tags,
		"priority": priority,
		"is_active": is_active,
		"is_expired": is_expired,
		"created_at": created_at
	}

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> BattleEffect:
	var effect = BattleEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("effect_type", EffectType.STATUS),
		source,
		target,
		data.get("params", {})
	)

	effect.icon_path = data.get("icon_path", "")
	effect.is_permanent = data.get("is_permanent", false)
	effect.is_stackable = data.get("is_stackable", false)
	effect.stack_count = data.get("stack_count", 1)
	effect.max_stacks = data.get("max_stacks", 1)
	effect.tags = data.get("tags", [])
	effect.priority = data.get("priority", 0)
	effect.is_active = data.get("is_active", false)
	effect.is_expired = data.get("is_expired", false)
	effect.created_at = data.get("created_at", Time.get_ticks_msec())

	return effect

# 创建视觉效果
func _create_visual_effect() -> void:
	# 基类不实现具体逻辑，由子类重写
	pass

# 移除视觉效果
func _remove_visual_effect() -> void:
	if visual_effect and is_instance_valid(visual_effect):
		visual_effect.queue_free()
		visual_effect = null

# 生成唯一ID
func _generate_id() -> String:
	return "effect_" + str(randi()) + "_" + str(Time.get_ticks_msec())
