# 配置文件结构标准

本文档描述了项目中配置文件的标准结构和命名约定。

## 配置文件位置

- 所有配置文件统一放在 `config/` 目录下
- 对于复杂的配置，可以使用子目录（如 `config/events/`, `config/relics/`）

## 配置文件命名

- 使用有意义的名称（如 `events.json`, `relics.json`）
- 避免重复的配置文件

## 配置文件结构

### 通用字段

所有配置文件应包含以下通用字段：

- `id`: 唯一标识符
- `name` 或 `title`: 显示名称
- `description`: 描述信息

### 事件配置 (events.json)

```json
{
  "event_id": {
    "id": "event_id",
    "title": "事件标题",
    "description": "事件描述",
    "image_path": "res://assets/images/events/event_image.png",
    "event_type": "normal|shop|battle|treasure",
    "weight": 100,
    "is_one_time": false,
    "choices": [
      {
        "text": "选项文本",
        "requirements": {
          "gold": 5,
          "has_item": "item_id"
        },
        "effects": [
          {
            "type": "gold|health|relic|item|chess_piece",
            "operation": "add|subtract|buff|remove",
            "value": 10,
            "chance": 0.7
          }
        ]
      }
    ]
  }
}
```

### 遗物配置 (relics.json)

```json
{
  "relic_id": {
    "id": "relic_id",
    "name": "遗物名称",
    "description": "遗物描述",
    "rarity": 0,
    "icon_path": "res://assets/images/relics/relic_icon.png",
    "is_passive": true,
    "cooldown": 0,
    "charges": 1,
    "effects": [
      {
        "type": "gold|stat_boost|heal|shop",
        "value": 10,
        "trigger": "on_acquire|on_round_start|on_round_end|on_battle_start|on_battle_end|on_activate",
        "description": "效果描述"
      }
    ]
  }
}
```

### 棋子配置 (chess_pieces.json)

```json
{
  "piece_id": {
    "id": "piece_id",
    "name": "棋子名称",
    "description": "棋子描述",
    "cost": 1,
    "health": 500,
    "attack_damage": 50,
    "attack_speed": 0.7,
    "armor": 20,
    "magic_resist": 20,
    "attack_range": 1,
    "move_speed": 300,
    "ability": {
      "name": "技能名称",
      "description": "技能描述",
      "type": "damage|area_damage|chain|teleport|aura|summon",
      "damage": 150,
      "cooldown": 8,
      "range": 1,
      "damage_type": "physical|magical|true"
    },
    "synergies": ["synergy1", "synergy2"],
    "tier": 1,
    "icon": "piece_icon.png",
    "model": "piece_model.tscn"
  }
}
```

### 装备配置 (equipment.json)

```json
{
  "equipment_id": {
    "id": "equipment_id",
    "name": "装备名称",
    "description": "装备描述",
    "rarity": 0,
    "icon_path": "res://assets/images/equipment/equipment_icon.png",
    "stats": {
      "attack_damage": 10,
      "attack_speed": 0.1,
      "armor": 5,
      "magic_resist": 5,
      "health": 50
    },
    "effects": [
      {
        "type": "passive|active|trigger",
        "description": "效果描述",
        "trigger": "on_attack|on_hit|on_spell_cast",
        "cooldown": 10
      }
    ],
    "components": ["component1_id", "component2_id"],
    "restricted_classes": ["warrior", "mage"]
  }
}
```

### 羁绊配置 (synergies.json)

```json
{
  "synergy_id": {
    "id": "synergy_id",
    "name": "羁绊名称",
    "description": "羁绊描述",
    "type": "class|race|special",
    "icon_path": "res://assets/images/synergies/synergy_icon.png",
    "thresholds": [
      {
        "count": 2,
        "effects": [
          {
            "type": "stat_boost",
            "stats": {
              "attack_damage": 0.1,
              "armor": 5
            },
            "is_percentage": true
          }
        ]
      },
      {
        "count": 4,
        "effects": [
          {
            "type": "stat_boost",
            "stats": {
              "attack_damage": 0.2,
              "armor": 10
            },
            "is_percentage": true
          }
        ]
      }
    ]
  }
}
```

### 地图节点配置 (map_nodes.json)

```json
{
  "map_templates": {
    "standard": {
      "name": "标准地图",
      "description": "平衡各类节点的标准地图",
      "node_weights": {
        "battle": 40,
        "elite": 15,
        "shop": 15,
        "event": 15,
        "rest": 10,
        "treasure": 5
      },
      "layers": 8,
      "nodes_per_layer": [3, 4, 4, 3, 4, 3, 3, 1]
    }
  },
  "node_types": {
    "battle": {
      "name": "战斗",
      "description": "与敌人战斗",
      "icon_path": "res://assets/images/map/battle_node.png",
      "color": "#FF0000"
    },
    "elite": {
      "name": "精英战斗",
      "description": "与强化敌人战斗",
      "icon_path": "res://assets/images/map/elite_node.png",
      "color": "#FF00FF"
    }
  }
}
```

### 难度配置 (difficulty.json)

```json
{
  "1": {
    "name": "简单",
    "description": "适合新手的难度",
    "enemy_health_multiplier": 0.8,
    "enemy_damage_multiplier": 0.8,
    "gold_reward_multiplier": 1.2,
    "item_drop_rate_multiplier": 1.2
  },
  "2": {
    "name": "普通",
    "description": "标准难度",
    "enemy_health_multiplier": 1.0,
    "enemy_damage_multiplier": 1.0,
    "gold_reward_multiplier": 1.0,
    "item_drop_rate_multiplier": 1.0
  }
}
```

### 成就配置 (achievements.json)

```json
{
  "achievement_id": {
    "id": "achievement_id",
    "name": "成就名称",
    "description": "成就描述",
    "icon_path": "res://assets/images/achievements/achievement_icon.png",
    "category": "gameplay|collection|challenge",
    "requirements": {
      "type": "win_games|collect_relics|defeat_enemies",
      "count": 10,
      "specific_id": "specific_item_id"
    },
    "rewards": {
      "gold": 100,
      "unlock_item": "item_id"
    }
  }
}
```

### 皮肤配置 (skins.json)

```json
{
  "skin_id": {
    "id": "skin_id",
    "name": "皮肤名称",
    "description": "皮肤描述",
    "preview_path": "res://assets/images/skins/skin_preview.png",
    "type": "chess|board|ui",
    "target_id": "target_piece_id",
    "assets": {
      "model": "res://assets/models/skins/skin_model.tscn",
      "icon": "res://assets/images/skins/skin_icon.png",
      "effects": "res://assets/effects/skins/skin_effects.tscn"
    },
    "unlock_condition": {
      "type": "achievement|purchase|special",
      "id": "condition_id"
    }
  }
}
```

## 使用指南

1. 使用 `ConfigManager` 加载和访问配置数据
2. 使用 `get_all_xxx()` 方法获取所有配置
3. 使用 `get_xxx_config(id)` 方法获取特定配置
4. 使用 `load_json(path)` 方法加载任意配置文件
5. 使用 `save_json(path, data)` 方法保存配置数据

## 注意事项

1. 所有路径应使用完整的 Godot 路径（如 `res://assets/...`）
2. 所有 ID 应使用小写字母和下划线
3. 所有配置文件应使用 UTF-8 编码
4. 所有配置文件应使用 JSON 格式
