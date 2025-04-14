# 自走棋游戏项目

基于Godot引擎开发的自走棋游戏，结合杀戮尖塔的分支树形地图设计。

## 项目概述

本项目是一款融合了自走棋战斗机制与杀戮尖塔分支路径地图的游戏。玩家需要在地图上选择路径前进，经历战斗、商店、事件等不同节点，并通过购买、升级棋子来组建强大的阵容。

### 核心玩法
- 在分支树形地图上选择路径前进
- 自动战斗系统，棋子会根据AI自动战斗
- 棋子羁绊系统，相同职业或种族的棋子组合会触发特殊效果
- 装备和遗物系统，提供各种属性加成和特殊效果
- 随机事件系统，提供多样化的游戏体验

## 项目架构

### 目录结构

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

#### 核心框架
- ✅ 项目基础结构
- ✅ 事件总线系统 (EventBus)
- ✅ 游戏管理器 (GameManager)
- ✅ 配置管理器 (ConfigManager)
- ✅ 存档管理器 (SaveManager)
- ✅ 本地化管理器 (LocalizationManager)
- ✅ 音频管理器 (AudioManager)
- ✅ 调试管理器 (DebugManager)

#### 工具类
- ✅ 状态机 (StateMachine)
- ✅ 资源管理器 (ResourceManager)
- ✅ 对象池 (ObjectPool)
- ✅ 数学工具 (MathUtils)
- ✅ 随机工具 (RandomUtils)
- ✅ 调试工具 (DebugUtils)

#### 配置文件
- ✅ 棋子配置 (chess_pieces.json)
- ✅ 装备配置 (equipment.json)
- ✅ 遗物配置 (relics.json)
- ✅ 羁绊配置 (synergies.json)
- ✅ 地图配置 (map_nodes.json)
- ✅ 事件配置 (events.json)
- ✅ 难度配置 (difficulty.json)
- ✅ 成就配置 (achievements.json)
- ✅ 皮肤配置 (skins.json)

#### 场景
- ✅ 主菜单场景 (基础结构)
- ✅ 地图场景 (基础结构)
- ✅ 战斗场景 (基础结构)
- ✅ 商店场景 (基础结构)

#### 多语言支持
- ✅ 中文本地化文件 (zh_CN.json)

### 待完成模块 ❌

#### 游戏逻辑
- ❌ 棋子系统 (ChessSystem)
- ❌ 棋盘系统 (BoardSystem)
- ❌ 战斗系统 (BattleSystem)
- ❌ 装备系统 (EquipmentSystem)
- ❌ 遗物系统 (RelicSystem)
- ❌ 事件系统 (EventSystem)
- ❌ 经济系统 (EconomySystem)
- ❌ 玩家系统 (PlayerSystem)
- ❌ 地图系统 (MapSystem) - 基础结构已完成，但需要完善生成算法和交互

#### UI系统
- ❌ UI管理器 (UIManager)
- ❌ 场景管理器 (SceneManager)
- ❌ HUD组件

#### 其他系统
- ❌ 教程系统 (TutorialSystem)
- ❌ 成就系统 (AchievementSystem)
- ❌ 网络多人模式 (NetworkSystem) - 预留接口

## 下一步工作计划

1. **实现棋子和棋盘系统**
   - 完成棋子基类和工厂
   - 实现棋盘格子和交互
   - 实现棋子放置和移动逻辑

2. **实现战斗系统**
   - 完成战斗管理器
   - 实现攻击系统和伤害计算
   - 实现技能系统和效果

3. **完善地图系统**
   - 优化地图生成算法
   - 实现节点连接线的绘制
   - 完善节点交互和事件触发

4. **实现装备和遗物系统**
   - 完成装备基类和管理器
   - 实现装备效果和属性加成
   - 实现遗物效果和触发条件

5. **完善UI系统**
   - 实现各场景的完整UI
   - 添加动画和过渡效果
   - 实现拖放交互

## 注意事项

- 多语言系统目前只支持简体中文
- 所有系统间通信应使用事件总线，避免直接引用
- 配置数据与逻辑代码分离，便于后续调整
- 考虑系统间的交互，如多语言、自动存档、成就统计等

## 技术细节

- 使用Godot 4.4.1引擎开发
- 使用GDScript作为主要编程语言
- 使用JSON文件存储配置和本地化数据
- 使用信号(Signal)机制实现系统间通信
- 使用状态机管理游戏状态和对象行为
