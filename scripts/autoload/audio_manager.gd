extends Node
## 音频管理器
## 负责游戏音频的播放和管理

# 音频类型
enum AudioType {
	MUSIC,  # 背景音乐
	SFX,    # 音效
	UI      # UI音效
}

# 音频播放器节点
var music_players = []
var sfx_players = []
var ui_players = []

# 当前播放的音乐
var current_music = ""

# 音量设置
var master_volume = 1.0
var music_volume = 1.0
var sfx_volume = 1.0
var ui_volume = 1.0

# 是否静音
var is_muted = false

# 音频资源缓存
var audio_cache = {}

# 音频文件路径
const AUDIO_PATHS = {
	AudioType.MUSIC: "res://assets/audio/bgm/",
	AudioType.SFX: "res://assets/audio/sfx/",
	AudioType.UI: "res://assets/audio/ui/"
}

# 最大同时播放的音频数
const MAX_MUSIC_PLAYERS = 2  # 用于交叉淡入淡出
const MAX_SFX_PLAYERS = 8
const MAX_UI_PLAYERS = 4

func _ready():
	# 初始化音频播放器
	_initialize_audio_players()
	
	# 连接信号
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

## 初始化音频播放器
func _initialize_audio_players() -> void:
	# 创建音乐播放器
	for i in range(MAX_MUSIC_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = linear_to_db(music_volume)
		add_child(player)
		music_players.append(player)
	
	# 创建音效播放器
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)
	
	# 创建UI音效播放器
	for i in range(MAX_UI_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		player.volume_db = linear_to_db(ui_volume)
		add_child(player)
		ui_players.append(player)

## 播放背景音乐
func play_music(music_name: String, fade_time: float = 1.0) -> void:
	if current_music == music_name:
		return
	
	var music_path = AUDIO_PATHS[AudioType.MUSIC] + music_name
	var stream = _load_audio(music_path)
	if stream == null:
		EventBus.debug_message.emit("音乐文件不存在: " + music_path, 1)
		return
	
	# 找到一个空闲的音乐播放器
	var player = _get_free_player(AudioType.MUSIC)
	if player == null:
		EventBus.debug_message.emit("没有可用的音乐播放器", 1)
		return
	
	# 淡出当前音乐
	for p in music_players:
		if p != player and p.playing:
			_fade_out(p, fade_time)
	
	# 设置新音乐
	player.stream = stream
	player.volume_db = linear_to_db(0.0)  # 从静音开始
	player.play()
	
	# 淡入新音乐
	_fade_in(player, fade_time)
	
	current_music = music_name
	EventBus.bgm_changed.emit(music_name)

## 播放音效
func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_scale: float = 1.0) -> void:
	var sfx_path = AUDIO_PATHS[AudioType.SFX] + sfx_name
	var stream = _load_audio(sfx_path)
	if stream == null:
		EventBus.debug_message.emit("音效文件不存在: " + sfx_path, 1)
		return
	
	# 找到一个空闲的音效播放器
	var player = _get_free_player(AudioType.SFX)
	if player == null:
		EventBus.debug_message.emit("没有可用的音效播放器", 1)
		return
	
	# 设置音效
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()
	
	EventBus.sfx_played.emit(sfx_name)

## 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	var sound_path = AUDIO_PATHS[AudioType.UI] + sound_name
	var stream = _load_audio(sound_path)
	if stream == null:
		EventBus.debug_message.emit("UI音效文件不存在: " + sound_path, 1)
		return
	
	# 找到一个空闲的UI音效播放器
	var player = _get_free_player(AudioType.UI)
	if player == null:
		EventBus.debug_message.emit("没有可用的UI音效播放器", 1)
		return
	
	# 设置UI音效
	player.stream = stream
	player.volume_db = linear_to_db(ui_volume)
	player.play()

## 停止所有音乐
func stop_all_music(fade_time: float = 1.0) -> void:
	for player in music_players:
		if player.playing:
			_fade_out(player, fade_time)
	
	current_music = ""

## 停止所有音效
func stop_all_sfx() -> void:
	for player in sfx_players:
		player.stop()

## 停止所有UI音效
func stop_all_ui_sounds() -> void:
	for player in ui_players:
		player.stop()

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	
	# 更新所有音乐播放器的音量
	for player in music_players:
		if player.playing:
			player.volume_db = linear_to_db(music_volume)

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

## 设置UI音效音量
func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(ui_volume))

## 静音/取消静音
func toggle_mute() -> void:
	is_muted = !is_muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)

## 加载音频资源
func _load_audio(path: String) -> AudioStream:
	# 检查缓存
	if audio_cache.has(path):
		return audio_cache[path]
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path):
		return null
	
	# 加载音频资源
	var stream = load(path)
	if stream is AudioStream:
		audio_cache[path] = stream
		return stream
	
	return null

## 获取空闲的音频播放器
func _get_free_player(type: int) -> AudioStreamPlayer:
	var players
	match type:
		AudioType.MUSIC:
			players = music_players
		AudioType.SFX:
			players = sfx_players
		AudioType.UI:
			players = ui_players
	
	# 首先尝试找到一个未播放的播放器
	for player in players:
		if not player.playing:
			return player
	
	# 如果所有播放器都在播放，则选择一个最早开始播放的
	var oldest_player = players[0]
	var oldest_time = Time.get_ticks_msec()
	
	for player in players:
		var playback = player.get_playback_position()
		if playback < oldest_time:
			oldest_time = playback
			oldest_player = player
	
	return oldest_player

## 淡入音频
func _fade_in(player: AudioStreamPlayer, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(music_volume), duration)

## 淡出音频
func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(0.0), duration)
	tween.tween_callback(player.stop)

## 游戏暂停处理
func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		# 降低音乐音量
		for player in music_players:
			if player.playing:
				player.volume_db = linear_to_db(music_volume * 0.3)
	else:
		# 恢复音乐音量
		for player in music_players:
			if player.playing:
				player.volume_db = linear_to_db(music_volume)

## 游戏状态变更处理
func _on_game_state_changed(old_state, new_state) -> void:
	# 根据游戏状态切换音乐
	match new_state:
		GameManager.GameState.MAIN_MENU:
			play_music("main_menu.ogg")
		GameManager.GameState.MAP:
			play_music("map.ogg")
		GameManager.GameState.SHOP:
			play_music("shop.ogg")
		GameManager.GameState.GAME_OVER:
			play_music("game_over.ogg")
		GameManager.GameState.VICTORY:
			play_music("victory.ogg")

## 战斗开始处理
func _on_battle_started() -> void:
	play_music("battle.ogg")
	play_sfx("battle_start.ogg")

## 战斗结束处理
func _on_battle_ended(result) -> void:
	if result:
		play_sfx("victory.ogg")
	else:
		play_sfx("defeat.ogg")
