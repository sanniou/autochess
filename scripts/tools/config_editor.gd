extends Control
## 配置编辑工具
## 用于编辑配置文件

# UI 组件
@onready var config_list = $VBoxContainer/HSplitContainer/ConfigList
@onready var config_tree = $VBoxContainer/HSplitContainer/VSplitContainer/ConfigTree
@onready var property_editor = $VBoxContainer/HSplitContainer/VSplitContainer/PropertyEditor
@onready var save_button = $VBoxContainer/HBoxContainer/SaveButton
@onready var reload_button = $VBoxContainer/HBoxContainer/ReloadButton
@onready var status_label = $VBoxContainer/StatusLabel

# 配置数据
var current_config_path = ""
var current_config_data = {}
var config_files = {}

func _ready():
	# 连接信号
	save_button.pressed.connect(_on_save_button_pressed)
	reload_button.pressed.connect(_on_reload_button_pressed)
	config_list.item_selected.connect(_on_config_selected)
	config_tree.item_selected.connect(_on_tree_item_selected)
	
	# 加载配置文件列表
	_load_config_files()

## 加载配置文件列表
func _load_config_files() -> void:
	config_files = GameManager.config_manager.get_all_config_files()
	config_list.clear()
	
	for config_name in config_files:
		config_list.add_item(config_name)
	
	status_label.text = "已加载 " + str(config_files.size()) + " 个配置文件"

## 加载配置文件
func _load_config_file(config_path: String) -> void:
	current_config_path = config_path
	current_config_data = GameManager.config_manager.load_json(config_path)
	
	_update_config_tree()
	
	status_label.text = "已加载配置文件: " + config_path

## 更新配置树
func _update_config_tree() -> void:
	config_tree.clear()
	
	var root = config_tree.create_item()
	root.set_text(0, current_config_path.get_file())
	
	_add_dict_to_tree(root, current_config_data)

## 将字典添加到树中
func _add_dict_to_tree(parent: TreeItem, dict: Dictionary) -> void:
	for key in dict:
		var item = config_tree.create_item(parent)
		item.set_text(0, key)
		
		if typeof(dict[key]) == TYPE_DICTIONARY:
			item.set_text(1, "Dictionary")
			_add_dict_to_tree(item, dict[key])
		elif typeof(dict[key]) == TYPE_ARRAY:
			item.set_text(1, "Array[" + str(dict[key].size()) + "]")
			_add_array_to_tree(item, dict[key])
		else:
			item.set_text(1, str(dict[key]))
			item.set_metadata(0, {"key": key, "value": dict[key], "parent": dict})

## 将数组添加到树中
func _add_array_to_tree(parent: TreeItem, array: Array) -> void:
	for i in range(array.size()):
		var item = config_tree.create_item(parent)
		item.set_text(0, str(i))
		
		if typeof(array[i]) == TYPE_DICTIONARY:
			item.set_text(1, "Dictionary")
			_add_dict_to_tree(item, array[i])
		elif typeof(array[i]) == TYPE_ARRAY:
			item.set_text(1, "Array[" + str(array[i].size()) + "]")
			_add_array_to_tree(item, array[i])
		else:
			item.set_text(1, str(array[i]))
			item.set_metadata(0, {"key": i, "value": array[i], "parent": array})

## 更新属性编辑器
func _update_property_editor(item: TreeItem) -> void:
	property_editor.clear()
	
	var metadata = item.get_metadata(0)
	if metadata == null:
		return
	
	var key = metadata.key
	var value = metadata.value
	var parent = metadata.parent
	
	# 创建属性编辑器
	var type_label = Label.new()
	type_label.text = "类型: " + _get_type_name(typeof(value))
	property_editor.add_child(type_label)
	
	var key_label = Label.new()
	key_label.text = "键: " + str(key)
	property_editor.add_child(key_label)
	
	var value_label = Label.new()
	value_label.text = "值: "
	property_editor.add_child(value_label)
	
	var value_edit = LineEdit.new()
	value_edit.text = str(value)
	value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_editor.add_child(value_edit)
	
	var apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.pressed.connect(func(): _apply_property_change(parent, key, value_edit.text))
	property_editor.add_child(apply_button)

## 应用属性更改
func _apply_property_change(parent: Variant, key: Variant, new_value_text: String) -> void:
	var new_value = _parse_value(new_value_text, typeof(parent[key]))
	parent[key] = new_value
	
	_update_config_tree()
	status_label.text = "已更新属性: " + str(key) + " = " + str(new_value)

## 解析值
func _parse_value(value_text: String, type: int) -> Variant:
	match type:
		TYPE_BOOL:
			return value_text.to_lower() == "true"
		TYPE_INT:
			return int(value_text)
		TYPE_FLOAT:
			return float(value_text)
		TYPE_STRING:
			return value_text
		_:
			return value_text

## 获取类型名称
func _get_type_name(type: int) -> String:
	match type:
		TYPE_NIL:
			return "Null"
		TYPE_BOOL:
			return "Boolean"
		TYPE_INT:
			return "Integer"
		TYPE_FLOAT:
			return "Float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_RECT2:
			return "Rect2"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_TRANSFORM2D:
			return "Transform2D"
		TYPE_PLANE:
			return "Plane"
		TYPE_QUATERNION:
			return "Quaternion"
		TYPE_AABB:
			return "AABB"
		TYPE_BASIS:
			return "Basis"
		TYPE_TRANSFORM3D:
			return "Transform3D"
		TYPE_COLOR:
			return "Color"
		TYPE_NODE_PATH:
			return "NodePath"
		TYPE_RID:
			return "RID"
		TYPE_OBJECT:
			return "Object"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_ARRAY:
			return "Array"
		TYPE_PACKED_BYTE_ARRAY:
			return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY:
			return "PackedInt32Array"
		TYPE_PACKED_FLOAT32_ARRAY:
			return "PackedFloat32Array"
		TYPE_PACKED_STRING_ARRAY:
			return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY:
			return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY:
			return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY:
			return "PackedColorArray"
		_:
			return "Unknown"

## 保存按钮点击事件
func _on_save_button_pressed() -> void:
	if current_config_path.is_empty():
		status_label.text = "错误: 未选择配置文件"
		return
	
	var result = GameManager.config_manager.save_json(current_config_path, current_config_data)
	if result:
		status_label.text = "已保存配置文件: " + current_config_path
	else:
		status_label.text = "保存配置文件失败: " + current_config_path

## 重新加载按钮点击事件
func _on_reload_button_pressed() -> void:
	_load_config_files()
	
	if not current_config_path.is_empty():
		_load_config_file(current_config_path)

## 配置选择事件
func _on_config_selected(index: int) -> void:
	var config_name = config_list.get_item_text(index)
	var config_path = config_files[config_name]
	
	_load_config_file(config_path)

## 树项目选择事件
func _on_tree_item_selected() -> void:
	var selected_item = config_tree.get_selected()
	if selected_item:
		_update_property_editor(selected_item)
