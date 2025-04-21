# 自走棋游戏项目

基于Godot 4引擎开发的自走棋游戏，结合杀戮尖塔的分支树形地图设计。

## 项目概述

融合自走棋战斗机制和杀戮尖塔式地图探索的单人游戏，玩家通过树形地图探索，组建棋子阵容，激活羁绊效果，获取装备和遗物来增强实力，最终完成地图挑战。

## 开发环境

- Godot 4.4.1
- GDScript
- 配置文件格式：JSON

### 环境设置

1. 安装Godot 4.4.1
2. 克隆项目仓库
3. 使用Godot编辑器打开项目文件夹
4. 运行主场景（`scenes/main/main_scene.tscn`）开始调试

## 项目结构

```
autochess/
├── assets/            # 游戏资源（图像、音频等）
├── scenes/            # 场景文件
│   ├── main/          # 主场景
│   ├── battle/        # 战斗场景
│   ├── map/           # 地图场景
│   └── ui/            # UI场景
├── scripts/           # 脚本文件
│   ├── autoload/      # 自动加载脚本
│   ├── events/        # 事件系统
│   ├── game/          # 游戏核心逻辑
│   │   ├── battle/    # 战斗系统
│   │   ├── chess/     # 棋子系统
│   │   ├── map/       # 地图系统
│   │   └── shop/      # 商店系统
│   ├── managers/      # 管理器类
│   └── utils/         # 工具类
├── resources/         # 资源文件
│   └── configs/       # JSON配置文件
└── project.godot      # 项目配置文件
```

## 技术架构

项目采用模块化设计，各系统通过事件总线进行松耦合通信，配置数据与逻辑代码分离。

### 核心系统

- **游戏管理器 (GameManager)**: 中央控制器，负责游戏状态管理和系统协调
  - 路径：`scripts/autoload/game_manager.gd`
  - 功能：管理器注册、初始化和生命周期管理

- **事件总线 (EventBus)**: 实现系统间的松耦合通信
  - 路径：`scripts/events/event_bus.gd`
  - 功能：事件分组、批处理和历史记录

- **配置管理器 (ConfigManager)**: 加载和管理游戏配置数据
  - 路径：`scripts/managers/config_manager.gd`
  - 功能：JSON配置加载和访问

- **状态管理器 (StateManager)**: 集中管理应用状态
  - 路径：`scripts/managers/state_manager.gd`
  - 功能：状态存储、变更通知和单向数据流

### 游戏逻辑系统

- **地图系统**: 生成和管理分支树形地图
  - 路径：`scripts/game/map/map_controller.gd`
  - 功能：节点生成、路径连接和节点交互

- **棋盘系统**: 管理战斗和准备阶段的棋盘
  - 路径：`scripts/game/battle/board_manager.gd`
  - 功能：棋子放置、移动和位置管理

- **棋子系统**: 采用组件化设计管理棋子
  - 路径：`scripts/game/chess/chess_piece_entity.gd`
  - 功能：属性管理、状态控制和行为实现

- **战斗系统**: 实现回合制自动战斗逻辑
  - 路径：`scripts/game/battle/battle_engine.gd`
  - 功能：战斗流程控制、命令队列和AI决策

- **商店系统**: 管理商店刷新和物品购买
  - 路径：`scripts/game/shop/shop_system.gd`
  - 功能：物品生成、刷新机制和购买逻辑

## 设计模式与实现技术

### 组件化设计

棋子实体采用组件系统，实现功能模块化：

```gdscript
# 组件示例
class_name AttributeComponent
extends Component

var attributes = {}

func initialize(data):
    attributes = data.duplicate()

func get_attribute(name):
    return attributes.get(name, 0)
```

### 事件驱动架构

使用事件总线实现系统间松耦合通信：

```gdscript
# 事件发送示例
EventBus.emit_event("battle_started", {"round": current_round})

# 事件监听示例
EventBus.connect_event("battle_started", self, "_on_battle_started")
```

### 命令模式

在战斗系统中实现命令队列和执行：

```gdscript
# 命令示例
class_name AttackCommand
extends BattleCommand

func execute():
    source.attack(target)
    return true
```

### 对象池模式

用于管理频繁创建和销毁的对象：

```gdscript
# 对象池使用示例
var effect = EffectPool.get_object()
effect.initialize(effect_data)
# 使用完毕后
EffectPool.return_object(effect)
```

## 当前状态与进展

### 已实现的核心功能

- 事件总线系统：支持事件分组和批处理
- 管理器系统：统一的管理器注册和初始化
- 状态机实现：用于棋子行为和游戏流程控制
- 对象池系统：管理频繁创建和销毁的对象
- 地图系统：分支树形地图生成和交互
- 棋盘系统：棋子放置和移动机制
- 棋子系统：组件化设计，实现棋子属性和行为
- 战斗系统：回合制自动战斗逻辑
- 商店系统：商店刷新和物品购买机制
- 配置管理：JSON格式存储游戏配置数据
- 存档系统：游戏数据的持久化和加载
- 本地化支持：中文界面和文本

### 最近完成的优化

- 采用MVC模式重构棋子系统，分离数据、逻辑和视图
- 实现逻辑与表现层分离，提高代码可维护性
- 优化事件系统，实现高频事件的批处理
- 实现对象池系统，减少内存分配和垃圾回收
- 优化渲染性能，减少不必要的重绘
- 实现动画系统的LOD（细节层次）机制

### 下一步计划

1. **核心系统完善**
   - 完善状态管理系统，实现集中化的状态管理
   - 优化战斗系统，提高AI决策和战斗流畅度
   - 完善羁绊系统，增强策略性和多样性
   - 扩展地图系统，丰富节点类型和事件

2. **性能优化**
   - 进一步优化对象池系统，减少内存占用
   - 实现渲染缓存和批处理，提高渲染效率
   - 优化事件处理机制，减少事件分发开销

3. **用户体验提升**
   - 完善UI系统，提高界面反应速度和可用性
   - 增强视觉反馈，提供更直观的游戏信息
   - 实现教程系统，降低新手入门门槛

## 开发规范

### 代码风格

- 使用驼峰命名法（camelCase）命名变量和函数
- 使用帕斯卡命名法（PascalCase）命名类和节点
- 使用下划线命名法（snake_case）命名文件
- 缩进使用4个空格
- 每个脚本文件顶部添加类描述注释

### 提交规范

遵循AngularJS提交规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型（type）:
- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- style: 代码风格调整
- refactor: 代码重构
- perf: 性能优化
- test: 测试相关
- chore: 构建过程或辅助工具的变动

### 开发流程

1. 从主分支创建功能分支
2. 完成功能开发和测试
3. 提交代码并创建合并请求
4. 代码审查通过后合并到主分支

## 设计原则

1. **模块化设计**：系统功能明确，职责单一，便于扩展和维护
2. **松耦合通信**：系统间通过事件总线通信，降低耦合度
3. **数据驱动**：游戏数据与逻辑分离，使用JSON配置文件
4. **性能优先**：注重对象池、批处理和渲染优化
5. **组件化设计**：采用组件系统实现棋子功能，提高可扩展性
6. **代码质量**：不使用防御性代码，主动采用更优设计
7. **测试验证**：实现关键功能的单元测试，确保代码质量
