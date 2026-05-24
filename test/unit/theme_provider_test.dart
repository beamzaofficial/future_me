import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_me/providers/theme_provider.dart';
import 'package:future_me/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.create();
  });

  test('defaults to system mode when nothing stored', () {
    final p = ThemeProvider(storage);
    expect(p.mode, ThemeMode.system);
  });

  test('reads stored mode on startup', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final s = await LocalStorageService.create();
    final p = ThemeProvider(s);
    expect(p.mode, ThemeMode.dark);
  });

  test('setMode persists and notifies', () async {
    final p = ThemeProvider(storage);
    var notified = 0;
    p.addListener(() => notified++);
    await p.setMode(ThemeMode.light);
    expect(p.mode, ThemeMode.light);
    expect(storage.getThemeMode(), 'light');
    expect(notified, 1);
  });
}
