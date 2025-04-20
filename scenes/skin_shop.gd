extends Control
## 皮肤商店界面
## 用于购买和解锁游戏皮肤

# 玩家金币
var player_gold = 0

# 皮肤项模板
var skin_shop_item_scene = preload("res://scenes/ui/skin_shop_item.tscn")

# 初始化
func _ready():
	
	# 获取玩家金币
	var save_data = SaveManager.get_save_data()
	if save_data.has("gold"):
		player_gold = save_data.gold
	
	# 更新金币显示
	$Header/GoldContainer/GoldValue.text = str(player_gold)
	
	# 加载皮肤
	_load_skins()
	
	# 添加动画效果
	_add_animations()
	
	# 播放背景音乐
	AudioManager.play_music("shop.ogg")
	
	# 连接信号
	$Header/BackButton.pressed.connect(_on_back_button_pressed)

# 加载皮肤
func _load_skins() -> void:
	if GameManager.skin_manager:
		# 加载棋子皮肤
		_load_chess_skins()
		
		# 加载棋盘皮肤
		_load_board_skins()
		
		# 加载UI皮肤
		_load_ui_skins()

# 加载棋子皮肤
func _load_chess_skins() -> void:
	var container = $TabContainer/棋子皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有棋子皮肤
	var chess_skins = GameManager.skin_manager.get_all_skins("chess")
	
	# 添加皮肤项
	for skin_id in chess_skins:
		var skin_data = chess_skins[skin_id]
		var item = _create_skin_shop_item(skin_id, skin_data, "chess")
		container.add_child(item)

# 加载棋盘皮肤
func _load_board_skins() -> void:
	var container = $TabContainer/棋盘皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有棋盘皮肤
	var board_skins = GameManager.skin_manager.get_all_skins("board")
	
	# 添加皮肤项
	for skin_id in board_skins:
		var skin_data = board_skins[skin_id]
		var item = _create_skin_shop_item(skin_id, skin_data, "board")
		container.add_child(item)

# 加载UI皮肤
func _load_ui_skins() -> void:
	var container = $TabContainer/UI皮肤/ScrollContainer/GridContainer
	
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有UI皮肤
	var ui_skins = GameManager.skin_manager.get_all_skins("ui")
	
	# 添加皮肤项
	for skin_id in ui_skins:
		var skin_data = ui_skins[skin_id]
		var item = _create_skin_shop_item(skin_id, skin_data, "ui")
		container.add_child(item)

# 创建皮肤商店项
func _create_skin_shop_item(skin_id: String, skin_data: Dictionary, skin_type: String) -> Control:
	var item = skin_shop_item_scene.instantiate()
	item.skin_id = skin_id
	item.skin_type = skin_type
	item.skin_data = skin_data
	
	# 设置皮肤名称
	item.set_skin_name(skin_data.name)
	
	# 设置皮肤图标
	if skin_data.has("icon") and skin_data.icon:
		item.set_skin_icon(skin_data.icon)
	
	# 设置皮肤描述
	if skin_data.has("description") and skin_data.description:
		item.set_skin_description(skin_data.description)
	
	# 设置皮肤价格
	var price = 0
	if skin_data.has("price"):
		price = skin_data.price
	item.set_skin_price(price)
	
	# 设置皮肤状态
	var is_unlocked = GameManager.skin_manager.is_skin_unlocked(skin_id, skin_type)
	item.set_skin_state(is_unlocked, player_gold >= price)
	
	# 连接信号
	item.skin_purchased.connect(_on_skin_purchased)
	
	return item

# 添加动画效果
func _add_animations() -> void:
	# 标题动画
	var title_tween = create_tween()
	title_tween.tween_property($Header/Title, "modulate:a", 1.0, 0.5)
	
	# 金币容器动画
	var gold_tween = create_tween()
	gold_tween.tween_interval(0.2)  # 等待标题动画
	gold_tween.tween_property($Header/GoldContainer, "modulate:a", 1.0, 0.5)
	
	# 选项卡动画
	var tab_tween = create_tween()
	tab_tween.tween_interval(0.4)  # 等待金币容器动画
	tab_tween.tween_property($TabContainer, "modulate:a", 1.0, 0.5)

# 皮肤购买处理
func _on_skin_purchased(skin_id: String, skin_type: String, price: int) -> void:
	# 检查金币是否足够
	if player_gold < price:
		# 显示金币不足提示
		var dialog = AcceptDialog.new()
		dialog.title = "金币不足"
		dialog.dialog_text = "您的金币不足，无法购买此皮肤。"
		add_child(dialog)
		dialog.popup_centered()
		return
	
	# 扣除金币
	player_gold -= price
	
	# 更新金币显示
	$Header/GoldContainer/GoldValue.text = str(player_gold)
	
	# 更新存档中的金币
	var save_data = SaveManager.get_save_data()
	save_data.gold = player_gold
	SaveManager.save_game()
	
	# 解锁皮肤
	if GameManager.skin_manager.unlock_skin(skin_id, skin_type):
		# 播放购买成功音效
		var audio_manager = AudioManager
		audio_manager.play_ui_sound("purchase.ogg")
		
		# 显示购买成功提示
		var dialog = AcceptDialog.new()
		dialog.title = "购买成功"
		dialog.dialog_text = "皮肤已成功解锁！"
		add_child(dialog)
		dialog.popup_centered()
		
		# 刷新皮肤列表
		_load_skins()
	else:
		# 显示购买失败提示
		var dialog = AcceptDialog.new()
		dialog.title = "购买失败"
		dialog.dialog_text = "皮肤解锁失败，请稍后再试。"
		add_child(dialog)
		dialog.popup_centered()
		
		# 退还金币
		player_gold += price
		$Header/GoldContainer/GoldValue.text = str(player_gold)
		save_data.gold = player_gold
		SaveManager.save_game()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 创建过渡动画
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.size = get_viewport_rect().size
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/skins.tscn"))
