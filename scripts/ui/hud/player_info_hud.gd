extends BaseHUD
class_name PlayerInfoHUD
## 玩家信息HUD
## 显示玩家的生命值、金币、等级等信息

# 玩家引用
var player: Player = null

# 初始化
func _initialize() -> void:
	# 获取当前玩家
	player = game_manager.player_manager.get_current_player()
	
	if player == null:
		EventBus.debug_message.emit("无法获取当前玩家", 1)
		return
	
	# 连接玩家信号
	player.health_changed.connect(_on_player_health_changed)
	player.gold_changed.connect(_on_player_gold_changed)
	player.level_changed.connect(_on_player_level_changed)
	player.exp_changed.connect(_on_player_exp_changed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	if player == null:
		return
	
	# 更新生命值
	if has_node("HealthBar"):
		var health_bar = get_node("HealthBar")
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
	
	if has_node("HealthLabel"):
		var health_label = get_node("HealthLabel")
		health_label.text = tr("ui.player.health", [str(player.current_health), str(player.max_health)])
	
	# 更新金币
	if has_node("GoldLabel"):
		var gold_label = get_node("GoldLabel")
		gold_label.text = tr("ui.player.gold", [str(player.gold)])
	
	# 更新等级
	if has_node("LevelLabel"):
		var level_label = get_node("LevelLabel")
		level_label.text = tr("ui.player.level", [str(player.level)])
	
	# 更新经验
	if has_node("ExpBar"):
		var exp_bar = get_node("ExpBar")
		exp_bar.max_value = player.exp_to_next_level
		exp_bar.value = player.current_exp
	
	if has_node("ExpLabel"):
		var exp_label = get_node("ExpLabel")
		exp_label.text = tr("ui.player.exp", [str(player.current_exp), str(player.exp_to_next_level)])
	
	# 调用父类方法
	super.update_hud()

# 玩家生命值变化处理
func _on_player_health_changed(old_value: int, new_value: int) -> void:
	# 更新生命值显示
	if has_node("HealthBar"):
		var health_bar = get_node("HealthBar")
		health_bar.value = new_value
	
	if has_node("HealthLabel"):
		var health_label = get_node("HealthLabel")
		health_label.text = tr("ui.player.health", [str(new_value), str(player.max_health)])
	
	# 播放音效
	if new_value < old_value:
		# 受伤音效
		AudioManager.play_sfx("player_hurt.ogg")
	else:
		# 治疗音效
		AudioManager.play_sfx("player_heal.ogg")

# 玩家金币变化处理
func _on_player_gold_changed(old_value: int, new_value: int) -> void:
	# 更新金币显示
	if has_node("GoldLabel"):
		var gold_label = get_node("GoldLabel")
		gold_label.text = tr("ui.player.gold", [str(new_value)])
	
	# 播放音效
	if new_value > old_value:
		# 获得金币音效
		AudioManager.play_sfx("coin_gain.ogg")
	else:
		# 花费金币音效
		AudioManager.play_sfx("coin_spend.ogg")

# 玩家等级变化处理
func _on_player_level_changed(old_level: int, new_level: int) -> void:
	# 更新等级显示
	if has_node("LevelLabel"):
		var level_label = get_node("LevelLabel")
		level_label.text = tr("ui.player.level", [str(new_level)])
	
	# 播放音效
	if new_level > old_level:
		# 升级音效
		AudioManager.play_sfx("level_up.ogg")
	
	# 更新经验条
	if has_node("ExpBar"):
		var exp_bar = get_node("ExpBar")
		exp_bar.max_value = player.exp_to_next_level
		exp_bar.value = player.current_exp
	
	if has_node("ExpLabel"):
		var exp_label = get_node("ExpLabel")
		exp_label.text = tr("ui.player.exp", [str(player.current_exp), str(player.exp_to_next_level)])

# 玩家经验变化处理
func _on_player_exp_changed(old_value: int, new_value: int) -> void:
	# 更新经验显示
	if has_node("ExpBar"):
		var exp_bar = get_node("ExpBar")
		exp_bar.value = new_value
	
	if has_node("ExpLabel"):
		var exp_label = get_node("ExpLabel")
		exp_label.text = tr("ui.player.exp", [str(new_value), str(player.exp_to_next_level)])
	
	# 播放音效
	if new_value > old_value:
		# 获得经验音效
		AudioManager.play_sfx("exp_gain.ogg")
