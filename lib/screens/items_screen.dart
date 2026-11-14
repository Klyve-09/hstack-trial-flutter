import 'package:material_ui/material_ui.dart';

import '../data/items_repository.dart';
import '../models/item.dart';
import 'compose_screen.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, required this.repository});

  final ItemsRepository repository;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late Future<List<Item>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.repository.load();
  }

  void _reload() {
    setState(() {
      _items = widget.repository.load();
    });
  }

  Future<void> _compose() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposeScreen(repository: widget.repository),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FutureBuilder<List<Item>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load your items.'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No items yet. Write your first note with New item.',
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.add),
        label: const Text('New item'),
      ),
    );
  }
}
