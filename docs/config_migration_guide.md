# 配置系统迁移指南

本文档提供了从旧版配置系统迁移到新版配置系统的指南。

## 概述

我们已经重构了配置系统，提供了更强大、更类型安全的配置数据访问机制。新的配置系统具有以下特点：

- 类型安全的配置模型类
- 更强大的数据验证机制
- 更好的代码提示和自动完成
- 更好的错误处理

## 主要变化

1. 配置管理器实现移至 `scripts/managers/system/config_manager.gd`
2. 配置数据现在通过配置模型类访问，而不是原始字典
3. 配置模型类提供了类型安全的方法来访问配置数据

## 迁移步骤

### 1. 使用配置模型类

旧代码：
```gdscript
var chess_data = ConfigManager.get_chess_piece_config("knight")
var health = chess_data.health
```

新代码：
```gdscript
var chess_model = ConfigManager.get_chess_piece_config("knight")
var health = chess_model.get_health()
```

### 2. 使用配置模型类的方法

旧代码：
```gdscript
var equipment_data = ConfigManager.get_equipment_config("sword")
var attack_bonus = equipment_data.stats.attack
```

新代码：
```gdscript
var equipment_model = ConfigManager.get_equipment_config("sword")
var attack_bonus = equipment_model.get_stat("attack")
```

### 3. 使用配置模型类的辅助方法

旧代码：
```gdscript
var synergy_data = ConfigManager.get_synergy_config("warrior")
var threshold = 0
for t in synergy_data.thresholds:
    if t.count <= active_count:
        threshold = t
```

新代码：
```gdscript
var synergy_model = ConfigManager.get_synergy_config("warrior")
var threshold = synergy_model.get_threshold_for_count(active_count)
```

### 4. 使用配置模型类的验证功能

旧代码：
```gdscript
var event_data = ConfigManager.get_event_config("treasure_chest")
if event_data.has("choices") and event_data.choices.size() > 0:
    # 处理选项
```

新代码：
```gdscript
var event_model = ConfigManager.get_event_config("treasure_chest")
if event_model.get_choices().size() > 0:
    # 处理选项
```

## 配置模型类

新的配置系统提供了以下配置模型类：

- `ChessPieceConfig` - 棋子配置模型
- `EquipmentConfig` - 装备配置模型
- `MapNodeConfig` - 地图节点配置模型
- `RelicConfig` - 遗物配置模型
- `SynergyConfig` - 羁绊配置模型
- `EventConfig` - 事件配置模型
- `DifficultyConfig` - 难度配置模型
- `AchievementConfig` - 成就配置模型
- `SkinConfig` - 皮肤配置模型
- `TutorialConfig` - 教程配置模型

每个配置模型类都提供了一组方法来访问配置数据，例如：

```gdscript
# ChessPieceConfig
var name = chess_model.get_name()
var health = chess_model.get_health()
var attack = chess_model.get_attack_damage()
var synergies = chess_model.get_synergies()

# EquipmentConfig
var name = equipment_model.get_name()
var rarity = equipment_model.get_rarity()
var attack_bonus = equipment_model.get_stat("attack")
var has_crit = equipment_model.has_effect_type("critical")

# SynergyConfig
var name = synergy_model.get_name()
var type = synergy_model.get_type()
var threshold = synergy_model.get_threshold_for_count(active_count)
var effects = synergy_model.get_effects_for_threshold(active_count)
```

## 新功能

### 1. 配置验证

```gdscript
# 验证配置数据
var is_valid = chess_model.validate(chess_data)

# 获取验证错误
var errors = chess_model.get_validation_errors()
```

### 2. 配置模型辅助方法

```gdscript
# 检查装备是否可以被特定职业使用
var can_use = equipment_model.can_be_used_by_class("warrior")

# 获取特定类型的效果
var passive_effects = equipment_model.get_effects_by_type("passive")

# 检查是否满足解锁条件
var is_unlocked = skin_model.meets_unlock_condition(player_data)
```

### 3. 配置数据过滤

```gdscript
# 获取特定羁绊的棋子
var warrior_pieces = ConfigManager.get_chess_pieces_by_synergy("warrior")

# 获取特定费用的棋子
var high_cost_pieces = ConfigManager.get_chess_pieces_by_cost([4, 5])

# 获取特定稀有度的装备
var rare_equipment = ConfigManager.get_equipments_by_rarity([3, 4, 5])
```

## 最佳实践

1. 使用配置模型类的方法访问配置数据，而不是直接访问字典
2. 利用配置模型类的辅助方法简化代码
3. 使用配置模型类的验证功能确保数据有效
4. 使用配置管理器的过滤方法获取特定条件的配置数据

## 常见问题

### 1. 我需要访问配置数据的原始字典

如果确实需要访问原始字典，可以使用配置模型类的 `get_data()` 方法：

```gdscript
var chess_model = ConfigManager.get_chess_piece_config("knight")
var raw_data = chess_model.get_data()
```

但是，我们强烈建议使用配置模型类的方法访问配置数据，以获得类型安全和更好的代码提示。

### 2. 我需要修改配置数据

配置数据应该是只读的，不应该在运行时修改。如果需要修改配置数据，应该创建一个新的配置数据对象，然后使用配置模型类的 `set_data()` 方法：

```gdscript
var chess_model = ConfigManager.get_chess_piece_config("knight")
var data = chess_model.get_data()
data.health = 1000
var new_model = ChessPieceConfig.new("knight", data)
```

### 3. 我需要创建自定义配置模型类

如果需要创建自定义配置模型类，可以继承 `ConfigModel` 类：

```gdscript
extends "res://scripts/config/config_model.gd"
class_name MyCustomConfig

func _get_config_type() -> String:
    return "my_custom"

func _get_default_schema() -> Dictionary:
    return {
        "id": {
            "type": "string",
            "required": true,
            "description": "配置ID"
        },
        # 其他字段
    }

# 自定义方法
func get_my_field() -> String:
    return data.get("my_field", "")
```

## 结论

新的配置系统提供了更强大、更类型安全的配置数据访问机制，使代码更加清晰和可维护。通过遵循本指南，您可以轻松地将代码从旧版配置系统迁移到新版配置系统。
