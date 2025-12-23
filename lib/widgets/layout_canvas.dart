import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:layout_designer/models/box.dart';
import 'package:layout_designer/providers/layout_provider.dart';

class LayoutCanvas extends StatefulWidget {
  const LayoutCanvas({Key? key}) : super(key: key);

  @override
  State<LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<LayoutCanvas> {
  List<int>? _draggedBorderPath;
  double? _dragStartX;
  double? _dragStartY;
  int? _dragStartSize;

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutProvider>(
      builder: (context, provider, _) {
        return MouseRegion(
          cursor: _draggedBorderPath != null ? SystemMouseCursors.resizeColumn : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (details) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              final path = _hitTest(provider.root, Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height), localPosition, []);
              if (path != null) {
                provider.selectBox(path);
              }
            },
            onPanStart: (details) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              _startDrag(context, provider, localPosition);
            },
            onPanUpdate: (details) {
              if (_draggedBorderPath != null) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                _updateDrag(context, provider, localPosition);
              }
            },
            onPanEnd: (_) {
              _draggedBorderPath = null;
              _dragStartX = null;
              _dragStartY = null;
              _dragStartSize = null;
            },
            child: CustomPaint(
              painter: BoxPainter(
                root: provider.root,
                selectedPath: provider.selectedBoxPath,
              ),
              child: Container(),
            ),
          ),
        );
      },
    );
  }

  void _startDrag(BuildContext context, LayoutProvider provider, Offset localPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final parentPath = _findBorderAtPoint(
      provider.root,
      Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height),
      localPosition,
      [],
    );

    if (parentPath != null) {
      _draggedBorderPath = parentPath;
      final parentBox = _getBoxAtPath(provider.root, parentPath);
      if (parentBox?.split == SplitDirection.horizontal) {
        _dragStartX = localPosition.dx;
        _dragStartSize = parentBox?.children?[0].size ?? 100;
      } else {
        _dragStartY = localPosition.dy;
        _dragStartSize = parentBox?.children?[0].size ?? 100;
      }
    }
  }

  void _updateDrag(BuildContext context, LayoutProvider provider, Offset localPosition) {
    if (_draggedBorderPath == null || _dragStartSize == null) return;

    final parentBox = _getBoxAtPath(provider.root, _draggedBorderPath!);
    if (parentBox == null || parentBox.split == null) return;

    int newSize;
    if (parentBox.split == SplitDirection.horizontal && _dragStartX != null) {
      final delta = localPosition.dx - _dragStartX!;
      newSize = (_dragStartSize! + delta).toInt();
    } else if (parentBox.split == SplitDirection.vertical && _dragStartY != null) {
      final delta = localPosition.dy - _dragStartY!;
      newSize = (_dragStartSize! + delta).toInt();
    } else {
      return;
    }

    if (newSize > 20) {
      try {
        final childIndex = 0;
        provider.selectBox([..._draggedBorderPath!, childIndex]);
        provider.updateSelectedSize(newSize);
      } catch (e) {
        // Ignore constraint violations during drag
      }
    }
  }

  List<int>? _findBorderAtPoint(Box box, Rect rect, Offset point, List<int> path) {
    if (!rect.contains(point)) return null;
    if (box.split == null) return null;

    final children = box.children!;
    final split = box.split!;
    final tolerance = 10.0;

    if (split == SplitDirection.horizontal) {
      final fixed = (children[0].size ?? 100).toDouble();
      final borderX = rect.left + fixed;
      if ((point.dx - borderX).abs() < tolerance) {
        return path;
      }
      final leftRect = Rect.fromLTWH(rect.left, rect.top, fixed, rect.height);
      final rightRect = Rect.fromLTWH(rect.left + fixed, rect.top, rect.width - fixed, rect.height);
      if (leftRect.contains(point)) {
        return _findBorderAtPoint(children[0], leftRect, point, [...path, 0]);
      } else if (rightRect.contains(point)) {
        return _findBorderAtPoint(children[1], rightRect, point, [...path, 1]);
      }
    } else {
      final fixed = (children[0].size ?? 100).toDouble();
      final borderY = rect.top + fixed;
      if ((point.dy - borderY).abs() < tolerance) {
        return path;
      }
      final topRect = Rect.fromLTWH(rect.left, rect.top, rect.width, fixed);
      final bottomRect = Rect.fromLTWH(rect.left, rect.top + fixed, rect.width, rect.height - fixed);
      if (topRect.contains(point)) {
        return _findBorderAtPoint(children[0], topRect, point, [...path, 0]);
      } else if (bottomRect.contains(point)) {
        return _findBorderAtPoint(children[1], bottomRect, point, [...path, 1]);
      }
    }
    return null;
  }

  Box? _getBoxAtPath(Box box, List<int> path) {
    Box current = box;
    for (final index in path) {
      if (current.children == null || index >= current.children!.length) {
        return null;
      }
      current = current.children![index];
    }
    return current;
  }


  List<int>? _hitTest(Box box, Rect rect, Offset point, List<int> path) {
    if (!rect.contains(point)) return null;
    if (box.split == null) return path;

    final children = box.children!;
    final split = box.split!;

    if (split == SplitDirection.horizontal) {
      final fixed = (children[0].size ?? 100).toDouble();
      final leftRect = Rect.fromLTWH(rect.left, rect.top, fixed, rect.height);
      final rightRect = Rect.fromLTWH(rect.left + fixed, rect.top, rect.width - fixed, rect.height);
      if (leftRect.contains(point)) {
        return _hitTest(children[0], leftRect, point, [...path, 0]);
      } else if (rightRect.contains(point)) {
        return _hitTest(children[1], rightRect, point, [...path, 1]);
      }
    } else {
      final fixed = (children[0].size ?? 100).toDouble();
      final topRect = Rect.fromLTWH(rect.left, rect.top, rect.width, fixed);
      final bottomRect = Rect.fromLTWH(rect.left, rect.top + fixed, rect.width, rect.height - fixed);
      if (topRect.contains(point)) {
        return _hitTest(children[0], topRect, point, [...path, 0]);
      } else if (bottomRect.contains(point)) {
        return _hitTest(children[1], bottomRect, point, [...path, 1]);
      }
    }
    return path;
  }
}

class BoxPainter extends CustomPainter {
  static const double padding = 12.0; // Visual padding between boxes
  static const double cornerRadius = 8.0; // Rounded corners

  // Color palette that cycles through boxes
  static const List<Color> boxColors = [
    Color(0xFFE3F2FD), // Light blue
    Color(0xFFF3E5F5), // Light purple
    Color(0xFFE8F5E9), // Light green
    Color(0xFFFFF3E0), // Light orange
    Color(0xFFFCE4EC), // Light pink
  ];

  final Box root;
  final List<int> selectedPath;

  BoxPainter({
    required this.root,
    required this.selectedPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBox(canvas, root, Rect.fromLTWH(0, 0, size.width, size.height), []);
  }

  void _paintBox(Canvas canvas, Box box, Rect rect, List<int> path) {
    final isSelected = path == selectedPath;

    // Draw background with color cycling based on depth
    final colorIndex = path.length % boxColors.length;
    final bgPaint = Paint()
      ..color = boxColors[colorIndex]
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
    canvas.drawRRect(rRect, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1;

    canvas.drawRRect(rRect, borderPaint);

    if (box.split == null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: box.name,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft + const Offset(5, 5));
    } else {
      final children = box.children!;
      final childRects = _splitRect(rect, box.split!, children);
      for (int i = 0; i < children.length; i++) {
        _paintBox(canvas, children[i], childRects[i], [...path, i]);
      }

      // Draw draggable border
      final borderPaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 2;

      if (box.split == SplitDirection.horizontal) {
        final fixed = (children[0].size ?? 100).toDouble();
        final borderX = rect.left + fixed;
        canvas.drawLine(Offset(borderX, rect.top), Offset(borderX, rect.bottom), borderPaint);
      } else {
        final fixed = (children[0].size ?? 100).toDouble();
        final borderY = rect.top + fixed;
        canvas.drawLine(Offset(rect.left, borderY), Offset(rect.right, borderY), borderPaint);
      }
    }
  }

  List<Rect> _splitRect(Rect rect, SplitDirection split, List<Box> children) {
    if (split == SplitDirection.horizontal) {
      final fixed = (children[0].size ?? 100).toDouble();
      return [
        Rect.fromLTWH(rect.left + padding, rect.top + padding, fixed - padding, rect.height - padding),
        Rect.fromLTWH(rect.left + fixed + padding, rect.top + padding, rect.width - fixed - padding, rect.height - padding),
      ];
    } else {
      final fixed = (children[0].size ?? 100).toDouble();
      return [
        Rect.fromLTWH(rect.left + padding, rect.top + padding, rect.width - padding, fixed - padding),
        Rect.fromLTWH(rect.left + padding, rect.top + fixed + padding, rect.width - padding, rect.height - fixed - padding),
      ];
    }
  }

  @override
  bool shouldRepaint(BoxPainter oldDelegate) {
    return oldDelegate.root != root || oldDelegate.selectedPath != selectedPath;
  }
}
