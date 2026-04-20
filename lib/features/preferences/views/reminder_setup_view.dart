import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/top_title_widget.dart';

class ReminderSetupView extends StatefulWidget {
  const ReminderSetupView({super.key});

  @override
  State<ReminderSetupView> createState() => _ReminderSetupViewState();
}

class _ReminderSetupViewState extends State<ReminderSetupView> {
  final List<String> _days = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final Set<int> _selectedDayIndexes = {};
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopTitleWidget(
          title: "When should we remind you?",
          subtitle:
              "Pick the days and time. You can change this anytime in settings.",
        ),
        Space.vertical(16),
        Text(
          "Remind me on",
          style: AppTextStyles.medium.copyWith(fontSize: 15),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryColor : kWhiteColor,
                  border: Border.all(
                    color: isSelected
                        ? kPrimaryColor
                        : kGreyColor.withOpacityValue(0.65),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _days[index],
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 14,
                    color: isSelected ? kWhiteColor : kBlackColor,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_selectedDayIndexes.isNotEmpty) ...[
          Space.vertical(24),
          Text(
            "Time to remind",
            style: AppTextStyles.medium.copyWith(fontSize: 15),
          ),
          Space.vertical(12),
          Container(
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kGreyColor.withOpacityValue(0.5)),
            ),
            child: SizedBox(
              height: 170,
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
          ),
          Space.vertical(16),
        ],
      ],
    );
  }
}
