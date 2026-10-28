import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/widgets.dart';

/// Деректер қоры ашылмаған жағдайдағы экран.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: AppPage(
        title: S.startupErrorTitle,
        body: [Text(S.startupErrorBody)],
        actions: [
          AppButton(
            label: S.retry,
            loading: _retrying,
            onPressed: () async {
              setState(() => _retrying = true);
              await widget.onRetry();
              if (mounted) setState(() => _retrying = false);
            },
          ),
        ],
      ),
    );
  }
}
