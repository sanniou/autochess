# 状态管理系统指南

本文档提供了状态管理系统的详细说明和使用指南。

## 概述

状态管理系统采用类似于Redux的单向数据流模式，提供了集中式的状态管理解决方案。它具有以下特点：

- 集中管理应用状态
- 单向数据流
- 可预测的状态更新
- 状态变更追踪
- 组件状态订阅

## 系统架构

状态管理系统由以下组件组成：

1. **状态定义（StateDefinitions）**：定义应用的状态结构
2. **状态动作（StateActions）**：定义可以执行的状态更新操作
3. **状态存储（StateStore）**：存储和管理应用状态
4. **状态管理器（StateManager）**：提供状态访问和更新的接口

### 状态结构

应用状态被分为以下几个部分：

- **game**：游戏核心状态（如当前关卡、难度等）
- **player**：玩家状态（如生命值、金币、经验等）
- **board**：棋盘状态（如棋子位置、战斗状态等）
- **shop**：商店状态（如商店物品、刷新费用等）
- **map**：地图状态（如当前节点、已访问节点等）
- **ui**：UI状态（如当前屏幕、打开的窗口等）
- **settings**：设置状态（如音量、语言等）
- **achievements**：成就状态（如已解锁成就、成就进度等）
- **stats**：统计状态（如游戏次数、总伤害等）

## 使用指南

### 访问状态

可以通过`StateManager`访问应用状态：

```gdscript
# 获取整个应用状态
var state = StateManager.get_state()

# 获取特定部分的状态
var player_state = StateManager.get_state_section("player")

# 获取特定状态值
var health = StateManager.get_state_value("player.health")
```

### 更新状态

状态更新通过分发动作来实现：

```gdscript
# 创建动作
var action = StateManager.create_action("CHANGE_GOLD", {"amount": 10})

# 分发动作
StateManager.dispatch(action)
```

### 订阅状态变更

组件可以订阅状态变更，以便在状态变化时更新：

```gdscript
# 订阅状态变更
StateManager.subscribe("player", self, "_on_player_state_changed")

# 状态变更处理
func _on_player_state_changed(new_state):
    # 更新组件
    update_ui(new_state)
```

### 取消订阅

在组件销毁时，应该取消订阅状态变更：

```gdscript
# 取消特定订阅
StateManager.unsubscribe("player", self, "_on_player_state_changed")

# 取消所有订阅
StateManager.unsubscribe_all(self)
```

## 动作类型

以下是可用的动作类型：

### 游戏状态动作

- `SET_DIFFICULTY`：设置游戏难度
- `SET_GAME_MODE`：设置游戏模式
- `SET_PAUSED`：设置游戏暂停状态
- `SET_GAME_OVER`：设置游戏结束状态
- `NEXT_TURN`：进入下一回合
- `SET_PHASE`：设置游戏阶段
- `SET_SEED`：设置随机种子

### 玩家状态动作

- `SET_HEALTH`：设置玩家生命值
- `CHANGE_HEALTH`：改变玩家生命值
- `SET_GOLD`：设置玩家金币
- `CHANGE_GOLD`：改变玩家金币
- `SET_EXPERIENCE`：设置玩家经验
- `CHANGE_EXPERIENCE`：改变玩家经验
- `ADD_RELIC`：添加遗物
- `REMOVE_RELIC`：移除遗物
- `RECORD_BATTLE_RESULT`：记录战斗结果

### 棋盘状态动作

- `SET_BOARD_SIZE`：设置棋盘大小
- `PLACE_PIECE`：放置棋子
- `REMOVE_PIECE`：移除棋子
- `MOVE_PIECE`：移动棋子
- `LOCK_BOARD`：锁定棋盘
- `SET_BATTLE_STATE`：设置战斗状态
- `UPDATE_SYNERGY`：更新羁绊
- `CLEAR_BOARD`：清空棋盘

### 商店状态动作

- `SET_SHOP_OPEN`：设置商店开关状态
- `SET_SHOP_ITEMS`：设置商店物品
- `REFRESH_SHOP`：刷新商店
- `BUY_ITEM`：购买物品
- `LOCK_ITEM`：锁定物品
- `SET_SHOP_TIER`：设置商店等级

### 地图状态动作

- `SET_MAP`：设置当前地图
- `SELECT_NODE`：选择地图节点
- `VISIT_NODE`：访问地图节点
- `SET_AVAILABLE_NODES`：设置可用节点
- `SET_MAP_LEVEL`：设置地图等级

### UI状态动作

- `SET_SCREEN`：设置当前屏幕
- `OPEN_WINDOW`：打开窗口
- `CLOSE_WINDOW`：关闭窗口
- `SELECT_ITEM`：选择物品
- `SET_DRAG_ITEM`：设置拖拽物品
- `SHOW_TOOLTIP`：显示工具提示
- `ADD_NOTIFICATION`：添加通知
- `CLEAR_NOTIFICATIONS`：清除通知

### 设置状态动作

- `SET_VOLUME`：设置音量
- `SET_FULLSCREEN`：设置全屏
- `SET_LANGUAGE`：设置语言
- `SET_SHOW_FPS`：设置显示FPS
- `SET_VSYNC`：设置垂直同步
- `SET_PARTICLE_QUALITY`：设置粒子质量
- `SET_UI_SCALE`：设置UI缩放

### 成就状态动作

- `UNLOCK_ACHIEVEMENT`：解锁成就
- `UPDATE_ACHIEVEMENT_PROGRESS`：更新成就进度

### 统计状态动作

- `RECORD_GAME_RESULT`：记录游戏结果
- `RECORD_GOLD_EARNED`：记录金币获取
- `RECORD_DAMAGE`：记录伤害
- `RECORD_HEALING`：记录治疗
- `RECORD_CHESS_PIECE_BOUGHT`：记录棋子购买
- `RECORD_CHESS_PIECE_3STAR`：记录3星棋子
- `RECORD_SYNERGY_ACTIVATED`：记录羁绊激活

## 示例

### 基本使用

```gdscript
extends Node


# 当前玩家状态
var player_state = {}

func _ready():
    # 订阅状态变更
    GameManager.state_manager.subscribe("player", self, "_on_player_state_changed")
    
    # 获取初始状态
    player_state = GameManager.state_manager.get_state_section("player")
    
    # 更新UI
    _update_ui()

func _exit_tree():
    # 取消订阅状态变更
    GameManager.state_manager.unsubscribe_all(self)

# 添加金币
func add_gold(amount: int):
    # 创建动作
    var action = GameManager.state_manager.create_action("CHANGE_GOLD", {"amount": amount})
    
    # 分发动作
    GameManager.state_manager.dispatch(action)

# 玩家状态变更处理
func _on_player_state_changed(new_state):
    # 更新玩家状态
    player_state = new_state
    
    # 更新UI
    _update_ui()

# 更新UI
func _update_ui():
    # 更新UI元素
    $GoldLabel.text = str(player_state.gold)
    $HealthBar.value = player_state.health
```

### 复杂示例

请参考 `scripts/examples/state_example.gd` 文件，了解更复杂的使用示例。

## 最佳实践

1. **组件化状态访问**：每个组件只访问和订阅它需要的状态部分
2. **单向数据流**：通过分发动作更新状态，不要直接修改状态
3. **状态规范化**：避免状态嵌套过深，保持状态结构扁平
4. **取消订阅**：在组件销毁时取消订阅状态变更
5. **状态持久化**：使用`StateManager.save_state()`和`StateManager.load_state()`持久化状态
6. **状态调试**：在开发模式下，使用状态历史记录调试状态变更

## 调试

状态管理系统提供了以下调试功能：

- **状态历史记录**：记录状态变更历史
- **状态日志**：记录状态变更日志
- **状态快照**：保存和加载状态快照

可以通过以下方式访问这些功能：

```gdscript
# 获取状态历史
var history = StateManager.state_store.get_history()

# 启用状态历史记录
StateManager.state_store.enable_history_recording(true)

# 设置最大历史记录数
StateManager.state_store.set_max_history_size(200)

# 清除状态历史
StateManager.state_store.clear_history()
```

## 结论

状态管理系统提供了一种集中式的状态管理解决方案，使应用状态更加可预测和可维护。通过遵循单向数据流模式，可以减少状态管理的复杂性，提高代码的可读性和可维护性。
