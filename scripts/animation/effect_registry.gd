extends Node
class_name EffectRegistry
## 特效注册系统
## 负责管理和注册游戏中的各种特效
## 提供统一的特效配置和播放接口

# 特效类型
enum EffectType {
	PARTICLE,  # 粒子特效
	SPRITE,    # 精灵特效
	COMBINED,  # 组合特效
	SHADER     # 着色器特效
}

# 特效配置
var effect_configs = {}

# 初始化
func _init() -> void:
	# 注册默认特效
	_register_default_effects()

# 注册默认特效
func _register_default_effects() -> void:
	# 注册攻击特效
	register_effect("physical_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "hit_particles",
				"duration": 0.3,
				"params": {
					"amount": 10,
					"lifetime": 0.3,
					"color": Color(1, 0.2, 0.2, 0.8),
					"spread": 180.0,
					"speed": 100.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/hit.png",
				"frame_count": 4,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	register_effect("magical_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "magic_particles",
				"duration": 0.3,
				"params": {
					"amount": 15,
					"lifetime": 0.3,
					"color": Color(0.2, 0.2, 1, 0.8),
					"spread": 360.0,
					"speed": 80.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/magic_hit.png",
				"frame_count": 5,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	register_effect("fire_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "fire_particles",
				"duration": 0.4,
				"params": {
					"amount": 20,
					"lifetime": 0.4,
					"color": Color(1, 0.5, 0, 0.8),
					"spread": 180.0,
					"speed": 120.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/fire_hit.png",
				"frame_count": 6,
				"frame_duration": 0.08,
				"params": {
					"scale": Vector2(1.8, 1.8)
				}
			}
		]
	})

	register_effect("ice_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "ice_particles",
				"duration": 0.4,
				"params": {
					"amount": 15,
					"lifetime": 0.4,
					"color": Color(0, 0.8, 1, 0.8),
					"spread": 180.0,
					"speed": 80.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/ice_hit.png",
				"frame_count": 5,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.6, 1.6)
				}
			}
		]
	})

	register_effect("lightning_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "lightning_particles",
				"duration": 0.3,
				"params": {
					"amount": 12,
					"lifetime": 0.3,
					"color": Color(1, 1, 0, 0.8),
					"spread": 360.0,
					"speed": 150.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/lightning_hit.png",
				"frame_count": 4,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.7, 1.7)
				}
			}
		]
	})

	register_effect("poison_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "poison_particles",
				"duration": 0.4,
				"params": {
					"amount": 15,
					"lifetime": 0.4,
					"color": Color(0, 0.8, 0, 0.8),
					"spread": 180.0,
					"speed": 70.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/poison_hit.png",
				"frame_count": 5,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	register_effect("true_hit", EffectType.COMBINED, {
		"duration": 0.5,
		"effects": [
			{
				"type": "particle",
				"name": "true_damage_particles",
				"duration": 0.3,
				"params": {
					"amount": 20,
					"lifetime": 0.3,
					"color": Color(1, 1, 1, 0.8),
					"spread": 360.0,
					"speed": 130.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/true_hit.png",
				"frame_count": 6,
				"frame_duration": 0.08,
				"params": {
					"scale": Vector2(2.0, 2.0)
				}
			}
		]
	})

	# 注册状态特效
	register_effect("buff", EffectType.COMBINED, {
		"duration": 1.0,
		"effects": [
			{
				"type": "particle",
				"name": "buff_particles",
				"duration": 0.8,
				"params": {
					"amount": 15,
					"lifetime": 0.8,
					"color": Color(0, 0.8, 0.8, 0.8),
					"spread": 180.0,
					"speed": 50.0,
					"direction": Vector2(0, -1)
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/buff.png",
				"frame_count": 8,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	register_effect("debuff", EffectType.COMBINED, {
		"duration": 1.0,
		"effects": [
			{
				"type": "particle",
				"name": "debuff_particles",
				"duration": 0.8,
				"params": {
					"amount": 15,
					"lifetime": 0.8,
					"color": Color(0.8, 0, 0.8, 0.8),
					"spread": 180.0,
					"speed": 50.0,
					"direction": Vector2(0, -1)
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/debuff.png",
				"frame_count": 8,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.5, 1.5)
				}
			}
		]
	})

	# 注册其他特效
	register_effect("heal", EffectType.COMBINED, {
		"duration": 1.0,
		"effects": [
			{
				"type": "particle",
				"name": "heal_particles",
				"duration": 0.8,
				"params": {
					"amount": 20,
					"lifetime": 0.8,
					"color": Color(0, 0.8, 0, 0.8),
					"spread": 180.0,
					"speed": 60.0,
					"direction": Vector2(0, -1)
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/heal.png",
				"frame_count": 8,
				"frame_duration": 0.1,
				"params": {
					"scale": Vector2(1.8, 1.8)
				}
			}
		]
	})

	register_effect("level_up", EffectType.COMBINED, {
		"duration": 1.5,
		"effects": [
			{
				"type": "particle",
				"name": "level_up_particles",
				"duration": 1.2,
				"params": {
					"amount": 30,
					"lifetime": 1.2,
					"color": Color(1, 0.8, 0, 0.8),
					"spread": 360.0,
					"speed": 80.0,
					"direction": Vector2(0, -1)
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/level_up.png",
				"frame_count": 10,
				"frame_duration": 0.15,
				"params": {
					"scale": Vector2(2.0, 2.0)
				}
			}
		]
	})

	register_effect("death", EffectType.COMBINED, {
		"duration": 1.0,
		"effects": [
			{
				"type": "particle",
				"name": "death_particles",
				"duration": 0.8,
				"params": {
					"amount": 25,
					"lifetime": 0.8,
					"color": Color(0.3, 0.3, 0.3, 0.8),
					"spread": 360.0,
					"speed": 70.0
				}
			},
			{
				"type": "sprite",
				"texture_path": "res://assets/images/vfx/death.png",
				"frame_count": 8,
				"frame_duration": 0.12,
				"params": {
					"scale": Vector2(2.0, 2.0)
				}
			}
		]
	})

# 注册特效
func register_effect(effect_name: String, effect_type: int, config: Dictionary) -> void:
	effect_configs[effect_name] = {
		"type": effect_type,
		"config": config
	}

# 获取特效配置
func get_effect_config(effect_name: String) -> Dictionary:
	if effect_configs.has(effect_name):
		return effect_configs[effect_name].duplicate(true)
	return {}

# 播放特效
func play_effect(effect_animator: VisualEffectAnimator, position: Vector2, effect_name: String, params: Dictionary = {}) -> String:
	# 检查特效是否存在
	if not effect_configs.has(effect_name):
		print("EffectRegistry: 特效不存在: " + effect_name)
		return ""

	# 检查特效动画器是否有效
	if not effect_animator or not effect_animator.has_method("play_combined_effect"):
		print("EffectRegistry: 无效的特效动画器")
		return ""

	# 获取特效配置
	var effect_config = effect_configs[effect_name]

	# 合并参数
	var merged_params = effect_config.config.duplicate(true)
	for key in params:
		merged_params[key] = params[key]

	# 根据特效类型播放特效
	match effect_config.type:
		EffectType.PARTICLE:
			return effect_animator.play_particle_effect(
				position,
				effect_name,
				merged_params.get("duration", 1.0),
				merged_params
			)
		EffectType.SPRITE:
			return effect_animator.play_sprite_effect(
				position,
				merged_params.get("texture_path", ""),
				merged_params.get("frame_count", 1),
				merged_params.get("frame_duration", 0.1),
				merged_params
			)
		EffectType.COMBINED:
			return effect_animator.play_combined_effect(
				position,
				effect_name,
				merged_params
			)
		EffectType.SHADER:
			if merged_params.has("target") and is_instance_valid(merged_params.target):
				return effect_animator.play_shader_effect(
					merged_params.target,
					merged_params.get("shader_path", ""),
					merged_params.get("duration", 1.0),
					merged_params
				)

	return ""
