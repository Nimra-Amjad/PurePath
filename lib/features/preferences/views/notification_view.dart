import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/top_title_widget.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  static const _benefits = <({IconData icon, String text, Color color})>[
    (
      icon: Icons.check_circle_outline_rounded,
      text: 'Daily habit nudges at your chosen time',
      color: Color(0xFF6A5AE0),
    ),
    (
      icon: Icons.add_rounded,
      text: 'Streak alerts before you lose momentum',
      color: Color(0xFF21A67A),
    ),
    (
      icon: Icons.star_rounded,
      text: 'Weekly insights delivered to you',
      color: Color(0xFFF4A220),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopTitleWidget(
          title: "Stay on track with smart reminders",
          subtitle:
              "Rituals can nudge you at the right moment — never missing a habit again.",
        ),
        Space.vertical(16),
        ..._benefits.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGreyColor.withOpacityValue(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: item.color.withOpacityValue(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  Space.horizontal(12),
                  Expanded(
                    child: Text(
                      item.text,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 14,
                        color: kBlackColor.withOpacityValue(0.84),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
