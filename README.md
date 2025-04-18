# 自走棋游戏项目

基于Godot引擎开发的自走棋游戏，结合杀戮尖塔的分支树形地图设计。

## 游戏规则 (基于云顶之弈和杀戮尖塔)

### 基础规则
1. **回合制战斗**：
   - 准备阶段：30秒，用于布置阵容和购买棋子
   - 战斗阶段：90秒，棋子自动战斗
2. **玩家机制**：
   - 单人游戏模式：玩家对战AI对手
   - AI对手使用真实玩家策略模拟器，保留多人对战扩展可能
3. **生命值系统**：
   - 初始生命值：100点
   - 战败扣血：基础10点 + 每个存活敌方棋子2点
   - 破产保护：生命值低于20点时获得额外金币补助
4. **胜负判定**：最后存活的玩家获胜

### 羁绊系统（以下只是示例，应该开发成一个可扩展的系统）
1. **羁绊类型**：
   - 每个棋子有职业和种族特征，部分棋子可以有多个羁绊类型
   - 职业羁绊：战士、法师、射手、刺客、坦克、辅助
   - 种族羁绊：人类、精灵、兽人、亡灵、恶魔、元素
   - 特殊羁绊：传说、英雄、异界、机械
2. **激活条件**：
   - 初级羁绊：2/3个相同特征
   - 中级羁绊：4/6个相同特征
   - 高级羁绊：6/9个相同特征
3. **职业羁绊效果**：
   - 战士(2/4/6)：
     - 护甲提升15/30/50%
     - 生命值提升10/20/30%
   - 法师(2/4/6)：
     - 法力值获取提升20/40/60%
     - 技能伤害提升15/30/45%
   - 射手(2/4/6)：
     - 攻击速度提升10/25/40%
     - 暴击率提升5/15/25%
   - 刺客(2/4/6)：
     - 暴击伤害提升20/40/60%
     - 闪避率提升5/15/25%
   - 坦克(2/4/6)：
     - 生命值提升20/40/60%
     - 控制抗性提升15/30/45%
   - 辅助(2/4)：
     - 光环效果范围扩大1/2格
     - 治疗效果提升20/40%
4. **种族羁绊效果**：
   - 人类(3/6/9)：
     - 全属性提升8/16/24%
   - 精灵(2/4/6)：
     - 闪避率提升15/30/45%
   - 兽人(2/4/6)：
     - 生命值提升15/30/45%
   - 亡灵(2/4)：
     - 生命值偷取10/20%
   - 恶魔(2/4)：
     - 技能伤害提升20/40%
   - 元素(2/4)：
     - 元素伤害提升25/50%
5. **特殊羁绊效果**：
   - 传说(2)：所有羁绊等级+1
   - 英雄(3)：全队伤害提升30%
   - 异界(2)：随机获得一个额外羁绊
   - 机械(2/4)：攻击速度提升20/40%
6. **羁绊互动机制**：
   - 装备加成：特定装备可提供羁绊点数
   - 遗物效果：可改变羁绊激活条件或效果
   - 叠加规则：同类羁绊取最高等级效果
   - 特殊组合：某些羁绊组合有额外效果

### 经济系统
1. **基础收入**：
   - 回合基础收入：5金币
   - 利息收入：每10金币获得1金币(上限5金币)
   - 连胜/连败奖励：
     - 2连胜/败：+1金币
     - 3连胜/败：+2金币
     - 5连胜/败：+3金币
2. **保护机制**：
   - 破产保护：生命值低于20点且金币为0时，获得5金币补助
   - 最低保底：每场战斗至少获得2金币
3. **利息系统**：
   - 基础利息：每10金币获得1金币利息
   - 利息上限：每回合最多获得5金币利息
   - 特殊加成：某些羁绊或遗物可提升利息上限

### 棋子系统
1. **棋子获取**：
   - 商店自动刷新：每回合开始时
   - 手动刷新：消耗2金币
   - 棋子费用：1-5费，出现概率随等级变化
2. **棋子升级**：
   - 2星升级：3个相同1星棋子
   - 3星升级：3个相同2星棋子
   - 升级后属性提升：攻击力和生命值翻倍
3. **棋子属性**：
   - 基础属性：生命值、护甲、魔抗、攻击力、攻速、暴击几率、暴击伤害、闪避率、控制抗性、伤害减免、伤害加成、法术强度
   - 技能属性：法力值、技能冷却、施法时间
   - 移动属性：移动速度、攻击范围
4. **棋子定位**：
   - 前排：战士/坦克，高生命值和护甲
   - 中排：战士/刺客，平衡攻防属性
   - 后排：法师/射手，高输出低生命
5. **技能类型**：
   - 主动技能：需要积累法力值
   - 被动技能：持续生效
   - 光环技能：影响周围友军
6. **技能范围**：
   - 单体技能：伤害/增益效果最高
   - 小范围技能：2格范围
   - 大范围技能：3格范围
   - 全场技能：效果较弱
7. **克制关系**：
   - 战士克制刺客
   - 刺客克制射手
   - 射手克制法师
   - 法师克制战士
8. **成长体系**：
   - 1星：基础属性
   - 2星：属性翻倍，技能强化
   - 3星：属性翻三倍，技能特殊效果
9. **成长收益**：
   - 2星：属性提升100%，技能效果提升50%
   - 3星：属性提升200%，技能效果提升100%，解锁特殊效果
### 战斗系统
1. **战斗机制**：
   - 自动战斗：棋子按AI逻辑行动
   - 攻击优先级：最近敌人优先
   - 技能施放：积累足够法力值后自动释放
2. **伤害计算**：
   - 物理伤害：攻击力 * (1 - 护甲/100)
   - 法术伤害：技能伤害 * (1 - 魔抗/100)
   - 真实伤害：无视护甲和魔抗
3. **法力值获取**：
   - 普通攻击：+10点
   - 受到伤害：受伤害值的10%转化为法力值
4. **战斗属性**：
   - 暴击：基础暴击率10%，暴击伤害150%
   - 闪避：基础闪避率5%
   - 控制抗性：基础10%，随星级提升
5. **控制效果**：
   - 眩晕：无法行动，持续1.5秒
   - 沉默：无法施放技能，持续3秒
   - 减速：移动速度降低30%，持续2秒
   - 缴械：无法普攻，持续2秒
   - 嘲讽：强制攻击施法者，持续1.5秒
6. **控制效果机制**：
   - 同类型控制效果不叠加，取最长持续时间
   - 不同类型控制效果可以共存
   - 控制免疫时间：被控制结束后0.5秒内免疫同类型控制
   - 控制效果优先级：眩晕 > 嘲讽 > 沉默 > 缴械 > 减速

### 等级系统
1. **等级机制**：
   - 最高等级：9级
   - 每级人口上限：跟随等级
2. **经验获取**：
   - 自动经验：每回合2点
   - 购买经验：4金币获得4点
3. **等级效果**：
   - 解锁高费棋子概率
   - 提升人口上限
   - 特定等级额外奖励

### 商店系统
1. **刷新机制**：
   - 自动刷新：回合开始
   - 手动刷新：2金币
   - 免费刷新：特定等级或事件奖励
2. **出现概率**：
   - 1费：100%→60%→50%→35%→20%→15%→10%
   - 2费：0%→30%→35%→35%→30%→20%→15%
   - 3费：0%→10%→15%→25%→30%→30%→25%
   - 4费：0%→0%→0%→5%→15%→25%→30%
   - 5费：0%→0%→0%→0%→5%→10%→20%
3. **特殊商店**：
   - 黑市商人：每3回合随机出现，提供折扣商品和独特装备
   - 神秘商店：击杀精英敌人概率触发，提供高级棋子
   - 装备商店：固定回合出现，可购买成品装备
4. **棋子池限制**：
   - 1费棋子：每类39个
   - 2费棋子：每类26个
   - 3费棋子：每类18个
   - 4费棋子：每类12个
   - 5费棋子：每类10个
5. **保底机制**：
   - 连续3次刷新无目标棋子，第4次必出1个
   - 8级以上每次刷新至少出现1个4费以上棋子
6. **特殊商店**：
   - 黑市商人(35%/3回合)：
     - 60-80%折扣商品
     - 独特道具：合成装备分解券、棋子改造卷轴
   - 神秘商店(精英战胜40%)：
     - 提供阵容相关高星棋子
     - 可能出现限定棋子

### 地图系统
1. **地图结构**：
   - 每层3-4个节点
   - 总计8层地图深度
   - 支线任务节点
2. **节点类型与概率**：
   - 战斗：40%，标准对战
   - 精英战斗：15%，强化对手
   - 商店：15%，折扣商品
   - 事件：15%，随机剧情
   - 休息：10%，恢复生命值
   - 宝藏：5%，高价值奖励
3. **地图模板**：
   - 标准路线：平衡各类节点
   - 精英路线：更多精英战斗和宝藏
   - 商人路线：更多商店和事件
   - 挑战路线：更多战斗和精英战斗
4. **节点连接规则**：
   - 每个节点最多连接3个下层节点
   - 精英节点必须通过普通节点解锁
   - 支线节点需要特定条件触发
5. **区域特性**：
   - 起始区域：1-2层，简单战斗
   - 中期区域：3-5层，开始出现精英
   - 后期区域：6-8层，高难度挑战

### 游戏节奏
1. **早期阶段(1-3回合)**：
   - 重点：经济积累
   - 策略：连胜/连败规划
   - 目标：确定初始阵容方向
2. **中期阶段(4-6回合)**：
   - 重点：阵容成型
   - 策略：装备分配
   - 目标：开始升星核心棋子
3. **后期阶段(7回合以后)**：
   - 重点：阵容完善
   - 策略：针对性调整
   - 目标：追求最强阵容

### 事件系统
1. **事件奖励**：
   - 全局事件：影响所有玩家
   - 个人事件：仅影响当前玩家
1. **事件类型**：
   - 剧情事件：需要玩家选择
   - 战斗事件：特殊战斗规则
   - 奖励事件：直接获得奖励
   - 诅咒事件：负面效果
2. **事件效果**：
   - 经济类：金币奖励/惩罚
   - 战斗类：棋子属性调整
   - 特殊类：改变游戏规则
2. **奖励机制**：
   - 即时效果：立即生效
   - 持续效果：持续特定回合
   - 条件效果：满足条件触发
3. **事件触发**：
   - 固定回合触发
   - 地图节点触发
   - 遗物效果触发
3. **连锁事件**：
   - 选择影响后续事件
   - 多重分支结局
   - 特殊成就解锁

### 遗物系统
1. **获取方式**：
   - 精英战斗奖励
   - 宝藏节点发现
   - 特殊事件获得
2. **遗物效果**：
   - 被动增益：属性提升
   - 主动技能：可主动使用
   - 条件触发：特定条件激活
3. **遗物组合**：
   - 某些遗物有协同效果
   - 遗物可改变游戏策略
   - 双遗物效果
   - 三遗物效果
   - 特殊组合解锁

### 装备系统
1. **装备获取**：
   - 战斗掉落：基础装备
   - 商店购买：成品装备
   - 合成制作：高级装备
2. **装备合成**：
   - 2个基础装备合成1个高级装备
   - 装备可给棋子提供属性加成或特殊效果
2. **装备效果**：
   - 属性提升：基础属性加成
   - 特殊效果：独特能力
   - 套装效果：多件装备组合
3. **装备限制**：
   - 每个棋子最多3件装备
   - 装备可自由拆卸
   - 部分装备职业限定

### 棋盘布局
1. **区域划分**：
   - 备战区：9个格子
   - 战斗区：4行8列
   - 装备区：独立装备栏
2. **布阵规则**：
   - 人口上限限制上场棋子数
   - 前后排位置影响战斗优先级
   - 特殊位置提供额外效果

### 特殊机制
1. **选秀环节**：
   - 所有玩家轮流选择装备或棋子
   - 选择顺序基于当前生命值
   - 每轮限时15秒
2. **野怪回合**：
   - 固定回合出现
   - 难度随游戏进程提升
   - 特殊野怪：远古巨龙、虚空巨兽、元素领主

所有规则都具有扩展性，可能被遗物、装备、羁绊、事件等改变。游戏平衡性通过数值调整和机制互动持续优化。

## 项目概述

这是一个使用Godot 4.4.1开发的自走棋游戏，具有以下特点：

- 杀戮尖塔式的分支树形地图
- 自走棋战斗规则
- 棋子羁绊系统
- 装备和遗物系统
- 随机事件系统
- 多语言支持（当前仅需要支持简体中文）
- 存档系统
- 成就系统
- 皮肤系统

## 项目架构

项目采用模块化设计，各系统通过事件总线进行松耦合通信，配置数据与逻辑代码分离。

### 核心系统

- [x] **游戏管理器 (GameManager)**: 负责游戏状态管理和系统协调
- [x] **事件总线 (EventBus)**: 实现系统间的松耦合通信
- [x] **配置管理器 (ConfigManager)**: 负责加载和管理游戏配置数据
- [x] **状态管理器 (StateManager)**: 集中管理应用状态，实现单向数据流
- [x] **存档管理器 (SaveManager)**: 负责游戏数据的持久化和加载
- [x] **本地化管理器 (LocalizationManager)**: 提供多语言支持
- [x] **音频管理器 (AudioManager)**: 负责游戏音频的播放和管理
- [x] **调试管理器 (DebugManager)**: 提供调试功能和日志记录

### 工具类

- [x] **状态机 (StateMachine)**: 通用状态机实现，用于管理游戏对象的状态
- [x] **资源管理器 (ResourceManager)**: 负责游戏资源的加载和缓存
- [x] **对象池 (ObjectPool)**: 用于管理和重用游戏对象，提高性能
- [x] **数学工具 (MathUtils)**: 提供常用的数学函数和算法
- [x] **随机工具 (RandomUtils)**: 提供高级随机数生成和随机选择功能
- [x] **调试工具 (DebugUtils)**: 提供调试和性能分析功能

### 游戏逻辑系统

- [x] **地图系统**: 生成和管理杀戮尖塔式的分支树形地图
- [x] **棋盘系统**: 管理战斗和准备阶段的棋盘
- [x] **棋子系统**: 管理棋子的创建、升级和属性
- [x] **战斗系统**: 实现自动战斗的逻辑
- [x] **经济系统**: 管理金币和商店
- [x] **装备系统**: 管理装备的使用和合成
- [x] **遗物系统**: 管理遗物效果
- [x] **事件系统**: 管理随机事件
- [x] **玩家系统**: 管理玩家状态和属性
- [x] **羁绊系统**: 管理棋子羁绊效果

### 表现层系统

- [x] **UI系统**: 管理游戏界面和交互
- [~] **场景管理**: 管理场景切换和过渡
- [~] **动画系统**: 管理游戏动画
- [✓] **特效系统**: 管理游戏特效
- [✓] **皮肤系统**: 管理游戏皮肤

### 辅助系统

- [✓] **成就系统**: 管理游戏成就
- [✓] **教程系统**: 提供新手引导
- [✓] **网络系统**: 预留多人游戏接口

## 当前进度

### 已完成

1. **项目基础架构**
   - 目录结构设计
   - 项目配置文件
   - 基本场景框架（主菜单、地图、战斗、商店、事件）

2. **核心系统**
   - 事件总线系统 (EventBus)
   - 游戏管理器 (GameManager)
   - 配置管理器 (ConfigManager)
   - 状态管理器 (StateManager)
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

5. **多语言支持**
   - 中文本地化文件 (zh_CN.json)

6. **UI框架**
   - UI管理器 (ui_manager.gd)
   - 场景管理器 (scene_manager.gd)
   - HUD组件基础框架
   - 弹窗系统基础框架
   - 通知系统框架
   - 工具提示系统框架

7. **动画系统框架**
   - 动画管理器 (animation_manager.gd)
   - 棋子动画控制器 (chess_animator.gd)
   - 战斗动画控制器 (battle_animator.gd)
   - 特效动画控制器 (effect_animator.gd)

## 最近完成的工作

### 架构优化

1. **棋盘系统重构**
   - 将 BoardManager 与 ChessBoard 分离，实现逻辑与表现层分离
   - BoardManager 作为纯逻辑类，负责棋盘状态管理
   - ChessBoard 作为场景控制器，负责视觉表现和用户交互
   - 修复了 cell_scene 实例化问题
   - 优化了对象池的使用方式

2. **棋子系统重构**
   - 采用MVC架构重构棋子系统，分离数据、逻辑和视图
   - 创建 ChessPieceData 类存储纯数据
   - 创建 ChessPieceController 类处理棋子逻辑
   - 创建 ChessPieceView 类处理视觉表现
   - 实现新的状态机系统，更模块化和可扩展
   - 优化棋子工厂，统一棋子创建和回收逻辑
   - 完全集成到新的效果系统

### 下一步计划

1. **性能优化**
   - 优化对象池使用，减少内存占用和垃圾回收
   - 优化渲染性能，减少不必要的绘制
   - 优化战斗计算逻辑，提高战斗流畅度

2. **游戏平衡性调整**
   - 调整棋子属性和技能效果，确保各棋子间平衡
   - 优化羁绑效果和触发条件，增加策略深度
   - 调整经济系统和奖励机制，提供合理的游戏进程

3. **用户体验优化**
   - 添加更多游戏引导和教程，降低新手门槛
   - 优化游戏反馈和提示，提高游戏可读性
   - 添加更多游戏统计和成就系统，增强游戏粘性

### 具体实施计划

1. **第一阶段：核心系统完善**
   - 继续优化 Manager 类与场景的分离，提高代码质量和可维护性
   - 完善状态管理系统，将分散的状态管理集中到StateManager
   - 进一步完善皮肤系统，实现皮肤实时预览和切换动画
   - 完善技能系统的目标选择和效果应用逻辑
   - 完善战斗系统的战斗逻辑和AI
   - 完善地图系统的节点类型和事件内容

2. **第二阶段：UI和体验优化**
   - 优化战斗、商店、地图等界面的交互逻辑
   - 完善视觉效果和动画系统
   - 优化多语言支持和文本显示

3. **第三阶段：性能和平衡性优化**
   - 进行性能分析和优化
   - 调整游戏平衡性
   - 完善存档系统和数据持久化

4. **第四阶段：测试和发布准备**
   - 进行全面测试，修复发现的问题
   - 优化游戏体验和细节
   - 准备发布版本和更新计划

## 设计原则

1. **模块化设计**：各系统功能明确，职责单一
2. **松耦合通信**：系统间通过事件总线通信，降低耦合度
3. **数据驱动**：游戏数据与逻辑分离，便于调整和扩展
4. **可扩展性**：预留接口，便于添加新功能
5. **可维护性**：清晰的代码结构和注释，便于维护
6. **性能优先**：注重游戏性能，使用对象池、资源管理和渲染优化
7. **用户体验**：关注用户体验，提供直观的界面和反馈
8. **可测试性**：设计便于测试的代码结构，支持自动化测试
9. **代码质量**: 不应该为了兼容老式系统而写出各种防御性代码，兼容代码，应该主动脱离老式系统，重构/改造使用更优秀更高效的新模块以保证代码质量

## 技术栈

- Godot 4.4.1
- GDScript
- JSON（配置文件）
- 应用 AngularJS commit 规范

## 要求

阅读 README.md ，继续完成项目，文件中的完成状态可能不准确，你可以自己判断所有模块的完成度，然后优化完善模块。用中文回复我。

- 修改代码的时候必须先对原文件和相关模块完全的掌握，不应该粗暴的完全替换原文件。
- 带着重构优化的目光审视相关代码，以最优解重构模块，不需要考虑兼容问题，如果有保护性的兼容代码请修改掉，不要使用注释相关功能的方式来逃避问题。
- 分步进行修改。
- 优先使用已有文件，然后判断已有文件是否合理，如何改造,不合理可以直接修改/删除/替换。不要随意新建相同功能的新文件/函数，以免造成混乱。
- 提高代码质量：比如封装重复对象，合并重复功能，清理冗余代码，
- 不合理的或者有更好实现的模块请直接用最优解重构，不需要考虑兼容问题，重构完成后检查api的变化，修复其他引用此模块的地方。
- 我们生成代码的时候，提前考虑好性能、可扩展性、可配置、解耦、模块化的实现。代码要提前关注可能与其他系统的交互,预设交互空间（比如难度、皮肤、多语言-目前只需要中文、成就统计、遗物影响、事件影响、插件系统以及其它系统）
- 当涉及到无法生成的文件的时候，请使用虚拟文件占位（或者godot 是否会有一些公共素材？）。
- 新增/删除/重构功能时判断此项目是否真的需要这些需修改？在合适的范围内做减法。
- 完成模块开发后，在最后再次确认是否有遗漏，确认无误后更新 README.md，以规划下一步的开发工作。

## Debug
运行 godot 查看错误日志并继续修复，每次修復一个问题之前，请先告诉我问题的根源，以及你修复的方式，修复之前请先思考有没有更好的方式。
