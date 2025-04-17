extends Resource
class_name BattleResult
## 战斗结果
## 标准化的战斗结果数据结构

# 基本结果
var is_victory: bool = false

# 棋子统计
var player_pieces: Dictionary = {
	"initial": 0,    # 初始棋子数量
	"remaining": 0,  # 剩余棋子数量
	"lost": 0        # 损失棋子数量
}

var enemy_pieces: Dictionary = {
	"initial": 0,    # 初始棋子数量
	"remaining": 0,  # 剩余棋子数量
	"lost": 0        # 损失棋子数量
}

# 战斗信息
var battle_info: Dictionary = {
	"round": 1,           # 当前回合
	"difficulty": 1,      # 战斗难度
	"duration": 0.0,      # 战斗持续时间(秒)
	"map_node_id": ""     # 地图节点ID
}

# 战斗统计
var stats: Dictionary = {
	"damage_dealt": 0.0,  # 造成的伤害
	"damage_taken": 0.0,  # 受到的伤害
	"healing_done": 0.0,  # 治疗量
	"abilities_used": 0,  # 使用的技能数量
	"kills": 0,           # 击杀数
	"gold_earned": 0      # 获得的金币
}

# 奖励
var rewards: Dictionary = {
	"gold": 0,            # 金币奖励
	"exp": 0,             # 经验奖励
	"items": [],          # 物品奖励
	"chess_pieces": [],   # 棋子奖励
	"relics": []          # 遗物奖励
}

# 玩家影响
var player_impact: Dictionary = {
	"health_change": 0,   # 生命值变化
	"streak_change": 0    # 连胜/连败变化
}

## 初始化战斗结果
func _init(victory: bool = false) -> void:
	is_victory = victory

## 设置棋子统计
func set_pieces_stats(p_initial: int, p_remaining: int, e_initial: int, e_remaining: int) -> void:
	player_pieces.initial = p_initial
	player_pieces.remaining = p_remaining
	player_pieces.lost = p_initial - p_remaining
	
	enemy_pieces.initial = e_initial
	enemy_pieces.remaining = e_remaining
	enemy_pieces.lost = e_initial - e_remaining

## 设置战斗信息
func set_battle_info(round_num: int, diff: int, duration: float, node_id: String = "") -> void:
	battle_info.round = round_num
	battle_info.difficulty = diff
	battle_info.duration = duration
	battle_info.map_node_id = node_id

## 设置战斗统计
func set_stats(dmg_dealt: float, dmg_taken: float, healing: float, abilities: int, kills: int, gold: int) -> void:
	stats.damage_dealt = dmg_dealt
	stats.damage_taken = dmg_taken
	stats.healing_done = healing
	stats.abilities_used = abilities
	stats.kills = kills
	stats.gold_earned = gold

## 设置奖励
func set_rewards(gold: int, exp: int, items: Array = [], chess_pieces: Array = [], relics: Array = []) -> void:
	rewards.gold = gold
	rewards.exp = exp
	rewards.items = items
	rewards.chess_pieces = chess_pieces
	rewards.relics = relics

## 设置玩家影响
func set_player_impact(health_change: int, streak_change: int) -> void:
	player_impact.health_change = health_change
	player_impact.streak_change = streak_change

## 转换为字典
func to_dict() -> Dictionary:
	return {
		"is_victory": is_victory,
		"player_pieces": player_pieces.duplicate(),
		"enemy_pieces": enemy_pieces.duplicate(),
		"battle_info": battle_info.duplicate(),
		"stats": stats.duplicate(),
		"rewards": rewards.duplicate(),
		"player_impact": player_impact.duplicate()
	}

## 从字典创建
static func from_dict(dict: Dictionary) -> BattleResult:
	var result = BattleResult.new(dict.get("is_victory", false))
	
	# 设置棋子统计
	var p_pieces = dict.get("player_pieces", {})
	var e_pieces = dict.get("enemy_pieces", {})
	result.set_pieces_stats(
		p_pieces.get("initial", 0),
		p_pieces.get("remaining", 0),
		e_pieces.get("initial", 0),
		e_pieces.get("remaining", 0)
	)
	
	# 设置战斗信息
	var b_info = dict.get("battle_info", {})
	result.set_battle_info(
		b_info.get("round", 1),
		b_info.get("difficulty", 1),
		b_info.get("duration", 0.0),
		b_info.get("map_node_id", "")
	)
	
	# 设置战斗统计
	var b_stats = dict.get("stats", {})
	result.set_stats(
		b_stats.get("damage_dealt", 0.0),
		b_stats.get("damage_taken", 0.0),
		b_stats.get("healing_done", 0.0),
		b_stats.get("abilities_used", 0),
		b_stats.get("kills", 0),
		b_stats.get("gold_earned", 0)
	)
	
	# 设置奖励
	var b_rewards = dict.get("rewards", {})
	result.set_rewards(
		b_rewards.get("gold", 0),
		b_rewards.get("exp", 0),
		b_rewards.get("items", []),
		b_rewards.get("chess_pieces", []),
		b_rewards.get("relics", [])
	)
	
	# 设置玩家影响
	var p_impact = dict.get("player_impact", {})
	result.set_player_impact(
		p_impact.get("health_change", 0),
		p_impact.get("streak_change", 0)
	)
	
	return result

## 创建简单的战斗结果
static func create_simple(victory: bool, player_remaining: int = 0, enemy_remaining: int = 0) -> BattleResult:
	var result = BattleResult.new(victory)
	result.player_pieces.remaining = player_remaining
	result.enemy_pieces.remaining = enemy_remaining
	return result
