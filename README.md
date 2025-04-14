# 自走棋游戏项目

基于Godot 4.4.1开发的自走棋游戏，结合杀戮尖塔的分支树形地图设计。

## 项目概述

这是一个融合了自走棋战斗机制和杀戮尖塔地图探索元素的游戏。玩家将在分支树形地图上选择路径，遇到战斗、商店、事件等不同节点，并通过自走棋战斗系统与敌人对抗。

### 核心玩法

1. **地图探索**: 玩家在杀戮尖塔式的分支树形地图上选择路径前进
2. **自走棋战斗**: 在战斗节点中，玩家需要布置棋子阵容进行自动战斗
3. **棋子养成**: 通过购买、升级棋子和装备来增强阵容
4. **羁绊系统**: 相同职业或种族的棋子组合会触发特殊效果
5. **遗物系统**: 获得特殊遗物提供全局增益效果
6. **随机事件**: 遇到各种随机事件，做出选择影响游戏进程

## 项目结构

```
autochess/
├── addons/                    # 第三方插件
├── assets/                    # 游戏资源
│   ├── audio/                 # 音频资源
│   │   ├── bgm/               # 背景音乐
│   │   ├── sfx/               # 音效
│   │   └── ui/                # UI音效
│   ├── fonts/                 # 字体资源
│   ├── images/                # 图片资源
│   │   ├── backgrounds/       # 背景图
│   │   ├── icons/             # 图标
│   │   ├── ui/                # UI图片
│   │   └── vfx/               # 视觉特效
│   ├── models/                # 3D模型(如果使用)
│   └── shaders/               # 着色器
├── config/                    # 配置文件
│   ├── chess_pieces.json      # 棋子配置
│   ├── equipment.json         # 装备配置
│   ├── map_nodes.json         # 地图节点配置
│   ├── relics.json            # 遗物配置
│   ├── synergies.json         # 羁绊配置
│   ├── events.json            # 事件配置
│   ├── difficulty.json        # 难度配置
│   ├── achievements.json      # 成就配置
│   └── skins.json             # 皮肤配置
├── data/                      # 游戏数据
│   ├── localization/          # 本地化文件
│   ├── saves/                 # 存档文件
│   └── settings/              # 设置文件
├── scenes/                    # 场景文件
│   ├── battle/                # 战斗场景
│   ├── chess_board/           # 棋盘场景
│   ├── main_menu/             # 主菜单场景
│   ├── map/                   # 地图场景
│   └── shop/                  # 商店场景
├── scripts/                   # 脚本文件
│   ├── autoload/              # 自动加载脚本(单例)
│   │   ├── event_bus.gd       # 事件总线
│   │   ├── game_manager.gd    # 游戏管理器
│   │   ├── save_manager.gd    # 存档管理器
│   │   ├── config_manager.gd  # 配置管理器
│   │   ├── localization_manager.gd # 本地化管理器
│   │   ├── audio_manager.gd   # 音频管理器
│   │   └── debug_manager.gd   # 调试管理器
│   ├── core/                  # 核心系统
│   │   ├── state_machine.gd   # 状态机
│   │   ├── resource_manager.gd # 资源管理器
│   │   └── object_pool.gd     # 对象池
│   ├── game/                  # 游戏逻辑
│   │   ├── battle/            # 战斗系统
│   │   │   ├── battle_manager.gd # 战斗管理器
│   │   │   ├── attack_system.gd # 攻击系统
│   │   │   └── aura_system.gd # 光环系统
│   │   ├── board/             # 棋盘系统
│   │   │   ├── board_manager.gd # 棋盘管理器
│   │   │   └── cell.gd        # 棋盘格子
│   │   ├── chess/             # 棋子系统
│   │   │   ├── chess_piece.gd # 棋子基类
│   │   │   ├── chess_factory.gd # 棋子工厂
│   │   │   └── synergy_manager.gd # 羁绊管理器
│   │   ├── economy/           # 经济系统
│   │   │   ├── economy_manager.gd # 经济管理器
│   │   │   └── shop_manager.gd # 商店管理器
│   │   ├── equipment/         # 装备系统
│   │   │   ├── equipment.gd   # 装备基类
│   │   │   └── equipment_manager.gd # 装备管理器
│   │   ├── map/               # 地图系统
│   │   │   ├── map_generator.gd # 地图生成器
│   │   │   ├── map_node.gd    # 地图节点
│   │   │   └── map_manager.gd # 地图管理器
│   │   ├── player/            # 玩家系统
│   │   │   ├── player.gd      # 玩家类
│   │   │   └── player_manager.gd # 玩家管理器
│   │   ├── relic/             # 遗物系统
│   │   │   ├── relic.gd       # 遗物基类
│   │   │   └── relic_manager.gd # 遗物管理器
│   │   └── events/            # 随机事件系统
│   │       ├── event.gd       # 事件基类
│   │       └── event_manager.gd # 事件管理器
│   ├── ui/                    # UI系统
│   │   ├── ui_manager.gd      # UI管理器
│   │   ├── scene_manager.gd   # 场景管理器
│   │   └── hud/               # HUD组件
│   └── utils/                 # 工具类
│       ├── debug_utils.gd     # 调试工具
│       ├── math_utils.gd      # 数学工具
│       └── random_utils.gd    # 随机数工具
└── tests/                     # 测试文件
    ├── unit/                  # 单元测试
    └── integration/           # 集成测试
```

## 模块完成状态

### 已完成模块 ✅

1. **项目基础架构**
   - 目录结构设计
   - 项目配置文件

2. **核心系统**
   - 事件总线 (EventBus)
   - 游戏管理器 (GameManager)
   - 配置管理器 (ConfigManager)
   - 存档管理器 (SaveManager)
   - 本地化管理器 (LocalizationManager)
   - 音频管理器 (AudioManager)
   - 调试管理器 (DebugManager)

3. **工具类**
   - 状态机 (StateMachine)
   - 资源管理器 (ResourceManager)
   - 对象池 (ObjectPool)
   - 数学工具 (MathUtils)
   - 随机工具 (RandomUtils)
   - 调试工具 (DebugUtils)

4. **配置文件**
   - 棋子配置 (chess_pieces.json)
   - 装备配置 (equipment.json)
   - 遗物配置 (relics.json)
   - 羁绊配置 (synergies.json)
   - 地图配置 (map_nodes.json)
   - 事件配置 (events.json)
   - 难度配置 (difficulty.json)
   - 成就配置 (achievements.json)
   - 皮肤配置 (skins.json)

5. **基本场景框架**
   - 主菜单场景 (main_menu.tscn)
   - 地图场景 (map_scene.tscn)
   - 战斗场景 (battle_scene.tscn)
   - 商店场景 (shop_scene.tscn)

6. **多语言支持**
   - 中文本地化文件 (zh_CN.json)

### 未完成模块 ❌

1. **游戏逻辑系统**
   - 棋子系统 (chess_piece.gd, chess_factory.gd)
   - 棋盘系统 (board_manager.gd, cell.gd)
   - 战斗系统 (battle_manager.gd, attack_system.gd)
   - 羁绊系统 (synergy_manager.gd)
   - 装备系统 (equipment.gd, equipment_manager.gd)
   - 遗物系统 (relic.gd, relic_manager.gd)
   - 经济系统 (economy_manager.gd, shop_manager.gd)
   - 地图系统 (map_generator.gd, map_manager.gd)
   - 玩家系统 (player.gd, player_manager.gd)
   - 事件系统 (event.gd, event_manager.gd)

2. **UI系统**
   - UI管理器 (ui_manager.gd)
   - 场景管理器 (scene_manager.gd)
   - HUD组件

3. **资源文件**
   - 音频资源 (bgm, sfx, ui)
   - 图片资源 (backgrounds, icons, ui, vfx)
   - 字体资源

4. **场景实现**
   - 场景之间的完整交互
   - 战斗逻辑实现
   - 商店购买逻辑实现
   - 事件系统实现

5. **测试系统**
   - 单元测试
   - 集成测试

## 下一步工作计划

1. **实现棋子和棋盘系统**
   - 棋子基类和工厂
   - 棋盘管理器和格子
   - 棋子放置和移动逻辑

2. **实现战斗系统**
   - 战斗管理器
   - 攻击系统
   - 技能系统
   - 战斗结算

3. **完善UI系统**
   - UI管理器
   - 各场景UI组件
   - 拖放交互

4. **实现游戏流程**
   - 地图探索
   - 战斗-商店-事件循环
   - 游戏进度保存和加载

5. **添加游戏内容**
   - 更多棋子、装备和遗物
   - 丰富的随机事件
   - 多样化的地图节点

## 技术说明

- **事件驱动架构**: 使用事件总线实现系统间松耦合通信
- **数据驱动设计**: 游戏数据与逻辑分离，便于平衡性调整
- **状态模式**: 使用状态机管理游戏流程和UI状态
- **单例模式**: 关键系统使用单例模式，便于全局访问
- **工厂模式**: 使用工厂模式创建棋子和其他游戏对象
- **对象池**: 使用对象池管理频繁创建和销毁的对象

## 特别注意事项

1. **多语言支持**: 当前仅实现了简体中文，所有文本应使用LocalizationManager.tr()获取
2. **事件通信**: 系统间通信应使用EventBus，避免直接引用
3. **配置数据**: 游戏数据应从ConfigManager获取，避免硬编码
4. **存档系统**: 游戏状态变更应考虑触发自动存档
5. **皮肤系统**: UI和游戏对象应支持皮肤切换

## 开发环境

- Godot 4.4.1
- GDScript

## 下一次对话重点

在下一次对话中，我们将重点关注以下内容：

1. 实现棋子系统和棋盘系统的核心逻辑
2. 完善战斗系统的自动战斗机制
3. 实现装备和遗物系统的效果应用
4. 优化UI交互和游戏流程

这些是游戏核心玩法的关键组成部分，需要优先实现。
