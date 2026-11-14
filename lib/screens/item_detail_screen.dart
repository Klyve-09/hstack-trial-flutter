import 'package:material_ui/material_ui.dart';

import '../models/item.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final created = item.createdAt.toLocal();
    final date = MaterialLocalizations.of(context);
    final timestamp =
        '${date.formatMediumDate(created)} · '
        '${date.formatTimeOfDay(TimeOfDay.fromDateTime(created))}';

    return Scaffold(
      appBar: AppBar(title: const Text('Item detail')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Created $timestamp',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                SelectableText(
                  item.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
