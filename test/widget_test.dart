import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:items/data/items_repository.dart';
import 'package:items/main.dart';
import 'package:items/models/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingRepository extends ItemsRepository {
  @override
  Future<void> add(Item item) async => throw StateError('Storage unavailable');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    await tester.tap(find.text('New item'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved'), findsNothing);
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
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
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
