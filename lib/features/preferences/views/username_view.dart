import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/validators.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/preferences/widgets/top_title_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UsernameView — first onboarding step
//
// Lets the user pick a handle-style username (e.g. `nimraamjad_5`). The parent
// [PreferencesPage] owns the [formKey] so it can validate this step before
// letting the user advance, and listens to [onChanged] to capture the value.
// ─────────────────────────────────────────────────────────────────────────────

class UsernameView extends StatelessWidget {
  const UsernameView({
    super.key,
    required this.formKey,
    required this.controller,
    this.asyncError,
    this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;

  /// Server-side error to surface on the field (e.g. "already taken"),
  /// resolved by the parent after its uniqueness query. Cleared as the user
  /// edits the field.
  final String? asyncError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopTitleWidget(
            title: 'Choose a username',
            subtitle: 'This is how others will see you across PurePath.',
          ),
          Space.vertical(24),
          CustomTextField(
            controller: controller,
            hintText: 'Pick a unique username',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            // Force lowercase and permit only letters, digits and underscore
            // as the user types, so the value can never become invalid.
            inputFormatters: [
              _LowerCaseTextFormatter(),
              FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (value) {
              // Format rules first, then any pending "already taken" result.
              final formatError = Validators.username(value);
              if (formatError != null) return formatError;
              return asyncError;
            },
            onChanged: onChanged,
          ),
          Space.vertical(10),
          Text(
            'Lowercase letters, numbers and underscores. 3–20 characters.',
            style: TextStyle(color: kSecondaryGreyColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Lowercases every keystroke so typed capitals become valid handle characters.
class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
