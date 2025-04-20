extends Control

# 引用
@onready var language_option = $MainPanel/VBoxContainer/LanguageContainer/LanguageOptionButton
@onready var key_input = $MainPanel/VBoxContainer/KeyContainer/KeyInput
@onready var params_input = $MainPanel/VBoxContainer/ParamsContainer/ParamsInput
@onready var translate_button = $MainPanel/VBoxContainer/TranslateButton
@onready var result_text = $MainPanel/VBoxContainer/ResultContainer/ResultPanel/ResultText
@onready var common_keys_grid = $MainPanel/VBoxContainer/CommonKeysContainer/CommonKeysGrid
@onready var back_button = $BackButton

# 本地化管理器
var localization_manager = null

# 常用翻译键
var common_keys = [
    "ui.main_menu.start",
    "ui.main_menu.settings",
    "ui.main_menu.quit",
    "game.battle.victory",
    "game.battle.defeat",
    "game.chess.upgrade",
    "game.item.equip",
    "game.map.next_level"
]

# 初始化
func _ready():
    # 获取本地化管理器
    localization_manager = LocalizationManager

    # 连接按钮信号
    translate_button.pressed.connect(_on_translate_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)
    language_option.item_selected.connect(_on_language_selected)

    # 初始化语言选项
    _initialize_language_options()

    # 初始化常用键按钮
    _initialize_common_key_buttons()

# 初始化语言选项
func _initialize_language_options():
    # 清空选项
    language_option.clear()

    # 获取可用语言
    var languages = localization_manager.get_available_languages()

    # 添加到选项
    for language in languages:
        language_option.add_item(language)

    # 设置当前语言
    var current_language = localization_manager.get_current_language()
    for i in range(language_option.item_count):
        if language_option.get_item_text(i) == current_language:
            language_option.select(i)
            break

# 初始化常用键按钮
func _initialize_common_key_buttons():
    # 清空网格
    for child in common_keys_grid.get_children():
        child.queue_free()

    # 添加常用键按钮
    for key in common_keys:
        var button = Button.new()
        button.text = key
        button.pressed.connect(func(): _on_common_key_button_pressed(key))
        common_keys_grid.add_child(button)

# 翻译按钮处理
func _on_translate_button_pressed():
    # 获取翻译键
    var key = key_input.text
    if key.is_empty():
        result_text.text = "请输入翻译键!"
        return

    # 获取参数
    var params = []
    var params_str = params_input.text
    if not params_str.is_empty():
        params = params_str.split(",")

    # 获取翻译
    var translation = ""
    if params.is_empty():
        translation = localization_manager.translate(key)
    else:
        # 处理参数
        var formatted_params = []
        for param in params:
            formatted_params.append(param.strip_edges())

        # 使用参数获取翻译
        translation = localization_manager.translate(key, formatted_params)

    # 显示结果
    result_text.text = translation

# 语言选择处理
func _on_language_selected(index):
    # 获取选择的语言
    var language = language_option.get_item_text(index)

    # 切换语言
    localization_manager.set_language(language)

    # 更新标题
    $Title.text = localization_manager.translate("ui.test.localization_title")

    # 如果有翻译键，重新翻译
    if not key_input.text.is_empty():
        _on_translate_button_pressed()

# 常用键按钮处理
func _on_common_key_button_pressed(key):
    # 设置翻译键
    key_input.text = key

    # 触发翻译
    _on_translate_button_pressed()

# 返回按钮处理
func _on_back_button_pressed():
    # 返回测试菜单
    get_tree().change_scene_to_file("res://scenes/test/test_menu.tscn")
