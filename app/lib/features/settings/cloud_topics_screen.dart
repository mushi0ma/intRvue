import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/remote/dto.dart';
import '../../data/remote/request_state.dart';
import '../../data/remote/sync_api.dart';
import '../../data/repositories/cloud_topics_repository.dart';
import '../../data/repositories/sync_repository.dart';
import 'sync_screen.dart';

/// Сервердегі тақырыптар (практикалық №5): GET тізімі, POST, PATCH, DELETE.
/// Loading / Success / Error / Offline / Timeout күйлері осы экранда.
class CloudTopicsScreen extends StatefulWidget {
  const CloudTopicsScreen({super.key});

  @override
  State<CloudTopicsScreen> createState() => _CloudTopicsScreenState();
}

class _CloudTopicsScreenState extends State<CloudTopicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CloudTopicsRepository>().load();
    });
  }

  Future<void> _run(Future<SyncFailure?> action, String done) async {
    final failure = await action;
    if (!mounted) return;
    showAppSnackBar(context, failure == null ? done : _failureText(failure));
  }

  /// Бұл экранда кейінге қалдырылған қайталау жоқ: офлайн хабарламасы
  /// «сақталды, қайталаймыз» демейді.
  static String _failureText(SyncFailure failure) =>
      failure == SyncFailure.offline
      ? S.cloudOffline
      : SyncScreen.failureText(failure);

  Future<void> _rename(TopicDto topic) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: topic.title),
    );
    if (title == null || title == topic.title || !mounted) return;
    await _run(
      context.read<CloudTopicsRepository>().rename(topic.id, title),
      S.cloudRenamed,
    );
  }

  Future<void> _delete(TopicDto topic) async {
    final ok = await showConfirmDialog(
      context,
      title: S.cloudDeleteTitle,
      body: S.cloudDeleteBody,
      confirmLabel: S.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(
      context.read<CloudTopicsRepository>().remove(topic.id),
      S.cloudDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudTopicsRepository>();
    final state = cloud.state;
    final data = state.data;
    final loading = state is RequestLoading;
    final muted = context.text.bodyMedium!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final server = context.read<SyncRepository>().serverUrl;
    final small = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return AppPage(
      showBack: true,
      onBack: () => context.popOr(Routes.sync),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text('${S.serverLabel} · ${server.authority}', style: small),
      ),
      title: S.cloudTitle,
      subtitle: S.cloudSubtitle,
      body: [
        if (state case RequestFailure(:final failure)) ...[
          // F13/F14: сұрау қай жерде үзілгені + не сақталғаны.
          if (const {
            SyncFailure.offline,
            SyncFailure.timeout,
            SyncFailure.server,
          }.contains(failure))
            FullBleed(
              child: ColoredBox(
                color: context.palette.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.sm,
                    children: [
                      RequestTrace(
                        request: 'GET ${server.authority}/v1/topics',
                        reachedNetwork: failure != SyncFailure.offline,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _failureText(failure),
                        style: context.text.titleSmall,
                      ),
                      Text(S.cloudKeptOnDevice, style: small),
                    ],
                  ),
                ),
              ),
            )
          else
            FullBleed(child: InfoBanner(title: _failureText(failure))),
          const SizedBox(height: AppSpacing.md),
        ],
        if (data == null && (loading || state is RequestIdle))
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                spacing: 16,
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  Text(S.cloudLoading, style: muted),
                ],
              ),
            ),
          ),
        if (data != null) ...[
          GroupHeader(
            icon: AppIcons.cloud,
            title: S.cloudOnServer,
            meta: '${data.topics.length}',
          ),
          if (data.topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(S.cloudEmpty, style: muted),
            )
          else
            ListGroup(
              children: [
                for (final t in data.topics)
                  ItemRow(
                    title: t.title,
                    meta:
                        '${t.direction.label} · ${t.level.label} · '
                        '${S.questionsCount(t.questions.length)}',
                    metaTrailing: AppTag(
                      _relationLabel(cloud.relationOf(t)),
                      kind: cloud.relationOf(t) == CloudRelation.synced
                          ? TagKind.success
                          : TagKind.neutral,
                    ),
                    trailing: cloud.isBusy(t.id)
                        ? const _Busy()
                        : PopupMenuButton<_Action>(
                            tooltip: S.cloudActions,
                            onSelected: (a) => switch (a) {
                              _Action.rename => _rename(t),
                              _Action.delete => _delete(t),
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: _Action.rename,
                                child: Text(S.cloudRename),
                              ),
                              PopupMenuItem(
                                value: _Action.delete,
                                child: Text(S.cloudDelete),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          if (cloud.deviceOnly case final local when local.isNotEmpty) ...[
            GroupHeader(
              icon: AppIcons.phone,
              title: S.cloudDeviceOnly,
              meta: '${local.length}',
            ),
            ListGroup(
              children: [
                for (final t in local)
                  ItemRow(
                    title: t.title,
                    meta: t.trackLabel,
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: cloud.isBusy(t.id)
                          ? const _Busy()
                          : OutlinedButton.icon(
                              onPressed: () =>
                                  _run(cloud.upload(t.id), S.cloudUploaded),
                              icon: const Icon(AppIcons.upload, size: 18),
                              label: Text(S.cloudUpload),
                            ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${S.cloudAccount}: ${data.account.name} · ${data.account.email} · '
            '${S.cloudRegistered} ${Fmt.day(data.account.createdAt.toLocal())}'
            ' · ${S.cloudLoadedAt} ${Fmt.time(data.loadedAt)}',
            style: small,
          ),
        ],
      ],
      actions: [
        AppButton.tonal(
          label: S.cloudRefresh,
          loading: loading,
          onPressed: cloud.linked ? cloud.load : null,
        ),
      ],
    );
  }

  static String _relationLabel(CloudRelation r) => switch (r) {
    CloudRelation.synced => S.cloudSynced,
    CloudRelation.newerInCloud => S.cloudNewerInCloud,
    CloudRelation.newerOnDevice => S.cloudNewerOnDevice,
    CloudRelation.cloudOnly => S.cloudOnlyRemote,
  };
}

enum _Action { rename, delete }

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 48,
    child: Center(
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_title.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(S.cloudRename),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _title,
        autofocus: true,
        decoration: InputDecoration(labelText: S.cloudRenameField),
        validator: Validators.topicTitle,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(S.cancel),
      ),
      TextButton(onPressed: _submit, child: Text(S.save)),
    ],
  );
}
