import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class FotoCache {
  FotoCache._();

  static final _cache = <int, Uint8List?>{};
  static final notifier = ValueNotifier<int>(0);

  static Uint8List? get(int userId) => _cache[userId];
  static bool has(int userId) => _cache.containsKey(userId);

  static void set(int userId, Uint8List? bytes) {
    _cache[userId] = bytes;
    notifier.value++;
  }

  static void invalidate(int userId) {
    _cache.remove(userId);
    notifier.value++;
  }

  static void clear() {
    _cache.clear();
    notifier.value++;
  }
}
