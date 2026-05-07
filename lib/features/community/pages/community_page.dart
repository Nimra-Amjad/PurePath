import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/community/bloc/community_bloc.dart';
import 'package:purepath/features/community/pages/create_post_page.dart';
import 'package:purepath/features/community/widgets/post_card_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Community page
//
// Reads the global [CommunityBloc] (registered in DI).
// Tab 0 = Feed (every post in the community)
// Tab 1 = My Posts (filtered by the current user's uid)
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        final currentUid = context.select<UserBloc, String?>(
          (b) => b.state.user?.uid,
        );
        final initial = context.select<UserBloc, String>(
          (b) {
            final name = b.state.user?.fullName ?? '';
            return name.isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
          },
        );

        return Column(
          children: [
            _Header(
              tabController: _tabController,
              onCreatePost: _openCreatePost,
              selectedIndex: _tabController.index,
              avatarInitial: initial,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FeedView(state: state, currentUid: currentUid),
                  _FeedView(
                    state: state,
                    currentUid: currentUid,
                    onlyMine: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed view — handles loading / error / empty / loaded states
// ─────────────────────────────────────────────────────────────────────────────

class _FeedView extends StatelessWidget {
  final CommunityState state;
  final String? currentUid;
  final bool onlyMine;

  const _FeedView({
    required this.state,
    required this.currentUid,
    this.onlyMine = false,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == CommunityStatus.loading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: purple),
      );
    }

    if (state.status == CommunityStatus.error && state.posts.isEmpty) {
      return _ErrorView(
        message: state.errorMessage ?? 'Could not load posts.',
        onRetry: () =>
            context.read<CommunityBloc>().add(CommunityRefreshRequested()),
      );
    }

    final posts =
        onlyMine ? state.myPosts(currentUid) : state.posts;

    if (posts.isEmpty) {
      return _EmptyFeed(
        label: onlyMine ? "You haven't posted yet" : 'No posts yet',
      );
    }

    return RefreshIndicator(
      color: purple,
      onRefresh: () async {
        context.read<CommunityBloc>().add(CommunityRefreshRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: posts.length,
        separatorBuilder: (_, __) => Space.vertical(12),
        itemBuilder: (_, i) => PostCard(
          post: posts[i],
          currentUid: currentUid,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — title row + custom animated pill selector
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onCreatePost;
  final int selectedIndex;
  final String avatarInitial;

  const _Header({
    required this.tabController,
    required this.onCreatePost,
    required this.selectedIndex,
    required this.avatarInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kWhiteColor,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Community',
                  style: AppTextStyles.bold.copyWith(fontSize: 24),
                ),
              ),
              // Compose button
              GestureDetector(
                onTap: onCreatePost,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: purple.withOpacityValue(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: purple,
                  ),
                ),
              ),
              Space.horizontal(10),
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: purple.withOpacityValue(0.12),
                child: Text(
                  avatarInitial,
                  style: AppTextStyles.bold.copyWith(
                    fontSize: 16,
                    color: purple,
                  ),
                ),
              ),
            ],
          ),
          Space.vertical(16),

          // ── Animated pill tab selector ───────────────────────────────────
          _PillTabSelector(
            selectedIndex: selectedIndex,
            tabs: const [
              (Icons.newspaper_rounded, 'Feed'),
              (Icons.person_rounded, 'My Posts'),
            ],
            onTabChanged: (i) => tabController.animateTo(i),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated pill tab selector
// ─────────────────────────────────────────────────────────────────────────────

class _PillTabSelector extends StatefulWidget {
  final int selectedIndex;
  final List<(IconData, String)> tabs;
  final ValueChanged<int> onTabChanged;

  const _PillTabSelector({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  State<_PillTabSelector> createState() => _PillTabSelectorState();
}

class _PillTabSelectorState extends State<_PillTabSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  int _lastTapped = 0;

  @override
  void initState() {
    super.initState();
    _lastTapped = widget.selectedIndex;
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.94,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.94,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == widget.selectedIndex) return;
    setState(() => _lastTapped = index);
    _bounceCtrl.forward(from: 0);
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (i) {
          final (icon, label) = widget.tabs[i];
          final isSelected = widget.selectedIndex == i;
          final isBouncing = _lastTapped == i;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, child) {
                  final scale = (isSelected && isBouncing)
                      ? _bounceAnim.value
                      : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  curve: Curves.easeInOut,
                  // selected fills full area; unselected shrinks slightly
                  margin: isSelected
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected ? purple : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: purple.withOpacityValue(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          icon,
                          key: ValueKey('$i-$isSelected'),
                          size: 17,
                          color: isSelected ? kWhiteColor : textSecondary,
                        ),
                      ),
                      Space.horizontal(7),
                      // Animated text
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: isSelected
                            ? AppTextStyles.semiBold.copyWith(
                                fontSize: 13,
                                color: kWhiteColor,
                              )
                            : AppTextStyles.normal.copyWith(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / error placeholders
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String label;
  const _EmptyFeed({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          Space.vertical(14),
          Text(label, style: AppTextStyles.semiBold.copyWith(fontSize: 16)),
          Space.vertical(6),
          Text(
            'Posts from the community\nwill appear here.',
            style: AppTextStyles.normal.copyWith(
              fontSize: 13,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: red, size: 44),
            Space.vertical(12),
            Text(
              message,
              style: AppTextStyles.normal.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            Space.vertical(16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: kWhiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
