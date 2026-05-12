import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/app_bottom_sheet.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';

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
  const CreatePostSheet._();

  /// Opens the sheet. Returns `true` if the user successfully published a
  /// post, `null` if they dismissed without posting.
  static Future<bool?> show(BuildContext context) {
    return AppBottomSheet.show<bool>(
      context,
      body: const CreatePostSheet._(),
      enableScrollView: false,
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  final _contentFocus = FocusNode();

  static const int _maxLength = 500;

  bool _showImageField = false;
  bool _isSubmitting = false;

  bool get _canPost =>
      !_isSubmitting && _contentController.text.trim().isNotEmpty;

  int get _charCount => _contentController.text.characters.length;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _contentFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageController.dispose();
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

    final imageUrl = _imageController.text.trim();
    bloc.add(CommunityPostCreated(
      content: content,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    ));

    if (!mounted) return;
    AppSnackBar.success(context, 'Post published!');
    Navigator.of(context).pop(true);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.read<CommunityBloc>().currentUser;
    final fullName = (user?.fullName ?? '').trim();
    final displayName = fullName.isEmpty ? 'You' : fullName;
    final initial =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    // Cap the sheet at 75% of screen height so the user keeps a sense of
    // place — they should still see a hint of the feed behind.
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              displayName: displayName,
              initial: initial,
              isSubmitting: _isSubmitting,
              canPost: _canPost,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
            ),
            Space.vertical(18),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ComposerCard(
                      controller: _contentController,
                      focusNode: _contentFocus,
                      maxLength: _maxLength,
                      charCount: _charCount,
                    ),
                    if (_showImageField) ...[
                      Space.vertical(12),
                      _ImageField(
                        controller: _imageController,
                        onClose: () => setState(() {
                          _showImageField = false;
                          _imageController.clear();
                        }),
                      ),
                    ],
                    Space.vertical(16),
                    _AttachImageChip(
                      isActive: _showImageField,
                      onTap: () =>
                          setState(() => _showImageField = !_showImageField),
                    ),
                    Space.vertical(16),
                    const _InspireBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  final bool canPost;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _SheetHeader({
    required this.displayName,
    required this.initial,
    required this.isSubmitting,
    required this.canPost,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [purple, purple.withOpacityValue(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: kWhiteColor,
                child: Text(
                  initial,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 16,
                    color: purple,
                  ),
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
                  color: purple,
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
                style: AppTextStyles.semiBold.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Space.vertical(1),
              Text(
                'Posting to Community',
                style: AppTextStyles.normal.copyWith(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          style: TextButton.styleFrom(
            foregroundColor: textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        Space.horizontal(4),
        FilledButton(
          onPressed: canPost ? onSubmit : null,
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            disabledBackgroundColor: purple.withOpacityValue(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: kWhiteColor,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Share',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 13,
                        color: kWhiteColor,
                      ),
                    ),
                    Space.horizontal(4),
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: kWhiteColor,
                    ),
                  ],
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focusNode.hasFocus
              ? purple.withOpacityValue(0.4)
              : kBlackColor.withOpacityValue(0.05),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxLength),
            ],
            style: AppTextStyles.normal.copyWith(
              fontSize: 15,
              height: 1.5,
              color: kBlackColor,
            ),
            decoration: InputDecoration(
              hintText:
                  "What's the win today? Share a streak, a small habit, or what's keeping you going.",
              hintStyle: AppTextStyles.normal.copyWith(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image URL field — collapsible
// ─────────────────────────────────────────────────────────────────────────────

class _ImageField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClose;

  const _ImageField({required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlackColor.withOpacityValue(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: textSecondary),
          Space.horizontal(10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              style: AppTextStyles.normal.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste an image URL',
                hintStyle: AppTextStyles.normal.copyWith(
                  fontSize: 13,
                  color: textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: textSecondary,
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attach image chip — only attachment option, replaces the old toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _AttachImageChip extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AttachImageChip({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? purple : purple.withOpacityValue(0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? Icons.image_rounded
                  : Icons.add_photo_alternate_outlined,
              size: 16,
              color: isActive ? kWhiteColor : purple,
            ),
            Space.horizontal(6),
            Text(
              isActive ? 'Image attached' : 'Add image',
              style: AppTextStyles.semiBold.copyWith(
                fontSize: 12,
                color: isActive ? kWhiteColor : purple,
              ),
            ),
          ],
        ),
      ),
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
        gradient: LinearGradient(
          colors: [
            purple.withOpacityValue(0.10),
            purple.withOpacityValue(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
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
              boxShadow: [
                BoxShadow(
                  color: purple.withOpacityValue(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  style: AppTextStyles.semiBold.copyWith(fontSize: 13),
                ),
                Space.vertical(3),
                Text(
                  'Talk about today\'s streak, the habit you\'re proud of, or the trick that\'s working for you.',
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 11.5,
                    color: textSecondary,
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
