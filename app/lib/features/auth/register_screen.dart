import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/auth_repository.dart';

/// S03 Тіркелу: аты, email, пароль және құпиялылыққа келісім.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  bool _loading = false;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _emailError = null;
    });
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    final AuthError? error;
    try {
      error = await context.read<AuthRepository>().register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error == AuthError.emailTaken) {
      setState(() => _emailError = S.emailTaken);
      return;
    }
    context.go(Routes.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: _form,
      autovalidateMode: _autovalidate,
      child: AutofillGroup(
        child: AppPage(
          showBack: true,
          title: S.registerTitle,
          subtitle: S.registerSubtitle,
          body: [
            AppTextField(
              label: S.fieldName,
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              validator: Validators.name,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldEmail,
              controller: _email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldPassword,
              controller: _password,
              obscure: true,
              helper: S.passwordRule,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 16),
            FormField<bool>(
              initialValue: false,
              validator: (v) => v == true ? null : S.privacyConsentRequired,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConsentRow(
                    checked: field.value ?? false,
                    onChanged: field.didChange,
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 4),
                      child: Text(
                        field.errorText!,
                        style: context.text.bodyMedium!.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.aiConsentLater,
              style: context.text.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          actions: [
            AppButton(
              label: S.createAccount,
              loading: _loading,
              onPressed: _submit,
            ),
            AppLink(
              label: S.haveAccountLogin,
              alignment: Alignment.center,
              onPressed: () => context.pushReplacement(Routes.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: S.privacyConsent,
      excludeSemantics: true,
      onTap: () => onChanged(!checked),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Checkbox(
                    value: checked,
                    onChanged: (v) => onChanged(v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Expanded(
                child: Text(S.privacyConsent, style: context.text.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
