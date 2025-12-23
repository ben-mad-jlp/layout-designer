import 'package:flutter/foundation.dart';
import 'package:layout_designer/models/box.dart';

class LayoutProvider extends ChangeNotifier {
  Box root;

  LayoutProvider() : root = Box(name: 'root', stretch: true);

  List<int> _selectedBoxPath = [];

  List<int> get selectedBoxPath => _selectedBoxPath;

  /// Get the currently selected box, or null if none selected.
  Box? get selectedBox {
    if (_selectedBoxPath.isEmpty) {
      return root;
    }
    return _getBoxAtPath(_selectedBoxPath);
  }

  /// Navigate to a box by path (list of child indices).
  void selectBox(List<int> path) {
    _selectedBoxPath = path;
    notifyListeners();
  }

  /// Split the selected box horizontally or vertically.
  void splitSelected(SplitDirection direction) {
    root = _updateBoxAtPath(_selectedBoxPath, (box) => box.splitBox(direction));
    notifyListeners();
  }

  /// Split the selected box in a directional manner (adds new parent).
  void splitSelectedDirectional(DirectionalSplit direction) {
    if (_selectedBoxPath.isEmpty) {
      // Splitting root - replace root entirely
      root = root.splitDirectional(direction);
      _selectedBoxPath = [];
    } else {
      // Splitting a child - update the tree
      root = _updateBoxAtPath(_selectedBoxPath, (box) => box.splitDirectional(direction));
    }
    notifyListeners();
  }

  /// Update the name of the selected box.
  void updateSelectedName(String newName) {
    root = _updateBoxAtPath(_selectedBoxPath, (box) {
      return Box(
        name: newName,
        split: box.split,
        size: box.size,
        stretch: box.stretch,
        children: box.children,
      );
    });
    notifyListeners();
  }

  /// Update the selected box's size (if fixed) or set it to stretch.
  void updateSelectedSize(int? size) {
    if (_selectedBoxPath.isEmpty) {
      throw Exception('Cannot modify root box size');
    }

    final parentPath = _selectedBoxPath.sublist(0, _selectedBoxPath.length - 1);
    final childIndex = _selectedBoxPath.last;

    root = _updateBoxAtPath(parentPath, (parent) {
      return parent.setChildFixed(childIndex, size != null, size);
    });
    notifyListeners();
  }

  /// Delete the split of the selected box (unsplit it).
  void deleteSelectedSplit() {
    if (_selectedBoxPath.isEmpty) {
      throw Exception('Cannot delete root split');
    }

    final selectedBox = this.selectedBox;
    if (selectedBox == null || selectedBox.split == null) {
      throw Exception('Cannot delete split of a box that is not split');
    }

    // Create a new box with the same properties but no split
    final unsplitBox = Box(
      name: selectedBox.name,
      stretch: selectedBox.stretch,
      size: selectedBox.size,
    );

    root = _updateBoxAtPath(_selectedBoxPath, (_) => unsplitBox);
    notifyListeners();
  }

  /// Export the current layout to JSON.
  Map<String, dynamic> exportJson() {
    return root.toJson();
  }

  /// Import a layout from JSON.
  void importJson(Map<String, dynamic> json) {
    try {
      root = Box.fromJson(json);
      _selectedBoxPath = [];
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid JSON: $e');
    }
  }

  /// Helper: Get a box at a specific path.
  Box? _getBoxAtPath(List<int> path) {
    Box current = root;
    for (final index in path) {
      if (current.children == null || index >= current.children!.length) {
        return null;
      }
      current = current.children![index];
    }
    return current;
  }

  /// Helper: Update a box at a specific path and return the new root.
  Box _updateBoxAtPath(
    List<int> path,
    Box Function(Box) update,
  ) {
    if (path.isEmpty) {
      return update(root);
    }

    return _updateBoxRecursive(root, path, 0, update);
  }

  Box _updateBoxRecursive(
    Box current,
    List<int> path,
    int depth,
    Box Function(Box) update,
  ) {
    if (depth == path.length - 1) {
      final childIndex = path[depth];
      if (current.children == null || childIndex >= current.children!.length) {
        throw Exception('Invalid path');
      }
      final updatedChild = update(current.children![childIndex]);
      final newChildren = [...current.children!];
      newChildren[childIndex] = updatedChild;
      return Box(
        name: current.name,
        split: current.split,
        size: current.size,
        stretch: current.stretch,
        children: newChildren,
      );
    }

    final childIndex = path[depth];
    if (current.children == null || childIndex >= current.children!.length) {
      throw Exception('Invalid path');
    }
    final updatedChild = _updateBoxRecursive(
      current.children![childIndex],
      path,
      depth + 1,
      update,
    );
    final newChildren = [...current.children!];
    newChildren[childIndex] = updatedChild;
    return Box(
      name: current.name,
      split: current.split,
      size: current.size,
      stretch: current.stretch,
      children: newChildren,
    );
  }
}
