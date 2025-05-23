extends Control
## 羁绊信息界面
## 显示当前激活的羁绊和所有羁绊信息

# 引入羁绊常量
const SC = preload("res://scripts/game/synergy/synergy_constants.gd")

# 初始化
func _ready():
	# 更新界面
	_update_ui()

	# 连接信号
	GlobalEventBus.chess.add_listener("synergy_activated", _on_synergy_activated)
	GlobalEventBus.chess.add_listener("synergy_deactivated", _on_synergy_deactivated)
	GlobalEventBus.chess.add_listener("chess_piece_created", _on_chess_piece_created)
	GlobalEventBus.chess.add_listener("chess_piece_sold", _on_chess_piece_sold)

# 更新界面
func _update_ui():
	# 更新激活的羁绊
	_update_active_synergies()

	# 更新所有羁绊
	_update_all_synergies()

# 更新激活的羁绊
func _update_active_synergies():
	# 获取激活的羁绊
	var active_synergies = GameManager.synergy_manager.get_active_synergies()

	# 获取羁绊配置
	var synergy_configs = GameManager.synergy_manager.get_all_synergy_configs()

	# 获取羁绊计数
	var synergy_counts = _get_synergy_counts()

	# 清空激活羁绊列表
	var grid = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/ActiveSynergiesPanel/MarginContainer/VBoxContainer/ActiveSynergiesGrid
	for child in grid.get_children():
		child.queue_free()

	# 添加激活的羁绊
	for synergy_id in active_synergies:
		var level = active_synergies[synergy_id]
		var config = synergy_configs[synergy_id]
		var count = synergy_counts.get(synergy_id, 0)

		# 创建羁绊项
		var item = _create_synergy_item(synergy_id, config, level, count)
		grid.add_child(item)

# 更新所有羁绊
func _update_all_synergies():
	# 获取所有羁绊配置
	var synergy_configs = GameManager.synergy_manager.get_all_synergy_configs()

	# 获取激活的羁绊
	var active_synergies = GameManager.synergy_manager.get_active_synergies()

	# 获取羁绊计数
	var synergy_counts = _get_synergy_counts()

	# 清空所有羁绊列表
	var grid = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/VBoxContainer/AllSynergiesPanel/MarginContainer/VBoxContainer/AllSynergiesGrid
	for child in grid.get_children():
		child.queue_free()

	# 添加所有羁绊
	for synergy_id in synergy_configs:
		var config = synergy_configs[synergy_id]
		var level = active_synergies.get(synergy_id, 0)
		var count = synergy_counts.get(synergy_id, 0)

		# 创建羁绊项
		var item = _create_synergy_item(synergy_id, config, level, count)
		grid.add_child(item)

# 创建羁绊项
func _create_synergy_item(synergy_id, config, level, count):
	# 复制模板
	var template = $SynergyItemTemplate
	var item = template.duplicate()
	item.visible = true

	# 设置羁绊图标
	var icon = item.get_node("VBoxContainer/SynergyIcon")
	var icon_path = "res://assets/images/synergy/" + config.icon
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)

	# 设置羁绊名称
	var name_label = item.get_node("VBoxContainer/SynergyName")
	name_label.text = config.name

	# 设置羁绊等级
	var level_label = item.get_node("VBoxContainer/SynergyLevel")
	if level > 0:
		level_label.text = "等级: " + str(level)
		level_label.modulate = Color(0.2, 0.8, 0.2, 1.0)
	else:
		level_label.text = "未激活"
		level_label.modulate = Color(0.8, 0.2, 0.2, 1.0)

	# 设置羁绊描述
	var desc_label = item.get_node("VBoxContainer/SynergyDesc")
	desc_label.text = config.description

	# 设置羁绊数量
	var count_label = item.get_node("VBoxContainer/SynergyCountLabel")

	# 获取下一个激活等级所需数量
	var next_level_count = _get_next_level_count(config, level)
	if next_level_count > 0:
		count_label.text = "数量: " + str(count) + "/" + str(next_level_count)

		# 设置颜色
		if count >= next_level_count:
			count_label.modulate = Color(0.2, 0.8, 0.2, 1.0)
		else:
			count_label.modulate = Color(0.8, 0.2, 0.2, 1.0)
	else:
		count_label.text = "数量: " + str(count) + " (最高等级)"
		count_label.modulate = Color(0.2, 0.8, 0.2, 1.0)

	return item

# 获取下一个激活等级所需数量
func _get_next_level_count(config, current_level):
	# 获取阈值数组
	var thresholds = config.get_thresholds()
	if thresholds.is_empty():
		return 0

	# 获取当前阈值
	var current_threshold = null
	var next_threshold = null

	# 查找当前阈值和下一个阈值
	for i in range(thresholds.size()):
		var threshold = thresholds[i]
		if not threshold.has("count"):
			continue

		# 如果当前等级为0，返回第一个阈值
		if current_level == 0:
			return threshold.count

		# 如果找到当前阈值
		if current_threshold == null and threshold.count <= current_level:
			current_threshold = threshold

			# 尝试获取下一个阈值
			if i + 1 < thresholds.size():
				next_threshold = thresholds[i + 1]
				break

	# 如果找到下一个阈值，返回其count
	if next_threshold != null and next_threshold.has("count"):
		return next_threshold.count

	# 如果没有下一个阈值，返回0表示已达到最高等级
	return 0

# 获取羁绊计数
func _get_synergy_counts():
	var counts = {}

	# 获取当前玩家
	var player = GameManager.player_manager.get_current_player()
	if not player:
		return counts

	# 统计场上棋子的羁绊
	for piece in player.chess_pieces:
		for synergy in piece.synergies:
			if not counts.has(synergy):
				counts[synergy] = 0
			counts[synergy] += 1

	# 统计备战区棋子的羁绊
	for piece in player.bench_pieces:
		for synergy in piece.synergies:
			if not counts.has(synergy):
				counts[synergy] = 0
			counts[synergy] += 1

	return counts

# 关闭按钮处理
func _on_close_button_pressed():
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 羁绊激活事件处理
func _on_synergy_activated(synergy_id, level):
	# 更新界面
	_update_ui()

# 羁绊失效事件处理
func _on_synergy_deactivated(synergy_id):
	# 更新界面
	_update_ui()

# 棋子创建事件处理
func _on_chess_piece_created(piece):
	# 更新界面
	_update_ui()

# 棋子出售事件处理
func _on_chess_piece_sold(piece):
	# 更新界面
	_update_ui()
