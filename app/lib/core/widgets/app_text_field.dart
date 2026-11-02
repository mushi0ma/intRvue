import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'review_mark.dart';

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
    this.leadingIcon,
    this.flagged = false,
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

  /// Өріс ішіндегі сол жақ белгіше (Figma: mail, lock, search).
  final IconData? leadingIcon;

  /// Хабарламасыз белгі: жиек — сия 1,5 (хабарлама ортақ, [FlagGroup]).
  final bool flagged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  /// Валидатор қайтарған соңғы қате — өріс жиегіндегі белгі үшін.
  String? _validatorError;

  String? _validate(String? value) {
    final error = widget.validator?.call(value);
    if (error != _validatorError) {
      // Валидатор build кезінде де шақырылады — күйді кейін жаңартамыз.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _validatorError = error);
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final flagged = widget.errorText != null || _validatorError != null;
    final ink = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: context.palette.ink, width: 1.5),
    );
    return ReviewGutter(
      flagged: flagged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs + 2),
          TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: widget.focusNode,
            validator: widget.validator == null ? null : _validate,
            errorBuilder: (context, message) => ReviewNote(message),
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
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helper,
              // Қазақша мәтіндер ұзын: бір жолға сыймаса қысқармасын.
              helperMaxLines: 4,
              errorMaxLines: 4,
              // Сервер қатесі де валидатор қатесі сияқты белгімен көрсетіледі.
              error: widget.errorText == null
                  ? null
                  : ReviewNote(widget.errorText!),
              counterText: '',
              enabledBorder: widget.flagged ? ink : null,
              prefixIcon: widget.leadingIcon == null
                  ? null
                  : Icon(
                      widget.leadingIcon,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? S.showPassword : S.hidePassword,
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden ? AppIcons.visibility : AppIcons.visibilityOff,
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : widget.suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}
