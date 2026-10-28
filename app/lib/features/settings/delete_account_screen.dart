import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/sync_repository.dart';

/// Аккаунтты жою: парольмен растау, қате парольде аккаунт сақталады.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final sync = context.read<SyncRepository>();
    final AuthError? error;
    try {
      error = await context.read<AuthRepository>().deleteAccount(
        _password.text,
        // Бұлттағы көшірме де жойылады; сервер қолжетімсіз болса,
        // құрылғыдағы аккаунт сақталып, себебі көрсетіледі.
        beforeDelete: () async {
          if (await sync.deleteRemote() != null) {
            throw AppException(S.syncDeleteRemoteFailed);
          }
        },
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = S.deleteAccountWrongPassword);
      return;
    }
    showAppSnackBar(context, S.accountDeleted);
    context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodyLarge!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Form(
      key: _form,
      child: AppPage(
        showBack: true,
        title: S.deleteAccountTitle,
        subtitle: S.deleteAccountSubtitle,
        headerGap: 40,
        body: [
          Text(S.deleteAccountBody, style: muted),
          const SizedBox(height: 32),
          AppTextField(
            label: S.deleteAccountPassword,
            controller: _password,
            obscure: true,
            autofillHints: const [AutofillHints.password],
            validator: Validators.loginPassword,
            errorText: _error,
            onSubmitted: (_) => _delete(),
          ),
          const SizedBox(height: 16),
          Text(
            S.deleteAccountNote,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        actions: [
          AppButton.danger(
            label: S.deleteAccountAction,
            loading: _loading,
            onPressed: _delete,
          ),
          AppButton.tonal(
            label: S.cancel,
            onPressed: () => context.popOr(Routes.settings),
          ),
        ],
      ),
    );
  }
}
