import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reminders page
//
// Lets the user enable / disable each reminder and change its time.
// State is managed locally — connect to SharedPreferences or Firestore later.
// ─────────────────────────────────────────────────────────────────────────────

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  // Master toggle — when off, all individual reminders are also visually disabled.
  bool _allEnabled = true;

  // Each entry: label, icon, color, enabled, TimeOfDay.
  final List<_ReminderItem> _reminders = [
    _ReminderItem(
      label: 'Morning Check-in',
      subtitle: 'Start your day with your habits',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFFB300),
      isEnabled: true,
      time: const TimeOfDay(hour: 7, minute: 0),
    ),
    _ReminderItem(
      label: 'Midday Boost',
      subtitle: 'Stay on track through the afternoon',
      icon: Icons.wb_twilight_rounded,
      color: const Color(0xFFF97316),
      isEnabled: false,
      time: const TimeOfDay(hour: 13, minute: 0),
    ),
    _ReminderItem(
      label: 'Evening Review',
      subtitle: 'Reflect and mark today\'s habits done',
      icon: Icons.nights_stay_rounded,
      color: const Color(0xFF6C4DFF),
      isEnabled: true,
      time: const TimeOfDay(hour: 21, minute: 0),
    ),
    _ReminderItem(
      label: 'Hydration Reminder',
      subtitle: 'Don\'t forget your water goal',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF29B6F6),
      isEnabled: false,
      time: const TimeOfDay(hour: 11, minute: 0),
    ),
    _ReminderItem(
      label: 'Mindfulness Break',
      subtitle: 'Take a moment to breathe',
      icon: Icons.self_improvement_rounded,
      color: const Color(0xFFAB47BC),
      isEnabled: true,
      time: const TimeOfDay(hour: 12, minute: 0),
    ),
    _ReminderItem(
      label: 'Bedtime Wind-down',
      subtitle: 'Prepare for quality sleep',
      icon: Icons.bedtime_rounded,
      color: const Color(0xFF5C6BC0),
      isEnabled: false,
      time: const TimeOfDay(hour: 22, minute: 30),
    ),
  ];

  // ── Time picker ────────────────────────────────────────────────────────────

  Future<void> _pickTime(int index) async {
    if (!_allEnabled || !_reminders[index].isEnabled) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _reminders[index].time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: purple),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _reminders[index].time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        surfaceTintColor: kWhiteColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: kBlackColor.withOpacityValue(0.06),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: kBlackColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reminders',
          style: AppTextStyles.bold.copyWith(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Master toggle card ───────────────────────────────────────────
          _MasterToggleCard(
            isEnabled: _allEnabled,
            onChanged: (val) => setState(() => _allEnabled = val),
          ),
          Space.vertical(20),

          // ── Section label ────────────────────────────────────────────────
          Text(
            'SCHEDULED REMINDERS',
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 11,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          Space.vertical(10),

          // ── Individual reminders ─────────────────────────────────────────
          ...List.generate(
            _reminders.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReminderCard(
                item: _reminders[i],
                masterEnabled: _allEnabled,
                onToggle: (val) =>
                    setState(() => _reminders[i].isEnabled = val),
                onTimeTap: () => _pickTime(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master toggle card
// ─────────────────────────────────────────────────────────────────────────────

class _MasterToggleCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _MasterToggleCard({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEnabled ? lightPurple : kLightGreyColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEnabled
                  ? purple.withOpacityValue(0.15)
                  : kGreyColor.withOpacityValue(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: isEnabled ? purple : textSecondary,
              size: 20,
            ),
          ),
          Space.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Reminders',
                  style: AppTextStyles.semiBold.copyWith(fontSize: 15),
                ),
                Space.vertical(2),
                Text(
                  isEnabled
                      ? 'Reminders are active'
                      : 'All reminders are paused',
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: purple,
            activeTrackColor: lightPurple,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual reminder card
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final _ReminderItem item;
  final bool masterEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _ReminderCard({
    required this.item,
    required this.masterEnabled,
    required this.onToggle,
    required this.onTimeTap,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool get _isActive => masterEnabled && item.isEnabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: masterEnabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kBlackColor.withOpacityValue(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isActive
                    ? item.color.withOpacityValue(0.12)
                    : kLightGreyColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: _isActive ? item.color : textSecondary,
                size: 20,
              ),
            ),
            Space.horizontal(12),

            // Label + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.semiBold.copyWith(fontSize: 14),
                  ),
                  Space.vertical(2),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  Space.vertical(6),
                  // Time chip — tappable to change time
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? item.color.withOpacityValue(0.1)
                            : kLightGreyColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: _isActive ? item.color : textSecondary,
                          ),
                          Space.horizontal(4),
                          Text(
                            _formatTime(item.time),
                            style: AppTextStyles.semiBold.copyWith(
                              fontSize: 12,
                              color: _isActive ? item.color : textSecondary,
                            ),
                          ),
                          if (_isActive) ...[
                            Space.horizontal(4),
                            Icon(
                              Icons.edit_rounded,
                              size: 10,
                              color: item.color.withOpacityValue(0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Toggle
            Switch(
              value: item.isEnabled,
              onChanged: masterEnabled ? onToggle : null,
              activeThumbColor: item.color,
              activeTrackColor: item.color.withOpacityValue(0.25),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mutable reminder item (local state)
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  bool isEnabled;
  TimeOfDay time;

  _ReminderItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.time,
  });
}
