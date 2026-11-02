import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/remote/live_channel.dart';
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
  // initState-те жасалады: lazy болса, байланыс бар кезде өріс көрсетілмейді
  // және бірінші рет dispose-та (context жарамсыз кезде) оқылар еді.
  late final TextEditingController _server;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(
      text: context.read<SyncRepository>().serverUrl.toString(),
    );
  }

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
        onBack: () => context.popOr(Routes.profile),
        title: S.syncTitle,
        subtitle: S.syncSubtitle,
        body: [
          if (failure != null) ...[
            FullBleed(
              child: InfoBanner(title: SyncScreen.failureText(failure)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (link == null) ...[
            Text(S.syncIntro, style: muted),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: S.syncPassword,
              controller: _password,
              obscure: true,
              helper: S.syncPasswordHint,
              autofillHints: const [AutofillHints.password],
              validator: Validators.loginPassword,
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: AppSpacing.md),
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
            // F9/F10: тікелей байланыс күйі жоғарыда, астында деректер тобы.
            const LiveStatusSection(),
            const SizedBox(height: AppSpacing.md),
            ListGroup(
              children: [
                GroupRow(
                  title: S.syncAccount,
                  subtitle:
                      '${context.watch<AuthRepository>().user?.email ?? link.email}'
                      ' · ${sync.serverUrl.authority}',
                  trailing: null,
                ),
                Semantics(
                  liveRegion: true,
                  child: GroupRow(
                    title: S.syncLast,
                    subtitle: SyncScreen.statusLabel(sync),
                    trailing: null,
                  ),
                ),
                GroupRow(
                  title: S.cloudTitle,
                  onTap: () => context.push(Routes.cloudTopics),
                ),
              ],
            ),
          ],
        ],
        actions: link == null
            ? [
                AppButton.accent(
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

/// Тікелей (WebSocket) байланыс күйі: қосулы / қосылуда / үзілді + кері
/// санақ және «Қазір қосылу». Үзілу қате емес: деректер құрылғыда қалады.
class LiveStatusSection extends StatefulWidget {
  const LiveStatusSection({super.key});

  @override
  State<LiveStatusSection> createState() => _LiveStatusSectionState();
}

class _LiveStatusSectionState extends State<LiveStatusSection> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // Кері санақ тек күту кезінде жаңарады.
  void _ticker(bool waiting) {
    if (waiting && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!waiting) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = context.read<SyncRepository>().live;
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final status = live.status;
        _ticker(status == LiveStatus.waiting);
        final at = live.retryAt;
        final seconds = at == null
            ? 0
            : (at.difference(DateTime.now()).inMilliseconds / 1000)
                  .ceil()
                  .clamp(0, 999);
        final body = switch (status) {
          LiveStatus.live => S.syncLiveOn,
          LiveStatus.connecting => S.syncLiveConnecting,
          LiveStatus.waiting => S.syncLiveWaiting(seconds),
          LiveStatus.off => S.syncAuto,
        };
        if (status == LiveStatus.waiting) {
          return FullBleed(
            child: InfoBanner(
              title: S.syncLiveTitle,
              body: body,
              actionLabel: S.syncLiveRetry,
              onAction: live.retryNow,
            ),
          );
        }
        final p = context.palette;
        return Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status == LiveStatus.live ? p.accent : p.tonal,
                    border: Border.all(color: p.ink),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(S.syncLiveTitle, style: context.text.titleSmall),
                    Text(
                      body,
                      style: context.text.bodySmall!.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
