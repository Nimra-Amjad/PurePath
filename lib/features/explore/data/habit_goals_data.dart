import 'package:flutter/material.dart';
import 'package:purepath/features/explore/models/habit_goal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit goals data
//
// Curated goals shown on the "Habit ideas" screen. Each goal carries a small
// set of concrete, easy-to-start habits — tapping one opens the configure
// sheet so the user can schedule it before it's added.
// ─────────────────────────────────────────────────────────────────────────────

const kHabitGoals = <HabitGoal>[
  HabitGoal(
    title: 'Lose weight',
    subtitle: 'Small changes, real results.',
    icon: Icons.balance_rounded,
    color: Color(0xFFB39DDB),
    habits: [
      HabitIdea(title: 'Eat eggs at breakfast', icon: Icons.egg_outlined),
      HabitIdea(title: 'Walk after lunch', icon: Icons.directions_walk_rounded),
      HabitIdea(title: 'No food after 9pm', icon: Icons.no_food_rounded),
      HabitIdea(
        title: 'Home food, not takeaway',
        icon: Icons.takeout_dining_outlined,
      ),
      HabitIdea(title: 'Water instead of soda', icon: Icons.water_drop_rounded),
      HabitIdea(title: 'Check weight once', icon: Icons.monitor_weight_outlined),
    ],
  ),
  HabitGoal(
    title: 'Get fit',
    subtitle: 'Build muscle, feel strong.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF64B5F6),
    habits: [
      HabitIdea(title: 'Gym or workout', icon: Icons.fitness_center_rounded),
      HabitIdea(title: 'Eat more protein', icon: Icons.set_meal_outlined),
      HabitIdea(title: 'Warm up first', icon: Icons.directions_run_rounded),
      HabitIdea(title: '20 push-ups', icon: Icons.back_hand_rounded),
      HabitIdea(title: 'Sleep 8 hours', icon: Icons.bedtime_rounded),
      HabitIdea(title: 'Take a rest day', icon: Icons.weekend_rounded),
    ],
  ),
  HabitGoal(
    title: 'More energy',
    subtitle: 'Stop feeling tired all day.',
    icon: Icons.bolt_rounded,
    color: Color(0xFF4CD9A8),
    habits: [
      HabitIdea(title: 'Get morning sunlight', icon: Icons.wb_sunny_rounded),
      HabitIdea(title: 'Water before tea', icon: Icons.water_drop_rounded),
      HabitIdea(
        title: 'No tea or coffee after 5',
        icon: Icons.local_cafe_outlined,
      ),
      HabitIdea(title: 'Stand up and stretch', icon: Icons.swap_vert_rounded),
      HabitIdea(title: 'Wake up at the same time', icon: Icons.alarm_rounded),
    ],
  ),
  HabitGoal(
    title: 'Feel calm',
    subtitle: 'Less stress, clear head.',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFFFFB74D),
    habits: [
      HabitIdea(title: 'Deep breathing', icon: Icons.air_rounded),
      HabitIdea(title: 'Write 3 good things', icon: Icons.edit_note_rounded),
      HabitIdea(title: 'Phone away from bed', icon: Icons.phonelink_off_rounded),
      HabitIdea(
        title: 'Walk without earphones',
        icon: Icons.directions_walk_rounded,
      ),
      HabitIdea(title: 'No news in the morning', icon: Icons.newspaper_rounded),
    ],
  ),
  HabitGoal(
    title: 'Sleep better',
    subtitle: 'Fix sleep, fix everything.',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF4FC3F7),
    habits: [
      HabitIdea(title: 'Phone off at 10:30', icon: Icons.phonelink_off_rounded),
      HabitIdea(title: 'Dark, cool room', icon: Icons.thermostat_rounded),
      HabitIdea(title: 'Read a few pages', icon: Icons.menu_book_rounded),
      HabitIdea(title: 'No late night snacks', icon: Icons.cookie_rounded),
      HabitIdea(title: 'Lights off by 11', icon: Icons.lightbulb_outline_rounded),
    ],
  ),
  HabitGoal(
    title: 'Save money',
    subtitle: 'Start small, watch it grow.',
    icon: Icons.savings_rounded,
    color: Color(0xFFFFD54F),
    habits: [
      HabitIdea(
        title: 'Write down what I spend',
        icon: Icons.receipt_long_rounded,
      ),
      HabitIdea(title: 'Save first, spend later', icon: Icons.savings_rounded),
      HabitIdea(
        title: 'Wait 2 days before buying',
        icon: Icons.back_hand_rounded,
      ),
      HabitIdea(
        title: 'One no-spend day',
        icon: Icons.account_balance_wallet_rounded,
      ),
      HabitIdea(
        title: "Cancel what I don't use",
        icon: Icons.credit_card_off_rounded,
      ),
    ],
  ),
  HabitGoal(
    title: 'Study better',
    subtitle: 'Focus for real, not for hours.',
    icon: Icons.school_rounded,
    color: Color(0xFF4DD0E1),
    habits: [
      HabitIdea(title: 'Pick one main task', icon: Icons.gps_fixed_rounded),
      HabitIdea(title: 'Study 45 min, no phone', icon: Icons.timer_rounded),
      HabitIdea(
        title: 'Phone in another room',
        icon: Icons.phonelink_off_rounded,
      ),
      HabitIdea(
        title: "Revise yesterday's notes",
        icon: Icons.sticky_note_2_rounded,
      ),
      HabitIdea(title: 'Check my week', icon: Icons.event_available_rounded),
    ],
  ),
  HabitGoal(
    title: 'Learn a skill',
    subtitle: 'Daily practice beats talent.',
    icon: Icons.emoji_objects_rounded,
    color: Color(0xFF81C784),
    habits: [
      HabitIdea(title: 'Practise 20 minutes', icon: Icons.music_note_rounded),
      HabitIdea(title: 'Work on the hard part', icon: Icons.loop_rounded),
      HabitIdea(
        title: 'Watch one tutorial',
        icon: Icons.play_circle_outline_rounded,
      ),
      HabitIdea(title: 'Make something small', icon: Icons.inventory_2_rounded),
      HabitIdea(title: 'Show it to someone', icon: Icons.share_rounded),
    ],
  ),
  HabitGoal(
    title: 'Learn English',
    subtitle: 'A little every day is enough.',
    icon: Icons.translate_rounded,
    color: Color(0xFFCFE36E),
    habits: [
      HabitIdea(title: 'Learn 10 new words', icon: Icons.style_rounded),
      HabitIdea(title: 'Listen on the way out', icon: Icons.headphones_rounded),
      HabitIdea(
        title: 'Speak out loud',
        icon: Icons.chat_bubble_outline_rounded,
      ),
      HabitIdea(title: 'Watch with subtitles', icon: Icons.subtitles_rounded),
      HabitIdea(title: 'Write 5 sentences', icon: Icons.edit_rounded),
    ],
  ),
  HabitGoal(
    title: 'Family & friends',
    subtitle: 'Stay close to your people.',
    icon: Icons.groups_rounded,
    color: Color(0xFFE091B8),
    habits: [
      HabitIdea(title: 'Message someone first', icon: Icons.send_rounded),
      HabitIdea(title: 'Call home', icon: Icons.call_rounded),
      HabitIdea(
        title: 'No phone while eating',
        icon: Icons.phonelink_off_rounded,
      ),
      HabitIdea(title: 'Meet a friend', icon: Icons.event_rounded),
      HabitIdea(
        title: 'Say thank you',
        icon: Icons.volunteer_activism_rounded,
      ),
    ],
  ),
  HabitGoal(
    title: 'Tidy room',
    subtitle: '10 minutes beats a full Sunday.',
    icon: Icons.cottage_rounded,
    color: Color(0xFFFFAB91),
    habits: [
      HabitIdea(title: 'Make the bed', icon: Icons.bed_rounded),
      HabitIdea(title: '10-minute clean-up', icon: Icons.cleaning_services_rounded),
      HabitIdea(title: 'Wash your dishes', icon: Icons.water_drop_rounded),
      HabitIdea(title: 'Throw one thing away', icon: Icons.delete_outline_rounded),
      HabitIdea(title: 'Do the laundry', icon: Icons.checkroom_rounded),
    ],
  ),
  HabitGoal(
    title: 'Less phone',
    subtitle: 'Get your hours back.',
    icon: Icons.hourglass_bottom_rounded,
    color: Color(0xFFEC7FA9),
    habits: [
      HabitIdea(title: 'No phone for 1 hour', icon: Icons.hourglass_bottom_rounded),
      HabitIdea(title: 'Hide social apps', icon: Icons.apps_rounded),
      HabitIdea(
        title: 'Under 2 hours screen time',
        icon: Icons.hourglass_empty_rounded,
      ),
      HabitIdea(title: 'One evening offline', icon: Icons.wifi_off_rounded),
      HabitIdea(title: 'Read instead at night', icon: Icons.menu_book_rounded),
    ],
  ),
];
