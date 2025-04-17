#!/bin/bash

# 修复 EventBus 信号调用的脚本

# 游戏相关信号
sed -i 's/EventBus.game_state_changed/EventBus.game.game_state_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.game_paused/EventBus.game.game_paused/g' $(find . -name "*.gd")
sed -i 's/EventBus.game_started/EventBus.game.game_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.game_ended/EventBus.game.game_ended/g' $(find . -name "*.gd")
sed -i 's/EventBus.player_health_changed/EventBus.game.player_health_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.player_level_changed/EventBus.game.player_level_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.player_died/EventBus.game.player_died/g' $(find . -name "*.gd")

# 地图相关信号
sed -i 's/EventBus.map_generated/EventBus.map.map_generated/g' $(find . -name "*.gd")
sed -i 's/EventBus.map_node_selected/EventBus.map.map_node_selected/g' $(find . -name "*.gd")
sed -i 's/EventBus.map_node_hovered/EventBus.map.map_node_hovered/g' $(find . -name "*.gd")
sed -i 's/EventBus.map_completed/EventBus.map.map_completed/g' $(find . -name "*.gd")
sed -i 's/EventBus.mystery_node_revealed/EventBus.map.mystery_node_revealed/g' $(find . -name "*.gd")
sed -i 's/EventBus.challenge_started/EventBus.map.challenge_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.challenge_completed/EventBus.map.challenge_completed/g' $(find . -name "*.gd")
sed -i 's/EventBus.altar_opened/EventBus.map.altar_opened/g' $(find . -name "*.gd")
sed -i 's/EventBus.altar_sacrifice_made/EventBus.map.altar_sacrifice_made/g' $(find . -name "*.gd")
sed -i 's/EventBus.blacksmith_opened/EventBus.map.blacksmith_opened/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_upgraded/EventBus.map.equipment_upgraded/g' $(find . -name "*.gd")
sed -i 's/EventBus.treasure_collected/EventBus.map.treasure_collected/g' $(find . -name "*.gd")
sed -i 's/EventBus.rest_completed/EventBus.map.rest_completed/g' $(find . -name "*.gd")

# 棋盘相关信号
sed -i 's/EventBus.board_initialized/EventBus.board.board_initialized/g' $(find . -name "*.gd")
sed -i 's/EventBus.board_reset/EventBus.board.board_reset/g' $(find . -name "*.gd")
sed -i 's/EventBus.cell_selected/EventBus.board.cell_selected/g' $(find . -name "*.gd")
sed -i 's/EventBus.cell_hovered/EventBus.board.cell_hovered/g' $(find . -name "*.gd")
sed -i 's/EventBus.cell_clicked/EventBus.board.cell_clicked/g' $(find . -name "*.gd")
sed -i 's/EventBus.piece_placed_on_board/EventBus.board.piece_placed_on_board/g' $(find . -name "*.gd")
sed -i 's/EventBus.piece_removed_from_board/EventBus.board.piece_removed_from_board/g' $(find . -name "*.gd")
sed -i 's/EventBus.piece_placed_on_bench/EventBus.board.piece_placed_on_bench/g' $(find . -name "*.gd")
sed -i 's/EventBus.piece_removed_from_bench/EventBus.board.piece_removed_from_bench/g' $(find . -name "*.gd")

# 棋子相关信号
sed -i 's/EventBus.chess_piece_created/EventBus.chess.chess_piece_created/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_piece_upgraded/EventBus.chess.chess_piece_upgraded/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_piece_sold/EventBus.chess.chess_piece_sold/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_pieces_merged/EventBus.chess.chess_pieces_merged/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_piece_moved/EventBus.chess.chess_piece_moved/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_piece_ability_activated/EventBus.chess.chess_piece_ability_activated/g' $(find . -name "*.gd")
sed -i 's/EventBus.synergy_activated/EventBus.chess.synergy_activated/g' $(find . -name "*.gd")
sed -i 's/EventBus.synergy_deactivated/EventBus.chess.synergy_deactivated/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_chess_info/EventBus.chess.show_chess_info/g' $(find . -name "*.gd")
sed -i 's/EventBus.hide_chess_info/EventBus.chess.hide_chess_info/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_piece_obtained/EventBus.chess.chess_piece_obtained/g' $(find . -name "*.gd")

# 战斗相关信号
sed -i 's/EventBus.battle_started/EventBus.battle.battle_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_ended/EventBus.battle.battle_ended/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_round_started/EventBus.battle.battle_round_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_round_ended/EventBus.battle.battle_round_ended/g' $(find . -name "*.gd")
sed -i 's/EventBus.damage_dealt/EventBus.battle.damage_dealt/g' $(find . -name "*.gd")
sed -i 's/EventBus.heal_received/EventBus.battle.heal_received/g' $(find . -name "*.gd")
sed -i 's/EventBus.ability_used/EventBus.battle.ability_used/g' $(find . -name "*.gd")
sed -i 's/EventBus.ability_effect_applied/EventBus.battle.ability_effect_applied/g' $(find . -name "*.gd")
sed -i 's/EventBus.unit_died/EventBus.battle.unit_died/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_speed_changed/EventBus.battle.battle_speed_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_preparing_phase_started/EventBus.battle.battle_preparing_phase_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.battle_fighting_phase_started/EventBus.battle.battle_fighting_phase_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.critical_hit/EventBus.battle.critical_hit/g' $(find . -name "*.gd")
sed -i 's/EventBus.attack_missed/EventBus.battle.attack_missed/g' $(find . -name "*.gd")
sed -i 's/EventBus.mana_changed/EventBus.battle.mana_changed/g' $(find . -name "*.gd")

# 经济相关信号
sed -i 's/EventBus.gold_changed/EventBus.economy.gold_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_refreshed/EventBus.economy.shop_refreshed/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_opened/EventBus.economy.shop_opened/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_closed/EventBus.economy.shop_closed/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_item_purchased/EventBus.economy.shop_item_purchased/g' $(find . -name "*.gd")
sed -i 's/EventBus.item_purchased/EventBus.economy.item_purchased/g' $(find . -name "*.gd")
sed -i 's/EventBus.item_sold/EventBus.economy.item_sold/g' $(find . -name "*.gd")
sed -i 's/EventBus.income_granted/EventBus.economy.income_granted/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_inventory_updated/EventBus.economy.shop_inventory_updated/g' $(find . -name "*.gd")
sed -i 's/EventBus.black_market_appeared/EventBus.economy.black_market_appeared/g' $(find . -name "*.gd")
sed -i 's/EventBus.mystery_shop_appeared/EventBus.economy.mystery_shop_appeared/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_shop_appeared/EventBus.economy.equipment_shop_appeared/g' $(find . -name "*.gd")
sed -i 's/EventBus.exp_gained/EventBus.economy.exp_gained/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_manually_refreshed/EventBus.economy.shop_manually_refreshed/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_discount_applied/EventBus.economy.shop_discount_applied/g' $(find . -name "*.gd")
sed -i 's/EventBus.shop_refresh_requested/EventBus.economy.shop_refresh_requested/g' $(find . -name "*.gd")

# 装备相关信号
sed -i 's/EventBus.equipment_created/EventBus.equipment.equipment_created/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_equipped/EventBus.equipment.equipment_equipped/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_unequipped/EventBus.equipment.equipment_unequipped/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_combined/EventBus.equipment.equipment_combined/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_combine_animation_started/EventBus.equipment.equipment_combine_animation_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_combine_animation_completed/EventBus.equipment.equipment_combine_animation_completed/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_effect_triggered/EventBus.equipment.equipment_effect_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_preview_requested/EventBus.equipment.equipment_preview_requested/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_combine_requested/EventBus.equipment.equipment_combine_requested/g' $(find . -name "*.gd")
sed -i 's/EventBus.equipment_obtained/EventBus.equipment.equipment_obtained/g' $(find . -name "*.gd")

# 遗物相关信号
sed -i 's/EventBus.relic_acquired/EventBus.relic.relic_acquired/g' $(find . -name "*.gd")
sed -i 's/EventBus.relic_activated/EventBus.relic.relic_activated/g' $(find . -name "*.gd")
sed -i 's/EventBus.relic_effect_triggered/EventBus.relic.relic_effect_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_relic_info/EventBus.relic.show_relic_info/g' $(find . -name "*.gd")
sed -i 's/EventBus.hide_relic_info/EventBus.relic.hide_relic_info/g' $(find . -name "*.gd")
sed -i 's/EventBus.relic_deactivated/EventBus.relic.relic_deactivated/g' $(find . -name "*.gd")
sed -i 's/EventBus.relic_removed/EventBus.relic.relic_removed/g' $(find . -name "*.gd")

# 事件相关信号
sed -i 's/EventBus.event_triggered/EventBus.event.event_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.event_choice_made/EventBus.event.event_choice_made/g' $(find . -name "*.gd")
sed -i 's/EventBus.event_completed/EventBus.event.event_completed/g' $(find . -name "*.gd")
sed -i 's/EventBus.event_started/EventBus.event.event_started/g' $(find . -name "*.gd")
sed -i 's/EventBus.event_option_selected/EventBus.event.event_option_selected/g' $(find . -name "*.gd")

# 剧情相关信号
sed -i 's/EventBus.story_flag_set/EventBus.story.story_flag_set/g' $(find . -name "*.gd")
sed -i 's/EventBus.story_branch_selected/EventBus.story.story_branch_selected/g' $(find . -name "*.gd")
sed -i 's/EventBus.story_progress_advanced/EventBus.story.story_progress_advanced/g' $(find . -name "*.gd")

# 诅咒相关信号
sed -i 's/EventBus.curse_applied/EventBus.curse.curse_applied/g' $(find . -name "*.gd")
sed -i 's/EventBus.curse_removed/EventBus.curse.curse_removed/g' $(find . -name "*.gd")
sed -i 's/EventBus.curse_effect_triggered/EventBus.curse.curse_effect_triggered/g' $(find . -name "*.gd")

# UI相关信号
sed -i 's/EventBus.ui_screen_changed/EventBus.ui.ui_screen_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.ui_popup_opened/EventBus.ui.ui_popup_opened/g' $(find . -name "*.gd")
sed -i 's/EventBus.ui_popup_closed/EventBus.ui.ui_popup_closed/g' $(find . -name "*.gd")
sed -i 's/EventBus.ui_button_pressed/EventBus.ui.ui_button_pressed/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_toast/EventBus.ui.show_toast/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_popup/EventBus.ui.show_popup/g' $(find . -name "*.gd")
sed -i 's/EventBus.close_popup/EventBus.ui.close_popup/g' $(find . -name "*.gd")
sed -i 's/EventBus.start_transition/EventBus.ui.start_transition/g' $(find . -name "*.gd")
sed -i 's/EventBus.transition_midpoint/EventBus.ui.transition_midpoint/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_notification/EventBus.ui.show_notification/g' $(find . -name "*.gd")
sed -i 's/EventBus.hide_notification/EventBus.ui.hide_notification/g' $(find . -name "*.gd")
sed -i 's/EventBus.clear_notifications/EventBus.ui.clear_notifications/g' $(find . -name "*.gd")
sed -i 's/EventBus.show_tooltip/EventBus.ui.show_tooltip/g' $(find . -name "*.gd")
sed -i 's/EventBus.hide_tooltip/EventBus.ui.hide_tooltip/g' $(find . -name "*.gd")
sed -i 's/EventBus.update_tooltip/EventBus.ui.update_tooltip/g' $(find . -name "*.gd")
sed -i 's/EventBus.theme_changed/EventBus.ui.theme_changed/g' $(find . -name "*.gd")

# 成就相关信号
sed -i 's/EventBus.achievement_progress/EventBus.achievement.achievement_progress/g' $(find . -name "*.gd")
sed -i 's/EventBus.achievement_unlocked/EventBus.achievement.achievement_unlocked/g' $(find . -name "*.gd")

# 教程相关信号
sed -i 's/EventBus.start_tutorial/EventBus.tutorial.start_tutorial/g' $(find . -name "*.gd")
sed -i 's/EventBus.skip_tutorial/EventBus.tutorial.skip_tutorial/g' $(find . -name "*.gd")
sed -i 's/EventBus.complete_tutorial/EventBus.tutorial.complete_tutorial/g' $(find . -name "*.gd")
sed -i 's/EventBus.tutorial_step_changed/EventBus.tutorial.tutorial_step_changed/g' $(find . -name "*.gd")

# 存档相关信号
sed -i 's/EventBus.game_saved/EventBus.save.game_saved/g' $(find . -name "*.gd")
sed -i 's/EventBus.game_loaded/EventBus.save.game_loaded/g' $(find . -name "*.gd")
sed -i 's/EventBus.autosave_triggered/EventBus.save.autosave_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.save_requested/EventBus.save.save_requested/g' $(find . -name "*.gd")
sed -i 's/EventBus.load_requested/EventBus.save.load_requested/g' $(find . -name "*.gd")
sed -i 's/EventBus.save_deleted/EventBus.save.save_deleted/g' $(find . -name "*.gd")
sed -i 's/EventBus.save_created/EventBus.save.save_created/g' $(find . -name "*.gd")
sed -i 's/EventBus.save_renamed/EventBus.save.save_renamed/g' $(find . -name "*.gd")

# 多语言相关信号
sed -i 's/EventBus.language_changed/EventBus.localization.language_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.font_changed/EventBus.localization.font_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.font_loaded/EventBus.localization.font_loaded/g' $(find . -name "*.gd")
sed -i 's/EventBus.request_font/EventBus.localization.request_font/g' $(find . -name "*.gd")
sed -i 's/EventBus.request_language_code/EventBus.localization.request_language_code/g' $(find . -name "*.gd")

# 音频相关信号
sed -i 's/EventBus.bgm_changed/EventBus.audio.bgm_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.sfx_played/EventBus.audio.sfx_played/g' $(find . -name "*.gd")
sed -i 's/EventBus.play_sound/EventBus.audio.play_sound/g' $(find . -name "*.gd")

# 皮肤相关信号
sed -i 's/EventBus.skin_changed/EventBus.skin.skin_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.skin_unlocked/EventBus.skin.skin_unlocked/g' $(find . -name "*.gd")
sed -i 's/EventBus.chess_skin_changed/EventBus.skin.chess_skin_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.board_skin_changed/EventBus.skin.board_skin_changed/g' $(find . -name "*.gd")
sed -i 's/EventBus.ui_skin_changed/EventBus.skin.ui_skin_changed/g' $(find . -name "*.gd")

# 状态效果相关信号
sed -i 's/EventBus.status_effect_added/EventBus.status_effect.status_effect_added/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_removed/EventBus.status_effect.status_effect_removed/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_refreshed/EventBus.status_effect.status_effect_refreshed/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_stacked/EventBus.status_effect.status_effect_stacked/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_immunity_triggered/EventBus.status_effect.status_effect_immunity_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_dot_triggered/EventBus.status_effect.status_effect_dot_triggered/g' $(find . -name "*.gd")
sed -i 's/EventBus.status_effect_resisted/EventBus.status_effect.status_effect_resisted/g' $(find . -name "*.gd")

# 调试相关信号
sed -i 's/EventBus.debug_message/EventBus.debug.debug_message/g' $(find . -name "*.gd")
sed -i 's/EventBus.debug_command_executed/EventBus.debug.debug_command_executed/g' $(find . -name "*.gd")

echo "EventBus 信号调用修复完成！"
