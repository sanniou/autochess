extends Control
class_name SaveListComponent
## 存档列表组件
## 用于显示和管理游戏存档列表

# 信号
signal save_selected(save_name: String)
signal save_activated(save_name: String)

# 节点引用
@onready var save_list = $SaveList if has_node("SaveList") else null

# 存档管理器引用
var save_manager = null

# 选中的存档
var selected_save: String = ""

# 是否显示新存档选项
var show_new_save_option: bool = false

# 是否显示自动存档选项
var show_autosave_option: bool = true

# 初始化
func _ready() -> void:
	# 获取存档管理器
	save_manager = SaveManager
	
	# 连接列表信号
	if save_list:
		save_list.item_selected.connect(_on_save_list_item_selected)
		save_list.item_activated.connect(_on_save_list_item_activated)
	
	# 加载存档列表
	load_save_list()

# 加载存档列表
func load_save_list() -> void:
	if save_manager == null or save_list == null:
		return
	
	# 清空列表
	save_list.clear()
	
	# 添加新存档选项
	if show_new_save_option:
		save_list.add_item(tr("ui.save.new_game"), null, true)
	
	# 添加自动存档选项
	if show_autosave_option:
		var autosave_info = save_manager.get_save_info("autosave")
		if autosave_info != null:
			var date_string = ""
			if autosave_info.has("timestamp"):
				var date = Time.get_datetime_dict_from_unix_time(autosave_info.timestamp)
				date_string = "%04d-%02d-%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]
			
			var autosave_text = tr("ui.save.autosave")
			if date_string != "":
				autosave_text += " (" + date_string + ")"
			
			save_list.add_item(autosave_text, null, true)
	
	# 获取存档列表
	var saves = save_manager.get_save_list()
	
	# 添加存档项
	for save_info in saves:
		var save_name = save_info.name
		
		# 跳过自动存档
		if save_name == "autosave":
			continue
			
		var save_date = save_info.date
		var save_text = save_name + " (" + save_date + ")"
		
		save_list.add_item(save_text, null, true)
	
	# 更新选择状态
	update_selection()

# 更新选择状态
func update_selection() -> void:
	if save_list == null:
		return
		
	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	var has_selection = selected_idx.size() > 0
	
	# 如果没有选中项，默认选择第一项
	if not has_selection and save_list.item_count > 0:
		save_list.select(0)
		_on_save_list_item_selected(0)

# 获取选中的存档名称
func get_selected_save_name() -> String:
	if save_list == null:
		return ""
	
	# 获取选中的存档索引
	var selected_idx = save_list.get_selected_items()
	if selected_idx.size() == 0:
		return ""
	
	var index = selected_idx[0]
	
	# 处理新存档选项
	if show_new_save_option and index == 0:
		return "new"
	
	# 处理自动存档选项
	var autosave_index = 0 if show_new_save_option else 0
	if show_autosave_option and index == autosave_index:
		return "autosave"
	
	# 从文本中提取存档名称（去除日期和其他信息）
	var save_text = save_list.get_item_text(index)
	return save_text.split(" (")[0]

# 存档列表项选择处理
func _on_save_list_item_selected(index: int) -> void:
	# 获取选中的存档名称
	selected_save = get_selected_save_name()
	
	# 发送选择信号
	save_selected.emit(selected_save)

# 存档列表项激活处理（双击）
func _on_save_list_item_activated(index: int) -> void:
	# 获取选中的存档名称
	selected_save = get_selected_save_name()
	
	# 发送激活信号
	save_activated.emit(selected_save)
