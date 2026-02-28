/// Error types that can occur in the application.
enum AppErrorType {
  /// Device has no internet connection.
  network,

  /// User is not authenticated or session expired.
  auth,

  /// Requested resource does not exist.
  notFound,

  /// Permission denied (Firestore rules, etc.).
  permission,

  /// External API rate limit exceeded.
  rateLimit,

  /// Unexpected / catch-all error.
  unknown,
}

/// Standardised application error model.
///
/// Usage:
/// ```dart
/// try {
///   await someService.doThing();
/// } catch (e, st) {
///   final err = AppError.fromException(e, stackTrace: st);
///   ref.read(errorProvider.notifier).state = err;
/// }
/// ```
class AppError {
  const AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  final AppErrorType type;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  /// Creates an [AppError] from any exception, applying heuristic detection.
  factory AppError.fromException(
    Object e, {
    StackTrace? stackTrace,
    String? fallbackMessage,
  }) {
    final msg = e.toString().toLowerCase();
    AppErrorType type = AppErrorType.unknown;

    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      type = AppErrorType.network;
    } else if (msg.contains('permission-denied') || msg.contains('forbidden')) {
      type = AppErrorType.permission;
    } else if (msg.contains('not-found') || msg.contains('notfound')) {
      type = AppErrorType.notFound;
    } else if (msg.contains('unauthenticated') || msg.contains('sign-in')) {
      type = AppErrorType.auth;
    } else if (msg.contains('quota') || msg.contains('rate')) {
      type = AppErrorType.rateLimit;
    }

    return AppError(
      type: type,
      message: _messageFor(type, fallback: fallbackMessage ?? e.toString()),
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  /// Returns a human-readable Portuguese error message for the given type.
  static String _messageFor(AppErrorType type, {required String fallback}) {
    switch (type) {
      case AppErrorType.network:
        return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
      case AppErrorType.auth:
        return 'Sessão expirada. Faça login novamente para continuar.';
      case AppErrorType.notFound:
        return 'O recurso solicitado não foi encontrado.';
      case AppErrorType.permission:
        return 'Você não tem permissão para realizar esta ação.';
      case AppErrorType.rateLimit:
        return 'Limite de requisições atingido. Aguarde um momento e tente novamente.';
      case AppErrorType.unknown:
        return fallback;
    }
  }

  bool get isNetwork => type == AppErrorType.network;
  bool get isAuth => type == AppErrorType.auth;
  bool get isNotFound => type == AppErrorType.notFound;
  bool get isPermission => type == AppErrorType.permission;
  bool get isRateLimit => type == AppErrorType.rateLimit;

  @override
  String toString() => 'AppError(type: $type, message: $message)';
}
