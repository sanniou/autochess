extends Control
## 遗物管理场景
## 玩家可以在此查看和管理遗物

# 引用
@onready var player_manager = get_node("/root/GameManager/PlayerManager")
@onready var relic_manager = get_node("/root/GameManager/RelicManager")
@onready var config_manager = get_node("/root/ConfigManager")

# 当前玩家
var current_player = null

# 选中的遗物
var selected_relic = null

# 初始化
func _ready():
	# 获取当前玩家
	current_player = player_manager.get_current_player()
	
	# 设置标题
	$MarginContainer/VBoxContainer/HeaderPanel/HBoxContainer/TitleLabel.text = "遗物管理"
	
	# 加载遗物列表
	_load_relic_list()
	
	# 连接信号
	EventBus.relic.connect_event("relic_acquired", _on_relic_acquired)
	EventBus.relic.connect_event("relic_activated", _on_relic_activated)

# 加载遗物列表
func _load_relic_list():
	# 清空遗物列表
	var grid = $MarginContainer/VBoxContainer/ContentPanel/ScrollContainer/RelicGrid
	for child in grid.get_children():
		child.queue_free()
	
	# 获取玩家遗物
	var relics = []
	if relic_manager:
		relics = relic_manager.get_player_relics()
	
	# 添加遗物到列表
	for relic in relics:
		var item = _create_relic_item(relic)
		grid.add_child(item)

# 创建遗物项
func _create_relic_item(relic):
	# 复制模板
	var template = $RelicItemTemplate
	var item = template.duplicate()
	item.visible = true
	
	# 设置遗物图标
	var icon = item.get_node("VBoxContainer/RelicIcon")
	if relic.icon:
		icon.texture = relic.icon
	
	# 设置遗物名称
	var name_label = item.get_node("VBoxContainer/RelicName")
	name_label.text = relic.display_name
	
	# 设置遗物稀有度
	var rarity_label = item.get_node("VBoxContainer/RelicRarity")
	match relic.rarity:
		0:
			rarity_label.text = "普通"
			rarity_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
		1:
			rarity_label.text = "稀有"
			rarity_label.modulate = Color(0.2, 0.6, 1.0, 1.0)
		2:
			rarity_label.text = "史诗"
			rarity_label.modulate = Color(0.8, 0.4, 1.0, 1.0)
		3:
			rarity_label.text = "传说"
			rarity_label.modulate = Color(1.0, 0.8, 0.2, 1.0)
	
	# 设置遗物描述
	var desc_label = item.get_node("VBoxContainer/RelicDesc")
	desc_label.text = relic.description
	
	# 设置激活按钮
	var activate_button = item.get_node("VBoxContainer/ActivateButton")
	
	# 如果是被动遗物，隐藏激活按钮
	if relic.is_passive:
		activate_button.visible = false
	else:
		activate_button.visible = true
		
		# 如果遗物已激活，禁用按钮
		if relic.is_active:
			activate_button.disabled = true
			activate_button.text = "已激活"
		else:
			activate_button.disabled = false
			activate_button.text = "激活"
		
		# 如果遗物在冷却中，显示冷却时间
		if relic.current_cooldown > 0:
			activate_button.disabled = true
			activate_button.text = "冷却中: %.1f" % relic.current_cooldown
		
		# 如果遗物没有充能，禁用按钮
		if relic.charges == 0:
			activate_button.disabled = true
			activate_button.text = "已用尽"
		
		# 连接激活按钮信号
		activate_button.pressed.connect(_on_activate_button_pressed.bind(relic))
	
	return item

# 激活按钮处理
func _on_activate_button_pressed(relic):
	# 激活遗物
	relic_manager.activate_relic(relic.id)
	
	# 重新加载遗物列表
	_load_relic_list()

# 关闭按钮处理
func _on_close_button_pressed():
	# 返回地图
	GameManager.change_state(GameManager.GameState.MAP)

# 遗物获取事件处理
func _on_relic_acquired(relic):
	# 重新加载遗物列表
	_load_relic_list()

# 遗物激活事件处理
func _on_relic_activated(relic):
	# 重新加载遗物列表
	_load_relic_list()
