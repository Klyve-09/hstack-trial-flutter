import 'package:material_ui/material_ui.dart';

import '../data/items_repository.dart';
import '../models/item.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, required this.repository});

  final ItemsRepository repository;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.add(
        Item(
          title: _title.text.trim(),
          body: _body.text.trim(),
          createdAt: DateTime.now().toUtc(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your item. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('New item')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a title.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _body,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Body',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 6,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter some text.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save item'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
