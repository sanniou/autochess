# 特效系统设计文档

## 1. 概述

特效系统负责管理游戏中的各种特效，包括逻辑效果（如伤害、治疗、状态效果等）和视觉效果（如粒子、精灵、着色器等）。系统采用分层设计，明确职责分离，提高代码可维护性和可扩展性。

## 2. 系统架构

特效系统由以下几个主要组件组成：

### 2.1 EffectManager

- **路径**：`scripts/managers/game/effect_manager.gd`
- **职责**：
  - 协调游戏中的逻辑效果和视觉效果
  - 充当游戏逻辑和视觉表现之间的桥梁
  - 提供统一的特效创建接口
  - 管理特效的生命周期
  - 封装效果数据的创建和处理

### 2.2 BattleEffectManager

- **路径**：`scripts/game/battle/effect_manager.gd`
- **职责**：
  - 管理战斗中的所有效果
  - 处理效果的应用、移除和更新
  - 管理效果对象池
  - 提供效果查询接口

### 2.3 VisualEffectAnimator

- **路径**：`scripts/animation/effect_animator.gd`
- **职责**：
  - 专注于创建和管理视觉特效
  - 支持粒子、精灵、着色器等多种特效类型
  - 管理特效资源和对象池
  - 处理特效的播放、暂停、恢复和取消

### 2.4 EffectRegistry

- **路径**：`scripts/animation/effect_registry.gd`
- **职责**：
  - 注册和管理特效配置
  - 提供特效查询接口
  - 支持组合特效的创建

## 3. 特效创建流程

### 3.1 逻辑效果创建流程

1. 游戏逻辑调用 `EffectManager.create_effect()`
2. `EffectManager` 调用 `_create_effect_data()` 创建效果数据
3. `EffectManager` 调用 `_create_visual_effect_for_type()` 创建相应的视觉效果
4. `EffectManager` 调用 `_apply_battle_effect()` 应用效果
5. `_apply_battle_effect()` 调用 `BattleEffectManager.apply_effect()` 实际应用效果

### 3.2 视觉特效创建流程

1. `EffectManager.create_visual_effect()` 被调用
2. `EffectManager` 调用 `_get_effect_name_for_type()` 获取特效名称
3. `EffectManager` 调用 `_get_color_key_for_effect()` 获取颜色键
4. `EffectManager` 调用 `_create_effect_with_animator()` 创建特效
5. 如果特效在注册表中，使用 `EffectRegistry.play_effect()`
6. 否则，直接使用 `VisualEffectAnimator.play_combined_effect()`

## 4. 使用示例

### 4.1 创建伤害效果

```gdscript
# 创建伤害效果
var params = {
    "value": 10.0,
    "damage_type": "physical",
    "is_critical": false
}
GameManager.effect_manager.create_effect(BaseEffect.EffectType.DAMAGE, target, params)
```

### 4.2 创建视觉特效

```gdscript
# 创建伤害视觉特效
var params = {
    "damage_type": "fire",
    "damage_amount": 15.0
}
GameManager.effect_manager.create_visual_effect(
    GameManager.effect_manager.VisualEffectType.DAMAGE,
    target,
    params
)
```

## 5. 注意事项

1. 游戏逻辑应该只与 `EffectManager` 交互，不要直接调用 `VisualEffectAnimator` 或 `BattleEffectManager`
2. `EffectManager` 负责封装效果数据的创建和处理，使用辅助方法保持代码清晰
3. `BattleEffectManager` 专注于效果的实际应用和管理，不处理效果数据的创建
4. 使用 `EffectRegistry` 注册和管理特效配置，避免硬编码特效参数
5. 使用对象池减少特效创建和销毁的开销

## 6. 未来优化方向

1. 完善特效配置系统，支持从JSON文件加载特效配置
2. 优化特效LOD系统，根据性能动态调整特效质量
3. 添加特效预览工具，方便设计师调试特效
4. 实现特效序列化，支持保存和加载特效状态
