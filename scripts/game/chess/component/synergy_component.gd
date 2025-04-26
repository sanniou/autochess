extends Component
class_name SynergyComponent
## 羁绊组件
## 管理棋子的羁绊和羁绊效果

# 引入羁绊常量
const SC = preload("res://scripts/game/synergy/synergy_constants.gd")

# 信号
signal synergy_added(synergy_type, synergy_level)
signal synergy_removed(synergy_type)
signal synergy_level_changed(synergy_type, old_level, new_level)

# 羁绊数据
var synergy_types: Array = []  # 羁绊类型
var synergy_levels: Dictionary = {}  # 羁绊等级 {羁绊类型: 等级}

# 初始化
func _init(p_owner = null, p_name: String = "SynergyComponent"):
	super._init(p_owner, p_name)
	priority = 30  # 中等优先级

# 初始化组件
func initialize() -> void:
	super.initialize()

# 添加羁绊类型
func add_synergy_type(synergy_type: String) -> void:
	# 如果已有该羁绊类型，不做任何操作
	if synergy_types.has(synergy_type):
		return

	# 添加羁绊类型
	synergy_types.append(synergy_type)

	# 初始化羁绊等级
	synergy_levels[synergy_type] = 0

	# 发送事件
	GlobalEventBus.synergy.dispatch_event(ChessEvents.SynergyTypeAddedEvent.new(owner, synergy_type))

	# 发送信号
	synergy_added.emit(synergy_type, 0)

# 移除羁绊类型
func remove_synergy_type(synergy_type: String) -> void:
	# 如果没有该羁绊类型，不做任何操作
	if not synergy_types.has(synergy_type):
		return

	# 获取当前等级
	var current_level = synergy_levels[synergy_type]

	# 如果当前等级大于0，移除羁绊效果
	if current_level > 0:
		_remove_synergy_effects(synergy_type, current_level)

	# 移除羁绊类型
	synergy_types.erase(synergy_type)

	# 移除羁绊等级
	synergy_levels.erase(synergy_type)

	# 发送羁绊移除信号
	synergy_removed.emit(synergy_type)

	# 发送事件
	GlobalEventBus.synergy.dispatch_event(ChessEvents.SynergyTypeRemovedEvent.new(owner, synergy_type))

# 设置羁绊等级
func set_synergy_level(synergy_type: String, level: int) -> void:
	# 如果没有该羁绊类型，不做任何操作
	if not synergy_types.has(synergy_type):
		return

	# 如果等级相同，不做任何操作
	if synergy_levels[synergy_type] == level:
		return

	# 保存旧等级
	var old_level = synergy_levels[synergy_type]

	# 设置新等级
	synergy_levels[synergy_type] = level

	# 更新羁绊效果
	_update_synergy_effects(synergy_type, old_level, level)

	# 发送羁绊等级变化信号
	synergy_level_changed.emit(synergy_type, old_level, level)

	# 发送事件
	GlobalEventBus.synergy.dispatch_event(ChessEvents.SynergyLevelChangedEvent.new(owner, synergy_type, old_level, level))

# 获取羁绊等级
func get_synergy_level(synergy_type: String) -> int:
	# 如果没有该羁绊类型，返回0
	if not synergy_types.has(synergy_type):
		return 0

	return synergy_levels[synergy_type]

# 获取所有羁绊类型
func get_synergy_types() -> Array:
	return synergy_types.duplicate()

# 获取所有羁绊等级
func get_synergy_levels() -> Dictionary:
	return synergy_levels.duplicate()

# 检查是否有指定羁绊类型
func has_synergy_type(synergy_type: String) -> bool:
	return synergy_types.has(synergy_type)

# 更新羁绊效果
func _update_synergy_effects(synergy_type: String, old_level: int, new_level: int) -> void:
	# 如果没有该羁绊类型，不做任何操作
	if not synergy_types.has(synergy_type):
		return

	# 如果旧等级大于0，移除旧效果
	if old_level > 0:
		_remove_synergy_effects(synergy_type, old_level)

	# 如果新等级为0，不添加效果
	if new_level <= 0:
		return

	# 获取羁绊配置
	var synergy_config = GameManager.synergy_manager.get_synergy_config(synergy_type)
	if not synergy_config:
		return

	# 获取羁绊效果
	var effects = synergy_config.get_effects_for_level(new_level)

	# 使用新的羁绊效果处理器应用效果
	var target_pieces = [owner]
	SynergyEffectProcessor.apply_synergy_effects(synergy_type, new_level, effects, target_pieces)

# 移除羁绊效果
func _remove_synergy_effects(synergy_type: String, level: int) -> void:
	# 如果没有该羁绊类型，不做任何操作
	if not synergy_types.has(synergy_type):
		return

	# 获取羁绊配置
	var synergy_config = GameManager.synergy_manager.get_synergy_config(synergy_type)
	if not synergy_config:
		return

	# 获取羁绊效果
	var effects = synergy_config.get_effects_for_level(level)

	# 使用新的羁绊效果处理器移除效果
	var target_pieces = [owner]
	SynergyEffectProcessor.remove_synergy_effects(synergy_type, level, effects, target_pieces)

# 从字典初始化羁绊
func initialize_from_dict(data: Dictionary) -> void:
	# 清除现有羁绊
	for synergy_type in synergy_types.duplicate():
		remove_synergy_type(synergy_type)

	# 添加新羁绊
	for synergy_type in data:
		add_synergy_type(synergy_type)
		set_synergy_level(synergy_type, data[synergy_type])

# 获取羁绊数据
func get_synergy_data() -> Dictionary:
	return synergy_levels.duplicate()
