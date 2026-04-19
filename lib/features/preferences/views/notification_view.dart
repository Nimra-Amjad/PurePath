import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final List<String> _days = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final Set<int> _selectedDayIndexes = {};

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "When would you like to be reminded?",
          style: AppTextStyles.bold.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        Space.vertical(16),
        Text(
          "Select days to remind on",
          style: AppTextStyles.normal.copyWith(fontSize: 14),
        ),
        Space.vertical(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (index) {
            final isSelected = _selectedDayIndexes.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDayIndexes.remove(index);
                  } else {
                    _selectedDayIndexes.add(index);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF6C8E6C)
                      : kLightYellowColor.withOpacityValue(0.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  _days[index],
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: isSelected ? kWhiteColor : kBlackColor,
                  ),
                ),
              ),
            );
          }),
        ),
        Space.vertical(24),
        Text(
          "Time to remind",
          style: AppTextStyles.normal.copyWith(fontSize: 14),
        ),
        Space.vertical(12),
        SizedBox(
          height: 160,
          child: CupertinoTheme(
            data: CupertinoTheme.of(context).copyWith(
              textTheme: const CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Roboto',
                  color: kBlackColor,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: false,
              initialDateTime: DateTime(
                0,
                1,
                1,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              onDateTimeChanged: (dateTime) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: dateTime.hour,
                    minute: dateTime.minute,
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
