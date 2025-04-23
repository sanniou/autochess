# @tool
# extends EditorScript
# ## 常量测试工具
# ## 用于测试优化后的常量类

# # 引入常量类
# const GameConsts = preload("res://scripts/constants/game_constants.gd")
# const EffectConsts = preload("res://scripts/constants/effect_constants_optimized.gd")
# const RelicConsts = preload("res://scripts/constants/relic_constants_optimized.gd")

# # 执行测试
# func _run():
# 	print("开始测试常量类...")
	
# 	# 测试 GameConstants
# 	test_game_constants()
	
# 	# 测试 EffectConstants
# 	test_effect_constants()
	
# 	# 测试 RelicConstants
# 	test_relic_constants()
	
# 	# 测试常量类之间的交互
# 	test_constants_interaction()
	
# 	print("测试完成")

# # 测试 GameConstants
# func test_game_constants():
# 	print("\n=== 测试 GameConstants ===")
	
# 	# 测试稀有度
# 	print("稀有度枚举值: ", GameConsts.Rarity.RARE)
# 	print("稀有度名称: ", GameConsts.get_rarity_name(GameConsts.Rarity.RARE))
# 	print("稀有度颜色: ", GameConsts.get_rarity_color(GameConsts.Rarity.RARE))
# 	print("所有稀有度: ", GameConsts.get_all_rarities())
# 	print("等级5可用稀有度: ", GameConsts.get_rarities_by_level(5))
	
# 	# 测试伤害类型
# 	print("伤害类型枚举值: ", GameConsts.DamageType.FIRE)
# 	print("伤害类型名称: ", GameConsts.get_damage_type_name(GameConsts.DamageType.FIRE))
# 	print("伤害类型颜色: ", GameConsts.get_damage_type_color(GameConsts.DamageType.FIRE))
# 	print("所有伤害类型: ", GameConsts.get_all_damage_types())

# # 测试 EffectConstants
# func test_effect_constants():
# 	print("\n=== 测试 EffectConstants ===")
	
# 	# 测试效果类型
# 	print("效果类型枚举值: ", EffectConsts.EffectType.DAMAGE)
# 	print("效果类型名称: ", EffectConsts.EFFECT_TYPE_NAMES[EffectConsts.EffectType.DAMAGE])
# 	print("所有效果类型: ", EffectConsts.get_effect_types())
# 	print("所有效果类型名称: ", EffectConsts.get_effect_type_names())
# 	print("效果类型描述: ", EffectConsts.get_effect_type_description(EffectConsts.EffectType.DAMAGE))
	
# 	# 测试触发条件
# 	print("触发条件枚举值: ", EffectConsts.TriggerType.ON_ATTACK)
# 	print("触发条件名称: ", EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_ATTACK])
# 	print("所有触发条件: ", EffectConsts.get_trigger_types())
# 	print("所有触发条件名称: ", EffectConsts.get_trigger_type_names())
# 	print("触发条件描述: ", EffectConsts.get_trigger_type_description(EffectConsts.TriggerType.ON_ATTACK))
	
# 	# 测试条件类型
# 	print("条件类型枚举值: ", EffectConsts.ConditionType.ATTACK)
# 	print("条件类型名称: ", EffectConsts.CONDITION_TYPE_NAMES[EffectConsts.ConditionType.ATTACK])
# 	print("所有条件类型: ", EffectConsts.get_condition_types())
# 	print("所有条件类型名称: ", EffectConsts.get_condition_type_names())
	
# 	# 测试映射
# 	print("触发条件对应的条件类型: ", EffectConsts.get_default_condition_for_trigger(EffectConsts.TriggerType.ON_ATTACK))
# 	print("效果类型对应的默认触发条件: ", EffectConsts.get_default_trigger_for_effect(EffectConsts.EffectType.DAMAGE))
	
# 	# 测试字符串转换
# 	print("字符串转效果类型: ", EffectConsts.string_to_effect_type("damage"))
# 	print("字符串转触发条件: ", EffectConsts.string_to_trigger_type("on_attack"))
# 	print("字符串转条件类型: ", EffectConsts.string_to_condition_type("attack"))
	
# 	# 测试验证
# 	print("验证效果类型: ", EffectConsts.is_valid_effect_type("damage"))
# 	print("验证触发条件: ", EffectConsts.is_valid_trigger_type("on_attack"))
# 	print("验证条件类型: ", EffectConsts.is_valid_condition_type("attack"))
	
# 	# 测试创建效果数据
# 	var effect_data = EffectConsts.create_effect_data(EffectConsts.EffectType.DAMAGE, 10, EffectConsts.TriggerType.ON_ATTACK)
# 	print("创建的效果数据: ", effect_data)

# # 测试 RelicConstants
# func test_relic_constants():
# 	print("\n=== 测试 RelicConstants ===")
	
# 	# 测试遗物类型
# 	print("遗物类型枚举值: ", RelicConsts.RelicType.OFFENSIVE)
# 	print("遗物类型名称: ", RelicConsts.get_relic_type_name(RelicConsts.RelicType.OFFENSIVE))
# 	print("遗物类型描述: ", RelicConsts.get_relic_type_description(RelicConsts.RelicType.OFFENSIVE))
# 	print("遗物类型颜色: ", RelicConsts.get_relic_type_color(RelicConsts.RelicType.OFFENSIVE))
# 	print("所有遗物类型: ", RelicConsts.get_relic_types())
# 	print("所有遗物类型名称: ", RelicConsts.get_relic_type_names())
	
# 	# 测试字符串转换
# 	print("字符串转遗物类型: ", RelicConsts.string_to_relic_type("offensive"))
	
# 	# 测试验证
# 	print("验证遗物类型: ", RelicConsts.is_valid_relic_type("offensive"))
	
# 	# 测试获取价格
# 	print("稀有度对应的价格: ", RelicConsts.get_relic_price_by_rarity(GameConsts.Rarity.RARE))
	
# 	# 测试创建遗物数据
# 	var relic_data = RelicConsts.create_relic_data(
# 		"test_relic",
# 		"测试遗物",
# 		"这是一个测试遗物",
# 		GameConsts.Rarity.RARE,
# 		RelicConsts.RelicType.OFFENSIVE,
# 		true,
# 		[EffectConsts.create_effect_data(EffectConsts.EffectType.DAMAGE, 10, EffectConsts.TriggerType.ON_ATTACK)]
# 	)
# 	print("创建的遗物数据: ", relic_data)
	
# 	# 测试添加触发条件
# 	relic_data = RelicConsts.add_trigger_condition(
# 		relic_data,
# 		EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_ATTACK],
# 		EffectConsts.CONDITION_TYPE_NAMES[EffectConsts.ConditionType.CHANCE],
# 		0.5,
# 		"50%几率触发"
# 	)
# 	print("添加触发条件后的遗物数据: ", relic_data)

# # 测试常量类之间的交互
# func test_constants_interaction():
# 	print("\n=== 测试常量类交互 ===")
	
# 	# 测试 RelicConstants 使用 EffectConstants
# 	print("RelicConstants 获取有效触发条件: ", RelicConsts.get_valid_triggers())
# 	print("RelicConstants 获取有效效果类型: ", RelicConsts.get_valid_effect_types())
# 	print("RelicConstants 获取有效条件类型: ", RelicConsts.get_valid_condition_types())
	
# 	# 测试创建完整的遗物数据
# 	var effects = [
# 		EffectConsts.create_effect_data(EffectConsts.EffectType.DAMAGE, 10, EffectConsts.TriggerType.ON_ATTACK),
# 		EffectConsts.create_effect_data(EffectConsts.EffectType.STAT_BOOST, 5, EffectConsts.TriggerType.PASSIVE)
# 	]
	
# 	var relic_data = RelicConsts.create_relic_data(
# 		"fire_sword",
# 		"火焰之剑",
# 		"一把燃烧着烈火的剑",
# 		GameConsts.Rarity.EPIC,
# 		RelicConsts.RelicType.OFFENSIVE,
# 		true,
# 		effects
# 	)
	
# 	# 添加触发条件
# 	relic_data = RelicConsts.add_trigger_condition(
# 		relic_data,
# 		EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_ATTACK],
# 		EffectConsts.CONDITION_TYPE_NAMES[EffectConsts.ConditionType.CHANCE],
# 		0.3,
# 		"30%几率触发"
# 	)
	
# 	relic_data = RelicConsts.add_trigger_condition(
# 		relic_data,
# 		EffectConsts.TRIGGER_TYPE_NAMES[EffectConsts.TriggerType.ON_ATTACK],
# 		EffectConsts.CONDITION_TYPE_NAMES[EffectConsts.ConditionType.ATTACK_COUNT],
# 		3,
# 		"每3次攻击触发"
# 	)
	
# 	print("完整的遗物数据: ", relic_data)
