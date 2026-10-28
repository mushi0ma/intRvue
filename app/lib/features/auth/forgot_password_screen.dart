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

/// S04 Парольді қалпына келтіру: email енгізу.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    Uri? link;
    try {
      link = await context.read<AuthRepository>().requestPasswordReset(
        _email.text,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    context.pushReplacement(
      Uri(
        path: Routes.resetSent,
        queryParameters: {
          'email': _email.text.trim(),
          'token': ?link?.queryParameters['token'],
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodyLarge!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Form(
      key: _form,
      autovalidateMode: _autovalidate,
      child: AppPage(
        showBack: true,
        title: S.resetTitle,
        body: [
          const SizedBox(height: 4),
          Text(S.resetSubtitle, style: muted),
          const SizedBox(height: 40),
          AppTextField(
            label: S.fieldEmail,
            controller: _email,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 48),
          AppButton(label: S.resetSend, loading: _loading, onPressed: _submit),
          const SectionDivider(vertical: 42),
          InfoSection(title: S.resetNoEmailTitle, body: S.resetNoEmailBody),
        ],
        actions: [
          AppLink(
            label: S.backToLogin,
            alignment: Alignment.center,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.login),
          ),
        ],
      ),
    );
  }
}

/// S04 күйі: «Хат жіберілді».
class ResetSentScreen extends StatefulWidget {
  const ResetSentScreen({super.key, required this.email, this.token});

  final String email;

  /// Пошта сервері жоқ: демо режимінде сілтеме экранда ашылады.
  final String? token;

  @override
  State<ResetSentScreen> createState() => _ResetSentScreenState();
}

class _ResetSentScreenState extends State<ResetSentScreen> {
  late String? _token = widget.token;

  Future<void> _resend() async {
    try {
      final link = await context.read<AuthRepository>().requestPasswordReset(
        widget.email,
      );
      if (!mounted) return;
      setState(() => _token = link?.queryParameters['token'] ?? _token);
      showAppSnackBar(context, S.resetResent);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final token = _token;
    return AppPage(
      showBack: true,
      title: S.resetSentTitle,
      subtitle: widget.email,
      body: [
        Text(
          S.resetSentBody,
          style: context.text.bodyLarge!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        AppButton.tonal(label: S.resetResend, onPressed: _resend),
        if (token != null) ...[
          const SizedBox(height: 24),
          InfoBanner(title: S.resetDemoTitle, body: S.resetDemoBody),
          const SizedBox(height: 12),
          AppLink(
            label: S.resetDemoOpen,
            onPressed: () => context.push(
              Uri(
                path: Routes.resetPassword,
                queryParameters: {'token': token},
              ).toString(),
            ),
          ),
        ],
        const SizedBox(height: 40),
        InfoSection(title: S.resetNoEmailTitle, body: S.resetSentHint),
      ],
      actions: [
        AppButton.tonal(
          label: S.backToLogin,
          onPressed: () => context.go(Routes.login),
        ),
      ],
    );
  }
}

/// S04 «Жаңа пароль» (Figma 6:868): сілтемемен ашылады.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.token});

  final String token;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  bool _loading = false;
  bool _invalidLink = false;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    AuthError? error;
    try {
      error = await context.read<AuthRepository>().resetPassword(
        widget.token,
        _password.text,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _invalidLink = true;
      });
      return;
    }
    showAppSnackBar(context, S.passwordChanged);
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: _form,
      autovalidateMode: _autovalidate,
      child: AppPage(
        showBack: true,
        onBack: () => context.go(Routes.login),
        title: S.newPasswordTitle,
        subtitle: S.newPasswordSubtitle,
        body: [
          if (_invalidLink) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                S.resetLinkInvalid,
                style: context.text.bodyLarge!.copyWith(color: colors.error),
              ),
            ),
            const SizedBox(height: 24),
          ],
          AppTextField(
            label: S.newPasswordField,
            controller: _password,
            obscure: true,
            helper: S.passwordRule,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.newPassword,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: S.repeatPasswordField,
            controller: _repeat,
            obscure: true,
            textInputAction: TextInputAction.done,
            validator: Validators.confirmPassword(() => _password.text),
            onSubmitted: (_) => _save(),
          ),
        ],
        actions: [
          AppButton(label: S.savePassword, loading: _loading, onPressed: _save),
          AppLink(
            label: S.resetLinkExpired,
            alignment: Alignment.center,
            onPressed: () => context.go(Routes.forgotPassword),
          ),
        ],
      ),
    );
  }
}
