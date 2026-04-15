import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/enums/snackbar_enum.dart';
import 'package:purepath/core/extensions/color.dart';
import 'package:purepath/core/utils/utils.dart';
import 'package:purepath/core/widgets/space.dart';

class TopSnackBar extends StatefulWidget {
  final String message;
  final String icon;
  final Color iconColor;
  final VoidCallback? onReadyToRemove;

  const TopSnackBar({
    super.key,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.onReadyToRemove,
  });

  @override
  State<TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      _autoTimer = Timer(const Duration(seconds: 2), () {
        _dismiss();
      });
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissed) return;
    _isDismissed = true;

    _autoTimer?.cancel();
    _autoTimer = null;

    await _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeIn,
    );

    widget.onReadyToRemove?.call();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.icon,
                colorFilter: colorFilter(color: widget.iconColor),
              ),
              Space.horizontal(12),
              Expanded(
                child: Text(
                  widget.message,
                  style: AppTextStyles.normal.copyWith(
                    fontSize: 14,
                    color: kBlackColor,
                  ),
                ),
              ),
              Space.horizontal(8),
              GestureDetector(
                onTap: _dismiss,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: kBlackColor.withOpacityValue(0.4),
                  child: const Icon(Icons.close, color: kWhiteColor, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Private helper
void _showSnackBar(BuildContext context, String message, SnackBarType type) {
  late String icon;
  late Color color;

  switch (type) {
    case SnackBarType.success:
      icon = Assets.svgSuccessIcon;
      color = kGreenColor;
      break;
    case SnackBarType.error:
      icon = Assets.svgErrorIcon;
      color = kRedColor;
      break;
    case SnackBarType.warning:
      icon = Assets.svgWarningIcon;
      color = kOrangeColor;
      break;
  }

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TopSnackBar(
          message: message,
          icon: icon,
          iconColor: color,
          onReadyToRemove: () => entry.remove(),
        ),
      ),
    ),
  );

  overlay.insert(entry);
}

class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.success);
  }

  static void error(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.error);
  }

  static void warning(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.warning);
  }
}
