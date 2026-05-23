import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/sheet_handle_bar.dart';
import 'package:purepath/core/widgets/space.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppBottomSheet
//
// A reusable styled bottom sheet used across the whole app.
//
// ── Quick usage ──────────────────────────────────────────────────────────────
//
//   // Show
//   AppBottomSheet.show(
//     context,
//     body: MyWidget(),
//   );
//
//   // Show and await a result
//   final result = await AppBottomSheet.show<String>(
//     context,
//     body: MyWidget(),
//   );
//
//   // Dismiss programmatically from inside the sheet
//   AppBottomSheet.hide(context);
//
// ── Parameters ────────────────────────────────────────────────────────────────
//
//   body              — Required. The content widget placed inside the sheet.
//   showSheetHandler  — Whether to show the grey drag handle at the top.
//                       Defaults to true.
//   isDismissible     — Whether tapping outside dismisses the sheet.
//                       Defaults to true.
//   enableDrag        — Whether the sheet can be dragged to dismiss.
//                       Defaults to true.
//   enableScrollView  — Wraps body in a SingleChildScrollView when true
//                       (default). Pass false for content that manages its own
//                       scrolling (e.g. a ListView inside Expanded).
//   backgroundColor   — Sheet background colour. Defaults to white.
//   borderRadius      — Top-corner radius. Defaults to 24.
//   scrollController  — Optional ScrollController forwarded to the inner
//                       SingleChildScrollView.
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.body,
    this.showSheetHandler = true,
    this.backgroundColor = kScaffoldColor,
    this.borderRadius = 24,
    this.enableScrollView = true,
    this.scrollController,
  });

  final Widget body;
  final bool showSheetHandler;
  final Color backgroundColor;
  final double borderRadius;
  final bool enableScrollView;
  final ScrollController? scrollController;

  // ── Static helpers ─────────────────────────────────────────────────────────

  /// Shows the bottom sheet and returns a result of type [T] when dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget body,
    bool showSheetHandler = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool enableScrollView = true,
    Color backgroundColor = kScaffoldColor,
    double borderRadius = 24,
    ScrollController? scrollController,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      scrollControlDisabledMaxHeightRatio: 0.85,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: true,
      builder: (ctx) => Padding(
        // Lifts the sheet above the keyboard when it appears
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AppBottomSheet(
          body: body,
          showSheetHandler: showSheetHandler,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          enableScrollView: enableScrollView,
          scrollController: scrollController,
        ),
      ),
    );
  }

  /// Dismisses the currently shown bottom sheet.
  static void hide(BuildContext context) => context.pop();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSheetHandler) ...[const SheetHandleBar(), Space.vertical(20)],
          if (enableScrollView)
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: body,
              ),
            )
          else
            Expanded(child: body),
        ],
      ),
    );
  }
}
