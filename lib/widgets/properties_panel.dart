import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:layout_designer/models/box.dart';
import 'package:layout_designer/providers/layout_provider.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({Key? key}) : super(key: key);

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  List<int> _lastSelectedPath = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _sizeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutProvider>(
      builder: (context, provider, _) {
        final selectedBox = provider.selectedBox;
        if (selectedBox == null) {
          return const Center(child: Text('No box selected'));
        }

        // Only update controllers if selection changed
        if (provider.selectedBoxPath != _lastSelectedPath) {
          _lastSelectedPath = provider.selectedBoxPath;
          _nameController.text = selectedBox.name;
          _sizeController.text = selectedBox.size?.toString() ?? '';
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  provider.updateSelectedName(value);
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Fixed Size'),
                value: !selectedBox.stretch,
                onChanged: (value) {
                  if (value == true) {
                    provider.updateSelectedSize(100);
                  } else {
                    provider.updateSelectedSize(null);
                  }
                },
              ),
              if (!selectedBox.stretch)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _sizeController,
                    decoration: const InputDecoration(labelText: 'Size (px)'),
                    onChanged: (value) {
                      final size = int.tryParse(value);
                      if (size != null && size > 0) {
                        provider.updateSelectedSize(size);
                      }
                    },
                  ),
                ),
              const SizedBox(height: 24),
              const Text('Split Box', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.splitSelected(SplitDirection.horizontal);
                  },
                  child: const Text('Split Horizontal'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.splitSelected(SplitDirection.vertical);
                  },
                  child: const Text('Split Vertical'),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedBox.split != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        provider.deleteSelectedSplit();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: const Text('Delete Split'),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Directional Split', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.splitSelectedDirectional(DirectionalSplit.up);
                      },
                      child: const Text('↑ Up'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.splitSelectedDirectional(DirectionalSplit.down);
                      },
                      child: const Text('↓ Down'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.splitSelectedDirectional(DirectionalSplit.left);
                      },
                      child: const Text('← Left'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.splitSelectedDirectional(DirectionalSplit.right);
                      },
                      child: const Text('→ Right'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
