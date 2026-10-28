import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Белгісі өрістің үстінде тұратын енгізу өрісі (Figma «Field / …»).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;

  /// Өріс астындағы түсіндірме: «Кемінде 8 таңба: әріп пен сан.»
  final String? helper;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;

  /// Сервер қайтарған қате (мысалы, «Email немесе пароль қате.»).
  final String? errorText;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: context.text.labelMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          obscureText: _hidden,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          minLines: widget.minLines,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: widget.textCapitalization,
          style: context.text.bodyLarge!.copyWith(height: 1.4),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            // Қазақша мәтіндер ұзын: бір жолға сыймаса қысқармасын.
            helperMaxLines: 4,
            errorMaxLines: 4,
            helperStyle: context.text.bodyMedium!.copyWith(
              color: colors.onSurfaceVariant,
            ),
            errorText: widget.errorText,
            errorStyle: context.text.bodyMedium!.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w500,
            ),
            counterText: '',
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? S.showPassword : S.hidePassword,
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Тізімнен таңдау өрісі (Figma «Field / Dropdown»).
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: context.text.labelMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: colors.onSurfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.field),
          dropdownColor: colors.surface,
          style: context.text.bodyLarge!.copyWith(height: 1.4),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(itemLabel(item))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
