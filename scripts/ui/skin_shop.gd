extends Control
class_name SkinShop
## 皮肤商店
## 用于展示和购买皮肤

# 引用
@onready var chess_skin_container: GridContainer = $TabContainer/ChessSkins/ScrollContainer/GridContainer
@onready var board_skin_container: GridContainer = $TabContainer/BoardSkins/ScrollContainer/GridContainer
@onready var ui_skin_container: GridContainer = $TabContainer/UISkins/ScrollContainer/GridContainer
@onready var preview_panel: Panel = $PreviewPanel
@onready var preview_image: TextureRect = $PreviewPanel/PreviewImage
@onready var preview_name: Label = $PreviewPanel/NameLabel
@onready var preview_description: Label = $PreviewPanel/DescriptionLabel
@onready var preview_price: Label = $PreviewPanel/PriceLabel
@onready var buy_button: Button = $PreviewPanel/BuyButton
@onready var select_button: Button = $PreviewPanel/SelectButton
@onready var close_button: Button = $CloseButton

# 皮肤项模板
var skin_item_scene = preload("res://scenes/ui/skin_item.tscn")

# 当前预览的皮肤
var current_preview_skin: SkinConfig = null
var current_preview_type: String = ""

# 初始化
func _ready() -> void:
	# 连接信号
	_connect_signals()
	
	# 加载皮肤
	_load_skins()
	
	# 隐藏预览面板
	preview_panel.visible = false

# 连接信号
func _connect_signals() -> void:
	# 按钮信号
	buy_button.pressed.connect(_on_buy_button_pressed)
	select_button.pressed.connect(_on_select_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

# 加载皮肤
func _load_skins() -> void:
	# 加载棋子皮肤
	_load_skin_type("chess", chess_skin_container)
	
	# 加载棋盘皮肤
	_load_skin_type("board", board_skin_container)
	
	# 加载UI皮肤
	_load_skin_type("ui", ui_skin_container)

# 加载特定类型的皮肤
func _load_skin_type(skin_type: String, container: GridContainer) -> void:
	# 清空容器
	for child in container.get_children():
		child.queue_free()
	
	# 获取所有皮肤
	var skins = GameManager.skin_manager.get_all_skins(skin_type)
	
	# 按稀有度排序
	var sorted_skins = []
	for skin_id in skins:
		sorted_skins.append(skins[skin_id])
	
	sorted_skins.sort_custom(func(a, b): return a.get_rarity() > b.get_rarity())
	
	# 添加皮肤项
	for skin_model in sorted_skins:
		var skin_item = skin_item_scene.instantiate()
		container.add_child(skin_item)
		
		# 设置皮肤数据
		skin_item.set_skin_data(skin_model, skin_type)
		
		# 连接信号
		skin_item.skin_selected.connect(_on_skin_selected.bind(skin_model, skin_type))

# 皮肤选择处理
func _on_skin_selected(skin_model: SkinConfig, skin_type: String) -> void:
	# 保存当前预览的皮肤
	current_preview_skin = skin_model
	current_preview_type = skin_type
	
	# 更新预览面板
	_update_preview_panel()
	
	# 显示预览面板
	preview_panel.visible = true
	
	# 发送预览事件
	GlobalEventBus.skin.dispatch_event(SkinEvents.PreviewSkinEvent.new(skin_type, skin_model.get_id()))

# 更新预览面板
func _update_preview_panel() -> void:
	if current_preview_skin == null:
		return
	
	# 设置预览图
	var preview_texture = load(current_preview_skin.get_preview())
	if preview_texture:
		preview_image.texture = preview_texture
	
	# 设置名称和描述
	preview_name.text = current_preview_skin.get_name()
	preview_description.text = current_preview_skin.get_description()
	
	# 设置价格
	var unlock_condition = current_preview_skin.get_unlock_condition()
	if unlock_condition.has("gold"):
		preview_price.text = str(unlock_condition.gold) + " 金币"
	else:
		preview_price.text = "免费"
	
	# 更新按钮状态
	var is_unlocked = GameManager.skin_manager.is_skin_unlocked(current_preview_skin.get_id(), current_preview_type)
	buy_button.visible = not is_unlocked
	select_button.visible = is_unlocked
	
	# 检查是否已选中
	var is_selected = GameManager.skin_manager.get_selected_skin_id(current_preview_type) == current_preview_skin.get_id()
	select_button.disabled = is_selected
	select_button.text = "已选择" if is_selected else "选择"

# 购买按钮处理
func _on_buy_button_pressed() -> void:
	if current_preview_skin == null:
		return
	
	# 解锁皮肤
	var success = GameManager.skin_manager.unlock_skin(current_preview_skin.get_id(), current_preview_type)
	
	if success:
		# 更新预览面板
		_update_preview_panel()
		
		# 更新皮肤列表
		_load_skin_type(current_preview_type, _get_container_for_type(current_preview_type))

# 选择按钮处理
func _on_select_button_pressed() -> void:
	if current_preview_skin == null:
		return
	
	# 应用皮肤
	var skins = {current_preview_type: current_preview_skin.get_id()}
	GameManager.skin_manager.apply_skins(skins)
	
	# 更新预览面板
	_update_preview_panel()

# 关闭按钮处理
func _on_close_button_pressed() -> void:
	# 隐藏预览面板
	preview_panel.visible = false
	
	# 清除当前预览的皮肤
	current_preview_skin = null
	current_preview_type = ""

# 获取特定类型的容器
func _get_container_for_type(skin_type: String) -> GridContainer:
	match skin_type:
		"chess":
			return chess_skin_container
		"board":
			return board_skin_container
		"ui":
			return ui_skin_container
		_:
			return null
