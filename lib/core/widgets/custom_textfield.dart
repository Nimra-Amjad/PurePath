import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/extensions/color.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final int? maxLines;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.textCapitalization,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      maxLines: maxLines,
      readOnly: readOnly,

      onTap: onTap,
      cursorColor: kSecondaryGreyColor,
      inputFormatters: inputFormatters ?? [],
      style: TextStyle(color: kLightGreyColor.withOpacityValue(0.8)),
      decoration: InputDecoration(
        fillColor: kContainerColorContrast,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: kLightGreyColor.withOpacityValue(0.4)),
        labelText: labelText,
        prefixIcon: prefix != null
            ? Padding(padding: const EdgeInsets.all(10.0), child: prefix)
            : null,
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.all(10.0), child: suffix)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kSecondaryGreyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kSecondaryGreyColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kSecondaryGreyColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kSecondaryGreyColor),
        ),
      ),
    );
  }
}
