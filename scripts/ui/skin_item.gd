extends Control
class_name SkinItem
## 皮肤项
## 用于在皮肤商店中展示单个皮肤

# 信号
signal skin_selected

# 引用
@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var rarity_label: Label = $RarityLabel
@onready var lock_icon: TextureRect = $LockIcon

# 皮肤数据
var skin_model: SkinConfig = null
var skin_type: String = ""

# 初始化
func _ready() -> void:
	# 连接信号
	_connect_signals()

# 连接信号
func _connect_signals() -> void:
	# 点击事件
	gui_input.connect(_on_gui_input)

# 设置皮肤数据
func set_skin_data(p_skin_model: SkinConfig, p_skin_type: String) -> void:
	# 保存数据
	skin_model = p_skin_model
	skin_type = p_skin_type
	
	# 更新UI
	_update_ui()

# 更新UI
func _update_ui() -> void:
	if skin_model == null:
		return
	
	# 设置图标
	var icon_texture = load(skin_model.get_icon())
	if icon_texture:
		icon.texture = icon_texture
	
	# 设置名称
	name_label.text = skin_model.get_name()
	
	# 设置稀有度
	var rarity = skin_model.get_rarity()
	rarity_label.text = _get_rarity_text(rarity)
	rarity_label.modulate = _get_rarity_color(rarity)
	
	# 设置锁定状态
	var is_unlocked = GameManager.skin_manager.is_skin_unlocked(skin_model.get_id(), skin_type)
	lock_icon.visible = not is_unlocked
	
	# 设置选中状态
	var is_selected = GameManager.skin_manager.get_selected_skin_id(skin_type) == skin_model.get_id()
	if is_selected:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color(1.0, 1.0, 1.0)

# 获取稀有度文本
func _get_rarity_text(rarity: int) -> String:
	match rarity:
		0:
			return "普通"
		1:
			return "精良"
		2:
			return "稀有"
		3:
			return "史诗"
		4:
			return "传说"
		5:
			return "神话"
		_:
			return "未知"

# 获取稀有度颜色
func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0:
			return Color(0.7, 0.7, 0.7)  # 灰色
		1:
			return Color(0.0, 0.7, 0.0)  # 绿色
		2:
			return Color(0.0, 0.0, 1.0)  # 蓝色
		3:
			return Color(0.5, 0.0, 0.5)  # 紫色
		4:
			return Color(1.0, 0.5, 0.0)  # 橙色
		5:
			return Color(1.0, 0.0, 0.0)  # 红色
		_:
			return Color(1.0, 1.0, 1.0)  # 白色

# 点击处理
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 发送选中信号
		skin_selected.emit()
