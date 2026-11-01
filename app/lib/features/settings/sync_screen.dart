import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/remote/sync_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/sync_repository.dart';

/// Бұлттық синхрондау: PostgreSQL серверіне қосу, күйі, қолмен синхрондау.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  static String failureText(SyncFailure f) => switch (f) {
    SyncFailure.offline => S.syncErrOffline,
    SyncFailure.timeout => S.syncErrTimeout,
    SyncFailure.invalidCredentials => S.syncErrCredentials,
    SyncFailure.unauthorized => S.syncErrUnauthorized,
    SyncFailure.weakPassword => S.syncErrWeak,
    SyncFailure.rateLimited => S.syncErrRateLimited,
    SyncFailure.notFound => S.syncErrNotFound,
    SyncFailure.titleTaken => S.syncErrTitleTaken,
    SyncFailure.conflict => S.syncErrConflict,
    SyncFailure.invalidRequest => S.syncErrInvalid,
    SyncFailure.emailTaken || SyncFailure.server => S.syncErrServer,
  };

  /// Баптаулар тізіміндегі қысқа күйі.
  static String statusLabel(SyncRepository sync) {
    final link = sync.link;
    if (link == null) return S.syncOff;
    if (sync.syncing) return S.syncInProgress;
    final at = link.lastSyncAt;
    return at == null ? S.syncNever : Fmt.dayTime(at);
  }

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  late final _server = TextEditingController(
    text: context.read<SyncRepository>().serverUrl.toString(),
  );
  bool _connecting = false;

  /// Сервер мекенжайы — техникалық баптау, әдепкіде жасырын.
  bool _editServer = false;

  @override
  void dispose() {
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  static String? _validateServer(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return S.syncServerInvalid;
    }
    return null;
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final sync = context.read<SyncRepository>();
    setState(() => _connecting = true);
    await sync.setServerUrl(Uri.parse(_server.text.trim()));
    final failure = await sync.connect(_password.text);
    if (!mounted) return;
    setState(() => _connecting = false);
    if (failure == null) {
      _password.clear();
      showAppSnackBar(context, S.syncDone);
    }
  }

  Future<void> _syncNow() async {
    final failure = await context.read<SyncRepository>().syncNow();
    if (!mounted) return;
    showAppSnackBar(
      context,
      failure == null ? S.syncDone : SyncScreen.failureText(failure),
    );
  }

  Future<void> _disconnect() async {
    final ok = await showConfirmDialog(
      context,
      title: S.syncDisconnectTitle,
      body: S.syncDisconnectBody,
      confirmLabel: S.syncDisconnect,
    );
    if (!ok || !mounted) return;
    await context.read<SyncRepository>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncRepository>();
    final link = sync.link;
    final muted = context.text.bodyLarge!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final failure = sync.lastFailure;

    return Form(
      key: _form,
      child: AppPage(
        showBack: true,
        onBack: () => context.popOr(Routes.settings),
        title: S.syncTitle,
        subtitle: S.syncSubtitle,
        headerGap: 40,
        body: [
          if (failure != null) ...[
            InfoBanner(title: SyncScreen.failureText(failure)),
            const SizedBox(height: 24),
          ],
          if (link == null) ...[
            Text(S.syncIntro, style: muted),
            const SizedBox(height: 32),
            AppTextField(
              label: S.syncPassword,
              controller: _password,
              obscure: true,
              helper: S.syncPasswordHint,
              autofillHints: const [AutofillHints.password],
              validator: Validators.loginPassword,
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 24),
            if (_editServer)
              AppTextField(
                label: S.syncServer,
                controller: _server,
                keyboardType: TextInputType.url,
                validator: _validateServer,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${S.syncServer}: ${sync.serverUrl.authority}',
                      style: context.text.bodyMedium!.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _editServer = true),
                    child: Text(S.edit),
                  ),
                ],
              ),
          ] else ...[
            InfoSection(
              title: S.syncAccount,
              body:
                  '${context.watch<AuthRepository>().user?.email ?? link.email}'
                  '\n${sync.serverUrl}',
            ),
            SectionDivider(vertical: 28),
            Semantics(
              liveRegion: true,
              child: InfoSection(
                title: S.syncLast,
                body: SyncScreen.statusLabel(sync),
              ),
            ),
            const SizedBox(height: 24),
            Text(S.syncAuto, style: muted),
            SectionDivider(vertical: 28),
            SettingsRow(
              title: S.cloudTitle,
              value: sync.serverUrl.authority,
              onTap: () => context.push(Routes.cloudTopics),
            ),
          ],
        ],
        actions: link == null
            ? [
                AppButton(
                  label: S.syncConnect,
                  loading: _connecting,
                  onPressed: _connect,
                ),
              ]
            : [
                AppButton(
                  label: S.syncNow,
                  loading: sync.syncing,
                  onPressed: _syncNow,
                ),
                AppButton.text(
                  label: S.syncDisconnect,
                  onPressed: sync.syncing ? null : _disconnect,
                ),
              ],
      ),
    );
  }
}
