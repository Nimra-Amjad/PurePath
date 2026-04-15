import 'package:flutter/cupertino.dart';
import 'package:purepath/core/constants/color_constants.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const _height = 1.5;
  static const _baseTextStyle = TextStyle(
    color: kBlackColor,
    height: _height,
    fontFamily: 'Roboto',
  );

  static TextStyle light = _baseTextStyle.copyWith(fontWeight: FontWeight.w300);

  static TextStyle normal = _baseTextStyle.copyWith(
    fontWeight: FontWeight.w400,
  );

  static TextStyle medium = _baseTextStyle.copyWith(
    fontWeight: FontWeight.w500,
  );

  static TextStyle semiBold = _baseTextStyle.copyWith(
    fontWeight: FontWeight.w600,
  );

  static TextStyle bold = _baseTextStyle.copyWith(fontWeight: FontWeight.w700);

  static TextStyle black = _baseTextStyle.copyWith(fontWeight: FontWeight.w900);
}
