#!/usr/bin/env python3
"""
Equipment JSON 修复工具
用于修复 equipment.json 文件中的效果类型和触发条件
"""

import json
import os
import sys

# 项目根目录
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))

# 文件路径
EQUIPMENT_JSON_PATH = os.path.join(PROJECT_ROOT, "config/equipment.json")

# 有效的效果类型
VALID_EFFECT_TYPES = [
    "stat_boost",
    "damage",
    "heal",
    "gold",
    "shop",
    "synergy",
    "special",
    "status",
    "movement",
    "visual",
    "sound"
]

# 有效的触发条件
VALID_TRIGGER_TYPES = [
    "passive",
    "on_acquire",
    "on_round_start",
    "on_round_end",
    "on_battle_start",
    "on_battle_end",
    "on_battle_victory",
    "on_battle_defeat",
    "on_activate",
    "on_attack",
    "on_hit",
    "on_ability",
    "on_crit",
    "on_dodge",
    "on_damage",
    "on_low_health",
    "on_event_completed",
    "on_map_node_selected"
]

# 条件类型到触发条件的映射
CONDITION_TO_TRIGGER_MAP = {
    "attack": "on_attack",
    "ability_cast": "on_ability",
    "crit": "on_crit",
    "dodge": "on_dodge",
    "take_damage": "on_hit",
    "take_physical_damage": "on_hit",
    "take_magic_damage": "on_hit",
    "health_percent": "on_low_health",
    "low_health": "on_low_health",
    "attack_count": "on_attack",
    "elemental_effect": "on_hit"
}

# 触发条件到效果类型的映射
TRIGGER_TO_EFFECT_TYPE_MAP = {
    "on_attack": "damage",
    "on_ability": "special",
    "on_crit": "damage",
    "on_dodge": "special",
    "on_damage": "damage",
    "on_hit": "status",
    "passive": "stat_boost"
}

def load_json_file(file_path):
    """加载 JSON 文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        print(f"无法加载 JSON 文件 {file_path}: {e}")
        return {}

def save_json_file(file_path, data):
    """保存 JSON 文件"""
    try:
        with open(file_path, 'w', encoding='utf-8') as file:
            json.dump(data, file, ensure_ascii=False, indent=4)
        return True
    except Exception as e:
        print(f"无法保存 JSON 文件 {file_path}: {e}")
        return False

def find_closest_string(input_str, candidates):
    """找到最接近的字符串"""
    if input_str in candidates:
        return input_str
    
    best_match = ""
    best_score = 0
    
    for candidate in candidates:
        score = string_similarity(input_str, candidate)
        if score > best_score:
            best_score = score
            best_match = candidate
    
    # 只有当相似度大于 0.5 时才返回匹配
    if best_score > 0.5:
        return best_match
    
    return ""

def string_similarity(a, b):
    """计算字符串相似度"""
    if a == b:
        return 1.0
    
    len_a = len(a)
    len_b = len(b)
    
    if len_a == 0 or len_b == 0:
        return 0.0
    
    # 计算 Levenshtein 距离
    matrix = [[0 for _ in range(len_b + 1)] for _ in range(len_a + 1)]
    
    for i in range(len_a + 1):
        matrix[i][0] = i
    
    for j in range(len_b + 1):
        matrix[0][j] = j
    
    for i in range(1, len_a + 1):
        for j in range(1, len_b + 1):
            cost = 0 if a[i-1] == b[j-1] else 1
            matrix[i][j] = min(
                matrix[i-1][j] + 1,      # 删除
                matrix[i][j-1] + 1,      # 插入
                matrix[i-1][j-1] + cost  # 替换
            )
    
    distance = matrix[len_a][len_b]
    max_len = max(len_a, len_b)
    
    return 1.0 - float(distance) / max_len

def fix_effect_type(effect_type):
    """修复效果类型"""
    # 如果是有效的效果类型，直接返回
    if effect_type in VALID_EFFECT_TYPES:
        return effect_type
    
    # 如果是触发条件，转换为对应的效果类型
    if effect_type in VALID_TRIGGER_TYPES:
        return TRIGGER_TO_EFFECT_TYPE_MAP.get(effect_type, "special")
    
    # 尝试找到最接近的效果类型
    closest_type = find_closest_string(effect_type, VALID_EFFECT_TYPES)
    if closest_type:
        print(f"修复效果类型: {effect_type} -> {closest_type}")
        return closest_type
    
    # 默认返回 special
    print(f"无法修复效果类型: {effect_type}，使用默认值 special")
    return "special"

def fix_trigger_type(trigger_type):
    """修复触发条件"""
    # 如果是有效的触发条件，直接返回
    if trigger_type in VALID_TRIGGER_TYPES:
        return trigger_type
    
    # 如果是条件类型，转换为对应的触发条件
    if trigger_type in CONDITION_TO_TRIGGER_MAP:
        fixed_trigger = CONDITION_TO_TRIGGER_MAP[trigger_type]
        print(f"修复触发条件: {trigger_type} -> {fixed_trigger}")
        return fixed_trigger
    
    # 尝试找到最接近的触发条件
    closest_trigger = find_closest_string(trigger_type, VALID_TRIGGER_TYPES)
    if closest_trigger:
        print(f"修复触发条件: {trigger_type} -> {closest_trigger}")
        return closest_trigger
    
    # 默认返回 passive
    print(f"无法修复触发条件: {trigger_type}，使用默认值 passive")
    return "passive"

def fix_equipment_json():
    """修复 equipment.json 文件"""
    print("开始修复 equipment.json 文件...")
    
    # 加载 equipment.json 文件
    equipment_data = load_json_file(EQUIPMENT_JSON_PATH)
    if not equipment_data:
        print("无法加载 equipment.json 文件")
        return
    
    fixed_count = 0
    
    # 遍历所有装备
    for equipment_id, equipment in equipment_data.items():
        # 修复稀有度（确保是整数）
        if "rarity" in equipment and isinstance(equipment["rarity"], float):
            equipment["rarity"] = int(equipment["rarity"])
            fixed_count += 1
            print(f"修复装备 {equipment_id} 的稀有度: {equipment['rarity']}")
        
        # 修复效果
        if "effects" in equipment and isinstance(equipment["effects"], list):
            for effect in equipment["effects"]:
                # 修复效果类型
                if "type" in effect:
                    original_type = effect["type"]
                    effect["type"] = fix_effect_type(original_type)
                    if original_type != effect["type"]:
                        fixed_count += 1
                
                # 修复触发条件
                if "trigger" in effect:
                    original_trigger = effect["trigger"]
                    effect["trigger"] = fix_trigger_type(original_trigger)
                    if original_trigger != effect["trigger"]:
                        fixed_count += 1
    
    print(f"修复了 {fixed_count} 个问题")
    
    # 保存修复后的文件
    if save_json_file(EQUIPMENT_JSON_PATH, equipment_data):
        print("修复完成，已保存 equipment.json 文件")
    else:
        print("保存 equipment.json 文件失败")

def main():
    """主函数"""
    fix_equipment_json()

if __name__ == "__main__":
    main()
