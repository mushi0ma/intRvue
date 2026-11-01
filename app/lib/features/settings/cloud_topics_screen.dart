import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/remote/dto.dart';
import '../../data/remote/request_state.dart';
import '../../data/remote/sync_api.dart';
import '../../data/repositories/cloud_topics_repository.dart';
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
    showAppSnackBar(
      context,
      failure == null ? done : SyncScreen.failureText(failure),
    );
  }

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

    return AppPage(
      showBack: true,
      onBack: () => context.popOr(Routes.sync),
      title: S.cloudTitle,
      subtitle: S.cloudSubtitle,
      body: [
        if (state case RequestFailure(:final failure)) ...[
          InfoBanner(title: SyncScreen.failureText(failure)),
          const SizedBox(height: 24),
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
          InfoSection(
            title: S.cloudAccount,
            titleStyle: context.text.titleMedium,
            body:
                '${data.account.name} · ${data.account.email}\n'
                '${S.cloudRegistered}: ${Fmt.day(data.account.createdAt.toLocal())}'
                ' · ${S.cloudLoadedAt}: ${Fmt.time(data.loadedAt)}',
          ),
          const SizedBox(height: 32),
          Text(
            '${S.cloudOnServer} · ${data.topics.length}',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 4),
          if (data.topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(S.cloudEmpty, style: muted),
            ),
          for (final t in data.topics)
            ListRow(
              meta: _relationLabel(cloud.relationOf(t)),
              title: t.title,
              subtitle:
                  '${t.direction.label} · ${t.level.label} · '
                  '${S.questionsCount(t.questions.length)}',
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
          if (cloud.deviceOnly case final local when local.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              '${S.cloudDeviceOnly} · ${local.length}',
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 4),
            for (final t in local)
              ListRow(
                title: t.title,
                subtitle: t.trackLabel,
                trailing: cloud.isBusy(t.id)
                    ? const _Busy()
                    : TextButton(
                        onPressed: () =>
                            _run(cloud.upload(t.id), S.cloudUploaded),
                        child: Text(S.cloudUpload),
                      ),
              ),
          ],
        ],
      ],
      actions: [
        AppButton(
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
