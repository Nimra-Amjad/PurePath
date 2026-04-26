import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/widgets/post_card_widget.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Community",
                style: AppTextStyles.bold.copyWith(fontSize: 24),
              ),
              CircleAvatar(
                backgroundColor: kLightGreyColor,
                child: Text(
                  "A",
                  style: AppTextStyles.bold.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        Space.vertical(16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [PostCard(), PostCard(), PostCard(), PostCard()],
            ),
          ),
        ),
      ],
    );
  }
}
