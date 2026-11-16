import 'package:material_ui/material_ui.dart';

import '../data/items_repository.dart';
import '../data/draft_repository.dart';
import '../models/item.dart';
import 'compose_screen.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  ItemsScreen({
    super.key,
    required this.repository,
    DraftRepository? draftRepository,
  }) : draftRepository = draftRepository ?? DraftRepository();

  final ItemsRepository repository;
  final DraftRepository draftRepository;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late Future<List<Item>> _items;
  bool _openingCompose = false;

  @override
  void initState() {
    super.initState();
    _items = widget.repository.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  void _reload() {
    setState(() {
      _items = widget.repository.load();
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await widget.draftRepository.load();
    if (mounted && draft != null) await _compose();
  }

  Future<void> _compose() async {
    if (_openingCompose) return;
    _openingCompose = true;
    try {
      final draft = await widget.draftRepository.load();
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ComposeScreen(
            repository: widget.repository,
            draftRepository: widget.draftRepository,
            initialDraft: draft,
          ),
        ),
      );
      if (saved == true && mounted) _reload();
    } finally {
      _openingCompose = false;
    }
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
