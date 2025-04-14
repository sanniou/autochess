extends Node
## 随机工具
## 提供高级随机数生成和随机选择功能

# 随机数生成器
var _rng = RandomNumberGenerator.new()

# 当前种子
var current_seed: int = 0

func _ready():
	# 初始化随机数生成器
	randomize_seed()

## 设置随机种子
func set_seed(new_seed: int) -> void:
	current_seed = new_seed
	_rng.seed = new_seed

## 随机化种子
func randomize_seed() -> void:
	_rng.randomize()
	current_seed = _rng.seed

## 获取当前种子
func get_seed() -> int:
	return current_seed

## 生成随机整数
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

## 生成随机浮点数
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

## 生成随机布尔值
func randf_bool(probability: float = 0.5) -> bool:
	return _rng.randf() < probability

## 从数组中随机选择一个元素
func choose(array: Array):
	if array.size() == 0:
		return null
	
	var index = randi_range(0, array.size() - 1)
	return array[index]

## 从数组中随机选择多个元素（不重复）
func choose_multiple(array: Array, count: int) -> Array:
	if array.size() == 0 or count <= 0:
		return []
	
	# 限制选择数量不超过数组大小
	count = min(count, array.size())
	
	var shuffled = array.duplicate()
	shuffled.shuffle()
	
	return shuffled.slice(0, count)

## 从带权重的数组中随机选择一个元素
## items格式: [{item: 物品, weight: 权重}, ...]
func weighted_choice(items: Array):
	if items.size() == 0:
		return null
	
	var total_weight = 0
	for item_data in items:
		total_weight += item_data.weight
	
	var random_value = randf_range(0, total_weight)
	var current_weight = 0
	
	for item_data in items:
		current_weight += item_data.weight
		if random_value <= current_weight:
			return item_data.item
	
	return items[items.size() - 1].item

## 从带权重的数组中随机选择多个元素（不重复）
## items格式: [{item: 物品, weight: 权重}, ...]
func weighted_choose_multiple(items: Array, count: int) -> Array:
	if items.size() == 0 or count <= 0:
		return []
	
	# 限制选择数量不超过数组大小
	count = min(count, items.size())
	
	var result = []
	var remaining_items = items.duplicate()
	
	for i in range(count):
		if remaining_items.size() == 0:
			break
		
		var chosen = weighted_choice(remaining_items)
		result.append(chosen)
		
		# 从剩余项中移除已选择的项
		for j in range(remaining_items.size() - 1, -1, -1):
			if remaining_items[j].item == chosen:
				remaining_items.remove_at(j)
				break
	
	return result

## 洗牌数组
func shuffle(array: Array) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled

## 生成随机字符串
func random_string(length: int, chars: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String:
	var result = ""
	for i in range(length):
		var index = randi_range(0, chars.length() - 1)
		result += chars[index]
	
	return result

## 生成随机颜色
func random_color(alpha: float = 1.0) -> Color:
	return Color(
		_rng.randf(),
		_rng.randf(),
		_rng.randf(),
		alpha
	)

## 生成随机向量2D
func random_vector2(min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	return Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)

## 生成随机单位向量2D
func random_unit_vector2() -> Vector2:
	var angle = randf_range(0, TAU)
	return Vector2(cos(angle), sin(angle))

## 生成随机向量3D
func random_vector3(min_x: float, max_x: float, min_y: float, max_y: float, min_z: float, max_z: float) -> Vector3:
	return Vector3(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y),
		randf_range(min_z, max_z)
	)

## 生成随机单位向量3D
func random_unit_vector3() -> Vector3:
	var theta = randf_range(0, TAU)
	var phi = acos(randf_range(-1, 1))
	
	var x = sin(phi) * cos(theta)
	var y = sin(phi) * sin(theta)
	var z = cos(phi)
	
	return Vector3(x, y, z)

## 生成高斯分布的随机数
func random_gaussian(mean: float = 0.0, std_dev: float = 1.0) -> float:
	# Box-Muller变换
	var u1 = _rng.randf()
	var u2 = _rng.randf()
	
	while u1 <= 0.0001:
		u1 = _rng.randf()
	
	var z0 = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + z0 * std_dev

## 生成泊松分布的随机数
func random_poisson(lambda: float) -> int:
	var L = exp(-lambda)
	var k = 0
	var p = 1.0
	
	while p > L:
		k += 1
		p *= _rng.randf()
	
	return k - 1

## 生成指数分布的随机数
func random_exponential(lambda: float) -> float:
	return -log(_rng.randf()) / lambda

## 生成二项分布的随机数
func random_binomial(n: int, p: float) -> int:
	var result = 0
	for i in range(n):
		if _rng.randf() < p:
			result += 1
	
	return result

## 生成随机UUID
func generate_uuid() -> String:
	var uuid = ""
	
	for i in range(32):
		var random_char = randi_range(0, 15)
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid += "-"
		
		if i == 12:
			uuid += "4"  # 版本4 UUID
		elif i == 16:
			uuid += "89ab"[randi_range(0, 3)]  # 变体
		else:
			uuid += "0123456789abcdef"[random_char]
	
	return uuid
