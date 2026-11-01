import 'sync_api.dart';

/// Серверге сұраудың күйі: экран әр күйді бөлек салады.
///
/// Loading пен Failure алдыңғы сәтті нәтижені ([data]) сақтайды — жаңарту
/// кезінде тізім жоғалмайды, қате баннер оның үстінде көрсетіледі.
sealed class RequestState<T> {
  const RequestState();

  T? get data => null;
}

/// Сұрау әлі жіберілмеген.
final class RequestIdle<T> extends RequestState<T> {
  const RequestIdle();
}

final class RequestLoading<T> extends RequestState<T> {
  const RequestLoading([this.data]);

  @override
  final T? data;
}

final class RequestSuccess<T> extends RequestState<T> {
  const RequestSuccess(this.data);

  @override
  final T data;
}

final class RequestFailure<T> extends RequestState<T> {
  const RequestFailure(this.failure, [this.data]);

  final SyncFailure failure;

  @override
  final T? data;
}
