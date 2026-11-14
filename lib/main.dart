import 'package:material_ui/material_ui.dart';

import 'data/items_repository.dart';
import 'screens/items_screen.dart';

void main() => runApp(ItemsApp(repository: ItemsRepository()));

class ItemsApp extends StatelessWidget {
  const ItemsApp({super.key, required this.repository});

  final ItemsRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Items',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF42665B)),
      ),
      home: ItemsScreen(repository: repository),
    );
  }
}
