import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension SafePop on BuildContext {
  /// Стекте алдыңғы экран болса — артқа, әйтпесе [fallback]-қа (экран
  /// сілтемемен немесе қосымша іске қосылғанда тікелей ашылуы мүмкін).
  void popOr(String fallback) => canPop() ? pop() : go(fallback);
}
