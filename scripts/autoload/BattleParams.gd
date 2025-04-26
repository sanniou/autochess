class_name BattleParams
extends Resource

# 基本战斗参数
@export var difficulty: float = 1.0
@export var enemy_level: int = 1
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var is_challenge: bool = false

# 特殊参数
@export var boss_id: String = ""
@export var challenge_type: String = ""

# 奖励
@export var rewards: Dictionary = {}
