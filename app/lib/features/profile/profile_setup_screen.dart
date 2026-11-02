import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';

/// S05 Профильді баптау (Create): тіркелуден кейін бір рет.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: context.read<AuthRepository>().user?.name,
  );
  Direction _direction = Direction.mobile;
  Level _level = Level.beginner;
  InterviewLanguage _language = InterviewLanguage.kk;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthRepository>();
    try {
      await auth.updateProfile(
        auth.user!.copyWith(
          name: _name.text.trim(),
          direction: _direction,
          level: _level,
          interviewLanguage: _language,
        ),
      );
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
      return;
    }
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AppPage(
        showBack: true,
        onBack: () => context.go(Routes.home),
        title: S.setupTitle,
        subtitle: S.setupSubtitle,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            S.setupStep,
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        body: [
          AppTextField(
            label: S.fieldName,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
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
            columns: 3,
            values: Level.values,
            selected: _level,
            labelOf: (l) => l.label,
            onChanged: (l) => setState(() => _level = l),
          ),
          const SizedBox(height: AppSpacing.lg),
          ChoiceGroup<InterviewLanguage>(
            label: S.fieldInterviewLanguage,
            columns: 3,
            values: InterviewLanguage.values,
            selected: _language,
            labelOf: (l) => l.label,
            onChanged: (l) => setState(() => _language = l),
          ),
        ],
        actions: [AppButton.accent(label: S.setupSave, onPressed: _save)],
      ),
    );
  }
}
