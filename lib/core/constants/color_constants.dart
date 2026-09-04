import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF041F5D);
const kGreyColor = Color(0xffBDBDBD);
const kDarkGreyColor = Color(0xFF1E1E1E);
const kLightYellowColor = Color(0xFFF5E0BE);
const kGreenColor = Color(0xFF4CAF50);
const kPinkColor = Color(0xFFD4608A);
const kOrangeColor = Color(0xFFFF9800);
const kMainTealColor = Color(0xFF00d49a);
const kDarkTealColor = Color(0xFF00b87a);
const kTealGlowColor = Color.fromRGBO(0, 212, 154, 0.1);
const kLightPurpleColor = Color(0xFFc5b8ff);
const kMutedPurple = Color(0xFF9b7fff);
const kLightBackground = Color.fromARGB(255, 191, 191, 234);

const purple = Color(0xFF6C4DFF);
const lightPurple = Color(0xFFF3F0FF);
const green = Color(0xFF22C55E);
const blue = Color(0xFF3B82F6);
const orange = Color(0xFFF97316);
const red = Color(0xFFEF4444);

const textPrimary = Color(0xFF111827);
const textSecondary = Color(0xFF6B7280);
const border = Color(0xFFE5E7EB);
const bg = Color(0xFFF9FAFB);

///-------------------New Color---------------------
const kScaffoldColor = Color(0xFF111111);
const kWhiteColor = Color(0xFFFFFFFF);
const kBlackColor = Color(0xFF000000);
const kPrimaryGreenColor = Color(0xFFCFE36E);
const kDarkGreenColor = Color(0xFF679436);
const kLightGreenColor = Color(0xFFbce784);
const kPrimaryGreyColor = Color(0xFF495057);
const kSecondaryGreyColor = Color(0xFF6c757d);
const kLightGreyColor = Color(0xFFadb5bd);
const kContainerColor = Color(0xff2c2c2e);
const kContainerColorContrast = Color(0xff222223);
const kRedColor = Color(0xFFef233c);
const kTransparentColor = Colors.transparent;
const kPurpleColor = Color(0xFF6C4DFF);

// ── Habit defaults ───────────────────────────────────────────────────────────
// The default accent color, used whenever the user hasn't picked a custom color
// for a habit.
const kHabitAccentColor = kPrimaryGreenColor;

// ── Habit color palette ──────────────────────────────────────────────────────
// The soft, light colors the user can choose from when creating or editing a
// habit. The first entry is the default (used when the user leaves the color
// unset). Each habit stores its chosen color as an ARGB int (Color.toARGB32()).
const kHabitColorPalette = <Color>[
  kPrimaryGreenColor, // Lime — default accent
  Color(0xFFF7A8C4), // Blush
  Color(0xFFFFB39B), // Peach
  Color(0xFFFFCF9E), // Apricot
  Color(0xFFFCE38A), // Butter
  Color(0xFFC5E1A5), // Sage
  Color(0xFFA8E6CF), // Mint
  Color(0xFFA0DDE6), // Aqua
  Color(0xFFAEC6F7), // Sky
  Color(0xFFB3B0F0), // Periwinkle
  Color(0xFFCDB4F6), // Lavender
  Color(0xFFE3B7EC), // Lilac
];
