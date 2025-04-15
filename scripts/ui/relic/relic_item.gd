extends Panel
## 遗物项
## 显示单个遗物的图标和名称

# 信号
signal relic_clicked(relic)

# 引用
@onready var texture_rect = $TextureRect
@onready var name_label = $NameLabel

# 当前遗物
var relic = null

# 设置遗物数据
func set_relic_data(relic_data) -> void:
	relic = relic_data
	
	# 设置遗物图标
	if relic.icon:
		texture_rect.texture = relic.icon
	
	# 设置遗物名称
	name_label.text = relic.display_name
	
	# 设置稀有度颜色
	match relic.rarity:
		0: # 普通
			self_modulate = Color(0.8, 0.8, 0.8, 1.0)
		1: # 稀有
			self_modulate = Color(0.2, 0.6, 1.0, 1.0)
		2: # 史诗
			self_modulate = Color(0.8, 0.4, 1.0, 1.0)
		3: # 传说
			self_modulate = Color(1.0, 0.8, 0.2, 1.0)

# 鼠标输入事件处理
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 发送点击信号
		relic_clicked.emit(relic)
		
		# 发送显示遗物信息信号
		EventBus.show_relic_info.emit(relic)
