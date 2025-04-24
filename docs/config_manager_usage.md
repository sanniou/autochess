# 配置管理器使用指南

## 概述

配置管理器 (`ConfigManager`) 负责加载、验证和管理游戏配置数据。它提供了一套简洁的API，用于访问和查询配置数据。

## 基本用法

### 获取配置模型

使用 `get_config_model_enum` 方法获取单个配置模型：

```gdscript
# 获取棋子配置
var warrior = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.CHESS_PIECES, "warrior_1")
print("棋子名称:", warrior.get_chess_name())
print("棋子生命值:", warrior.get_health())
```

### 获取所有配置模型

使用 `get_all_config_models_enum` 方法获取所有配置模型：

```gdscript
# 获取所有装备配置
var all_equipment = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.EQUIPMENT)
print("装备数量:", all_equipment.size())
```

## 查询功能

### 使用查询构建器

查询构建器提供了链式调用API，简化配置查询：

```gdscript
# 查询稀有度为"rare"的遗物
var rare_relics = GameManager.config_manager.create_query(ConfigTypes.Type.RELICS)
    .where("rarity", "rare")
    .get_array()

print("稀有遗物数量:", rare_relics.size())
```

### 多条件查询

可以使用 `where_many` 方法进行多条件查询：

```gdscript
# 查询1费战士棋子
var warrior_chess = GameManager.config_manager.create_query(ConfigTypes.Type.CHESS_PIECES)
    .where_many({"cost": 1, "synergies": ["warrior"]})
    .get_array()

print("1费战士棋子数量:", warrior_chess.size())
```

### 获取第一个匹配结果

使用 `first` 方法获取第一个匹配结果：

```gdscript
# 获取第一个法师棋子
var first_mage = GameManager.config_manager.create_query(ConfigTypes.Type.CHESS_PIECES)
    .where("synergies", ["mage"])
    .first()

if first_mage:
    print("第一个法师棋子:", first_mage.get_chess_name())
```

### 计数查询

使用 `count` 方法获取匹配结果的数量：

```gdscript
# 获取5费棋子数量
var high_cost_count = GameManager.config_manager.create_query(ConfigTypes.Type.CHESS_PIECES)
    .where("cost", 5)
    .count()

print("5费棋子数量:", high_cost_count)
```

## 错误处理

配置管理器使用严格错误处理，对关键配置错误使用 `assert` 和 `push_error`。这意味着：

1. 如果配置类型不存在，将会触发断言错误
2. 如果配置ID不存在，将会触发断言错误
3. 如果配置模型类不存在，将会触发断言错误

这样可以在开发阶段及早发现配置问题，而不是在运行时添加复杂的错误处理逻辑。

## 配置类型

所有配置类型都定义在 `ConfigTypes` 枚举中：

```gdscript
enum Type {
    CHESS_PIECES,      # 棋子配置
    EQUIPMENT,         # 装备配置
    MAP_CONFIG,        # 地图配置
    RELICS,            # 遗物配置
    SYNERGIES,         # 羁绊配置
    EVENTS,            # 事件配置
    DIFFICULTY,        # 难度配置
    ACHIEVEMENTS,      # 成就配置
    SKINS,             # 皮肤配置
    TUTORIALS,         # 教程配置
    ANIMATION_CONFIG,  # 动画配置
    ENVIRONMENT_EFFECTS, # 环境效果配置
    SKILL_EFFECTS,     # 技能效果配置
    BOARD_SKINS,       # 棋盘皮肤配置
    CHESS_SKINS,       # 棋子皮肤配置
    UI_SKINS,          # UI皮肤配置
}
```

## 最佳实践

1. 始终使用枚举API，避免使用字符串版本
2. 使用查询构建器进行复杂查询，而不是手动过滤
3. 在开发阶段处理配置错误，而不是在运行时添加复杂的错误处理逻辑
4. 使用配置模型的类型安全方法，而不是直接访问配置数据
