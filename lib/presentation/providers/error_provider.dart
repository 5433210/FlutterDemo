import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorProvider = StateNotifierProvider<ErrorNotifier, String?>((ref) {
  return ErrorNotifier();
});

class ErrorNotifier extends StateNotifier<String?> {
  ErrorNotifier() : super(null);

  void setError(String? error) => state = error;
  void clearError() => state = null;

  Future<T> handleError<T>(Future<T> Function() task) async {
    try {
      clearError();
      return await task();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }
}
