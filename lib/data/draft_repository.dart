import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Draft {
  const Draft({required this.title, required this.body});

  final String title;
  final String body;

  bool get isBlank => title.trim().isEmpty && body.trim().isEmpty;
}

class DraftRepository {
  static const storageKey = 'draft';

  Future<void> _pending = Future<void>.value();

  Future<Draft?> load() async {
    try {
      await _pending;
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(storageKey);
      if (stored == null) return null;
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic> ||
          decoded['title'] is! String ||
          decoded['body'] is! String) {
        return null;
      }
      final draft = Draft(title: decoded['title'], body: decoded['body']);
      return draft.isBlank ? null : draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    // Recover the queue so one storage failure does not prevent later writes.
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<void> save(Draft draft) => _enqueue(() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = draft.isBlank
        ? await preferences.remove(storageKey)
        : await preferences.setString(
            storageKey,
            jsonEncode({'title': draft.title, 'body': draft.body}),
          );
    if (!saved) throw StateError('Could not save draft');
  });

  Future<void> clear() => _enqueue(() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(storageKey)) {
      throw StateError('Could not clear draft');
    }
  });
}
