extends Node
class_name VisualRegistry
## 视觉效果注册表
## 负责注册和管理视觉效果定义

# 效果定义字典 {效果名称: 效果定义}
var _effect_definitions: Dictionary = {}

# 初始化
func _init() -> void:
	# 注册预定义效果
	_register_predefined_effects()

# 注册预定义效果
func _register_predefined_effects() -> void:
	# 注册通用伤害效果
	register_effect("damage", {
		"type": "combined",
		"duration": 0.8,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "blood",
					"amount": 12,
					"duration": 0.5,
					"explosiveness": 0.8,
					"randomness": 0.5,
					"color": Color(0.8, 0.0, 0.0, 0.9)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册物理伤害效果
	register_effect("damage_physical", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "blood",
					"amount": 10,
					"duration": 0.3,
					"color": Color(1, 0.2, 0.2, 0.8),
					"spread": 180.0,
					"speed": 100.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册魔法伤害效果
	register_effect("damage_magical", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "magic",
					"amount": 15,
					"duration": 0.3,
					"color": Color(0.2, 0.2, 1, 0.8),
					"spread": 360.0,
					"speed": 80.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/magic_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册火焰伤害效果
	register_effect("damage_fire", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "fire",
					"amount": 20,
					"duration": 0.4,
					"color": Color(1, 0.5, 0, 0.8),
					"spread": 180.0,
					"speed": 120.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/fire_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.8, 1.8)
				}
			}
		]
	})

	# 注册冰冻伤害效果
	register_effect("damage_ice", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "ice",
					"amount": 15,
					"duration": 0.4,
					"color": Color(0, 0.8, 1, 0.8),
					"spread": 180.0,
					"speed": 80.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/ice_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.6, 1.6)
				}
			}
		]
	})

	# 注册闪电伤害效果
	register_effect("damage_lightning", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "lightning",
					"amount": 12,
					"duration": 0.3,
					"color": Color(1, 1, 0, 0.8),
					"spread": 360.0,
					"speed": 150.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/lightning_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.7, 1.7)
				}
			}
		]
	})

	# 注册毒素伤害效果
	register_effect("damage_poison", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "poison",
					"amount": 15,
					"duration": 0.4,
					"color": Color(0, 0.8, 0, 0.8),
					"spread": 180.0,
					"speed": 70.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/poison_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册真实伤害效果
	register_effect("damage_true", {
		"type": "combined",
		"duration": 0.5,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "sparkle",
					"amount": 20,
					"duration": 0.3,
					"color": Color(1, 1, 1, 0.8),
					"spread": 360.0,
					"speed": 130.0
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/true_hit.png",
					"duration": 0.3,
					"fade_in": 0.05,
					"fade_out": 0.1,
					"scale": Vector2(2.0, 2.0)
				}
			}
		]
	})

	# 注册暴击效果
	register_effect("critical", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "blood",
					"amount": 20,
					"duration": 0.7,
					"explosiveness": 0.9,
					"randomness": 0.6,
					"color": Color(1.0, 0.0, 0.0, 1.0)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/critical.png",
					"duration": 0.5,
					"fade_in": 0.05,
					"fade_out": 0.2,
					"scale": Vector2(2.0, 2.0)
				}
			},
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "sparkle",
					"amount": 15,
					"duration": 0.8,
					"explosiveness": 0.7,
					"randomness": 0.5,
					"color": Color(1.0, 0.8, 0.0, 1.0)
				}
			}
		]
	})

	# 注册治疗效果
	register_effect("heal", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "heal",
					"amount": 15,
					"duration": 0.8,
					"explosiveness": 0.5,
					"randomness": 0.5,
					"color": Color(0.0, 1.0, 0.0, 0.8)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/heal.png",
					"duration": 0.6,
					"fade_in": 0.1,
					"fade_out": 0.3,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册眩晕效果
	register_effect("stun", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "sprite",
				"position": Vector2(0, -30),
				"params": {
					"texture_path": "res://assets/textures/effects/stun.png",
					"duration": 1.0,
					"fade_in": 0.1,
					"fade_out": 0.1,
					"scale": Vector2(1.0, 1.0)
				}
			},
			{
				"type": "particle",
				"position": Vector2(0, -20),
				"params": {
					"particle_type": "sparkle",
					"amount": 8,
					"duration": 1.0,
					"explosiveness": 0.0,
					"randomness": 0.5,
					"color": Color(1.0, 1.0, 0.0, 0.8)
				}
			}
		]
	})

	# 注册沉默效果
	register_effect("silence", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "sprite",
				"position": Vector2(0, -30),
				"params": {
					"texture_path": "res://assets/textures/effects/silence.png",
					"duration": 1.0,
					"fade_in": 0.1,
					"fade_out": 0.1,
					"scale": Vector2(1.0, 1.0)
				}
			}
		]
	})

	# 注册燃烧效果
	register_effect("burning", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "fire",
					"amount": 20,
					"duration": 1.0,
					"explosiveness": 0.0,
					"randomness": 0.5,
					"color": Color(1.0, 0.5, 0.0, 0.8)
				}
			}
		]
	})

	# 注册中毒效果
	register_effect("poisoned", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "smoke",
					"amount": 15,
					"duration": 1.0,
					"explosiveness": 0.0,
					"randomness": 0.5,
					"color": Color(0.0, 0.8, 0.0, 0.7)
				}
			}
		]
	})

	# 注册护盾效果
	register_effect("shield", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/shield.png",
					"duration": 1.0,
					"fade_in": 0.2,
					"fade_out": 0.2,
					"scale": Vector2(1.5, 1.5)
				}
			},
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "sparkle",
					"amount": 10,
					"duration": 1.0,
					"explosiveness": 0.0,
					"randomness": 0.5,
					"color": Color(0.2, 0.6, 1.0, 0.8)
				}
			}
		]
	})

	# 注册爆炸效果
	register_effect("explosion", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "explosion",
					"amount": 30,
					"duration": 0.8,
					"explosiveness": 0.9,
					"randomness": 0.5,
					"color": Color(1.0, 0.5, 0.0, 1.0)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/explosion.png",
					"duration": 0.5,
					"fade_in": 0.05,
					"fade_out": 0.2,
					"scale": Vector2(2.0, 2.0)
				}
			}
		]
	})

	# 注册增益效果
	register_effect("buff", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "sparkle",
					"amount": 15,
					"duration": 0.8,
					"explosiveness": 0.5,
					"randomness": 0.5,
					"color": Color(0.0, 0.8, 0.8, 0.8)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/buff.png",
					"duration": 0.6,
					"fade_in": 0.1,
					"fade_out": 0.3,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册减益效果
	register_effect("debuff", {
		"type": "combined",
		"duration": 1.0,
		"sub_effects": [
			{
				"type": "particle",
				"position": Vector2.ZERO,
				"params": {
					"particle_type": "smoke",
					"amount": 15,
					"duration": 0.8,
					"explosiveness": 0.5,
					"randomness": 0.5,
					"color": Color(0.8, 0.0, 0.8, 0.8)
				}
			},
			{
				"type": "sprite",
				"position": Vector2.ZERO,
				"params": {
					"texture_path": "res://assets/textures/effects/debuff.png",
					"duration": 0.6,
					"fade_in": 0.1,
					"fade_out": 0.3,
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

# 注册效果
func register_effect(effect_name: String, effect_definition: Dictionary) -> void:
	_effect_definitions[effect_name] = effect_definition

# 注销效果
func unregister_effect(effect_name: String) -> bool:
	if not _effect_definitions.has(effect_name):
		return false

	_effect_definitions.erase(effect_name)
	return true

# 获取效果定义
func get_effect_definition(effect_name: String) -> Dictionary:
	if not _effect_definitions.has(effect_name):
		return {}

	return _effect_definitions[effect_name].duplicate(true)

# 获取所有效果名称
func get_all_effect_names() -> Array:
	return _effect_definitions.keys()

# 获取所有效果定义
func get_all_effect_definitions() -> Dictionary:
	return _effect_definitions.duplicate(true)

# 从文件加载效果定义
func load_effect_definitions_from_file(file_path: String) -> bool:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("VisualRegistry: 效果定义文件不存在: " + file_path)
		return false

	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("VisualRegistry: 无法打开效果定义文件: " + file_path)
		return false

	# 读取文件内容
	var json_text = file.get_as_text()

	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("VisualRegistry: 解析效果定义文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return false

	# 获取解析结果
	var effect_defs = json.get_data()

	# 检查结果是否是字典
	if not effect_defs is Dictionary:
		print("VisualRegistry: 效果定义文件格式错误，应为字典")
		return false

	# 注册效果
	for effect_name in effect_defs:
		register_effect(effect_name, effect_defs[effect_name])

	return true

# 保存效果定义到文件
func save_effect_definitions_to_file(file_path: String) -> bool:
	# 创建JSON文本
	var json_text = JSON.stringify(_effect_definitions, "\t")

	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("VisualRegistry: 无法打开效果定义文件进行写入: " + file_path)
		return false

	# 写入文件
	file.store_string(json_text)

	return true
