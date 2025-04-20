extends Control
## 皮肤商店项
## 用于在皮肤商店中显示和购买皮肤

# 信号
signal skin_purchased(skin_id, skin_type, price)

# 皮肤数据
var skin_id: String = ""
var skin_type: String = ""
var skin_data: Dictionary = {}
var price: int = 0

# 初始化
func _ready():
	# 连接按钮信号
	$PurchaseButton.pressed.connect(_on_purchase_button_pressed)
	$PreviewButton.pressed.connect(_on_preview_button_pressed)

# 设置皮肤名称
func set_skin_name(name: String) -> void:
	$NameLabel.text = name

# 设置皮肤图标
func set_skin_icon(icon_path: String) -> void:
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		$IconRect.texture = texture

# 设置皮肤描述
func set_skin_description(description: String) -> void:
	$DescriptionLabel.text = description

# 设置皮肤价格
func set_skin_price(value: int) -> void:
	price = value
	$PriceContainer/PriceLabel.text = str(price)

	# 如果价格为0，显示"免费"
	if price == 0:
		$PriceContainer/PriceLabel.text = "免费"

# 设置皮肤状态
func set_skin_state(is_unlocked: bool, can_afford: bool) -> void:
	if is_unlocked:
		# 已解锁
		$PurchaseButton.text = "已拥有"
		$PurchaseButton.disabled = true
		$PurchaseButton.modulate = Color(0.5, 0.5, 0.5)
	else:
		# 未解锁
		$PurchaseButton.text = "购买"
		$PurchaseButton.disabled = not can_afford

		if can_afford:
			$PurchaseButton.modulate = Color(1, 1, 1)
		else:
			$PurchaseButton.modulate = Color(0.7, 0.7, 0.7)

# 购买按钮处理
func _on_purchase_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 发送购买信号
	skin_purchased.emit(skin_id, skin_type, price)

# 预览按钮处理
func _on_preview_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")

	# 创建预览对话框
	var dialog = AcceptDialog.new()
	dialog.title = "皮肤预览: " + $NameLabel.text

	# 创建预览容器
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(400, 300)

	# 创建预览图像
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(300, 200)

	# 加载预览图像
	var preview_texture = null

	# 尝试不同的预览图像来源
	if skin_data.has("preview") and skin_data.preview and ResourceLoader.exists(skin_data.preview):
		preview_texture = load(skin_data.preview)
	elif skin_data.has("preview_path") and ResourceLoader.exists(skin_data.preview_path):
		preview_texture = load(skin_data.preview_path)
	elif skin_type == "chess" and skin_data.has("chess_pieces"):
		# 尝试加载棋子皮肤的预览
		for piece_id in skin_data.chess_pieces.keys():
			if ResourceLoader.exists(skin_data.chess_pieces[piece_id]):
				preview_texture = load(skin_data.chess_pieces[piece_id])
				break
	elif skin_type == "board" and skin_data.has("board") and skin_data.board.has("background"):
		# 尝试加载棋盘皮肤的预览
		if ResourceLoader.exists(skin_data.board.background):
			preview_texture = load(skin_data.board.background)
	elif skin_type == "ui" and skin_data.has("ui") and skin_data.ui.has("main_menu_background"):
		# 尝试加载UI皮肤的预览
		if ResourceLoader.exists(skin_data.ui.main_menu_background):
			preview_texture = load(skin_data.ui.main_menu_background)
	elif $IconRect.texture:
		# 使用图标作为预览
		preview_texture = $IconRect.texture

	# 设置预览图像
	if preview_texture:
		preview.texture = preview_texture

	# 创建描述标签
	var description = Label.new()
	description.text = $DescriptionLabel.text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 添加到容器
	container.add_child(preview)
	container.add_child(HSeparator.new())
	container.add_child(description)

	# 添加价格信息
	container.add_child(HSeparator.new())
	var price_label = Label.new()
	if price > 0:
		price_label.text = "价格: " + str(price) + " 金币"
	else:
		price_label.text = "价格: 免费"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	container.add_child(price_label)

	# 添加特性信息（如果有）
	if skin_data.has("features") and skin_data.features is Array and not skin_data.features.is_empty():
		container.add_child(HSeparator.new())

		var features_label = Label.new()
		features_label.text = "特性:"
		features_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(features_label)

		for feature in skin_data.features:
			var feature_label = Label.new()
			feature_label.text = "- " + feature
			feature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(feature_label)

	# 添加到对话框
	dialog.add_child(container)

	# 显示对话框
	add_child(dialog)
	dialog.popup_centered(Vector2(500, 400))
