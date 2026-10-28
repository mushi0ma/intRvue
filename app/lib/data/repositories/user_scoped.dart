import '../models/user_profile.dart';

/// Ағымдағы пайдаланушының деректерін жүктейтін репозиторий.
/// Кіру, тіркелу, шығу кезінде AuthRepository шақырады.
abstract interface class UserScoped {
  Future<void> loadFor(UserProfile? user);
}
