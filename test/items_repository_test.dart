import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:items/data/items_repository.dart';
import 'package:items/models/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an empty store has no items', () async {
    expect(await ItemsRepository().load(), isEmpty);
  });

  test('persists title, multiline body and timestamp, newest first', () async {
    final repository = ItemsRepository();
    final created = DateTime.utc(2026, 1, 2, 3, 4);
    await repository.add(
      Item(title: 'First', body: 'Line one\nLine two ☕', createdAt: created),
    );
    await repository.add(
      Item(
        title: 'Second',
        body: 'Another note',
        createdAt: created.add(const Duration(hours: 1)),
      ),
    );

    final restored = await ItemsRepository().load();
    expect(restored.map((item) => item.title), ['Second', 'First']);
    expect(restored.last.body, 'Line one\nLine two ☕');
    expect(restored.last.createdAt, created);
    final preferences = await SharedPreferences.getInstance();
    final json = jsonDecode(preferences.getString(ItemsRepository.storageKey)!);
    expect(json, hasLength(2));
  });

  test('invalid stored data is reported and never overwritten', () async {
    for (final data in [
      'broken json',
      '{}',
      '[null]',
      '[{"title":"Missing fields"}]',
    ]) {
      SharedPreferences.setMockInitialValues({
        ItemsRepository.storageKey: data,
      });
      final repository = ItemsRepository();
      await expectLater(repository.load(), throwsFormatException);
      await expectLater(
        repository.add(
          Item(title: 'New', body: 'Text', createdAt: DateTime.utc(2026)),
        ),
        throwsFormatException,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(ItemsRepository.storageKey), data);
    }
  });
}
