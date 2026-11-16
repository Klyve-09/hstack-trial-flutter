import 'package:material_ui/material_ui.dart';

import 'data/items_repository.dart';
import 'data/draft_repository.dart';
import 'screens/items_screen.dart';

void main() => runApp(ItemsApp(repository: ItemsRepository()));

class ItemsApp extends StatelessWidget {
  ItemsApp({
    super.key,
    required this.repository,
    DraftRepository? draftRepository,
  }) : draftRepository = draftRepository ?? DraftRepository();

  final ItemsRepository repository;
  final DraftRepository draftRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Items',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF42665B)),
      ),
      home: ItemsScreen(
        repository: repository,
        draftRepository: draftRepository,
      ),
    );
  }
}
