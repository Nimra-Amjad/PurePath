import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class CustomErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const CustomErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: red, size: 48),
            Space.vertical(12),
            Text(
              message,
              style: AppTextStyles.normal.copyWith(color: kWhiteColor),
              textAlign: TextAlign.center,
            ),
            Space.vertical(16),
            PrimaryButton(text: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
