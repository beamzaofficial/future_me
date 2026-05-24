import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LetterDraft {
  final String title;
  final String content;
  final DateTime? unlockAt;
  final bool isPublic;
  final DateTime savedAt;

  const LetterDraft({
    required this.title,
    required this.content,
    this.unlockAt,
    required this.isPublic,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'unlockAt': unlockAt?.toIso8601String(),
    'isPublic': isPublic,
    'savedAt': savedAt.toIso8601String(),
  };

  factory LetterDraft.fromJson(Map<String, dynamic> json) => LetterDraft(
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    unlockAt: json['unlockAt'] != null
        ? DateTime.tryParse(json['unlockAt'] as String)
        : null,
    isPublic: json['isPublic'] as bool? ?? false,
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
  );

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;
}

class LocalStorageService {
  static const _kThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _kNotifPref = 'notification_pref'; // bool
  static const _kDraft = 'letter_draft'; // json string
  static const _kLastVaultViewedAt = 'last_vault_viewed_at'; // iso string

  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Theme
  String getThemeMode() => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  // Notification preference
  bool getNotificationsEnabled() => _prefs.getBool(_kNotifPref) ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(_kNotifPref, v);

  // Draft
  LetterDraft? getDraft() {
    final raw = _prefs.getString(_kDraft);
    if (raw == null) return null;
    try {
      return LetterDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(LetterDraft draft) =>
      _prefs.setString(_kDraft, jsonEncode(draft.toJson()));

  Future<void> clearDraft() => _prefs.remove(_kDraft);

  // Last viewed (used to highlight newly-unlocked letters)
  DateTime? getLastVaultViewedAt() {
    final v = _prefs.getString(_kLastVaultViewedAt);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLastVaultViewedAt(DateTime at) =>
      _prefs.setString(_kLastVaultViewedAt, at.toIso8601String());
}
