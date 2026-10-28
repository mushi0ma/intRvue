import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('бос email', () => expect(Validators.email(''), S.emailEmpty));
    test('тек бос орын', () => expect(Validators.email('   '), S.emailEmpty));
    test('қате формат', () {
      for (final v in ['aidana', 'aidana@', 'aidana@example', '@example.com']) {
        expect(Validators.email(v), S.emailInvalid, reason: v);
      }
    });
    test('дұрыс email', () {
      expect(Validators.email('aidana@example.com'), isNull);
      expect(Validators.email(' a.b+c@mail.kz '), isNull);
    });
  });

  group('Validators пароль', () {
    test('кіруде бос пароль', () {
      expect(Validators.loginPassword(''), S.passwordEmpty);
      expect(Validators.loginPassword('x'), isNull);
    });
    test('тіркелуде: 8 таңба, әріп пен сан', () {
      expect(Validators.newPassword(''), S.passwordEmpty);
      expect(Validators.newPassword('abc123'), S.passwordWeak);
      expect(Validators.newPassword('abcdefgh'), S.passwordWeak);
      expect(Validators.newPassword('12345678'), S.passwordWeak);
      expect(Validators.newPassword('құпия2026'), isNull);
    });
    test('парольді қайталау', () {
      final confirm = Validators.confirmPassword(() => 'abc12345');
      expect(confirm(''), S.passwordRepeat);
      expect(confirm('abc1234'), S.passwordMismatch);
      expect(confirm('abc12345'), isNull);
    });
  });

  group('Міндетті өрістер', () {
    test('аты', () {
      expect(Validators.name(''), S.nameEmpty);
      expect(Validators.name('А'), S.nameTooShort);
      expect(Validators.name('Айдана'), isNull);
    });
    test('жауап', () {
      expect(Validators.answer('  '), S.answerEmpty);
      expect(Validators.answer('a' * 4001), S.answerTooLong(4000));
      expect(Validators.answer('Жауап'), isNull);
    });
  });
}
