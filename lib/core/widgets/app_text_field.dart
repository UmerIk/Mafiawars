import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_effects.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'design/app_surface.dart';

class AppTextField extends StatelessWidget {
  const AppTextField(
      {super.key,
      this.controller,
      this.labelText,
      this.hintText,
      this.errorText,
      this.prefixIcon,
      this.suffixIcon,
      this.obscureText = false,
      this.keyboardType = TextInputType.text,
      this.onChanged,
      this.enabled = true,
      this.onSubmitted,
      this.textInputAction,
      this.inputFormatters,
      this.maxLength,
      this.autofillHints,
      this.focusNode});
  final TextEditingController? controller;
  final String? labelText, hintText, errorText;
  final Widget? prefixIcon, suffixIcon;
  final bool obscureText, enabled;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (labelText != null) ...[
              Text(labelText!,
                  textAlign: TextAlign.center, style: AppTypography.uiCaption),
              const SizedBox(height: 8)
            ],
            AppSurface(
                radius: 30,
                shadows: const [],
                gradient: const LinearGradient(colors: [
                  AppColors.figmaTextFieldBg,
                  AppColors.figmaTextFieldBg
                ]),
                borderGradient: errorText == null
                    ? AppGradients.neon
                    : const LinearGradient(
                        colors: [AppColors.error, AppColors.error]),
                child: DecoratedBox(
                    decoration: const BoxDecoration(
                        gradient: AppEffects.fieldInnerShadow),
                    child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        obscureText: obscureText,
                        keyboardType: keyboardType,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: textInputAction,
                        inputFormatters: inputFormatters,
                        maxLength: maxLength,
                        autofillHints: autofillHints,
                        style: AppTypography.uiBody,
                        decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: AppTypography.uiBody
                                .copyWith(color: AppColors.figmaBlue),
                            prefixIcon: prefixIcon,
                            suffixIcon: suffixIcon,
                            counterText: '',
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: prefixIcon == null ? 12 : 20,
                                vertical: 17),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none)))),
            if (errorText != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorText!,
                      style: AppTypography.uiCaption
                          .copyWith(color: AppColors.error))),
          ]);
}
