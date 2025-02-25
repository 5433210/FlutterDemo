import 'package:flutter_riverpod/flutter_riverpod.dart';

final loadingProvider = StateProvider<bool>((ref) => false);
final loadingMessageProvider = StateProvider<String?>((ref) => null);

class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier() : super(false);

  void startLoading() => state = true;
  void stopLoading() => state = false;
  
  Future<T> runWithLoading<T>(Future<T> Function() task) async {
    try {
      startLoading();
      return await task();
    } finally {
      stopLoading();
    }
  }
}
