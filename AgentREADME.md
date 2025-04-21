# 自走棋项目 - AI Agent助手指南

本文档为AI Agent助手提供项目的关键信息，帮助更好地理解和操作代码库。

## 项目概述

这是一个基于Godot 4.4.1引擎开发的自走棋游戏，融合了自走棋战斗机制和杀戮尖塔式地图探索。玩家通过树形地图探索，组建棋子阵容，激活羁绊效果，获取装备和遗物来增强实力，最终完成地图挑战。

## 技术栈

- Godot 4.4.1
- GDScript
- JSON配置文件

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

## 关键文件和路径

### 核心系统文件

- **游戏管理器**: `scripts/autoload/game_manager.gd`
- **事件总线**: `scripts/events/event_bus.gd`
- **配置管理器**: `scripts/managers/config_manager.gd`
- **状态管理器**: `scripts/managers/state_manager.gd`
- **存档管理器**: `scripts/managers/save_manager.gd`

### 游戏逻辑文件

- **地图系统**: `scripts/game/map/map_controller.gd`
- **棋盘系统**: `scripts/game/battle/board_manager.gd`
- **棋子实体**: `scripts/game/chess/chess_piece_entity.gd`
- **战斗引擎**: `scripts/game/battle/battle_engine.gd`
- **商店系统**: `scripts/game/shop/shop_system.gd`

### 配置文件

- **棋子配置**: `resources/configs/chess_pieces.json`
- **羁绊配置**: `resources/configs/synergies.json`
- **地图配置**: `resources/configs/map_nodes.json`
- **战斗配置**: `resources/configs/battle_config.json`
- **装备配置**: `resources/configs/equipment.json`
- **遗物配置**: `resources/configs/relics.json`

## 代码模式和约定

### 管理器类模式

所有管理器类都遵循以下模式：

```gdscript
class_name ExampleManager
extends Node

# 单例访问
static var instance: ExampleManager

func _ready():
    instance = self
    GameManager.register_manager(self)

# 初始化方法，由GameManager调用
func initialize():
    # 初始化逻辑
    pass

# 清理方法，由GameManager调用
func cleanup():
    # 清理逻辑
    pass
```

### 组件类模式

所有组件类都遵循以下模式：

```gdscript
class_name ExampleComponent
extends Component

# 组件属性
var some_property = null

# 初始化方法
func initialize(data):
    some_property = data.get("property", default_value)

# 组件启用时调用
func on_enable():
    # 启用逻辑
    pass

# 组件禁用时调用
func on_disable():
    # 禁用逻辑
    pass
```

### 事件系统使用模式

```gdscript
# 发送事件
EventBus.emit_event("event_name", {"param1": value1, "param2": value2})

# 连接事件
EventBus.connect_event("event_name", self, "_on_event_name")

# 事件处理方法
func _on_event_name(event_data):
    var param1 = event_data.get("param1")
    var param2 = event_data.get("param2")
    # 处理事件
```

### 命名约定

- **类名**: 使用PascalCase (如 `ChessPieceEntity`)
- **变量和函数**: 使用snake_case (如 `get_attribute`)
- **常量**: 使用UPPER_SNAKE_CASE (如 `MAX_HEALTH`)
- **私有成员**: 使用下划线前缀 (如 `_private_var`)
- **信号**: 使用过去时态 (如 `health_changed`)

## 系统交互流程

### 游戏初始化流程

1. `GameManager` 在 `_ready` 中开始初始化流程
2. 按顺序初始化各个管理器：
   - `ConfigManager` - 加载所有配置数据
   - `ResourceManager` - 预加载关键资源
   - `StateManager` - 初始化游戏状态
   - `EventBus` - 设置事件系统
   - `SaveManager` - 加载存档数据（如果有）
   - 其他游戏系统管理器
3. 初始化完成后，`GameManager` 发送 `game_initialized` 事件
4. 主场景响应事件，显示主菜单

### 战斗流程

1. `BattleManager` 接收开始战斗事件
2. `BattleManager` 创建 `BattleEngine` 实例
3. `BattleEngine` 初始化战斗状态并发送战斗准备事件
4. `ChessPieceEntity` 接收事件并准备战斗
5. `BattleEngine` 开始回合循环：
   - 发送回合开始事件
   - 处理所有棋子行动
   - 检查战斗结束条件
   - 发送回合结束事件
6. 战斗结束后，`BattleEngine` 发送战斗结束事件
7. `BattleManager` 处理战斗结果并清理资源

### 地图探索流程

1. `MapController` 生成地图节点和路径
2. 玩家选择节点后，`MapController` 发送节点激活事件
3. 根据节点类型，相应系统处理节点事件：
   - 战斗节点：`BattleManager` 开始战斗
   - 商店节点：`ShopSystem` 显示商店界面
   - 事件节点：`EventSystem` 触发随机事件
   - 休息节点：`PlayerManager` 恢复生命值
4. 节点完成后，`MapController` 更新可访问节点
5. 到达终点节点后，`MapController` 发送地图完成事件

## 常见修改场景指南

### 添加新棋子

1. 在 `resources/configs/chess_pieces.json` 中添加棋子配置：
```json
{
  "new_piece": {
    "name": "新棋子",
    "cost": 3,
    "health": 100,
    "attack": 15,
    "synergies": ["warrior", "human"],
    "skill": "new_skill"
  }
}
```

2. 如果有新技能，在 `scripts/game/chess/skills/` 创建技能脚本：
```gdscript
class_name NewSkill
extends Skill

func initialize(data):
    cooldown = 8
    mana_cost = 50
    
func activate(target):
    # 技能逻辑
    target.apply_damage(owner.get_attribute("attack") * 2)
    return true
```

3. 在 `resources/assets/chess/` 添加棋子资源
4. 确保 `ChessPieceFactory` 能够正确加载新棋子

### 添加新羁绊效果

1. 在 `resources/configs/synergies.json` 中添加羁绊配置：
```json
{
  "new_synergy": {
    "name": "新羁绊",
    "thresholds": [2, 4, 6],
    "effects": [
      {"type": "attribute_bonus", "attribute": "attack", "value": 15},
      {"type": "attribute_bonus", "attribute": "attack", "value": 30},
      {"type": "attribute_bonus", "attribute": "attack", "value": 50}
    ]
  }
}
```

2. 如果需要特殊效果，在 `scripts/game/synergy/effects/` 创建效果脚本
3. 在 `SynergyManager` 中注册新效果类型

### 修改战斗平衡性

1. 调整 `resources/configs/battle_config.json` 中的参数
2. 不要直接修改 `BattleEngine` 中的硬编码值
3. 所有平衡性参数应通过配置文件控制

## 错误处理和日志

项目使用分级日志系统：

```gdscript
# 日志级别
Logger.debug("调试信息")  # 仅在调试模式显示
Logger.info("一般信息")   # 提供操作信息
Logger.warn("警告信息")   # 潜在问题警告
Logger.error("错误信息")  # 运行时错误

# 错误处理示例
func some_function():
    var result = risky_operation()
    if result.has_error():
        Logger.error("操作失败: " + result.error_message)
        return null
    return result.data
```

## 性能优化指南

### 已知性能热点

1. `BattleEngine._process` - 战斗计算的主要性能瓶颈
2. `EventBus.emit_event` - 高频事件可能导致性能问题
3. `ChessPieceEntity.update_components` - 组件更新可能较重

### 优化策略

1. **对象池使用**：
```gdscript
# 获取对象
var effect = EffectPool.get_object()
effect.initialize(effect_data)

# 使用完毕后归还
EffectPool.return_object(effect)
```

2. **事件批处理**：
```gdscript
# 启用批处理
EventBus.enable_batch_processing("position_changed")

# 禁用批处理
EventBus.disable_batch_processing("position_changed")
```

3. **渲染优化**：
```gdscript
# 设置LOD级别
EffectManager.set_lod_level(EffectManager.LOD_LOW)

# 禁用不必要的处理
node.set_process(false)
```

## 调试技巧

1. **事件调试**：
```gdscript
# 启用事件历史记录
EventBus.enable_history()

# 查看最近事件
print(EventBus.get_recent_events(10))
```

2. **状态检查**：
```gdscript
# 打印当前游戏状态
print(StateManager.get_state_dump())
```

3. **性能分析**：
```gdscript
# 开始性能分析
PerformanceTracker.start("battle_calculation")

# 执行代码
perform_battle_calculation()

# 结束性能分析并打印结果
PerformanceTracker.end("battle_calculation")
```

## 常见问题和解决方案

1. **事件未触发**：
   - 检查事件名称是否正确
   - 确认接收者已正确连接事件
   - 查看 EventBus 历史记录确认事件已发送

2. **组件获取失败**：
   - 确保组件已正确注册到实体
   - 检查组件名称是否正确
   - 验证组件初始化是否成功

3. **配置加载问题**：
   - 确认 JSON 格式正确
   - 检查文件路径是否正确
   - 查看 ConfigManager 日志获取详细错误信息

4. **性能问题**：
   - 使用 Godot 的性能监视器（Shift+F1）分析性能瓶颈
   - 检查是否有过多事件或信号触发
   - 确认对象池正确使用

## 代码生成指南

当为项目生成代码时，请遵循以下原则：

1. **遵循现有模式**：新代码应遵循项目中已建立的模式和约定
2. **使用事件通信**：系统间通信应使用事件总线，避免直接引用
3. **配置驱动**：游戏参数应通过配置文件控制，避免硬编码
4. **组件化设计**：新功能应考虑如何融入现有组件系统
5. **错误处理**：包含适当的错误处理和日志记录
6. **性能考虑**：考虑代码对性能的影响，特别是在热点区域

## 项目特定注意事项

1. **不使用防御性代码**：项目倾向于使用更优雅的设计而非大量的空值检查
2. **优先使用组件**：新功能应优先考虑实现为组件而非继承
3. **状态管理集中化**：游戏状态应通过 StateManager 管理，避免分散状态
4. **资源预加载**：频繁使用的资源应通过 ResourceManager 预加载
5. **批处理高频事件**：对于位置更新等高频事件，应使用批处理机制
