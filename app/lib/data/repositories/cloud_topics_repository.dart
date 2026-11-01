import 'package:flutter/foundation.dart';

import '../../core/log.dart';
import '../models/topic.dart';
import '../remote/dto.dart';
import '../remote/request_state.dart';
import '../remote/sync_api.dart';
import 'sync_repository.dart';
import 'topic_repository.dart';

/// Сервердегі тақырып пен құрылғыдағы көшірменің арақатынасы.
enum CloudRelation {
  /// Екі жақта бірдей нұсқа.
  synced,

  /// Серверде жаңарақ — келесі синхрондауда құрылғыға келеді.
  newerInCloud,

  /// Құрылғыда жаңарақ — келесі синхрондауда серверге кетеді.
  newerOnDevice,

  /// Тек серверде (басқа құрылғыдан қосылған).
  cloudOnly,
}

/// `GET /v1/account` + `GET /v1/topics` нәтижесі.
class CloudSnapshot {
  const CloudSnapshot({
    required this.account,
    required this.topics,
    required this.loadedAt,
  });

  final AccountDto account;
  final List<TopicDto> topics;
  final DateTime loadedAt;
}

/// Сервердегі тақырыптармен REST арқылы жұмыс (практикалық №5):
/// GET — тізім мен аккаунт, POST — құрылғыдағы тақырыпты жіберу,
/// PATCH — өзгерту, DELETE — жою.
///
/// Әр өзгерістен кейін синхрондау іске қосылады: сервердегі нұсқа
/// жергілікті SQLite-қа жазылады, сондықтан каталог та бірден жаңарады.
class CloudTopicsRepository extends ChangeNotifier {
  CloudTopicsRepository({required this._sync, required this._topics}) {
    _sync.addListener(_onSyncChanged);
    _topics.addListener(notifyListeners);
  }

  final SyncRepository _sync;
  final TopicRepository _topics;

  RequestState<CloudSnapshot> _state = const RequestIdle();
  final _busy = <String>{};

  RequestState<CloudSnapshot> get state => _state;

  /// Сервер байланысы бар ма (токен сақталған).
  bool get linked => _sync.link != null;

  /// Осы тақырыппен сұрау жүріп жатыр.
  bool isBusy(String id) => _busy.contains(id);

  /// Тізімдегі тақырыптың құрылғыдағы көшірмемен арақатынасы.
  CloudRelation relationOf(TopicDto remote) {
    final local = _topics.tryById(remote.id);
    final remoteAt = remote.updatedAt;
    if (local == null || !local.isCustom) return CloudRelation.cloudOnly;
    final localAt = local.updatedAt;
    if (localAt == null || remoteAt == null) return CloudRelation.synced;
    final diff =
        localAt.millisecondsSinceEpoch - remoteAt.millisecondsSinceEpoch;
    if (diff == 0) return CloudRelation.synced;
    return diff < 0 ? CloudRelation.newerInCloud : CloudRelation.newerOnDevice;
  }

  /// Құрылғыда бар, серверде әлі жоқ өз тақырыптары.
  List<Topic> get deviceOnly {
    final remote = {...?_state.data?.topics.map((t) => t.id)};
    return [
      for (final t in _topics.all)
        if (t.isCustom && !remote.contains(t.id)) t,
    ];
  }

  // -------------------------------------------------------------- GET

  /// Аккаунт пен тақырыптарды серверден жүктеу.
  Future<SyncFailure?> load() async {
    final token = _sync.link?.token;
    if (token == null) {
      _set(const RequestFailure(SyncFailure.unauthorized));
      return SyncFailure.unauthorized;
    }
    _set(RequestLoading(_state.data));
    final api = _sync.api;
    final failure = await _guard(() async {
      final account = await api.account(token);
      final topics = await api.topics(token);
      _set(
        RequestSuccess(
          CloudSnapshot(
            account: account,
            topics: topics,
            loadedAt: DateTime.now(),
          ),
        ),
      );
    });
    if (failure != null) _set(RequestFailure(failure, _state.data));
    return failure;
  }

  // -------------------------------------------------- POST / PATCH / DELETE

  /// POST: құрылғыдағы тақырыпты серверге жіберу.
  Future<SyncFailure?> upload(String topicId) => _mutate(topicId, (api, t) {
    final topic = _topics.byId(topicId);
    return api.createTopic(
      t,
      TopicDto.fromModel(topic, _topics.questionsFor(topicId)),
    );
  });

  /// PATCH: тек атауын өзгерту.
  Future<SyncFailure?> rename(String topicId, String title) => _mutate(
    topicId,
    (api, t) => api.updateTopic(t, topicId, {'title': title}),
  );

  /// DELETE: серверден жою. Келесі синхрондауда құрылғыдан да жойылады.
  /// Серверде бұрыннан жоқ болса (404) — мақсатқа жеттік деп санаймыз.
  Future<SyncFailure?> remove(String topicId) =>
      _mutate(topicId, (api, t) async {
        try {
          await api.deleteTopic(t, topicId);
        } on SyncApiException catch (e) {
          if (e.failure != SyncFailure.notFound) rethrow;
        }
      });

  // ------------------------------------------- Форма: сақталғанды бірден жіберу

  /// Тақырып құрылғыда жасалды немесе өзгертілді — серверге бірден жіберу.
  /// Байланыс жоқ болса, ештеңе істемейді. Қате болса, дерек құрылғыда
  /// қалады және кейінгі синхрондауда кетеді.
  Future<SyncFailure?> pushSaved(Topic topic) async {
    final token = _sync.link?.token;
    if (token == null) return null;
    final api = _sync.api;
    final dto = TopicDto.fromModel(topic, _topics.questionsFor(topic.id));
    return _guard(() async {
      try {
        await api.updateTopic(token, topic.id, dto.toPatchJson());
      } on SyncApiException catch (e) {
        // Серверде әлі жоқ — жаңасын жасаймыз.
        if (e.failure != SyncFailure.notFound) rethrow;
        await api.createTopic(token, dto);
      }
    });
  }

  /// Тақырып құрылғыда жойылды — серверден де жою.
  Future<SyncFailure?> pushDeleted(String topicId) async {
    final token = _sync.link?.token;
    if (token == null) return null;
    final api = _sync.api;
    return _guard(() async {
      try {
        await api.deleteTopic(token, topicId);
      } on SyncApiException catch (e) {
        if (e.failure != SyncFailure.notFound) rethrow;
      }
    });
  }

  // -------------------------------------------------------------- ішкі

  Future<SyncFailure?> _mutate(
    String topicId,
    Future<void> Function(SyncApi api, String token) call,
  ) async {
    final token = _sync.link?.token;
    if (token == null) return SyncFailure.unauthorized;
    _busy.add(topicId);
    notifyListeners();
    try {
      final failure = await _guard(() => call(_sync.api, token));
      if (failure != null) return failure;
      // Сервердегі нұсқаны құрылғыға алып, тізімді жаңарту.
      // Тізім жүктелмесе, оның қатесі state-те көрінеді; операцияның өзі
      // сәтті өтті.
      await _sync.syncNow();
      await load();
      return null;
    } finally {
      _busy.remove(topicId);
      notifyListeners();
    }
  }

  /// Барлық қатені [SyncFailure]-ге айналдырады: экранға exception жетпейді.
  Future<SyncFailure?> _guard(Future<void> Function() body) async {
    try {
      await body();
      return null;
    } on SyncApiException catch (e) {
      if (e.failure == SyncFailure.unauthorized) await _sync.invalidateLink();
      Log.warn('cloud', '$e');
      return e.failure;
    } on Object catch (e) {
      Log.error('cloud', 'unexpected', e);
      return SyncFailure.server;
    }
  }

  void _set(RequestState<CloudSnapshot> state) {
    _state = state;
    notifyListeners();
  }

  void _onSyncChanged() {
    // Ажыратылды немесе пайдаланушы ауысты — ескі деректі көрсетпейміз.
    final account = _state.data?.account.email;
    if (!linked || (account != null && _sync.link?.email != account)) {
      if (_state is! RequestIdle) _set(const RequestIdle());
    }
  }

  bool _disposed = false;

  /// Сұрау экран жабылғаннан (немесе қосымша тоқтағаннан) кейін аяқталса,
  /// жойылған объектіге хабар жібермейміз.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sync.removeListener(_onSyncChanged);
    _topics.removeListener(notifyListeners);
    super.dispose();
  }
}
