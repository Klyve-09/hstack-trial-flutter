import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
  final _notes = TextEditingController();
  final _picker = ImagePicker();
  XFile? _labelPhoto;
  bool _scanning = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canScan =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _scanLabel() async {
    if (_saving || _scanning) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (mounted && photo != null) {
        setState(() => _labelPhoto = photo);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the camera. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
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
      canPop: !_saving && !_scanning,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New item'),
          actions: [
            IconButton(
              onPressed: _canScan && !_saving && !_scanning ? _scanLabel : null,
              icon: const Icon(Icons.document_scanner_outlined),
            ),
          ],
        ),
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
                  if (_scanning) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_labelPhoto != null) ...[
                    const SizedBox(height: 12),
                    Image.file(
                      File(_labelPhoto!.path),
                      height: 180,
                      fit: BoxFit.contain,
                      semanticLabel: 'Captured label',
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notes,
                    enabled: !_saving && !_scanning,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Jot down details from the label',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
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
                    onPressed: _saving || _scanning ? null : _save,
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
