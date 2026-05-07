import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create Post page
//
// Submits a new post via [CommunityBloc] which writes to Firestore.
// On submit, we wait for the bloc to finish persisting and then pop.
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  final _contentFocus = FocusNode();

  bool _showImageField = false;
  bool _isSubmitting = false;

  bool get _canPost =>
      !_isSubmitting && _contentController.text.trim().isNotEmpty;

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

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    final imageUrl = _imageController.text.trim();

    final bloc = context.read<CommunityBloc>();
    final user = bloc.currentUser;
    if (user == null || user.uid.isEmpty) {
      AppSnackBar.error(context, 'Please sign in to post.');
      return;
    }

    setState(() => _isSubmitting = true);

    bloc.add(CommunityPostCreated(
      content: content,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    ));

    if (!mounted) return;
    AppSnackBar.success(context, 'Post published!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<CommunityBloc>().currentUser;
    final fullName = user?.fullName ?? 'You';
    final initial =
        fullName.isNotEmpty ? fullName.trim()[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        surfaceTintColor: kWhiteColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: kBlackColor.withOpacityValue(0.06),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          color: kBlackColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Post',
          style: AppTextStyles.bold.copyWith(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: _canPost ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                disabledBackgroundColor: purple.withOpacityValue(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: kWhiteColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Post',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 14,
                        color: kWhiteColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Author row ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: purple.withOpacityValue(0.12),
                  child: Text(
                    initial,
                    style: AppTextStyles.bold.copyWith(
                      fontSize: 18,
                      color: purple,
                    ),
                  ),
                ),
                Space.horizontal(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTextStyles.semiBold.copyWith(fontSize: 15),
                      ),
                      Space.vertical(2),
                      Row(
                        children: [
                          _AudiencePill(
                            icon: Icons.public_rounded,
                            label: 'Community',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Space.vertical(16),

            // ── Content field ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kBlackColor.withOpacityValue(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                maxLines: null,
                minLines: 6,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.normal.copyWith(
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      "What's on your mind? Share a habit win, tip, or motivation… 💪",
                  hintStyle: AppTextStyles.normal.copyWith(
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Space.vertical(12),

            // ── Image URL field (collapsible) ───────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _showImageField
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kBlackColor.withOpacityValue(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        Space.horizontal(10),
                        Expanded(
                          child: TextField(
                            controller: _imageController,
                            style:
                                AppTextStyles.normal.copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Paste image URL (optional)',
                              hintStyle: AppTextStyles.normal.copyWith(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: textSecondary,
                          onPressed: () => setState(() {
                            _showImageField = false;
                            _imageController.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                  Space.vertical(12),
                ],
              ),
            ),

            // ── Toolbar ─────────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kBlackColor.withOpacityValue(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.image_rounded,
                    label: 'Image',
                    onTap: () => setState(() => _showImageField = true),
                    active: _showImageField,
                  ),
                  _ToolbarButton(
                    icon: Icons.emoji_emotions_rounded,
                    label: 'Emoji',
                    onTap: () {
                      _contentController.text += ' 🔥';
                      _contentController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                            offset: _contentController.text.length),
                      );
                    },
                  ),
                  _ToolbarButton(
                    icon: Icons.format_bold_rounded,
                    label: 'Bold',
                    onTap: () {
                      final sel = _contentController.selection;
                      if (sel.isCollapsed) return;
                      final selected = _contentController.text
                          .substring(sel.start, sel.end);
                      final newText = _contentController.text
                          .replaceRange(sel.start, sel.end, '**$selected**');
                      _contentController.text = newText;
                    },
                  ),
                ],
              ),
            ),

            Space.vertical(24),

            // ── Tips card ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightPurple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  Space.horizontal(10),
                  Expanded(
                    child: Text(
                      'Share your habit wins, daily streaks, or tips that helped you stay consistent. '
                      'Your story could inspire someone today!',
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audience pill
// ─────────────────────────────────────────────────────────────────────────────

class _AudiencePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AudiencePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: purple.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: purple),
          Space.horizontal(4),
          Text(
            label,
            style: AppTextStyles.semiBold.copyWith(
              fontSize: 11,
              color: purple,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? purple : textSecondary,
            ),
            Space.horizontal(6),
            Text(
              label,
              style: AppTextStyles.normal.copyWith(
                fontSize: 13,
                color: active ? purple : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
