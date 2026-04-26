import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/insights/widgets/analytics_calendar_widget.dart';
import 'package:purepath/features/insights/widgets/bar_chat_widget.dart';
import 'package:purepath/features/insights/widgets/barchart_calendar_widget.dart';
import 'package:purepath/features/insights/widgets/progress_widget.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insights",
            style: AppTextStyles.semiBold.copyWith(fontSize: 24),
          ),
          Space.vertical(20),
          BarchartCalendarWidget(),
          Space.vertical(20),
          BarChartWidget(),
          Space.vertical(30),
          AnalyticsCalendarWidget(),
          Space.vertical(30),
          ProgressWidget(title: "Meditation", progress: 0.9),
        ],
      ),
    );
  }
}
