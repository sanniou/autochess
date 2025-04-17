# Autoload 顺序建议

为了确保管理器之间的依赖关系正确初始化，建议在 project.godot 中按以下顺序设置 Autoload：

```
# 核心系统
EventBus="*res://scripts/autoload/event_bus.gd"
TextUtils="*res://scripts/ui/text_utils.gd"
UIUtils="*res://scripts/ui/ui_utils.gd"

# 配置和资源管理
ConfigManager="*res://scripts/autoload/config_manager.gd"
ResourceManager="*res://scripts/autoload/resource_manager.gd"
LocalizationManager="*res://scripts/autoload/localization_manager.gd"
FontManager="*res://scripts/autoload/font_manager.gd"

# 音频和存档
AudioManager="*res://scripts/autoload/audio_manager.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"

# UI相关
UIManager="*res://scripts/managers/ui_manager.gd"
SceneManager="*res://scripts/managers/scene_manager.gd"
ThemeManager="*res://scripts/managers/theme_manager.gd"

# 游戏核心
GameManager="*res://scripts/autoload/game_manager.gd"

# 其他管理器
# 这些管理器将由GameManager在需要时初始化
```

## 依赖关系说明

1. **EventBus** 应该最先加载，因为几乎所有其他系统都依赖于它进行通信
2. **TextUtils** 和 **UIUtils** 提供基础工具函数，应该早期加载
3. **ConfigManager** 和 **ResourceManager** 负责配置和资源加载，许多其他系统依赖它们
4. **LocalizationManager** 和 **FontManager** 处理文本和字体，依赖于ConfigManager
5. **AudioManager** 和 **SaveManager** 提供音频和存档功能，相对独立
6. **UIManager**、**SceneManager** 和 **ThemeManager** 处理UI和场景，依赖于前面的系统
7. **GameManager** 应该最后加载，因为它协调所有其他系统

## 注意事项

- 这个顺序确保了依赖关系的正确初始化
- GameManager会在需要时初始化其他管理器（如BattleManager、PlayerManager等）
- 使用管理器注册系统可以更灵活地管理依赖关系
- 如果添加新的Autoload，请考虑其依赖关系，并将其放在适当的位置
