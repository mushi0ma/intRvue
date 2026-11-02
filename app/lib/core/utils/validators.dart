import '../constants/app_strings.dart';

/// Форма өрістерін тексеру. Әр функция қате мәтінін немесе null қайтарады —
/// TextFormField.validator-ға тікелей беріледі.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$');
  static final _letter = RegExp(r'[A-Za-zА-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]');
  static final _digit = RegExp(r'\d');

  /// Пароль талаптары (рубрика ұяшықтары үшін де).
  static bool hasLetter(String v) => _letter.hasMatch(v);
  static bool hasDigit(String v) => _digit.hasMatch(v);

  static const minPasswordLength = 8;

  static String? required(String? value, {String? field}) {
    if (value == null || value.trim().isEmpty) {
      return S.fieldRequired(field ?? S.fieldDefault);
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return S.nameEmpty;
    if (v.length < 2) return S.nameTooShort;
    if (v.length > 40) return S.nameTooLong;
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return S.emailEmpty;
    if (!_email.hasMatch(v)) {
      return S.emailInvalid;
    }
    return null;
  }

  /// Кіру кезінде тек бос еместігі тексеріледі.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return S.passwordEmpty;
    return null;
  }

  /// Тіркелу және жаңа пароль: кемінде 8 таңба, әріп пен сан.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return S.passwordEmpty;
    if (v.length < minPasswordLength ||
        !_letter.hasMatch(v) ||
        !_digit.hasMatch(v)) {
      return S.passwordWeak;
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return S.passwordRepeat;
      if (value != original()) return S.passwordMismatch;
      return null;
    };
  }

  static String? answer(String? value, {int max = 4000}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return S.answerEmpty;
    if (v.length > max) return S.answerTooLong(max);
    return null;
  }

  static String? topicTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return S.topicTitleEmpty;
    if (v.length > 60) return S.topicTitleTooLong;
    return null;
  }

  static String? summary(String? value) =>
      (value?.trim() ?? '').isEmpty ? S.summaryEmpty : null;

  static String? questionText(String? value) =>
      (value?.trim() ?? '').isEmpty ? S.questionTextEmpty : null;

  static String? modelAnswer(String? value) =>
      (value?.trim() ?? '').isEmpty ? S.modelAnswerEmpty : null;
}
