import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

/// «intRvue» сөз-белгісі. Логотип ретінде ешқашан тасымалданбайды:
/// үлкен мәтін өлшемінде (200%) сыймаса, жолға сыятындай кішірейеді.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.large = false});

  /// true — splash экранындағы үлкен белгі (52), әйтпесе тақырып жолағы.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final base = large
        ? context.text.displayLarge!.copyWith(fontSize: 52)
        : context.text.headlineSmall!;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: large ? Alignment.center : AlignmentDirectional.centerStart,
      child: Text(
        S.appName,
        maxLines: 1,
        softWrap: false,
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
