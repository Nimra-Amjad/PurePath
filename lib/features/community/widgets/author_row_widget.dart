import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/models/post_model.dart';
import 'package:purepath/features/community/widgets/post_card_widget.dart';

class AuthorRowWidget extends StatelessWidget {
  final PostModel post;
  final bool isOwn;
  const AuthorRowWidget({super.key, required this.post, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final authorColor = post.authorColor;
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: authorColor.withOpacityValue(0.15),
          child: Text(
            post.authorInitial,
            style: AppTextStyles.bold.copyWith(
              fontSize: 15,
              color: authorColor,
            ),
          ),
        ),
        Space.horizontal(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.authorName,
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 14,
                        color: kWhiteColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwn) ...[Space.horizontal(6), youBadgeWidget()],
                ],
              ),
              Space.vertical(1),
              Row(
                children: [
                  if (post.authorUsername != null &&
                      post.authorUsername!.isNotEmpty) ...[
                    Flexible(
                      child: Text(
                        '@${post.authorUsername}',
                        style: AppTextStyles.normal.copyWith(
                          fontSize: 12,
                          color: kPrimaryGreenColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: kLightGreyColor,
                      ),
                    ),
                  ],
                  Text(
                    post.timeAgo,
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 12,
                      color: kLightGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Owner → edit / delete. Everyone else → hide post / block author.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => isOwn
              ? PostActionsSheet.show(context, post)
              : PostViewerActionsSheet.show(context, post),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: kSecondaryGreyColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget youBadgeWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kDarkGreenColor.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'You',
        style: AppTextStyles.semiBold.copyWith(
          fontSize: 10,
          color: kDarkGreenColor,
        ),
      ),
    );
  }
}
