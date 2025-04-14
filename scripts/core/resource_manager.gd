extends Node
## 资源管理器
## 负责游戏资源的加载和缓存

# 资源缓存
var _texture_cache = {}
var _audio_cache = {}
var _scene_cache = {}
var _shader_cache = {}
var _font_cache = {}

# 资源路径
const TEXTURE_PATH = "res://assets/images/"
const AUDIO_PATH = "res://assets/audio/"
const SCENE_PATH = "res://scenes/"
const SHADER_PATH = "res://assets/shaders/"
const FONT_PATH = "res://assets/fonts/"

# 预加载资源列表
var _preload_list = {
	"textures": [],
	"audio": [],
	"scenes": [],
	"shaders": [],
	"fonts": []
}

# 加载状态
var _loading_complete = false
var _loading_progress = 0.0

# 加载完成信号
signal loading_completed
signal loading_progress_changed(progress)

func _ready():
	# 初始化资源管理器
	pass

## 预加载资源
func preload_resources() -> void:
	# 从配置中获取预加载列表
	_load_preload_list()
	
	# 开始预加载
	_start_preloading()

## 加载预加载列表
func _load_preload_list() -> void:
	# 这里应该从配置文件加载预加载列表
	# 暂时使用硬编码的列表
	_preload_list = {
		"textures": [
			"ui/button_normal.png",
			"ui/button_pressed.png",
			"ui/button_hover.png",
			"ui/panel_background.png",
			"backgrounds/main_menu_bg.png"
		],
		"audio": [
			"bgm/main_menu.ogg",
			"bgm/battle.ogg",
			"sfx/click.ogg"
		],
		"scenes": [
			# 场景通常按需加载，而不是预加载
		],
		"shaders": [
			# 着色器通常按需加载
		],
		"fonts": [
			"default_font.ttf"
		]
	}

## 开始预加载资源
func _start_preloading() -> void:
	_loading_complete = false
	_loading_progress = 0.0
	
	# 计算总资源数
	var total_resources = 0
	for category in _preload_list:
		total_resources += _preload_list[category].size()
	
	if total_resources == 0:
		_loading_complete = true
		loading_completed.emit()
		return
	
	var loaded_resources = 0
	
	# 预加载纹理
	for texture_path in _preload_list.textures:
		var full_path = TEXTURE_PATH + texture_path
		var texture = load(full_path)
		if texture:
			_texture_cache[texture_path] = texture
		
		loaded_resources += 1
		_loading_progress = float(loaded_resources) / total_resources
		loading_progress_changed.emit(_loading_progress)
	
	# 预加载音频
	for audio_path in _preload_list.audio:
		var full_path = AUDIO_PATH + audio_path
		var audio = load(full_path)
		if audio:
			_audio_cache[audio_path] = audio
		
		loaded_resources += 1
		_loading_progress = float(loaded_resources) / total_resources
		loading_progress_changed.emit(_loading_progress)
	
	# 预加载字体
	for font_path in _preload_list.fonts:
		var full_path = FONT_PATH + font_path
		var font = load(full_path)
		if font:
			_font_cache[font_path] = font
		
		loaded_resources += 1
		_loading_progress = float(loaded_resources) / total_resources
		loading_progress_changed.emit(_loading_progress)
	
	# 预加载完成
	_loading_complete = true
	loading_completed.emit()

## 获取纹理
func get_texture(path: String) -> Texture2D:
	# 检查缓存
	if _texture_cache.has(path):
		return _texture_cache[path]
	
	# 加载纹理
	var full_path = TEXTURE_PATH + path
	if not FileAccess.file_exists(full_path):
		push_error("纹理文件不存在: " + full_path)
		return null
	
	var texture = load(full_path)
	if texture:
		_texture_cache[path] = texture
		return texture
	
	return null

## 获取音频
func get_audio(path: String) -> AudioStream:
	# 检查缓存
	if _audio_cache.has(path):
		return _audio_cache[path]
	
	# 加载音频
	var full_path = AUDIO_PATH + path
	if not FileAccess.file_exists(full_path):
		push_error("音频文件不存在: " + full_path)
		return null
	
	var audio = load(full_path)
	if audio:
		_audio_cache[path] = audio
		return audio
	
	return null

## 获取场景
func get_scene(path: String) -> PackedScene:
	# 检查缓存
	if _scene_cache.has(path):
		return _scene_cache[path]
	
	# 加载场景
	var full_path = SCENE_PATH + path
	if not FileAccess.file_exists(full_path):
		push_error("场景文件不存在: " + full_path)
		return null
	
	var scene = load(full_path)
	if scene:
		_scene_cache[path] = scene
		return scene
	
	return null

## 获取着色器
func get_shader(path: String) -> Shader:
	# 检查缓存
	if _shader_cache.has(path):
		return _shader_cache[path]
	
	# 加载着色器
	var full_path = SHADER_PATH + path
	if not FileAccess.file_exists(full_path):
		push_error("着色器文件不存在: " + full_path)
		return null
	
	var shader = load(full_path)
	if shader:
		_shader_cache[path] = shader
		return shader
	
	return null

## 获取字体
func get_font(path: String) -> Font:
	# 检查缓存
	if _font_cache.has(path):
		return _font_cache[path]
	
	# 加载字体
	var full_path = FONT_PATH + path
	if not FileAccess.file_exists(full_path):
		push_error("字体文件不存在: " + full_path)
		return null
	
	var font = load(full_path)
	if font:
		_font_cache[path] = font
		return font
	
	return null

## 清除缓存
func clear_cache(category: String = "") -> void:
	if category == "" or category == "textures":
		_texture_cache.clear()
	
	if category == "" or category == "audio":
		_audio_cache.clear()
	
	if category == "" or category == "scenes":
		_scene_cache.clear()
	
	if category == "" or category == "shaders":
		_shader_cache.clear()
	
	if category == "" or category == "fonts":
		_font_cache.clear()

## 获取加载进度
func get_loading_progress() -> float:
	return _loading_progress

## 是否加载完成
func is_loading_complete() -> bool:
	return _loading_complete
