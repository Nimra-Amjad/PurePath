import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';
import 'package:purepath/features/community/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create Post sheet
//
// A modal bottom sheet for composing and publishing a community post.
// Replaces the previous full-screen page so composing feels lightweight
// — the feed stays visible and dismiss is just a swipe away.
//
// Composition is intentionally minimal: a content field and an optional
// image URL. No emoji shortcut or bold formatting — those felt out of
// place for short-form motivational posts.
//
// ── Usage ────────────────────────────────────────────────────────────────────
//
//   CreatePostSheet.show(context);
//
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostSheet extends StatefulWidget {
  /// When non-null, the sheet opens in edit mode and pre-fills its fields
  /// from this post.
  final PostModel? existing;

  const CreatePostSheet._({this.existing});

  /// Opens the sheet to compose a brand-new post. Returns `true` if the user
  /// successfully published, `null` if they dismissed without posting.
  static Future<bool?> show(BuildContext context) {
    return AppBottomSheet.show<bool>(context, body: const CreatePostSheet._());
  }

  /// Opens the sheet in edit mode, pre-filled from [post]. Returns `true` if
  /// the user saved their edits, `null` if they dismissed.
  static Future<bool?> showEdit(BuildContext context, PostModel post) {
    return AppBottomSheet.show<bool>(
      context,
      body: CreatePostSheet._(existing: post),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _contentController = TextEditingController();
  final _contentFocus = FocusNode();

  static const int _maxLength = 500;

  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  bool get _canPost =>
      !_isSubmitting && _contentController.text.trim().isNotEmpty;

  int get _charCount => _contentController.text.characters.length;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the existing post when editing.
    final existing = widget.existing;
    if (existing != null) {
      _contentController.text = existing.content;
    }
    // Rebuild whenever the content changes so _canPost / _charCount stay
    // in sync with what the user has typed.
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    final bloc = context.read<CommunityBloc>();
    final user = bloc.currentUser;
    if (user == null || user.uid.isEmpty) {
      AppSnackBar.error(context, 'Please sign in to post.');
      return;
    }

    setState(() => _isSubmitting = true);


    if (_isEditing) {
      bloc.add(
        CommunityPostUpdated(
          postId: widget.existing!.id,
          content: content,
          imageUrl: null,
        ),
      );
    } else {
      bloc.add(CommunityPostCreated(content: content, imageUrl: null));
    }

    if (!mounted) return;
    AppSnackBar.success(
      context,
      _isEditing ? 'Post updated!' : 'Post published!',
    );
    context.pop(true);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.read<CommunityBloc>().currentUser;
    final fullName = (user?.fullName ?? '').trim();
    final displayName = fullName.isEmpty ? 'You' : fullName;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    // Cap the sheet at 75% of screen height so the user keeps a sense of
    // place — they should still see a hint of the feed behind.
    // final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHeader(
            displayName: displayName,
            initial: initial,
            isSubmitting: _isSubmitting,
            isEditing: _isEditing,
            onCancel: () => context.pop(),
          ),
          Space.vertical(18),
          _ComposerCard(
            controller: _contentController,
            focusNode: _contentFocus,
            maxLength: _maxLength,
            charCount: _charCount,
          ),
          Space.vertical(16),
          const _InspireBanner(),
          Space.vertical(16),
          PrimaryButton(
            text: _isEditing ? 'Save Changes' : 'Create Post',
            onPressed: _submit,
            inactive: !_canPost,
            isLoading: _isSubmitting,
            height: 50,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — author chip + cancel + post button
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String displayName;
  final String initial;
  final bool isSubmitting;
  final bool isEditing;
  final VoidCallback onCancel;

  const _SheetHeader({
    required this.displayName,
    required this.initial,
    required this.isSubmitting,
    required this.isEditing,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kContainerColor,
              child: Text(
                initial,
                style: AppTextStyles.bold.copyWith(
                  fontSize: 16,
                  color: kWhiteColor,
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: kDarkGreenColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kWhiteColor, width: 2),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 8,
                  color: kWhiteColor,
                ),
              ),
            ),
          ],
        ),
        Space.horizontal(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.semiBold.copyWith(
                  fontSize: 14,
                  color: kWhiteColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Space.vertical(1),
              Text(
                isEditing ? 'Editing your post' : 'Posting to Community',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 11,
                  color: kSecondaryGreyColor,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          style: TextButton.styleFrom(
            foregroundColor: textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.medium.copyWith(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composer card — content field with character counter
// ─────────────────────────────────────────────────────────────────────────────

class _ComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final int charCount;

  const _ComposerCard({
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.charCount,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxLength - charCount;
    final isNearLimit = remaining <= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          minLines: 5,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          hintText:
              "What's the win today? Share a streak, a small habit, or what's keeping you going.",
        ),
        Space.vertical(8),
        Row(
          children: [
            const Spacer(),
            Text(
              '$charCount / $maxLength',
              style: AppTextStyles.medium.copyWith(
                fontSize: 11,
                color: isNearLimit ? red : textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspire banner — gentle nudge for what to share
// ─────────────────────────────────────────────────────────────────────────────

class _InspireBanner extends StatelessWidget {
  const _InspireBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kContainerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kWhiteColor,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 16)),
            ),
          ),
          Space.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a spark?',
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 13,
                    color: kWhiteColor,
                  ),
                ),
                Space.vertical(3),
                Text(
                  'Talk about today\'s streak, the habit you\'re proud of, or the trick that\'s working for you.',
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 11.5,
                    color: kSecondaryGreyColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
