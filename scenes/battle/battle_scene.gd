extends Control
## 战斗场景
## 玩家棋子与敌方棋子进行自动战斗的场景

# 战斗状态
enum BattleState {
	PREPARE,  # 准备阶段
	FIGHTING, # 战斗阶段
	RESULT    # 结果阶段
}

# 当前战斗状态
var current_state = BattleState.PREPARE

# 当前回合
var current_round = 1

# 准备阶段时间（秒）
var prepare_time = 30
# 当前倒计时
var current_time = 0

# 是否自动战斗
var auto_battle = false

# 战斗结果
var battle_result = false

func _ready():
	# 设置标签文本
	$TopPanel/RoundLabel.text = LocalizationManager.tr("ui.battle.round").format({"round": str(current_round)})
	$TopPanel/PhaseLabel.text = LocalizationManager.tr("ui.battle.prepare")
	$TopPanel/TimeLabel.text = LocalizationManager.tr("ui.battle.time_left").format({"time": str(prepare_time)})

	$BottomPanel/ButtonContainer/StartButton.text = LocalizationManager.tr("ui.battle.start")
	$BottomPanel/ButtonContainer/SkipButton.text = LocalizationManager.tr("ui.battle.skip")
	$BottomPanel/ButtonContainer/AutoButton.text = LocalizationManager.tr("ui.battle.auto")

	# 初始化战斗场景
	_initialize_battle()

	# 开始准备阶段
	_start_prepare_phase()

	# 播放战斗音乐
	AudioManager.play_music("battle.ogg")

func _process(delta):
	# 更新倒计时
	if current_state == BattleState.PREPARE:
		current_time -= delta
		if current_time <= 0:
			current_time = 0
			_start_fighting_phase()

		$TopPanel/TimeLabel.text = LocalizationManager.tr("ui.battle.time_left").format({"time": str(int(current_time))})



## 创建棋盘格子
func _create_board_cells() -> void:
	# 清除现有格子
	for child in $BoardContainer/PlayerBoard.get_children():
		child.queue_free()

	for child in $BoardContainer/EnemyBoard.get_children():
		child.queue_free()

	# 创建玩家棋盘格子
	for i in range(32):  # 4行8列
		var cell = _create_board_cell()
		$BoardContainer/PlayerBoard.add_child(cell)

	# 创建敌方棋盘格子
	for i in range(32):  # 4行8列
		var cell = _create_board_cell()
		$BoardContainer/EnemyBoard.add_child(cell)

## 创建棋盘格子
func _create_board_cell() -> Control:
	var cell = Control.new()
	cell.custom_minimum_size = Vector2(80, 80)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	cell.add_child(panel)

	return cell

## 创建备战区格子
func _create_bench_cells() -> void:
	# 清除现有格子
	for child in $BottomPanel/BenchContainer.get_children():
		child.queue_free()

	# 创建备战区格子
	for i in range(8):
		var cell = _create_board_cell()
		$BottomPanel/BenchContainer.add_child(cell)

## 生成敌方棋子
func _generate_enemy_pieces() -> void:
	# 这里应该根据当前难度和回合生成敌方棋子
	# 暂时不实现
	pass

## 加载玩家棋子
func _load_player_pieces() -> void:
	# 这里应该从玩家管理器加载棋子
	# 暂时不实现
	pass

## 开始准备阶段
func _start_prepare_phase() -> void:
	current_state = BattleState.PREPARE
	current_time = prepare_time

	$TopPanel/PhaseLabel.text = LocalizationManager.tr("ui.battle.prepare")
	$BottomPanel/ButtonContainer/StartButton.disabled = false
	$BottomPanel/ButtonContainer/SkipButton.disabled = false

	# 发送战斗准备信号
	EventBus.battle.emit_event("battle_round_started", [current_round])

## 开始战斗阶段
func _start_fighting_phase() -> void:
	current_state = BattleState.FIGHTING

	$TopPanel/PhaseLabel.text = LocalizationManager.tr("ui.battle.fighting")
	$BottomPanel/ButtonContainer/StartButton.disabled = true
	$BottomPanel/ButtonContainer/SkipButton.disabled = false

	# 获取玩家和敌方棋子
	var player_team = get_tree().get_nodes_in_group("player_chess_pieces")
	var enemy_team = get_tree().get_nodes_in_group("enemy_chess_pieces")

	# 开始战斗
	battle_manager.start_battle(player_team, enemy_team)

# 战斗管理器
var battle_manager = null

## 初始化战斗场景
func _initialize_battle() -> void:
	# 创建棋盘格子
	_create_board_cells()

	# 创建备战区格子
	_create_bench_cells()

	# 生成敌方棋子
	_generate_enemy_pieces()

	# 加载玩家棋子
	_load_player_pieces()

	# 获取全局战斗管理器
	battle_manager = get_node_or_null("/root/GameManager/BattleManager")
	if battle_manager == null:
		# 如果全局战斗管理器不可用，创建一个临时的
		EventBus.debug.emit_event("debug_message", ["全局战斗管理器不可用，创建临时实例", 1])
		battle_manager = BattleManager.new()
		add_child(battle_manager)

	# 连接战斗结束信号
	if not battle_manager.is_connected("battle_ended", _on_battle_ended):
		battle_manager.battle_ended.connect(_on_battle_ended)

## 战斗结束处理
func _on_battle_ended(victory: bool) -> void:
	current_state = BattleState.RESULT
	battle_result = victory

	# 显示战斗结果
	if battle_result:
		$TopPanel/PhaseLabel.text = LocalizationManager.tr("ui.battle.victory")
	else:
		$TopPanel/PhaseLabel.text = LocalizationManager.tr("ui.battle.defeat")

	# 创建标准化的战斗结果
	var result = BattleResult.create_simple(victory)

	# 发送战斗结束信号
	EventBus.battle.emit_event("battle_ended", [result.to_dict()])
	EventBus.battle.emit_event("battle_round_ended", [current_round])

	# 延迟返回地图
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		_return_to_map()
		timer.queue_free()
	)
	timer.start()

## 返回地图
func _return_to_map() -> void:
	GameManager.change_state(GameManager.GameState.MAP)

## 开始战斗按钮处理
func _on_start_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	if current_state == BattleState.PREPARE:
		_start_fighting_phase()

## 跳过战斗按钮处理
func _on_skip_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	if current_state == BattleState.PREPARE or current_state == BattleState.FIGHTING:
		# 直接结束战斗
		if current_state == BattleState.PREPARE:
			EventBus.battle.emit_event("battle_started", [])

		_on_battle_ended(randf() > 0.5)  # 跳过时随机结果

## 自动战斗按钮处理
func _on_auto_button_pressed() -> void:
	AudioManager.play_ui_sound("button_click.ogg")

	auto_battle = !auto_battle

	if auto_battle:
		$BottomPanel/ButtonContainer/AutoButton.text = LocalizationManager.tr("ui.battle.auto") + " (开启)"
	else:
		$BottomPanel/ButtonContainer/AutoButton.text = LocalizationManager.tr("ui.battle.auto")
