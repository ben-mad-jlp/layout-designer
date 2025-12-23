import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:layout_designer/providers/layout_provider.dart';
import 'dart:convert';

class ImportExportControls extends StatelessWidget {
  const ImportExportControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _exportToClipboard(context),
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _importFromClipboard(context),
            icon: const Icon(Icons.upload),
            label: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _exportToClipboard(BuildContext context) {
    final provider = Provider.of<LayoutProvider>(context, listen: false);
    final json = provider.exportJson();
    final jsonString = jsonEncode(json);
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Layout exported to clipboard')),
    );
  }

  void _importFromClipboard(BuildContext context) async {
    final provider = Provider.of<LayoutProvider>(context, listen: false);
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) {
      _showError(context, 'No text in clipboard');
      return;
    }

    try {
      final json = jsonDecode(data!.text!) as Map<String, dynamic>;
      provider.importJson(json);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layout imported from clipboard')),
      );
    } catch (e) {
      _showError(context, 'Invalid JSON: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
