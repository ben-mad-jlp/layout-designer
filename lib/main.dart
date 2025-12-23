import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:layout_designer/providers/layout_provider.dart';
import 'package:layout_designer/widgets/layout_canvas.dart';
import 'package:layout_designer/widgets/properties_panel.dart';
import 'package:layout_designer/widgets/import_export_controls.dart';

void main() {
  runApp(const LayoutDesignerApp());
}

class LayoutDesignerApp extends StatelessWidget {
  const LayoutDesignerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LayoutProvider(),
      child: MaterialApp(
        title: 'Layout Designer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LayoutDesignerScreen(),
      ),
    );
  }
}

class LayoutDesignerScreen extends StatelessWidget {
  const LayoutDesignerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layout Designer v2.0'),
        actions: const [ImportExportControls()],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              child: const LayoutCanvas(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: const PropertiesPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
