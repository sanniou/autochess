extends Node2D
class_name BoardManager
## 棋盘管理器
## 管理整个棋盘和格子的交互逻辑

# 棋盘配置
@export var board_width: int = 8
@export var board_height: int = 4
@export var bench_size: int = 9
@export var cell_size: Vector2 = Vector2(64, 64)
@export var cell_scene: PackedScene

# 棋盘主题
@export var board_theme: String = "default"  # 棋盘主题(default/forest/desert/snow等)
@export var use_special_cells: bool = true   # 是否使用特殊效果格子

# 棋盘数据
var cells: Array = []  # 二维数组存储所有格子
var bench_cells: Array = []  # 备战区格子
var pieces: Array = []  # 当前棋盘上的棋子
var bench_pieces: Array = []  # 备战区棋子

# 拖拽相关
var dragging_piece: ChessPiece = null
var drag_start_cell: BoardCell = null
var drag_offset: Vector2 = Vector2.ZERO
var is_combining: bool = false  # 是否正在合成棋子

# 对象池
var piece_pool: ObjectPool

# 特殊格子概率
const SPECIAL_CELL_CHANCE = 0.15  # 特殊格子生成概率
const SPECIAL_EFFECTS = {
    "attack_buff": {"weight": 30, "min_value": 5, "max_value": 15},
    "health_buff": {"weight": 30, "min_value": 20, "max_value": 50},
    "armor_buff": {"weight": 20, "min_value": 5, "max_value": 15},
    "speed_buff": {"weight": 20, "min_value": 0.1, "max_value": 0.3}
}

func _ready():
    # 初始化对象池
    piece_pool = ObjectPool.new()
    add_child(piece_pool)

    # 初始化棋盘
    initialize_board()

    # 连接信号
    EventBus.battle_started.connect(_on_battle_started)
    EventBus.battle_ended.connect(_on_battle_ended)

func _process(_delta):
    # 处理拖拽逻辑
    if dragging_piece:
        dragging_piece.global_position = get_viewport().get_mouse_position() - drag_offset

# 初始化棋盘
func initialize_board():
    # 清空现有棋盘
    for child in get_children():
        if child is BoardCell:
            remove_child(child)
            child.queue_free()

    cells = []
    bench_cells = []
    pieces = []
    bench_pieces = []

    # 创建棋盘格子
    for y in range(board_height):
        var row = []
        for x in range(board_width):
            var cell = cell_scene.instantiate() as BoardCell
            cell.grid_position = Vector2i(x, y)
            cell.position = Vector2(x * cell_size.x, y * cell_size.y)

            # 设置格子类型
            if y == 0:  # 第一行为玩家出生区
                cell.set_cell_type("spawn")
            elif y == board_height - 1:  # 最后一行为敌人出生区
                cell.set_cell_type("blocked")
            else:
                cell.set_cell_type("normal")

            add_child(cell)
            row.append(cell)

            # 连接信号
            cell.cell_clicked.connect(_on_cell_clicked)
            cell.cell_hovered.connect(_on_cell_hovered)
            cell.cell_exited.connect(_on_cell_exited)
            cell.piece_placed.connect(_on_piece_placed)
            cell.piece_removed.connect(_on_piece_removed)

        cells.append(row)

    # 创建备战区格子
    var bench_y = board_height * cell_size.y + 20  # 备战区位置
    for i in range(bench_size):
        var cell = cell_scene.instantiate() as BoardCell
        cell.grid_position = Vector2i(i, -1)  # 使用特殊坐标表示备战区
        cell.position = Vector2(i * cell_size.x, bench_y)
        cell.set_cell_type("bench")

        add_child(cell)
        bench_cells.append(cell)

        # 连接信号
        cell.cell_clicked.connect(_on_cell_clicked)
        cell.cell_hovered.connect(_on_cell_hovered)
        cell.cell_exited.connect(_on_cell_exited)
        cell.piece_placed.connect(_on_bench_piece_placed)
        cell.piece_removed.connect(_on_bench_piece_removed)

    # 生成特殊格子
    if use_special_cells:
        _generate_special_cells()

    # 发送棋盘初始化信号
    EventBus.board_initialized.emit()

# 放置棋子
func place_piece(piece: ChessPiece, cell_pos: Vector2i) -> bool:
    if not is_valid_cell(cell_pos):
        return false

    var cell = get_cell(cell_pos)
    if cell.place_piece(piece):
        pieces.append(piece)
        return true
    return false

# 移动棋子
func move_piece(piece: ChessPiece, target_pos: Vector2i) -> bool:
    if not is_valid_cell(target_pos):
        return false

    var from_cell = get_cell(piece.board_position)
    var to_cell = get_cell(target_pos)

    if from_cell and to_cell and from_cell.remove_piece():
        return to_cell.place_piece(piece)
    return false

# 获取棋子
func get_piece_at(pos: Vector2i) -> ChessPiece:
    if is_valid_cell(pos):
        return get_cell(pos).current_piece
    return null

# 获取格子
func get_cell(pos: Vector2i) -> BoardCell:
    if is_valid_cell(pos):
        return cells[pos.y][pos.x]
    return null

# 检查格子是否有效
func is_valid_cell(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height

# 获取所有敌方棋子
func get_enemy_pieces(is_player: bool) -> Array:
    var enemies = []
    for piece in pieces:
        if piece.is_player_piece != is_player:
            enemies.append(piece)
    return enemies

# 获取所有友方棋子
func get_ally_pieces(is_player: bool) -> Array:
    var allies = []
    for piece in pieces:
        if piece.is_player_piece == is_player:
            allies.append(piece)
    return allies

# 从对象池获取棋子
func get_piece_from_pool(piece_id: String) -> ChessPiece:
    var piece = piece_pool.get_object(piece_id)
    if piece:
        piece.reset_stats()
        piece.show()
    return piece

# 回收棋子到对象池
func return_piece_to_pool(piece: ChessPiece):
    piece_pool.return_object(piece)

# 格子点击处理
func _on_cell_clicked(cell: BoardCell):
    if cell.current_piece and not dragging_piece:
        # 开始拖拽
        start_drag_piece(cell)

        # 尝试合成棋子
        if not is_combining and cell.current_piece.star_level < 3:
            try_combine_pieces(cell.current_piece)
    elif dragging_piece:
        # 结束拖拽
        end_drag_piece(cell)

    EventBus.cell_clicked.emit(cell)

# 格子悬停处理
func _on_cell_hovered(cell: BoardCell):
    # 如果正在拖拽棋子，高亮可放置的格子
    if dragging_piece and cell.is_playable and not cell.current_piece:
        cell.highlight(true, Color(0.2, 0.8, 0.2, 0.3))

    # 发送格子悬停信号
    EventBus.cell_hovered.emit(cell)

# 格子离开处理
func _on_cell_exited(cell: BoardCell):
    # 取消高亮
    if cell.is_highlighted and not is_combining:
        cell.highlight(false)

    # 发送格子离开信号
    EventBus.cell_exited.emit(cell)

# 棋子放置处理
func _on_piece_placed(piece: ChessPiece):
    if not pieces.has(piece):
        pieces.append(piece)
    EventBus.piece_placed_on_board.emit(piece)

# 棋子移除处理
func _on_piece_removed(piece: ChessPiece):
    pieces.erase(piece)
    EventBus.piece_removed_from_board.emit(piece)

# 备战区棋子放置处理
func _on_bench_piece_placed(piece: ChessPiece):
    if not bench_pieces.has(piece):
        bench_pieces.append(piece)
    EventBus.piece_placed_on_bench.emit(piece)

# 备战区棋子移除处理
func _on_bench_piece_removed(piece: ChessPiece):
    bench_pieces.erase(piece)
    EventBus.piece_removed_from_bench.emit(piece)

# 获取移动范围
func get_movement_range(start_pos: Vector2i, move_range: int) -> Array:
    var reachable = []
    var visited = {}
    var queue = [{ "pos": start_pos, "distance": 0 }]

    while not queue.is_empty():
        var current = queue.pop_front()
        var pos = current.pos
        var distance = current.distance

        if visited.has(pos) or distance > move_range:
            continue

        visited[pos] = true
        reachable.append(pos)

        # 检查相邻格子
        var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
        for dir in directions:
            var new_pos = pos + dir
            if is_valid_cell(new_pos) and not get_cell(new_pos).current_piece:
                queue.append({ "pos": new_pos, "distance": distance + 1 })

    return reachable

# 获取攻击目标
func find_attack_target(piece: ChessPiece) -> ChessPiece:
    var cell = get_cell(piece.board_position)
    var range_cells = cell.get_attack_range_cells(self, piece.attack_range)

    for target_cell in range_cells:
        if target_cell.has_enemy_piece(piece.is_player_piece):
            return target_cell.current_piece

    return null

# 重置棋盘
func reset_board():
    for row in cells:
        for cell in row:
            if cell.current_piece:
                cell.remove_piece()
    pieces.clear()

    # 重新生成特殊格子
    if use_special_cells:
        _generate_special_cells()

    # 发送棋盘重置信号
    EventBus.board_reset.emit()

# 开始拖拽棋子
func start_drag_piece(cell: BoardCell) -> void:
    if not cell.current_piece:
        return

    dragging_piece = cell.remove_piece()
    drag_start_cell = cell
    drag_offset = get_viewport().get_mouse_position() - dragging_piece.global_position

    # 将棋子移到顶层显示
    remove_child(dragging_piece)
    add_child(dragging_piece)

    # 添加视觉反馈
    dragging_piece.scale = Vector2(1.2, 1.2)  # 缩放效果
    dragging_piece.modulate.a = 0.8  # 半透明

    # 高亮可放置的格子
    _highlight_valid_cells()

# 结束拖拽棋子
func end_drag_piece(target_cell: BoardCell = null) -> void:
    if not dragging_piece:
        return

    # 恢复棋子的视觉效果
    dragging_piece.scale = Vector2(1.0, 1.0)
    dragging_piece.modulate.a = 1.0

    # 取消所有格子的高亮
    _clear_all_highlights()

    # 如果没有指定目标格子，查找鼠标下方的格子
    if not target_cell:
        var mouse_pos = get_viewport().get_mouse_position()
        target_cell = _find_cell_at_position(mouse_pos)

    if target_cell and not target_cell.current_piece and target_cell.is_playable:
        # 放置到新格子
        target_cell.place_piece(dragging_piece)

        # 发送移动信号
        EventBus.chess_piece_moved.emit(dragging_piece, drag_start_cell.grid_position, target_cell.grid_position)
    else:
        # 放回原格子
        drag_start_cell.place_piece(dragging_piece)

    dragging_piece = null
    drag_start_cell = null

# 查找指定位置的格子
func _find_cell_at_position(global_pos: Vector2) -> BoardCell:
    # 检查主棋盘格子
    for row in cells:
        for cell in row:
            var rect = Rect2(cell.global_position, cell_size)
            if rect.has_point(global_pos):
                return cell

    # 检查备战区格子
    for cell in bench_cells:
        var rect = Rect2(cell.global_position, cell_size)
        if rect.has_point(global_pos):
            return cell

    return null

# 获取所有备战区棋子
func get_bench_pieces() -> Array:
    return bench_pieces.duplicate()

# 获取备战区格子
func get_bench_cell(index: int) -> BoardCell:
    if index >= 0 and index < bench_cells.size():
        return bench_cells[index]
    return null

# 战斗开始事件处理
func _on_battle_started() -> void:
    # 禁用拖拽功能
    set_process(false)

    # 锁定所有格子
    for row in cells:
        for cell in row:
            cell.is_playable = false

    for cell in bench_cells:
        cell.is_playable = false

# 战斗结束事件处理
func _on_battle_ended(_result) -> void:
    # 重新启用拖拽功能
    set_process(true)

    # 解锁格子
    for row in cells:
        for cell in row:
            if cell.cell_type != "blocked":
                cell.is_playable = true

    for cell in bench_cells:
        cell.is_playable = true

# 生成特殊格子
func _generate_special_cells() -> void:
    # 清除现有特殊格子
    for row in cells:
        for cell in row:
            if cell.special_effect != "":
                cell.clear_special_effect()

    # 只在玩家区域生成特殊格子
    for y in range(1, board_height - 1):  # 跳过出生区和敌人区
        for x in range(board_width):
            # 根据概率决定是否生成特殊格子
            if randf() < SPECIAL_CELL_CHANCE:
                var cell = cells[y][x]

                # 随机选择一种特殊效果
                var effect = _weighted_random_effect()
                var effect_data = SPECIAL_EFFECTS[effect]

                # 随机生成效果值
                var value = randf_range(effect_data.min_value, effect_data.max_value)

                # 设置特殊效果
                cell.set_special_effect(effect, value)

# 加权随机选择特殊效果
func _weighted_random_effect() -> String:
    var total_weight = 0
    for effect in SPECIAL_EFFECTS:
        total_weight += SPECIAL_EFFECTS[effect].weight

    var random_value = randi() % total_weight
    var current_weight = 0

    for effect in SPECIAL_EFFECTS:
        current_weight += SPECIAL_EFFECTS[effect].weight
        if random_value < current_weight:
            return effect

    # 默认返回第一个效果
    return SPECIAL_EFFECTS.keys()[0]

# 升级棋子
func upgrade_piece(piece_id: String) -> ChessPiece:
    # 查找相同类型和星级的棋子
    var same_pieces = []

    # 检查棋盘上的棋子
    for p in pieces:
        if p.id == piece_id and p.star_level == same_pieces[0].star_level if same_pieces else 1:
            same_pieces.append(p)
            if same_pieces.size() >= 3:
                break

    # 检查备战区的棋子
    if same_pieces.size() < 3:
        for p in bench_pieces:
            if p.id == piece_id and p.star_level == same_pieces[0].star_level if same_pieces else 1:
                same_pieces.append(p)
                if same_pieces.size() >= 3:
                    break

    # 如果没有足够的棋子，返回空
    if same_pieces.size() < 3:
        return null

    # 获取第一个棋子的位置
    var first_piece = same_pieces[0]
    var first_cell = _find_cell_with_piece(first_piece)

    # 移除所有相同的棋子
    for p in same_pieces:
        var cell = _find_cell_with_piece(p)
        if cell:
            cell.remove_piece()

    # 创建升级后的棋子
    var upgraded_piece = get_piece_from_pool(piece_id)
    upgraded_piece.star_level = same_pieces[0].star_level + 1

    # 如果有原始位置，放回原位置
    if first_cell:
        first_cell.place_piece(upgraded_piece)

    # 发送升级信号
    EventBus.chess_piece_upgraded.emit(upgraded_piece)

    return upgraded_piece

# 查找棋子所在的格子
func _find_cell_with_piece(piece: ChessPiece) -> BoardCell:
    # 检查棋盘格子
    for row in cells:
        for cell in row:
            if cell.current_piece == piece:
                return cell

    # 检查备战区格子
    for cell in bench_cells:
        if cell.current_piece == piece:
            return cell

    return null

# 高亮可放置的格子
func _highlight_valid_cells() -> void:
    if not dragging_piece:
        return

    # 高亮棋盘上的可放置格子
    for row in cells:
        for cell in row:
            if cell.is_playable and not cell.current_piece:
                cell.highlight(true, Color(0.2, 0.8, 0.2, 0.3))

    # 高亮备战区的可放置格子
    for cell in bench_cells:
        if cell.is_playable and not cell.current_piece:
            cell.highlight(true, Color(0.2, 0.8, 0.2, 0.3))

# 清除所有高亮
func _clear_all_highlights() -> void:
    # 清除棋盘上的高亮
    for row in cells:
        for cell in row:
            if cell.is_highlighted:
                cell.highlight(false)

    # 清除备战区的高亮
    for cell in bench_cells:
        if cell.is_highlighted:
            cell.highlight(false)

# 尝试合成棋子
func try_combine_pieces(piece: ChessPiece) -> bool:
    # 如果棋子已经是最高星级，不能合成
    if piece.star_level >= 3:
        return false

    # 查找相同类型和星级的棋子
    var same_pieces = [piece]

    # 检查棋盘上的棋子
    for p in pieces:
        if p != piece and p.id == piece.id and p.star_level == piece.star_level:
            same_pieces.append(p)
            if same_pieces.size() >= 3:
                break

    # 检查备战区的棋子
    if same_pieces.size() < 3:
        for p in bench_pieces:
            if p != piece and p.id == piece.id and p.star_level == piece.star_level:
                same_pieces.append(p)
                if same_pieces.size() >= 3:
                    break

    # 如果有足够的棋子，进行合成
    if same_pieces.size() >= 3:
        is_combining = true

        # 高亮可合成的棋子
        for p in same_pieces:
            var cell = _find_cell_with_piece(p)
            if cell:
                cell.highlight(true, Color(1.0, 0.8, 0.2, 0.5))

        # 合成棋子
        upgrade_piece(piece.id)

        # 取消高亮
        for row in cells:
            for cell in row:
                cell.highlight(false)

        for cell in bench_cells:
            cell.highlight(false)

        is_combining = false
        return true

    return false
