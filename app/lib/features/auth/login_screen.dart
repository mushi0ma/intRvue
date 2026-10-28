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
import '../../data/repositories/sync_repository.dart';

/// S02 Кіру және «Кіру орындалмады» күйі.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = context.read<AuthRepository>();
    final sync = context.read<SyncRepository>();
    AuthError? error;
    var restored = false;
    try {
      error = await auth.login(_email.text, _password.text);
      // Құрылғыда аккаунт жоқ — бұлттағы көшірмеден қалпына келтіріп көреміз.
      if (error != null && !await auth.hasAccount(_email.text)) {
        restored = await sync.restore(_email.text, _password.text);
        if (restored) error = null;
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = error != null;
    });
    if (error != null) return;
    if (restored) showAppSnackBar(context, S.syncRestored);
    context.go(Routes.home);
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
          title: _failed ? S.loginErrorTitle : S.loginTitle,
          subtitle: _failed ? S.loginErrorSubtitle : S.loginSubtitle,
          headerGap: 44,
          body: [
            AppTextField(
              label: S.fieldEmail,
              controller: _email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onChanged: (_) => _clearFailure(),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldPassword,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: Validators.loginPassword,
              errorText: _failed ? S.loginWrongCredentials : null,
              onChanged: (_) => _clearFailure(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            AppLink(
              label: _failed ? S.resetPasswordLink : S.forgotPassword,
              onPressed: () => context.push(Routes.forgotPassword),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _failed ? S.loginRetry : S.loginAction,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 32),
            Text(S.noAccount, style: context.text.bodyLarge),
            const SizedBox(height: 16),
            AppButton.tonal(
              label: S.registerAction,
              onPressed: () => context.pushReplacement(Routes.register),
            ),
            const SizedBox(height: 40),
            Text(
              S.dataPrivate,
              style: context.text.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.demoHint,
              style: context.text.bodySmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFailure() {
    if (_failed) setState(() => _failed = false);
  }
}
