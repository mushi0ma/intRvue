import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/navigation.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';

/// S22 Профильді өзгерту (Edit). Сақталмаған өзгерістер болса,
/// шығар алдында растау сұралады.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _initial = context.read<AuthRepository>().user!;
  late final _name = TextEditingController(text: _initial.name);
  late Direction _direction = _initial.direction;
  late Level _level = _initial.level;
  late InterviewLanguage _language = _initial.interviewLanguage;
  bool _saving = false;

  bool get _dirty =>
      _name.text.trim() != _initial.name ||
      _direction != _initial.direction ||
      _level != _initial.level ||
      _language != _initial.interviewLanguage;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthRepository>().updateProfile(
        _initial.copyWith(
          name: _name.text.trim(),
          direction: _direction,
          level: _level,
          interviewLanguage: _language,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    showAppSnackBar(context, S.profileSaved);
    context.popOr(Routes.profile);
  }

  Future<void> _leave() async {
    if (!_dirty) {
      context.popOr(Routes.profile);
      return;
    }
    final discard = await showConfirmDialog(
      context,
      title: S.discardTitle,
      body: S.discardBody,
      confirmLabel: S.discardAction,
    );
    if (discard && mounted) context.popOr(Routes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AppPage(
          showBack: true,
          onBack: _leave,
          title: S.editProfile,
          subtitle: S.editProfileSubtitle,
          body: [
            AppTextField(
              label: S.fieldName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: Validators.name,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<Direction>(
              label: S.fieldDirection,
              values: Direction.values,
              selected: _direction,
              labelOf: (d) => d.label,
              onChanged: (d) => setState(() => _direction = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<Level>(
              label: S.fieldLevel,
              values: Level.values,
              selected: _level,
              labelOf: (l) => l.label,
              onChanged: (l) => setState(() => _level = l),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<InterviewLanguage>(
              label: S.fieldInterviewLanguage,
              values: InterviewLanguage.values,
              selected: _language,
              labelOf: (l) => l.label,
              onChanged: (l) => setState(() => _language = l),
            ),
          ],
          actions: [
            AppButton(label: S.saveChanges, loading: _saving, onPressed: _save),
            AppButton.text(label: S.cancel, onPressed: _leave),
          ],
        ),
      ),
    );
  }
}
