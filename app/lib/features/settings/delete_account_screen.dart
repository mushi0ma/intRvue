import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
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

  /// Сервердегі көшірме жойылмады (F17): аккаунт құрылғыда сақталды.
  bool _remoteFailed = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _error = null;
      _remoteFailed = false;
    });
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
    } on AppException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _remoteFailed = true;
      });
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
    final email = context.read<AuthRepository>().user?.email ?? '';
    return Form(
      key: _form,
      child: AppPage(
        showBack: true,
        title: S.deleteAccountTitle,
        subtitle: _remoteFailed
            ? S.deleteNothingRemoved
            : S.deleteAccountSubtitle,
        body: [
          if (_remoteFailed) ...[
            FullBleed(
              child: ColoredBox(
                color: context.palette.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.sm,
                      children: [
                        RequestTrace(
                          request:
                              'DELETE ${context.read<SyncRepository>().serverUrl.authority}/v1/account',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          S.deleteRemoteTitle,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          S.deleteRemoteBody,
                          style: context.text.bodySmall!.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(Routes.sync),
                            icon: const Icon(AppIcons.sync, size: 18),
                            label: Text(S.openSync),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // F16: не жойылатыны — нақты тізім, тақырыбында аккаунт.
          if (!_remoteFailed) ...[
            ConsequenceBox(
              header: email,
              items: [S.delSessions, S.delProgress, S.delTopics, S.delLogin],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.deleteAccountBody,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: S.deleteAccountPassword,
            controller: _password,
            obscure: true,
            autofillHints: const [AutofillHints.password],
            validator: Validators.loginPassword,
            errorText: _error,
            onSubmitted: (_) => _delete(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            S.deleteAccountNote,
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        actions: [
          AppButton.danger(
            label: _remoteFailed ? S.retryDelete : S.deleteAccountAction,
            loading: _loading,
            onPressed: _delete,
          ),
          AppButton.text(
            label: S.cancel,
            onPressed: () => context.popOr(Routes.profile),
          ),
        ],
      ),
    );
  }
}
