import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/planner/models/planner_task.dart';
import 'package:purepath/features/planner/widgets/planner_hour_label.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Timeline slot
//
// One hourly row of the planner timeline: a time label + an add button on the
// left, and the tasks scheduled in that hour stacked on the right. Pure UI —
// all interaction is delegated up through callbacks.
// ─────────────────────────────────────────────────────────────────────────────

class TimelineSlot extends StatelessWidget {
  const TimelineSlot({
    super.key,
    required this.hour,
    required this.tasks,
    required this.onAdd,
    required this.onTaskMove,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskToggle,
  });

  /// The slot this row represents (0 = 12 AM … 23 = 11 PM).
  final int hour;

  /// Tasks scheduled in this hour (already filtered by the page).
  final List<PlannerTask> tasks;

  final VoidCallback onAdd;
  final void Function(PlannerTask task) onTaskMove;
  final void Function(PlannerTask task) onTaskEdit;
  final void Function(PlannerTask task) onTaskDelete;
  final void Function(PlannerTask task) onTaskToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time label ──────────────────────────────────────────────────
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                plannerHourLabel(hour),
                style: AppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: kLightGreyColor,
                ),
              ),
            ),
          ),
          Space.horizontal(10),

          // ── Add button ──────────────────────────────────────────────────
          _AddButton(onTap: onAdd),
          Space.horizontal(12),

          // ── Tasks for this hour ─────────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                // Keeps the row height stable when a slot is empty so the
                // add buttons line up down the whole timeline.
                ? const SizedBox(height: 40)
                : Column(
                    children: [
                      for (final task in tasks) ...[
                        _TaskCard(
                          task: task,
                          onToggle: () => onTaskToggle(task),
                          onMove: () => onTaskMove(task),
                          onEdit: () => onTaskEdit(task),
                          onDelete: () => onTaskDelete(task),
                        ),
                        if (task != tasks.last) Space.vertical(8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add button — the "+" circle that opens the add-task sheet for this hour.
// ─────────────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kContainerColor,
          shape: BoxShape.circle,
          border: Border.all(color: kLightGreyColor.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.add_rounded, size: 20, color: kLightGreyColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task card — one scheduled task with a check-off toggle. Tapping the card
// opens the edit sheet; tapping the circle toggles done.
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerTask task;
  final VoidCallback onToggle;
  final VoidCallback onMove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    // The card body is not tappable — Edit/View/Delete all live in the ⋮ menu.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? kPrimaryGreenColor.withValues(alpha: 0.5)
                : kLightGreyColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Check toggle (with completion burst) ────────────────────
            _TaskCheck(done: done, onToggle: onToggle),
            Space.horizontal(10),

            // ── Title + note ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: done ? kLightGreyColor : kWhiteColor,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: kLightGreyColor,
                    ),
                  ),
                  if (task.note.isNotEmpty) ...[
                    Space.vertical(2),
                    Text(
                      task.note,
                      style: AppTextStyles.normal.copyWith(
                        fontSize: 12,
                        color: kLightGreyColor,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: kLightGreyColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Overflow menu (view · edit · delete) ────────────────────
            Space.horizontal(6),
            _TaskMenuButton(
              onMove: onMove,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task menu button
//
// The trailing "⋮" on a task card. Tapping it pops a small floating menu with
// View / Edit / Delete, anchored to the button via a [LayerLink] so it tracks
// the card on scroll. The menu animates in — the card springs up from the
// corner (scale + fade) and the rows stagger downward — and reverses out on
// dismiss. A full-screen translucent barrier catches the outside tap.
// ─────────────────────────────────────────────────────────────────────────────

class _TaskMenuButton extends StatefulWidget {
  const _TaskMenuButton({
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onMove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_TaskMenuButton> createState() => _TaskMenuButtonState();
}

class _TaskMenuButtonState extends State<_TaskMenuButton>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  late final AnimationController _controller;
  OverlayEntry? _entry;

  static const double _menuWidth = 210;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    super.dispose();
  }

  bool get _isOpen => _entry != null;

  void _open() {
    if (_isOpen) return;
    HapticFeedback.selectionClick();
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    _controller.forward(from: 0);
  }

  Future<void> _close() async {
    if (!_isOpen) return;
    try {
      await _controller.reverse();
    } finally {
      _entry?.remove();
      _entry = null;
    }
  }

  /// Runs the chosen action after the close animation settles, so the menu
  /// doesn't linger over a sheet/dialog it just opened.
  Future<void> _select(VoidCallback action) async {
    await _close();
    if (!mounted) return;
    action();
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        // Outside-tap barrier.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        // The menu, pinned to the button's bottom-right corner.
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          // Drop below the card's bottom border so the menu never overlaps it,
          // and nudge it toward the right edge to tighten the right gap.
          offset: const Offset(12, 16),
          child: Align(
            alignment: Alignment.topRight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final v = _controller.value.clamp(0.0, 1.0);
                final scale = 0.82 + 0.18 * Curves.easeOutBack.transform(v);
                return Opacity(
                  opacity: v,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topRight,
                    child: child,
                  ),
                );
              },
              child: _menuCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuCard() {
    return Material(
      color: kTransparentColor,
      child: Container(
        width: _menuWidth,
        decoration: BoxDecoration(
          color: kContainerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLightGreyColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: kBlackColor.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              index: 0,
              icon: Icons.drive_file_move_outline,
              label: 'Move',
              onTap: () => _select(widget.onMove),
            ),
            _divider(),
            _menuItem(
              index: 1,
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => _select(widget.onEdit),
            ),
            _divider(),
            _menuItem(
              index: 2,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: kRedColor,
              onTap: () => _select(widget.onDelete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    color: kLightGreyColor.withValues(alpha: 0.1),
  );

  /// One menu row, staggered in behind the card's own entrance so the three
  /// options cascade downward.
  Widget _menuItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = kWhiteColor,
  }) {
    final start = 0.15 + index * 0.18;
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * -8),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              Space.horizontal(12),
              Text(
                label,
                style: AppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: kLightGreyColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task check
//
// The round check toggle plus its completion celebration — the same burst the
// home habit tile plays: a radiating ring, sparkle dots shooting outward, the
// check springing in with an elastic "pop", and a light haptic tap. The
// transition is detected in [didUpdateWidget] off the real (bloc-driven) [done]
// flag, so the burst fires on a fresh completion only — never on a plain rebuild
// or when un-checking. A non-clipping [Stack] lets the burst spill past the
// 22×22 circle.
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCheck extends StatefulWidget {
  const _TaskCheck({required this.done, required this.onToggle});

  final bool done;
  final VoidCallback onToggle;

  @override
  State<_TaskCheck> createState() => _TaskCheckState();
}

class _TaskCheckState extends State<_TaskCheck>
    with SingleTickerProviderStateMixin {
  static const double _size = 22;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      // Start settled when already done, so re-selecting the day (a plain
      // rebuild) shows the check with no burst — only a fresh completion
      // animates from zero.
      value: widget.done ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _TaskCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final was = oldWidget.done;
    final now = widget.done;

    if (!was && now) {
      // Just completed → celebrate.
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0);
    } else if (was && !now) {
      // Un-completed → reset silently so the next completion animates again.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    final popScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    return GestureDetector(
      onTap: widget.onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 1),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Burst overlay (ring + sparkles) ──────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (!_controller.isAnimating) return const SizedBox.shrink();
                  return CustomPaint(
                    size: const Size(_size, _size),
                    painter: _CheckBurstPainter(progress: _controller.value),
                  );
                },
              ),

              // ── The circle itself ────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: done ? kPrimaryGreenColor : kTransparentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? kPrimaryGreenColor : kLightGreyColor,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? ScaleTransition(
                        scale: popScale,
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: kBlackColor,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Check burst painter
//
// One frame of the completion celebration: an expanding, fading ring plus six
// sparkle dots flung outward from the centre, sized for the 22×22 check circle.
// ─────────────────────────────────────────────────────────────────────────────

class _CheckBurstPainter extends CustomPainter {
  const _CheckBurstPainter({required this.progress});

  final double progress;

  static const int _sparkleCount = 6;
  static const Color _color = kPrimaryGreenColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(progress);
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    // ── Expanding ring ─────────────────────────────────────────────────────
    final ringRadius = 11 + eased * 10; // 11 → 21
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade
      ..color = _color.withValues(alpha: 0.5 * fade);
    if (ringPaint.strokeWidth > 0) {
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Sparkle dots ───────────────────────────────────────────────────────
    final dotDistance = 6 + eased * 13; // 6 → 19
    final dotRadius = 2.2 * fade;
    final dotPaint = Paint()..color = _color.withValues(alpha: fade);
    if (dotRadius > 0) {
      for (var i = 0; i < _sparkleCount; i++) {
        final angle = (2 * math.pi / _sparkleCount) * i - math.pi / 2;
        final dx = center.dx + math.cos(angle) * dotDistance;
        final dy = center.dy + math.sin(angle) * dotDistance;
        canvas.drawCircle(Offset(dx, dy), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
