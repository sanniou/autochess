extends Node
class_name ChessSkinHandler
## 棋子皮肤处理器
## 负责处理棋子皮肤的应用和预览

# 引用
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

# 当前皮肤ID
var current_skin_id: String = "default"
# 棋子类型
var chess_type: String = ""

# 初始化
func _ready() -> void:
	# 连接事件
	_connect_signals()
	
	# 获取棋子类型
	chess_type = _get_chess_type()
	
	# 应用当前皮肤
	_apply_current_skin()

# 连接信号
func _connect_signals() -> void:
	# 监听皮肤变更事件
	GlobalEventBus.skin.add_class_listener(SkinEvents.ChessSkinAppliedEvent, _on_chess_skin_applied)
	GlobalEventBus.skin.add_class_listener(SkinEvents.ChessSkinPreviewEvent, _on_chess_skin_preview)

# 获取棋子类型
func _get_chess_type() -> String:
	# 从父节点获取棋子类型
	var parent = get_parent()
	if parent and parent.has_method("get_chess_type"):
		return parent.get_chess_type()
	
	# 从节点名称推断棋子类型
	var node_name = get_parent().name.to_lower()
	if "warrior" in node_name:
		return "warrior"
	elif "mage" in node_name:
		return "mage"
	elif "archer" in node_name:
		return "archer"
	elif "assassin" in node_name:
		return "assassin"
	elif "tank" in node_name:
		return "tank"
	elif "support" in node_name:
		return "support"
	
	# 默认返回空字符串
	return ""

# 应用当前皮肤
func _apply_current_skin() -> void:
	# 获取当前选中的皮肤
	current_skin_id = GameManager.skin_manager.get_selected_skin_id("chess")
	
	# 应用皮肤
	_apply_skin(current_skin_id)

# 应用皮肤
func _apply_skin(skin_id: String) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(skin_id, "chess")
	if skin_model == null:
		push_error("无法加载棋子皮肤: " + skin_id)
		return
	
	# 获取纹理覆盖
	var texture_overrides = skin_model.get_texture_overrides()
	
	# 应用纹理
	_apply_texture_overrides(texture_overrides)

# 应用纹理覆盖
func _apply_texture_overrides(texture_overrides: Dictionary) -> void:
	# 检查是否有精灵组件
	if sprite == null:
		push_error("棋子没有Sprite2D组件")
		return
	
	# 检查是否有对应棋子类型的纹理
	if chess_type.is_empty():
		push_error("未知的棋子类型")
		return
	
	# 检查是否有对应的纹理
	if not texture_overrides.has(chess_type):
		push_error("皮肤没有对应的棋子纹理: " + chess_type)
		return
	
	# 加载纹理
	var texture_path = texture_overrides[chess_type]
	var texture = load(texture_path)
	
	if texture == null:
		push_error("无法加载纹理: " + texture_path)
		return
	
	# 应用纹理
	sprite.texture = texture

# 棋子皮肤应用事件处理
func _on_chess_skin_applied(event: SkinEvents.ChessSkinAppliedEvent) -> void:
	# 更新当前皮肤ID
	current_skin_id = event.skin_id
	
	# 应用纹理覆盖
	_apply_texture_overrides(event.texture_overrides)

# 棋子皮肤预览事件处理
func _on_chess_skin_preview(event: SkinEvents.ChessSkinPreviewEvent) -> void:
	# 获取皮肤数据
	var skin_model = GameManager.skin_manager.get_skin_data(event.skin_id, "chess")
	if skin_model == null:
		push_error("无法加载棋子皮肤预览: " + event.skin_id)
		return
	
	# 获取纹理覆盖
	var texture_overrides = skin_model.get_texture_overrides()
	
	# 临时应用纹理
	_apply_texture_overrides(texture_overrides)
	
	# 延迟恢复原来的皮肤
	await get_tree().create_timer(2.0).timeout
	_apply_skin(current_skin_id)

# 清理
func _exit_tree() -> void:
	# 断开事件连接
	GlobalEventBus.skin.remove_class_listener(SkinEvents.ChessSkinAppliedEvent, _on_chess_skin_applied)
	GlobalEventBus.skin.remove_class_listener(SkinEvents.ChessSkinPreviewEvent, _on_chess_skin_preview)
