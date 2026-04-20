import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purepath/core/constants/app_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonColor,
    this.textColor,
    this.inactive = false,
    this.showBorder = false,
    this.borderColor = kTransparentColor,
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.isLoading = false,
    this.height = 44,
    this.prefixIcon,
    this.postfixIcon,
    this.textFontWeight = FontWeight.w500,
    this.textFontSize = 16,
    this.isSpaceBetween = false,
    this.isMainAxisSizeMin = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.prefixIconSize = 24,
    this.postfixIconSize = 24,
    this.buttonOpacity = 0.6,
  });

  final String text;
  final bool inactive;
  final Color? buttonColor;
  final Color? textColor;
  final Widget? prefixIcon;
  final Widget? postfixIcon;
  final VoidCallback onPressed;
  final bool showBorder;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final bool isLoading;
  final double height;
  final double textFontSize;
  final FontWeight textFontWeight;
  final bool isSpaceBetween;
  final bool isMainAxisSizeMin;
  final EdgeInsets padding;
  final double prefixIconSize;
  final double postfixIconSize;
  final double buttonOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Semantics(
        button: true,
        child: CupertinoButton(
          pressedOpacity: 0.4,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(borderRadius),
          color: buttonColor ?? kPrimaryColor,
          disabledColor: buttonColor != null
              ? buttonColor!.withValues(alpha: buttonOpacity)
              : kGreyColor.withOpacityValue(0.5),
          onPressed: inactive
              ? null
              : () {
                  if (isLoading) return;
                  onPressed();
                },
          minimumSize: Size(0, 0),
          child: _buildButtonContent(context),
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    return Container(
      height: height,
      width: isMainAxisSizeMin ? null : double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: borderColor, width: borderWidth)
            : const Border(),
      ),
      child: _buildTextAndIcon(context),
    );
  }

  Widget _buildTextAndIcon(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: kWhiteColor,
              strokeWidth: 1,
            ),
          )
        : Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: isSpaceBetween
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              mainAxisSize: isMainAxisSizeMin
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                if (prefixIcon != null || isSpaceBetween)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox(
                      height: prefixIconSize,
                      width: prefixIconSize,
                      child: (prefixIcon != null) ? prefixIcon! : null,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: textFontSize,
                      fontWeight: textFontWeight,
                      fontFamily: kPrimaryFontFamily,
                      color:
                          textColor ??
                          (inactive
                              ? kBlackColor.withOpacityValue(0.4)
                              : kWhiteColor),
                    ),
                  ),
                ),
                if (postfixIcon != null || isSpaceBetween)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      height: postfixIconSize,
                      width: postfixIconSize,
                      child: (postfixIcon != null) ? postfixIcon! : null,
                    ),
                  ),
              ],
            ),
          );
  }
}
