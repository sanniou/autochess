extends RefCounted
class_name BattleConstants
## 战斗常量
## 定义战斗系统中使用的所有常量

# 战斗状态枚举
enum BattleState {
	INACTIVE,   # 未激活
	PREPARING,  # 准备中
	ACTIVE,     # 战斗中
	PAUSED,     # 暂停
	ENDED       # 已结束
}

# 战斗阶段枚举
enum BattlePhase {
	SETUP,      # 设置阶段
	PREPARE,    # 准备阶段
	COMBAT,     # 战斗阶段
	RESOLUTION, # 结算阶段
	CLEANUP     # 清理阶段
}

# 战斗配置默认值
const DEFAULT_PREPARE_TIME = 30.0   # 准备时间(秒)
const DEFAULT_BATTLE_TIME = 90.0    # 战斗时间(秒)
const DEFAULT_RESOLUTION_TIME = 5.0 # 结算时间(秒)
const DEFAULT_BATTLE_SPEED = 1.0    # 默认战斗速度
const MIN_BATTLE_SPEED = 0.5        # 最小战斗速度
const MAX_BATTLE_SPEED = 3.0        # 最大战斗速度

# AI难度枚举
enum AIDifficulty {
	EASY,    # 简单
	NORMAL,  # 普通
	HARD,    # 困难
	EXPERT   # 专家
}

# AI行为类型枚举
enum AIBehavior {
	RANDOM,     # 随机行为
	AGGRESSIVE, # 激进行为
	DEFENSIVE,  # 防御行为
	BALANCED,   # 平衡行为
	TACTICAL    # 战术行为
}

# 命令类型枚举
enum CommandType {
	MOVE,       # 移动命令
	ATTACK,     # 攻击命令
	ABILITY,    # 技能命令
	EFFECT,     # 效果命令
	SPAWN,      # 生成命令
	REMOVE,     # 移除命令
	STAT_CHANGE # 属性变化命令
}

# 伤害类型
enum DamageType {
	PHYSICAL,   # 物理伤害
	MAGICAL,    # 魔法伤害
	TRUE,       # 真实伤害
	ELEMENTAL   # 元素伤害
}

# 战斗事件类型
const EVENT_BATTLE_STARTED = "battle_started"
const EVENT_BATTLE_ENDED = "battle_ended"
const EVENT_BATTLE_PAUSED = "battle_paused"
const EVENT_BATTLE_RESUMED = "battle_resumed"
const EVENT_PREPARE_PHASE_STARTED = "prepare_phase_started"
const EVENT_COMBAT_PHASE_STARTED = "combat_phase_started"
const EVENT_RESOLUTION_PHASE_STARTED = "resolution_phase_started"
const EVENT_CLEANUP_PHASE_STARTED = "cleanup_phase_started"
const EVENT_ROUND_STARTED = "round_started"
const EVENT_ROUND_ENDED = "round_ended"
const EVENT_UNIT_DIED = "unit_died"
const EVENT_DAMAGE_DEALT = "damage_dealt"
const EVENT_HEALING_DONE = "healing_done"
const EVENT_ABILITY_USED = "ability_used"
const EVENT_BATTLE_SPEED_CHANGED = "battle_speed_changed"
