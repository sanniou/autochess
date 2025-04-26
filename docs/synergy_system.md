# 羁绊系统文档

## 概述

羁绊系统是游戏中的一个核心机制，允许同类型的棋子组合在一起获得额外的效果。羁绊系统由以下几个主要组件组成：

1. **SynergyManager**：全局管理器，负责跟踪所有羁绊的状态、激活条件和效果应用
2. **SynergyComponent**：棋子组件，管理单个棋子的羁绊类型和等级
3. **SynergyEffectProcessor**：静态工具类，处理羁绊效果的应用和移除
4. **SynergyConfig**：配置模型，定义羁绊的属性和效果
5. **SynergyConstants**：常量类，定义羁绊系统中使用的所有枚举和常量

## 羁绊类型

羁绊系统支持三种基本类型的羁绊：

```gdscript
enum SynergyType {
    CLASS,   # 职业羁绊
    RACE,    # 种族羁绊
    SPECIAL  # 特殊羁绊
}
```

- **职业羁绊**：基于棋子的职业类型，如战士、法师、刺客等
- **种族羁绊**：基于棋子的种族类型，如人类、精灵、元素等
- **特殊羁绊**：特殊的羁绊类型，可以跨职业和种族

## 效果类型

羁绊系统支持多种效果类型：

```gdscript
enum EffectType {
    ATTRIBUTE,         # 属性效果
    ABILITY,           # 技能效果
    SPECIAL,           # 特殊效果
    CRIT,              # 暴击效果
    DODGE,             # 闪避效果
    ELEMENTAL_EFFECT,  # 元素效果
    COOLDOWN_REDUCTION,# 冷却减少
    SPELL_AMP,         # 法术增强
    DOUBLE_ATTACK,     # 双重攻击
    SUMMON_BOOST,      # 召唤物增强
    TEAM_BUFF,         # 团队增益
    STAT_BOOST         # 属性增益
}
```

每种效果类型都有特定的参数和行为，详见下文。

## 目标选择器

羁绊效果可以应用于不同的目标，通过目标选择器来指定：

```gdscript
enum TargetSelector {
    SAME_SYNERGY,      # 同羁绊棋子
    ALL_PLAYER_PIECES, # 所有玩家棋子
    RANDOM,            # 随机棋子
    HIGHEST_ATTRIBUTE, # 特定属性最高的棋子
    LOWEST_ATTRIBUTE,  # 特定属性最低的棋子
    CUSTOM             # 自定义选择器
}
```

## 配置文件格式

羁绊配置使用JSON格式，存储在`config/synergies.json`文件中。以下是一个示例配置：

```json
{
  "assassin": {
    "description": "刺客获得额外的暴击几率和暴击伤害。",
    "icon_path": "res://assets/images/synergies/assassin_synergy.png",
    "id": "assassin",
    "name": "刺客",
    "type": "class",
    "thresholds": [
      {
        "count": 2,
        "effects": [
          {
            "id": "assassin_crit_1",
            "type": "crit",
            "description": "增加10%暴击几率和20%暴击伤害",
            "chance": 0.1,
            "damage": 0.2,
            "target_selector": "same_synergy"
          }
        ]
      },
      {
        "count": 4,
        "effects": [
          {
            "id": "assassin_crit_2",
            "type": "crit",
            "description": "增加20%暴击几率和40%暴击伤害",
            "chance": 0.2,
            "damage": 0.4,
            "target_selector": "same_synergy"
          }
        ]
      }
    ]
  }
}
```

### 配置字段说明

- **id**：羁绊的唯一标识符
- **name**：羁绊的显示名称
- **description**：羁绊的描述
- **type**：羁绊类型（class、race、special）
- **icon_path**：羁绊图标的资源路径
- **thresholds**：羁绊激活阈值数组
  - **count**：激活所需的棋子数量
  - **effects**：激活后的效果数组
    - **id**：效果的唯一标识符
    - **type**：效果类型
    - **description**：效果描述
    - **target_selector**：目标选择器（可选，默认为same_synergy）
    - 其他特定效果类型的参数

## 效果类型参数

### 暴击效果 (CRIT)

```json
{
  "id": "assassin_crit",
  "type": "crit",
  "chance": 0.2,  // 暴击几率
  "damage": 0.4   // 暴击伤害倍率
}
```

### 闪避效果 (DODGE)

```json
{
  "id": "elf_dodge",
  "type": "dodge",
  "chance": 0.3   // 闪避几率
}
```

### 元素效果 (ELEMENTAL_EFFECT)

```json
{
  "id": "elemental_effect",
  "type": "elemental_effect",
  "chance": 0.2,  // 触发几率
  "element_type": "random"  // 元素类型
}
```

### 冷却减少 (COOLDOWN_REDUCTION)

```json
{
  "id": "human_cooldown",
  "type": "cooldown_reduction",
  "chance": 0.4,  // 触发几率
  "reduction": 2  // 减少的冷却时间（秒）
}
```

### 法术增强 (SPELL_AMP)

```json
{
  "id": "mage_spell_amp",
  "type": "spell_amp",
  "amp": 0.4  // 法术伤害增强系数
}
```

### 双重攻击 (DOUBLE_ATTACK)

```json
{
  "id": "ranger_double_attack",
  "type": "double_attack",
  "chance": 0.35  // 触发几率
}
```

### 召唤物增强 (SUMMON_BOOST)

```json
{
  "id": "summoner_boost",
  "type": "summon_boost",
  "damage": 0.4,  // 伤害增强系数
  "health": 0.4   // 生命增强系数
}
```

### 团队增益 (TEAM_BUFF)

```json
{
  "id": "support_team_buff",
  "type": "team_buff",
  "stats": {
    "attack_speed": 0.2  // 属性增益
  }
}
```

### 属性增益 (STAT_BOOST)

```json
{
  "id": "warrior_armor",
  "type": "stat_boost",
  "stats": {
    "armor": 35.0  // 属性增益
  }
}
```

### 特殊效果 (SPECIAL)

```json
{
  "id": "guardian_shield",
  "type": "special",
  "special_id": "shield",  // 特殊效果ID
  "shield_percent": 0.3,   // 特殊效果参数
  "target_selector": "lowest_attribute",
  "target_attribute": "current_health",
  "count": 3
}
```

## 目标选择器参数

### 同羁绊棋子 (SAME_SYNERGY)

应用于具有相同羁绊的棋子。

```json
"target_selector": "same_synergy"
```

### 所有玩家棋子 (ALL_PLAYER_PIECES)

应用于所有玩家棋子。

```json
"target_selector": "all_player_pieces"
```

### 随机棋子 (RANDOM)

随机选择指定数量的棋子。

```json
"target_selector": "random",
"count": 2  // 选择的棋子数量
```

### 特定属性最高的棋子 (HIGHEST_ATTRIBUTE)

选择特定属性值最高的棋子。

```json
"target_selector": "highest_attribute",
"target_attribute": "attack",  // 目标属性
"count": 1  // 选择的棋子数量
```

### 特定属性最低的棋子 (LOWEST_ATTRIBUTE)

选择特定属性值最低的棋子。

```json
"target_selector": "lowest_attribute",
"target_attribute": "current_health",  // 目标属性
"count": 3  // 选择的棋子数量
```

## 使用示例

### 在代码中获取羁绊信息

```gdscript
# 获取当前激活的羁绊
var active_synergies = GameManager.synergy_manager.get_active_synergies()

# 获取特定羁绊的等级
var assassin_level = GameManager.synergy_manager.get_synergy_level("assassin")

# 获取特定羁绊的棋子数量
var assassin_count = GameManager.synergy_manager.get_synergy_count("assassin")

# 获取特定羁绊的配置
var assassin_config = GameManager.synergy_manager.get_synergy_config("assassin")
```

### 监听羁绊事件

```gdscript
# 连接羁绊激活信号
GameManager.synergy_manager.synergy_activated.connect(_on_synergy_activated)

# 连接羁绊停用信号
GameManager.synergy_manager.synergy_deactivated.connect(_on_synergy_deactivated)

# 连接羁绊等级变化信号
GameManager.synergy_manager.synergy_level_changed.connect(_on_synergy_level_changed)

# 羁绊激活回调
func _on_synergy_activated(synergy_id, level):
    print("羁绊激活: " + synergy_id + " 等级 " + str(level))

# 羁绊停用回调
func _on_synergy_deactivated(synergy_id, level):
    print("羁绊停用: " + synergy_id + " 等级 " + str(level))

# 羁绊等级变化回调
func _on_synergy_level_changed(synergy_id, old_level, new_level):
    print("羁绊等级变化: " + synergy_id + " 从 " + str(old_level) + " 到 " + str(new_level))
```

## 扩展羁绊系统

### 添加新的羁绊类型

1. 在`SynergyConstants.gd`中的`SynergyType`枚举中添加新的羁绊类型
2. 更新`string_to_synergy_type`和`synergy_type_to_string`方法
3. 在`SynergyManager.gd`的`_get_target_pieces_for_synergy`方法中添加新类型的处理逻辑

### 添加新的效果类型

1. 在`SynergyConstants.gd`中的`EffectType`枚举中添加新的效果类型
2. 更新`string_to_effect_type`和`effect_type_to_string`方法
3. 在`SynergyEffectProcessor.gd`中添加新效果类型的应用和移除方法
4. 在`SynergyConfig.gd`的`_validate_custom_rules`方法中添加新效果类型的验证逻辑

### 添加新的目标选择器

1. 在`SynergyConstants.gd`中的`TargetSelector`枚举中添加新的目标选择器
2. 更新`string_to_target_selector`和`target_selector_to_string`方法
3. 在`SynergyManager.gd`的`_get_pieces_by_selector`方法中添加新选择器的处理逻辑

## 最佳实践

1. 为每个羁绊效果提供唯一的ID，避免冲突
2. 使用适当的目标选择器，避免不必要的效果应用
3. 为每个效果提供清晰的描述，便于UI显示
4. 使用枚举类型而不是字符串常量，提高代码的类型安全性
5. 在添加新的羁绊或效果类型时，确保更新相关的验证逻辑
6. 使用信号系统通知UI更新，保持代码的解耦
