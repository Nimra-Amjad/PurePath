import 'package:flutter/material.dart';

abstract class Validators {
  Validators._();

  static FormFieldValidator<String>? getValidator(TextInputType? keyboardType) {
    return switch (keyboardType) {
      TextInputType.emailAddress => Validators.email,
      TextInputType.number => Validators.number,
      _ => null,
    };
  }

  static String? required(String? input) {
    if (input?.trim().isEmpty ?? true) {
      return 'Required';
    }

    return null;
  }

  static String? requiredTyped<T>(T? input) {
    if (input == null) {
      return 'Required';
    }

    return null;
  }

  static String? email(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? password(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Please enter your password';
    }

    final length = password.trim().length;
    if (length < 8) {
      return 'Your password must be at least 8 characters long';
    }
    if (length > 72) {
      return 'Your password is too long';
    }

    return null;
  }

  static String? userName(String? input, {bool isCheckDigitsOnly = false}) {
    if (input == null || input.isEmpty) {
      return 'Please enter your name';
    }

    if (RegExp(r'^\d+$').hasMatch(input)) {
      return 'Please enter valid name';
    }

    if (input.length < 3) {
      return 'Please enter valid name';
    }

    if (input.length > 15) {
      return 'Please enter valid name';
    }

    return null;
  }

  static String? firstName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter your first name';
    }

    if (input.length < 2) {
      return 'Please enter a valid first name';
    }

    return null;
  }

  static String? lastName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter your last name';
    }

    if (input.length < 2) {
      return 'Please enter a valid last name';
    }

    return null;
  }

  static String? birthday(
    String? value,
    BirthdayField field, {
    String? month,
    String? day,
    String? year,
  }) {
    if (value == null || value.isEmpty) {
      return switch (field) {
        BirthdayField.month => 'Enter month',
        BirthdayField.day => 'Enter date',
        BirthdayField.year => 'Enter year',
      };
    }

    final number = int.tryParse(value);
    if (number == null) return 'Invalid number';

    final currentYear = DateTime.now().year;
    final minYear = currentYear - 100;
    final maxYear = currentYear - 14;

    switch (field) {
      case BirthdayField.month:
        if (number < 1 || number > 12) {
          return '1-12';
        }
        break;
      case BirthdayField.day:
        final monthNum = int.tryParse(month ?? '');
        final yearNum = int.tryParse(year ?? '');

        if (monthNum != null && yearNum != null) {
          final daysInMonth = DateValidator().getDaysInMonth(yearNum, monthNum);
          if (number < 1 || number > daysInMonth) {
            return '1-$daysInMonth';
          }
        } else if (number < 1 || number > 31) {
          return '1-31';
        }
        break;
      case BirthdayField.year:
        if (number < minYear || number > maxYear) {
          return '$minYear-$maxYear';
        }
        break;
    }

    // Validate complete date if all fields are filled
    if (month != null && day != null && year != null) {
      final m = int.tryParse(month);
      final d = int.tryParse(day);
      final y = int.tryParse(year);

      if (m != null && d != null && y != null) {
        if (!DateValidator().isValidDate(d, m, y)) {
          return 'Invalid date';
        }
      }
    }

    return null;
  }

  static String? height({
    String? input,
    required bool isFeet,
    required bool isInches,
  }) {
    if (input?.trim().isEmpty ?? true) {
      return isFeet
          ? isInches
                ? 'Enter inches'
                : 'Enter feet'
          : 'Enter cm';
    }

    final value = double.tryParse(input!);
    if (value == null) return 'Invalid number';

    if (isFeet) {
      if (isInches) {
        return (value < HeightConstants.minInches ||
                value > HeightConstants.maxInches)
            ? '${HeightConstants.minInches.toInt()}-${HeightConstants.maxInches.toInt()} in'
            : null;
      }
      return (value < HeightConstants.minFeet ||
              value > HeightConstants.maxFeet)
          ? '${HeightConstants.minFeet.toInt()}-${HeightConstants.maxFeet.toInt()} ft'
          : null;
    }

    return (value < HeightConstants.minCm || value > HeightConstants.maxCm)
        ? '${HeightConstants.minCm}-${HeightConstants.maxCm} cm'
        : null;
  }

  static String? weight({String? input, required bool isLbs}) {
    if (input?.trim().isEmpty ?? true) {
      return isLbs ? 'Enter lbs' : 'Enter kg';
    }

    final value = double.tryParse(input!);
    if (value == null) return 'Invalid number';

    if (isLbs) {
      return (value < WeightConstants.minLbs || value > WeightConstants.maxLbs)
          ? '${WeightConstants.minLbs.toInt()}-${WeightConstants.maxLbs.toInt()} lbs'
          : null;
    }

    return (value < WeightConstants.minKg || value > WeightConstants.maxKg)
        ? '${WeightConstants.minKg}-${WeightConstants.maxKg} kg'
        : null;
  }

  static String? title(String? input) {
    if (input == null || input.isEmpty) {
      return 'Please enter your post title';
    }

    return null;
  }

  static String? emptyMsg(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }

    return null;
  }

  static String? number(String? input) {
    if (input == null || input.isEmpty) {
      return 'Required';
    }

    final number = num.tryParse(input);
    if (number == null) {
      return 'Enter valid number';
    }

    if (number <= 0) {
      return 'Invalid number';
    }

    return null;
  }

  static String? positiveInteger(String? input) {
    if (input == null) {
      return 'Required';
    }

    final integer = int.tryParse(input);
    if (integer == null || integer <= 0) {
      return 'Enter positive integer';
    }

    return null;
  }

  String? numberInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    return null;
  }
}

class HeightConstants {
  static const double minFeet = 3;
  static const double maxFeet = 10;
  static const double minInches = 0;
  static const double maxInches = 11;
  static const double minCm = 91; // 1ft in cm
  static const double maxCm = 332; // 12ft in cm
}

class WeightConstants {
  static const double minLbs = 66;
  static const double maxLbs = 440;
  static const double minKg = 36;
  static const double maxKg = 199;
}

class DateValidator {
  bool isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;

    try {
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

enum BirthdayField { month, day, year }
