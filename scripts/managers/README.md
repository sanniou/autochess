# 管理器结构说明

本项目的管理器采用统一的目录结构，按照功能分类到不同的子目录中。

## 目录结构

- `scripts/managers/core/` - 核心管理器
  - `base_manager.gd` - 管理器基类
  - `manager_registry.gd` - 管理器注册表
  - `resource_manager.gd` - 资源管理器

- `scripts/managers/test/` - 测试管理器
  - `test_config_manager.gd` - 配置管理器测试脚本

- `scripts/managers/game/` - 游戏管理器
  - `battle_manager.gd` - 战斗管理器
  - `board_manager.gd` - 棋盘管理器
  - `map_manager.gd` - 地图管理器
  - `animation_manager.gd` - 动画管理器
  - `status_effect_manager.gd` - 状态效果管理器
  - `equipment_tier_manager.gd` - 装备等级管理器
  - 等等...

- `scripts/managers/ui/` - UI管理器
  - `ui_manager.gd` - UI管理器
  - `scene_manager.gd` - 场景管理器
  - `hud_manager.gd` - HUD管理器
  - 等等...

## 系统管理器

系统管理器分为两类：

1. **Autoload系统管理器**：作为Godot的Autoload节点加载的，它们位于`scripts/autoload/`目录中：
   - `game_manager.gd` - 游戏管理器
   - `config_manager.gd` - 配置管理器
   - `save_manager.gd` - 存档管理器
   - `audio_manager.gd` - 音频管理器
   - `localization_manager.gd` - 本地化管理器
   - `font_manager.gd` - 字体管理器

2. **其他系统管理器**：位于`scripts/managers/system/`目录中：
   - `network_manager.gd` - 网络管理器
   - `sync_manager.gd` - 数据同步管理器

Autoload系统管理器由于是Autoload，所以保留在原始位置，但在概念上它们属于系统管理器类别。

## 管理器基类

所有管理器都继承自`BaseManager`类，该类提供了统一的接口和生命周期管理：

```gdscript
extends Node
class_name BaseManager

# 信号
signal initialized()
signal reset_completed()
signal cleaned_up()
signal dependency_added(dependency_name: String)
signal dependency_removed(dependency_name: String)
signal error_occurred(error_message: String)

# 初始化状态
var _initialized: bool = false

# 管理器名称
var manager_name: String = ""

# 依赖的管理器
var _dependencies: Array[String] = []

# 错误信息
var _error: String = ""

# 初始化方法
func initialize() -> bool
# 子类重写此方法实现具体初始化逻辑
func _do_initialize() -> void
# 清理方法
func cleanup() -> bool
# 重置方法
func reset() -> bool
# 检查是否已初始化
func is_initialized() -> bool
# 添加依赖
func add_dependency(dependency_name: String) -> bool
# 移除依赖
func remove_dependency(dependency_name: String) -> bool
# 检查依赖是否满足
func _check_dependencies() -> bool
```

## HUD系统

HUD系统采用统一的架构，所有HUD组件都继承自`BaseHUD`类，由`HUDManager`统一管理：

- `BaseHUD` - HUD基类，提供通用功能
- `HUDManager` - HUD管理器，负责HUD的加载、显示和隐藏

HUD管理器提供以下主要功能：

- `load_hud(hud_name: String, show_immediately: bool = true, data: Dictionary = {}) -> BaseHUD`
- `unload_hud(hud_name: String) -> bool`
- `show_hud(hud_name: String, data: Dictionary = {}) -> bool`
- `hide_hud(hud_name: String) -> bool`
- `toggle_hud(hud_name: String) -> bool`
- `get_hud(hud_name: String) -> BaseHUD`
- `get_loaded_huds() -> Dictionary`
- `get_visible_huds() -> Array`
- `hide_all_huds() -> void`
- `unload_all_huds() -> void`
