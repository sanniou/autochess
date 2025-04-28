extends Resource
class_name MapTheme
## 地图主题
## 定义地图的视觉样式和主题

# 基本信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# 节点样式
@export var node_colors: Dictionary = {
	"default": "#FFFFFF",
	"battle": "#FF5555",
	"shop": "#55AAFF",
	"event": "#FFAA55",
	"boss": "#FF5555",
	"treasure": "#FFFF55",
	"rest": "#55FF55",
	"start": "#55FF55",
	"end": "#FF5555"
}

# 连接样式
@export var connection_colors: Dictionary = {
	"default": "#AAAAAA",
	"elite": "#FF5555",
	"hidden": "#55AAFF",
	"locked": "#555555"
}

# 背景样式
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var grid_color: Color = Color(0.2, 0.2, 0.2, 0.5)
@export var background_texture: String = ""

# 动画设置
@export var animation_speed: float = 1.0
@export var use_animations: bool = true

# 从字典创建主题
static func from_dict(dict: Dictionary) -> MapTheme:
	var theme = MapTheme.new()
	
	# 设置基本信息
	theme.id = dict.get("id", "")
	theme.name = dict.get("name", "")
	theme.description = dict.get("description", "")
	
	# 设置节点样式
	if dict.has("node_colors"):
		theme.node_colors = dict.get("node_colors").duplicate()
	
	# 设置连接样式
	if dict.has("connection_colors"):
		theme.connection_colors = dict.get("connection_colors").duplicate()
	
	# 设置背景样式
	if dict.has("background_color"):
		theme.background_color = Color(dict.get("background_color"))
	
	if dict.has("grid_color"):
		theme.grid_color = Color(dict.get("grid_color"))
	
	if dict.has("background_texture"):
		theme.background_texture = dict.get("background_texture")
	
	# 设置动画设置
	if dict.has("animation_speed"):
		theme.animation_speed = dict.get("animation_speed")
	
	if dict.has("use_animations"):
		theme.use_animations = dict.get("use_animations")
	
	return theme

# 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"node_colors": node_colors.duplicate(),
		"connection_colors": connection_colors.duplicate(),
		"background_color": background_color.to_html(),
		"grid_color": grid_color.to_html(),
		"background_texture": background_texture,
		"animation_speed": animation_speed,
		"use_animations": use_animations
	}

# 获取节点颜色
func get_node_color(node_type: String) -> Color:
	if node_colors.has(node_type):
		return Color(node_colors[node_type])
	return Color(node_colors.get("default", "#FFFFFF"))

# 获取连接颜色
func get_connection_color(connection_type: String) -> Color:
	if connection_colors.has(connection_type):
		return Color(connection_colors[connection_type])
	return Color(connection_colors.get("default", "#AAAAAA"))

# 创建默认主题
static func create_default() -> MapTheme:
	var theme = MapTheme.new()
	theme.id = "default"
	theme.name = "默认主题"
	theme.description = "默认地图主题"
	return theme

# 创建暗色主题
static func create_dark() -> MapTheme:
	var theme = MapTheme.new()
	theme.id = "dark"
	theme.name = "暗色主题"
	theme.description = "暗色地图主题"
	theme.background_color = Color(0.05, 0.05, 0.05, 1.0)
	theme.grid_color = Color(0.15, 0.15, 0.15, 0.5)
	
	# 调整节点颜色为更暗的色调
	theme.node_colors = {
		"default": "#444444",
		"battle": "#992222",
		"shop": "#224477",
		"event": "#996622",
		"boss": "#992222",
		"treasure": "#999922",
		"rest": "#229922",
		"start": "#229922",
		"end": "#992222"
	}
	
	# 调整连接颜色
	theme.connection_colors = {
		"default": "#666666",
		"elite": "#992222",
		"hidden": "#224477",
		"locked": "#333333"
	}
	
	return theme

# 创建亮色主题
static func create_light() -> MapTheme:
	var theme = MapTheme.new()
	theme.id = "light"
	theme.name = "亮色主题"
	theme.description = "亮色地图主题"
	theme.background_color = Color(0.95, 0.95, 0.95, 1.0)
	theme.grid_color = Color(0.8, 0.8, 0.8, 0.5)
	
	# 调整节点颜色为更亮的色调
	theme.node_colors = {
		"default": "#FFFFFF",
		"battle": "#FF9999",
		"shop": "#99CCFF",
		"event": "#FFCC99",
		"boss": "#FF9999",
		"treasure": "#FFFF99",
		"rest": "#99FF99",
		"start": "#99FF99",
		"end": "#FF9999"
	}
	
	# 调整连接颜色
	theme.connection_colors = {
		"default": "#CCCCCC",
		"elite": "#FF9999",
		"hidden": "#99CCFF",
		"locked": "#AAAAAA"
	}
	
	return theme
