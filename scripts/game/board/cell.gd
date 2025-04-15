extends Area2D
class_name BoardCell
## 棋盘格子类
## 管理棋子的放置、移动和战斗交互

# 信号
signal piece_placed(piece)  # 棋子放置信号
signal piece_removed(piece) # 棋子移除信号
signal cell_clicked(cell)   # 格子点击信号

# 格子属性
var grid_position: Vector2i = Vector2i.ZERO  # 格子坐标
var current_piece: ChessPiece = null        # 当前棋子
var is_highlighted: bool = false            # 是否高亮
var is_playable: bool = true                # 是否可放置棋子
var cell_type: String = "normal"            # 格子类型(normal/spawn/blocked)

# 视觉组件
var highlight_sprite: Sprite2D
var base_sprite: Sprite2D

func _ready():
    # 初始化视觉组件
    _initialize_visuals()
    
    # 连接信号
    input_event.connect(_on_input_event)

# 初始化视觉组件
func _initialize_visuals():
    # 基础格子精灵
    base_sprite = Sprite2D.new()
    add_child(base_sprite)
    
    # 高亮精灵
    highlight_sprite = Sprite2D.new()
    highlight_sprite.modulate = Color(1, 1, 1, 0.3)
    highlight_sprite.visible = false
    add_child(highlight_sprite)

# 放置棋子
func place_piece(piece: ChessPiece) -> bool:
    if not is_playable or current_piece != null:
        return false
    
    current_piece = piece
    piece.board_position = grid_position
    piece.position = position
    piece.is_player_piece = (cell_type == "spawn")  # 出生点棋子属于玩家
    
    # 发送信号
    piece_placed.emit(piece)
    EventBus.piece_placed.emit(piece, self)
    
    return true

# 移除棋子
func remove_piece() -> ChessPiece:
    if current_piece == null:
        return null
    
    var piece = current_piece
    current_piece = null
    piece.board_position = Vector2i(-1, -1)
    
    # 发送信号
    piece_removed.emit(piece)
    EventBus.piece_removed.emit(piece, self)
    
    return piece

# 高亮格子
func highlight(enable: bool, color: Color = Color.YELLOW):
    is_highlighted = enable
    highlight_sprite.visible = enable
    highlight_sprite.modulate = color

# 输入事件处理
func _on_input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        cell_clicked.emit(self)

# 设置格子类型
func set_cell_type(type: String, texture: Texture2D = null):
    cell_type = type
    match type:
        "normal":
            is_playable = true
            base_sprite.modulate = Color(0.8, 0.8, 0.8)
        "spawn":
            is_playable = true
            base_sprite.modulate = Color(0.5, 0.8, 0.5)
        "blocked":
            is_playable = false
            base_sprite.modulate = Color(0.8, 0.5, 0.5)
    
    if texture:
        base_sprite.texture = texture

# 获取相邻格子
func get_adjacent_cells(board_manager) -> Array:
    var adjacent = []
    var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    
    for dir in directions:
        var pos = grid_position + dir
        if board_manager.is_valid_cell(pos):
            adjacent.append(board_manager.get_cell(pos))
    
    return adjacent

# 获取攻击范围内的格子
func get_attack_range_cells(board_manager, range: int) -> Array:
    var cells = []
    
    for x in range(-range, range + 1):
        for y in range(-range, range + 1):
            var pos = grid_position + Vector2i(x, y)
            if board_manager.is_valid_cell(pos) and (x != 0 or y != 0):
                cells.append(board_manager.get_cell(pos))
    
    return cells

# 判断是否有敌方棋子
func has_enemy_piece(is_player: bool) -> bool:
    return current_piece != null and current_piece.is_player_piece != is_player

# 判断是否有友方棋子
func has_ally_piece(is_player: bool) -> bool:
    return current_piece != null and current_piece.is_player_piece == is_player
