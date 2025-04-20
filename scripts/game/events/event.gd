extends Node
class_name Event
## 事件基类
## 定义事件的基本属性和行为

# 信号
signal choice_made(choice_data)
signal event_completed(result_data)

# 事件属性
var id: String = ""                # 事件ID
var title: String = ""             # 事件标题
var description: String = ""       # 事件描述
var image_path: String = ""        # 事件图片路径
var choices: Array = []            # 事件选项
var requirements: Dictionary = {}  # 触发要求
var weight: int = 100              # 触发权重
var is_one_time: bool = false      # 是否为一次性事件
var is_completed: bool = false     # 是否已完成
var event_type: String = "normal"  # 事件类型(normal/battle/shop/treasure)

# 事件结果
var result: Dictionary = {}

# 视觉组件
var event_image: TextureRect
var choice_buttons: Array = []

func _ready():
	# 初始化视觉组件
	_initialize_visuals()

# 初始化事件
func initialize(event_data: Dictionary) -> void:
	id = event_data.id
	title = event_data.title
	description = event_data.description

	# 设置图片
	if event_data.has("image_path"):
		image_path = event_data.image_path
		_load_event_image()

	# 设置选项
	if event_data.has("choices"):
		choices = event_data.choices

	# 设置触发要求
	if event_data.has("requirements"):
		requirements = event_data.requirements

	# 设置其他属性
	if event_data.has("weight"):
		weight = event_data.weight

	if event_data.has("is_one_time"):
		is_one_time = event_data.is_one_time

	if event_data.has("event_type"):
		event_type = event_data.event_type

	# 更新视觉效果
	_update_visuals()

# 开始事件
func start() -> void:
	# 发送事件触发信号
	EventBus.event.emit_event("event_triggered", [self])

	# 显示事件界面
	_show_event_ui()

# 选择选项
func make_choice(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= choices.size():
		return

	var choice = choices[choice_index]

	# 处理选项效果
	_process_choice_effects(choice)

	# 发送选择信号
	choice_made.emit(choice)
	EventBus.event.emit_event("event_choice_made", [self, choice])

	# 完成事件
	complete(choice)

# 完成事件
func complete(choice_data: Dictionary = {}) -> void:
	is_completed = true

	# 设置结果
	result = {
		"event_id": id,
		"choice": choice_data,
		"rewards": _get_rewards(choice_data)
	}

	# 发送事件完成信号
	event_completed.emit(result)
	EventBus.event.emit_event("event_completed", [self, result])

	# 隐藏事件界面
	_hide_event_ui()

# 检查是否满足触发条件
func check_requirements(context: Dictionary = {}) -> bool:
	# 如果是一次性事件且已完成，则不触发
	if is_one_time and is_completed:
		return false

	# 如果没有要求，默认满足
	if requirements.is_empty():
		return true

	# 检查每个要求
	for req_type in requirements:
		var req_value = requirements[req_type]

		match req_type:
			"player_level":
				# 检查玩家等级
				if not context.has("player_level") or context.player_level < req_value:
					return false

			"gold_amount":
				# 检查金币数量
				if not context.has("gold") or context.gold < req_value:
					return false

			"health_percentage":
				# 检查生命值百分比
				if not context.has("health_percentage") or context.health_percentage < req_value:
					return false

			"synergy_active":
				# 检查羁绊是否激活
				if not context.has("active_synergies") or not context.active_synergies.has(req_value):
					return false

			"map_depth":
				# 检查地图深度
				if not context.has("map_depth") or context.map_depth < req_value:
					return false

			"has_relic":
				# 检查是否拥有特定遗物
				if not context.has("relics") or not context.relics.has(req_value):
					return false

	return true

# 处理选项效果
func _process_choice_effects(choice: Dictionary) -> void:
	if not choice.has("effects"):
		return

	var effects = choice.effects

	for effect in effects:
		_apply_effect(effect)

# 应用效果
func _apply_effect(effect: Dictionary) -> void:
	# 根据效果类型应用不同效果
	if effect.has("type"):
		match effect.type:
			"gold":
				# 金币效果
				_apply_gold_effect(effect)

			"health":
				# 生命值效果
				_apply_health_effect(effect)

			"item":
				# 物品效果
				_apply_item_effect(effect)

			"relic":
				# 遗物效果
				_apply_relic_effect(effect)

			"chess_piece":
				# 棋子效果
				_apply_chess_piece_effect(effect)

			"shop":
				# 商店效果
				_apply_shop_effect(effect)

			"battle":
				# 战斗效果
				_apply_battle_effect(effect)

			"special":
				# 特殊效果
				_apply_special_effect(effect)

# 应用金币效果
func _apply_gold_effect(effect: Dictionary) -> void:
	var player_manager = GameManager.player_manager
	var amount = effect.value

	if effect.has("operation") and effect.operation == "subtract":
		player_manager.remove_gold(amount)
	else:
		player_manager.add_gold(amount)

# 应用生命值效果
func _apply_health_effect(effect: Dictionary) -> void:
	var player_manager = GameManager.player_manager
	var amount = effect.value

	if effect.has("operation") and effect.operation == "subtract":
		player_manager.damage_player(amount)
	else:
		player_manager.heal_player(amount)

# 应用物品效果
func _apply_item_effect(effect: Dictionary) -> void:
	var equipment_manager = GameManager.equipment_manager

	if effect.has("operation"):
		match effect.operation:
			"add":
				equipment_manager.create_equipment(effect.item_id)
			"remove":
				equipment_manager.remove_equipment(effect.item_id)

# 应用遗物效果
func _apply_relic_effect(effect: Dictionary) -> void:
	var relic_manager = GameManager.relic_manager

	if effect.has("operation"):
		match effect.operation:
			"add":
				relic_manager.acquire_relic(effect.relic_id)
			"remove":
				relic_manager.remove_relic(effect.relic_id)
			"activate":
				relic_manager.activate_relic(effect.relic_id)

# 应用棋子效果
func _apply_chess_piece_effect(effect: Dictionary) -> void:
	var chess_factory = GameManager.chess_factory
	var board_manager = GameManager.board_manager

	if effect.has("operation"):
		match effect.operation:
			"add":
				var piece = chess_factory.create_chess_piece(effect.piece_id)
				if piece and effect.has("position"):
					board_manager.place_piece(piece, effect.position)
			"remove":
				if effect.has("position"):
					var piece = board_manager.get_piece_at(effect.position)
					if piece:
						board_manager.remove_piece(piece, false)
			"upgrade":
				if effect.has("position"):
					var piece = board_manager.get_piece_at(effect.position)
					if piece:
						piece.upgrade()

# 应用商店效果
func _apply_shop_effect(effect: Dictionary) -> void:
	var shop_manager = GameManager.shop_manager

	if effect.has("operation"):
		match effect.operation:
			"refresh":
				shop_manager.refresh_shop(true)  # 免费刷新
			"discount":
				shop_manager.apply_discount(effect.value)
			"add_item":
				if effect.has("item_id"):
					shop_manager.add_specific_item(effect.item_id)

# 应用战斗效果
func _apply_battle_effect(effect: Dictionary) -> void:

	if effect.has("operation"):
		match effect.operation:
			"start":
				GameManager.change_state(GameManager.GameState.BATTLE)
			"skip":
				# 跳过战斗，直接获得奖励
				pass

# 应用特殊效果
func _apply_special_effect(effect: Dictionary) -> void:
	if not effect.has("operation"):
		return

	match effect.operation:
		"curse":
			# 应用诅咒效果
			if effect.has("curse_type") and effect.has("duration"):
				_apply_curse_effect(effect.curse_type, effect.duration)

		"story_flag":
			# 设置剧情标记
			if effect.has("flag"):
				_set_story_flag(effect.flag)

		"chain_event":
			# 触发连锁事件
			if effect.has("event_id"):
				_trigger_chain_event(effect.event_id)

		"modify_event_weight":
			# 修改事件权重
			if effect.has("event_id") and effect.has("weight_modifier"):
				_modify_event_weight(effect.event_id, effect.weight_modifier)

		"unlock_achievement":
			# 解锁成就
			if effect.has("achievement_id"):
				_unlock_achievement(effect.achievement_id)

		"modify_difficulty":
			# 修改游戏难度
			if effect.has("difficulty_modifier"):
				_modify_difficulty(effect.difficulty_modifier)

		"apply_buff_to_all":
			# 应用增益效果给所有棋子
			if effect.has("buff_type") and effect.has("value"):
				_apply_buff_to_all_pieces(effect.buff_type, effect.value, effect.get("duration", -1))

# 获取奖励
func _get_rewards(choice_data: Dictionary) -> Dictionary:
	var rewards = {}

	if choice_data.has("rewards"):
		rewards = choice_data.rewards

	return rewards

# 初始化视觉组件
func _initialize_visuals() -> void:
	# 创建事件图片
	event_image = TextureRect.new()
	event_image.expand = true
	event_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(event_image)

# 加载事件图片
func _load_event_image() -> void:
	if image_path.is_empty():
		return

	if ResourceLoader.exists(image_path):
		event_image.texture = load(image_path)

# 更新视觉效果
func _update_visuals() -> void:
	# 更新事件图片
	_load_event_image()

	# 更新选项按钮
	_update_choice_buttons()

# 更新选项按钮
func _update_choice_buttons() -> void:
	# 清除现有按钮
	for button in choice_buttons:
		button.queue_free()

	choice_buttons.clear()

	# 创建新按钮
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = choice.text
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		add_child(button)
		choice_buttons.append(button)

# 显示事件界面
func _show_event_ui() -> void:
	# 切换到事件场景
	GameManager.change_state(GameManager.GameState.EVENT)

# 隐藏事件界面
func _hide_event_ui() -> void:
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 选项按钮点击处理
func _on_choice_button_pressed(choice_index: int) -> void:
	make_choice(choice_index)

# 获取事件信息
func get_info() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"event_type": event_type,
		"choices": choices.size(),
		"is_completed": is_completed
	}

# 应用诅咒效果
func _apply_curse_effect(curse_type: String, duration: int) -> void:
	var curse_manager = GameManager.curse_manager
	curse_manager.apply_curse(curse_type, duration)
	EventBus.debug.emit_event("debug_message", ["应用诅咒效果: " + curse_type + ", 持续" + str(duration) + "回合", 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.event.curse_applied", tr("curse." + curse_type))])

# 设置剧情标记
func _set_story_flag(flag: String) -> void:
	var story_manager = GameManager.story_manager
	story_manager.set_flag(flag, true)
	EventBus.debug.emit_event("debug_message", ["设置剧情标记: " + flag, 0])

# 触发连锁事件
func _trigger_chain_event(event_id: String) -> void:
	var event_manager = GameManager.event_manager
	# 完成当前事件
	complete()
	# 触发连锁事件
	event_manager.trigger_event(event_id)
	EventBus.debug.emit_event("debug_message", ["触发连锁事件: " + event_id, 0])

# 修改事件权重
func _modify_event_weight(event_id: String, weight_modifier: float) -> void:
	var event_manager = GameManager.event_manager
	event_manager.modify_event_weight(event_id, weight_modifier)
	EventBus.debug.emit_event("debug_message", ["修改事件权重: " + event_id + ", 修改值: " + str(weight_modifier), 0])

# 解锁成就
func _unlock_achievement(achievement_id: String) -> void:
	var achievement_manager = GameManager.achievement_manager
	achievement_manager.unlock_achievement(achievement_id)
	EventBus.debug.emit_event("debug_message", ["解锁成就: " + achievement_id, 0])

# 修改游戏难度
func _modify_difficulty(difficulty_modifier: float) -> void:
	var current_difficulty = GameManager.difficulty_level
	var new_difficulty = clamp(current_difficulty + difficulty_modifier, 1, 3)
	GameManager.set_difficulty(new_difficulty)
	EventBus.debug.emit_event("debug_message", ["修改游戏难度: " + str(current_difficulty) + " -> " + str(new_difficulty), 0])

# 应用增益效果给所有棋子
func _apply_buff_to_all_pieces(buff_type: String, value: float, duration: int = -1) -> void:
	var board_manager = GameManager.board_manager
	var pieces = board_manager.get_all_player_pieces()
	for piece in pieces:
		piece.add_buff(buff_type, value, duration)

	EventBus.debug.emit_event("debug_message", ["应用增益效果给所有棋子: " + buff_type + ", 值: " + str(value), 0])
	EventBus.ui.emit_event("show_toast", [tr("ui.event.buff_applied"), tr("buff." + buff_type), str(value)])
