extends RefCounted
class_name ShopConstants
## 商店常量
## 定义商店系统中使用的所有常量

# 商店类型
enum ShopType {
	CHESS,      # 棋子商店
	EQUIPMENT,  # 装备商店
	RELIC,      # 遗物商店
	EXP,        # 经验商店
	BLACK_MARKET, # 黑市
	MYSTERY_SHOP, # 神秘商店
	CONSUMABLE, 消耗品
}

# 商店触发概率
const BLACK_MARKET_CHANCE = 0.35  # 黑市触发概率
const MYSTERY_SHOP_CHANCE = 0.40  # 神秘商店触发概率

# 商店触发回合
const EQUIPMENT_SHOP_ROUNDS = [3, 6, 9]  # 装备商店触发回合
const RELIC_SHOP_ROUNDS = [5, 10]        # 遗物商店触发回合

# 商店物品数量
const DEFAULT_CHESS_ITEMS = 5      # 默认棋子商店物品数量
const DEFAULT_EQUIPMENT_ITEMS = 3  # 默认装备商店物品数量
const DEFAULT_RELIC_ITEMS = 3      # 默认遗物商店物品数量
const SPECIAL_EQUIPMENT_ITEMS = 6  # 特殊装备商店物品数量
const SPECIAL_RELIC_ITEMS = 4      # 特殊遗物商店物品数量

# 折扣相关
const DEFAULT_DISCOUNT = 1.0       # 默认折扣（无折扣）
const NODE_DISCOUNT = 0.8          # 商店节点折扣（80%）
const BLACK_MARKET_MIN_DISCOUNT = 0.6  # 黑市最小折扣（60%）
const BLACK_MARKET_MAX_DISCOUNT = 0.8  # 黑市最大折扣（80%）

# 保底机制
const PITY_THRESHOLD = 3  # 保底触发阈值（连续刷新次数）

# 特殊物品
const SPECIAL_ITEMS = [
	"equipment_disassembler",  # 装备分解券
	"chess_transformer",       # 棋子改造卷轴
	"refresh_token",          # 免费刷新令牌
	"exp_potion"              # 经验药水
]

# 特殊物品数量
const MIN_SPECIAL_ITEMS = 1  # 最小特殊物品数量
const MAX_SPECIAL_ITEMS = 2  # 最大特殊物品数量
const SPECIAL_ITEM_CHANCE = 0.5  # 额外特殊物品概率
