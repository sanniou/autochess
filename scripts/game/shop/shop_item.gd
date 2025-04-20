extends RefCounted
class_name ShopItem
## 商店物品基类
## 定义商店物品的通用接口

# 物品类型
enum ItemType {
	CHESS,      # 棋子
	EQUIPMENT,  # 装备
	RELIC,      # 遗物
	CONSUMABLE, # 消耗品
}

# 物品属性
var id: String
var type: ItemType
var name: String
var description: String
var cost: int
var rarity: int
var icon: String
var data: Dictionary

# 初始化
func _init(item_data: Dictionary):
	# 设置基本属性
	id = item_data.get("id", "")
	name = item_data.get("name", "")
	description = item_data.get("description", "")
	cost = item_data.get("cost", 0)
	rarity = item_data.get("rarity", 0)
	icon = item_data.get("icon", "")
	data = item_data
	
	# 设置物品类型
	if item_data.has("type"):
		match item_data.type:
			"chess", "chess_piece":
				type = ItemType.CHESS
			"equipment":
				type = ItemType.EQUIPMENT
			"relic":
				type = ItemType.RELIC
			"consumable":
				type = ItemType.CONSUMABLE
			_:
				type = ItemType.CHESS

# 获取物品数据
func get_data() -> Dictionary:
	return data

# 获取物品类型
func get_type() -> ItemType:
	return type

# 获取物品ID
func get_id() -> String:
	return id

# 获取物品名称
func get_name() -> String:
	return name

# 获取物品描述
func get_description() -> String:
	return description

# 获取物品价格
func get_cost() -> int:
	return cost

# 获取物品稀有度
func get_rarity() -> int:
	return rarity

# 获取物品图标
func get_icon() -> String:
	return icon

# 设置物品价格
func set_cost(new_cost: int) -> void:
	cost = new_cost
