extends Node
class_name BoardSkinHandler
## 棋盘皮肤处理器
## 负责处理棋盘皮肤的应用和预览

# 引用
@onready var background: TextureRect = $Background if has_node("Background") else null
@onready var cells: Node = $Cells if has_node("Cells") else null

# 当前皮肤ID
var current_skin_id: String = "default"

# 初始化
func _ready() -> void:
	# 连接事件
	_connect_signals()
	
	# 应用当前皮肤
	_apply_current_skin()

# 连接信号
func _connect_signals() -> void:
	# 监听皮肤变更事件
	GlobalEventBus.skin.add_class_listener(SkinEvents.BoardSkinAppliedEvent, _on_board_skin_applied)
	GlobalEventBus.skin.add_class_listener(SkinEvents.BoardSkinPreviewEvent, _on_board_skin_preview)

# 应用当前皮肤
func _apply_current_skin() -> void:
	# 获取当前选中的皮肤
	current_skin_id = GameManager.skin_manager.get_selected_skin_id("board")
	
	# 应用皮肤
	_apply_skin(current_skin_id)

# 应用皮肤
func _apply_skin(skin_id: String) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(skin_id, "board")
	if skin_model == null:
		push_error("无法加载棋盘皮肤: " + skin_id)
		return
	
	# 获取棋盘纹理和格子纹理
	var board_texture = skin_model.get_board_texture()
	var cell_textures = skin_model.get_cell_textures()
	
	# 应用纹理
	_apply_board_texture(board_texture)
	_apply_cell_textures(cell_textures)

# 应用棋盘纹理
func _apply_board_texture(texture_path: String) -> void:
	# 检查是否有背景组件
	if background == null:
		push_error("棋盘没有Background组件")
		return
	
	# 加载纹理
	var texture = load(texture_path)
	
	if texture == null:
		push_error("无法加载纹理: " + texture_path)
		return
	
	# 应用纹理
	background.texture = texture

# 应用格子纹理
func _apply_cell_textures(cell_textures: Dictionary) -> void:
	# 检查是否有格子组件
	if cells == null:
		push_error("棋盘没有Cells组件")
		return
	
	# 遍历所有格子
	for cell in cells.get_children():
		# 检查格子类型
		var cell_type = _get_cell_type(cell)
		
		# 检查是否有对应的纹理
		if cell_type.is_empty() or not cell_textures.has(cell_type):
			continue
		
		# 获取纹理路径
		var texture_path = cell_textures[cell_type]
		
		# 加载纹理
		var texture = load(texture_path)
		
		if texture == null:
			push_error("无法加载格子纹理: " + texture_path)
			continue
		
		# 应用纹理
		if cell.has_node("Background"):
			cell.get_node("Background").texture = texture

# 获取格子类型
func _get_cell_type(cell: Node) -> String:
	# 检查格子是否有类型属性
	if cell.has_method("get_cell_type"):
		return cell.get_cell_type()
	
	# 从节点名称推断格子类型
	var node_name = cell.name.to_lower()
	if "normal" in node_name:
		return "normal"
	elif "highlighted" in node_name:
		return "highlighted"
	elif "selected" in node_name:
		return "selected"
	elif "spawn" in node_name:
		return "spawn"
	elif "blocked" in node_name:
		return "blocked"
	elif "bench" in node_name:
		return "bench"
	
	# 默认返回normal
	return "normal"

# 棋盘皮肤应用事件处理
func _on_board_skin_applied(event: SkinEvents.BoardSkinAppliedEvent) -> void:
	# 更新当前皮肤ID
	current_skin_id = event.skin_id
	
	# 应用纹理
	_apply_board_texture(event.board_texture)
	_apply_cell_textures(event.cell_textures)

# 棋盘皮肤预览事件处理
func _on_board_skin_preview(event: SkinEvents.BoardSkinPreviewEvent) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(event.skin_id, "board")
	if skin_model == null:
		push_error("无法加载棋盘皮肤预览: " + event.skin_id)
		return
	
	# 获取棋盘纹理和格子纹理
	var board_texture = skin_model.get_board_texture()
	var cell_textures = skin_model.get_cell_textures()
	
	# 临时应用纹理
	_apply_board_texture(board_texture)
	_apply_cell_textures(cell_textures)
	
	# 延迟恢复原来的皮肤
	await get_tree().create_timer(2.0).timeout
	_apply_skin(current_skin_id)

# 清理
func _exit_tree() -> void:
	# 断开事件连接
	GlobalEventBus.skin.remove_class_listener(SkinEvents.BoardSkinAppliedEvent, _on_board_skin_applied)
	GlobalEventBus.skin.remove_class_listener(SkinEvents.BoardSkinPreviewEvent, _on_board_skin_preview)
