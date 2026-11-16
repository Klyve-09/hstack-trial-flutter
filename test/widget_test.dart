import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:items/data/items_repository.dart';
import 'package:items/data/draft_repository.dart';
import 'package:items/main.dart';
import 'package:items/models/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingRepository extends ItemsRepository {
  @override
  Future<void> add(Item item) async => throw StateError('Storage unavailable');
}

class FailingClearDraftRepository extends DraftRepository {
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    throw StateError('Draft storage unavailable');
  }
}

class FailingSaveDraftRepository extends DraftRepository {
  int saveCalls = 0;

  @override
  Future<void> save(Draft draft) async {
    saveCalls++;
    throw StateError('Draft storage unavailable');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('draft clear failure still saves the item exactly once', (
    tester,
  ) async {
    final drafts = FailingClearDraftRepository();
    await tester.pumpWidget(
      ItemsApp(repository: ItemsRepository(), draftRepository: drafts),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Saved',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Body'),
      'Saved body',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(drafts.clearCalls, 1);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(
      find.text('Could not save your item. Please try again.'),
      findsNothing,
    );
    final stored = await ItemsRepository().load();
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Saved');
    expect(stored.single.body, 'Saved body');
  });

  testWidgets('draft write failures allow typing and saving the item', (
    tester,
  ) async {
    final drafts = FailingSaveDraftRepository();
    await tester.pumpWidget(
      ItemsApp(repository: ItemsRepository(), draftRepository: drafts),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'First',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Saved',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Body'),
      'Saved body',
    );
    await tester.pumpAndSettle();

    expect(drafts.saveCalls, greaterThanOrEqualTo(3));
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Saved body'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(
      find.text('Could not save your item. Please try again.'),
      findsNothing,
    );
    final stored = await ItemsRepository().load();
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Saved');
    expect(stored.single.body, 'Saved body');
  });

  testWidgets('restores raw draft after restart and back returns to list', (
    tester,
  ) async {
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      '  Draft  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Body'),
      'Body\ntext ',
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('  Draft  '), findsOneWidget);
    expect(find.text('Body\ntext '), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Items'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'saving a restored draft reloads list and clears it for restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        DraftRepository.storageKey: '{"title":"Restored","body":"Saved body"}',
      });
      await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Restored'), findsOneWidget);
      await tester.tap(find.text('Save item'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Restored'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Restored'), findsOneWidget);
      await tester.tap(find.text('New item'));
      await tester.pumpAndSettle();
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.controller!.text, isEmpty);
      }
    },
  );

  testWidgets('deleting all draft text removes the stored draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      DraftRepository.storageKey: '{"title":"Delete me","body":"Body"}',
    });
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), '  ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Body'), '\n ');
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(DraftRepository.storageKey), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
  });

  for (final unreadable in [
    'invalid JSON',
    '[]',
    '{"title":4,"body":"text"}',
    42,
  ]) {
    testWidgets('unreadable draft $unreadable does not block list or compose', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        DraftRepository.storageKey: unreadable,
        ItemsRepository.storageKey: '[{"title":"Existing","body":"Note","createdAt":"2026-01-01T00:00:00Z"}]',
      });
      await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Existing'), findsOneWidget);
      await tester.tap(find.text('New item'));
      await tester.pumpAndSettle();
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.controller!.text, isEmpty);
      }
    });
  }

  testWidgets('draft writes and clear preserve stored items byte for byte', (
    tester,
  ) async {
    const items =
        '[ {"title":"Existing", "body":"Note", "createdAt":"2026-01-01T00:00:00Z"} ]';
    SharedPreferences.setMockInitialValues({ItemsRepository.storageKey: items});
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Draft',
    );
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(ItemsRepository.storageKey), items);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(preferences.getString(ItemsRepository.storageKey), items);
    expect(preferences.containsKey(DraftRepository.storageKey), isFalse);
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), ' ');
    await tester.pumpAndSettle();
    expect(preferences.containsKey(DraftRepository.storageKey), isFalse);
    expect(preferences.getString(ItemsRepository.storageKey), items);
  });

  testWidgets('creates a note, opens its detail and restores it in a new app', (
    tester,
  ) async {
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.textContaining('No items yet.'), findsOneWidget);
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      '  Shopping  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Body'),
      'Apples\nTea',
    );
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();
    expect(find.text('Item detail'), findsOneWidget);
    expect(find.text('Apples\nTea'), findsOneWidget);
    expect(find.textContaining('Created '), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);
  });

  testWidgets('requires title and body; leaving compose does not save', (
    tester,
  ) async {
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
    expect(find.text('Enter some text.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Unsaved',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await ItemsRepository().load(), isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(DraftRepository.storageKey), isFalse);
    expect(find.text('Items'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Items'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved'), findsNothing);
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }
  });

  testWidgets('a save failure keeps entered text available for retry', (
    tester,
  ) async {
    await tester.pumpWidget(ItemsApp(repository: FailingRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Keep me',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Body'),
      'Keep this text',
    );
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your item. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Keep me'), findsOneWidget);
    expect(find.text('Keep this text'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(jsonDecode(preferences.getString(DraftRepository.storageKey)!), {
      'title': 'Keep me',
      'body': 'Keep this text',
    });
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ItemsApp(repository: FailingRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Keep me'), findsOneWidget);
    expect(find.text('Keep this text'), findsOneWidget);
  });

  testWidgets('load failure offers retry without replacing stored data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ItemsRepository.storageKey: 'invalid',
    });
    await tester.pumpWidget(ItemsApp(repository: ItemsRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your items.'), findsOneWidget);
    SharedPreferences.setMockInitialValues({});
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No items yet.'), findsOneWidget);
  });
}
