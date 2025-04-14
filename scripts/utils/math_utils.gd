extends Node
## 数学工具
## 提供常用的数学函数和算法

## 生成指定范围内的随机整数
static func random_int(min_value: int, max_value: int) -> int:
	return randi_range(min_value, max_value)

## 生成指定范围内的随机浮点数
static func random_float(min_value: float, max_value: float) -> float:
	return randf_range(min_value, max_value)

## 生成随机布尔值，带概率控制
static func random_bool(true_probability: float = 0.5) -> bool:
	return randf() < true_probability

## 从数组中随机选择一个元素
static func random_choice(array: Array):
	if array.size() == 0:
		return null
	
	var index = random_int(0, array.size() - 1)
	return array[index]

## 从带权重的数组中随机选择一个元素
## items格式: [{item: 物品, weight: 权重}, ...]
static func weighted_choice(items: Array):
	if items.size() == 0:
		return null
	
	var total_weight = 0
	for item_data in items:
		total_weight += item_data.weight
	
	var random_value = random_float(0, total_weight)
	var current_weight = 0
	
	for item_data in items:
		current_weight += item_data.weight
		if random_value <= current_weight:
			return item_data.item
	
	return items[items.size() - 1].item

## 计算两点间的距离
static func distance(point1: Vector2, point2: Vector2) -> float:
	return point1.distance_to(point2)

## 计算两点间的曼哈顿距离
static func manhattan_distance(point1: Vector2, point2: Vector2) -> float:
	return abs(point1.x - point2.x) + abs(point1.y - point2.y)

## 线性插值
static func lerp_value(start: float, end: float, t: float) -> float:
	return start + (end - start) * t

## 平滑插值（使用平方函数）
static func smooth_lerp(start: float, end: float, t: float) -> float:
	t = t * t * (3.0 - 2.0 * t)  # 平滑函数
	return start + (end - start) * t

## 角度插值（处理角度环绕）
static func lerp_angle(start_angle: float, end_angle: float, t: float) -> float:
	var diff = fmod(end_angle - start_angle + PI, TAU) - PI
	return start_angle + diff * t

## 将值限制在指定范围内
static func clamp_value(value: float, min_value: float, max_value: float) -> float:
	return clamp(value, min_value, max_value)

## 将值从一个范围映射到另一个范围
static func map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

## 计算数组的平均值
static func average(array: Array) -> float:
	if array.size() == 0:
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	
	return sum / array.size()

## 计算数组的中位数
static func median(array: Array):
	if array.size() == 0:
		return null
	
	var sorted_array = array.duplicate()
	sorted_array.sort()
	
	var middle = sorted_array.size() / 2
	if sorted_array.size() % 2 == 0:
		return (sorted_array[middle - 1] + sorted_array[middle]) / 2.0
	else:
		return sorted_array[middle]

## 计算数组的众数
static func mode(array: Array):
	if array.size() == 0:
		return null
	
	var counts = {}
	var max_count = 0
	var max_value = null
	
	for value in array:
		if not counts.has(value):
			counts[value] = 0
		
		counts[value] += 1
		
		if counts[value] > max_count:
			max_count = counts[value]
			max_value = value
	
	return max_value

## 计算数组的标准差
static func standard_deviation(array: Array) -> float:
	if array.size() <= 1:
		return 0.0
	
	var avg = average(array)
	var variance = 0.0
	
	for value in array:
		variance += pow(value - avg, 2)
	
	variance /= array.size()
	return sqrt(variance)

## 生成随机种子
static func generate_seed() -> int:
	return randi()

## 设置随机种子
static func set_seed(seed_value: int) -> void:
	seed(seed_value)

## 洗牌数组
static func shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled

## 计算两个向量的夹角（弧度）
static func angle_between(vec1: Vector2, vec2: Vector2) -> float:
	return vec1.angle_to(vec2)

## 将弧度转换为角度
static func rad_to_deg(radians: float) -> float:
	return radians * 180.0 / PI

## 将角度转换为弧度
static func deg_to_rad(degrees: float) -> float:
	return degrees * PI / 180.0

## 计算贝塞尔曲线点
static func bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

## 计算三次贝塞尔曲线点
static func cubic_bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)
	
	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)
	
	return r0.lerp(r1, t)

## 计算概率分布
static func probability_distribution(probabilities: Array) -> int:
	var total = 0.0
	for p in probabilities:
		total += p
	
	var r = randf() * total
	var cumulative = 0.0
	
	for i in range(probabilities.size()):
		cumulative += probabilities[i]
		if r <= cumulative:
			return i
	
	return probabilities.size() - 1
