extends Resource
class_name BattleCommand
## 战斗命令基类
## 所有战斗命令的基类，定义了命令的基本接口

# 引入战斗常量
const BC = preload("res://scripts/game/battle/battle_constants.gd")

# 命令属性
var command_type: int = BC.CommandType.MOVE
var source = null  # 命令来源
var target = null  # 命令目标
var params: Dictionary = {}  # 命令参数
var timestamp: int = 0  # 命令时间戳

# 初始化
func _init(type: int, src = null, tgt = null, cmd_params: Dictionary = {}) -> void:
	command_type = type
	source = src
	target = tgt
	params = cmd_params
	timestamp = Time.get_ticks_msec()

# 执行命令
func execute() -> Dictionary:
	# 基类不实现具体逻辑，由子类重写
	return {
		"success": false,
		"message": "Command not implemented"
	}

# 撤销命令
func undo() -> Dictionary:
	# 基类不实现具体逻辑，由子类重写
	return {
		"success": false,
		"message": "Undo not implemented"
	}

# 获取命令类型
func get_command_type() -> int:
	return command_type

# 获取命令来源
func get_source():
	return source

# 获取命令目标
func get_target():
	return target

# 获取命令参数
func get_params() -> Dictionary:
	return params

# 获取命令时间戳
func get_timestamp() -> int:
	return timestamp

# 获取命令描述
func get_description() -> String:
	var type_str = ""
	match command_type:
		BC.CommandType.MOVE: type_str = "移动"
		BC.CommandType.ATTACK: type_str = "攻击"
		BC.CommandType.ABILITY: type_str = "技能"
		BC.CommandType.EFFECT: type_str = "效果"
		BC.CommandType.SPAWN: type_str = "生成"
		BC.CommandType.REMOVE: type_str = "移除"
		BC.CommandType.STAT_CHANGE: type_str = "属性变化"

	var source_name = "未知"
	if source and source.has_method("get_display_name"):
		source_name = source.get_display_name()

	var target_name = "未知"
	if target and target.has_method("get_display_name"):
		target_name = target.get_display_name()

	return "%s: %s -> %s" % [type_str, source_name, target_name]

# 序列化命令
func serialize() -> Dictionary:
	var data = {
		"command_type": command_type,
		"params": params,
		"timestamp": timestamp
	}

	# 序列化来源和目标
	if source and source.has_method("get_id"):
		data["source_id"] = source.get_id()

	if target and target.has_method("get_id"):
		data["target_id"] = target.get_id()

	return data

# 从序列化数据创建命令
static func deserialize(data: Dictionary, entity_resolver = null) -> BattleCommand:
	var command_type = data.get("command_type", BattleConstants.CommandType.MOVE)
	var params = data.get("params", {})
	var timestamp = data.get("timestamp", 0)

	var source = null
	var target = null

	# 解析来源和目标
	if entity_resolver:
		if data.has("source_id"):
			source = entity_resolver.resolve_entity(data.source_id)

		if data.has("target_id"):
			target = entity_resolver.resolve_entity(data.target_id)

	# 创建命令
	var command = BattleCommand.new(command_type, source, target, params)
	command.timestamp = timestamp

	return command
