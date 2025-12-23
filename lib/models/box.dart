enum SplitDirection { horizontal, vertical }
enum DirectionalSplit { up, down, left, right }

class Box {
  final String name;
  final SplitDirection? split;
  final int? size;
  final bool stretch;
  final List<Box>? children;

  Box({
    required this.name,
    this.split,
    this.size,
    this.stretch = true,
    this.children,
  });

  /// Split this box into two children.
  /// If currently a leaf, creates two children: one fixed (100px), one stretch.
  Box splitBox(SplitDirection direction) {
    if (split != null) {
      throw Exception('Cannot split a box that is already split');
    }

    return Box(
      name: name,
      split: direction,
      stretch: stretch,
      children: [
        Box(name: '${name}_child1', stretch: false, size: 100),
        Box(name: '${name}_child2', stretch: true),
      ],
    );
  }

  /// Split by adding a new parent box above/below/left/right of this box.
  /// Creates a new root with this box as one child and a new empty box as the other.
  Box splitDirectional(DirectionalSplit direction) {
    final newChild = Box(name: '${name}_new', stretch: false, size: 60);

    switch (direction) {
      case DirectionalSplit.up:
        return Box(
          name: '${name}_parent',
          split: SplitDirection.vertical,
          stretch: stretch,
          children: [
            newChild,
            Box(
              name: name,
              split: split,
              size: size,
              stretch: true,
              children: children,
            ),
          ],
        );
      case DirectionalSplit.down:
        return Box(
          name: '${name}_parent',
          split: SplitDirection.vertical,
          stretch: stretch,
          children: [
            Box(
              name: name,
              split: split,
              size: size,
              stretch: true,
              children: children,
            ),
            newChild,
          ],
        );
      case DirectionalSplit.left:
        return Box(
          name: '${name}_parent',
          split: SplitDirection.horizontal,
          stretch: stretch,
          children: [
            newChild,
            Box(
              name: name,
              split: split,
              size: size,
              stretch: true,
              children: children,
            ),
          ],
        );
      case DirectionalSplit.right:
        return Box(
          name: '${name}_parent',
          split: SplitDirection.horizontal,
          stretch: stretch,
          children: [
            Box(
              name: name,
              split: split,
              size: size,
              stretch: true,
              children: children,
            ),
            newChild,
          ],
        );
    }
  }

  /// Set a child to fixed or stretch. Validates that at least one remains stretch.
  Box setChildFixed(int childIndex, bool fixed, int? size) {
    if (children == null || children!.isEmpty) {
      throw Exception('Cannot modify children of a leaf box');
    }
    if (childIndex < 0 || childIndex >= children!.length) {
      throw Exception('Child index out of bounds');
    }

    final updatedChildren = [...children!];
    updatedChildren[childIndex] = Box(
      name: updatedChildren[childIndex].name,
      split: updatedChildren[childIndex].split,
      size: fixed ? size : null,
      stretch: !fixed,
      children: updatedChildren[childIndex].children,
    );

    // Validate: at least one child must be stretch
    final hasStretchChild = updatedChildren.any((c) => c.stretch);
    if (!hasStretchChild) {
      throw Exception('At least one child must be stretch');
    }

    return Box(
      name: name,
      split: split,
      stretch: stretch,
      children: updatedChildren,
    );
  }

  /// Export to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'name': name};

    if (split != null) {
      json['split'] = split == SplitDirection.horizontal ? 'horizontal' : 'vertical';
      json['children'] = children!.map((c) => c.toJson()).toList();
    }

    if (size != null) {
      json['size'] = size;
    }

    if (stretch) {
      json['stretch'] = true;
    }

    return json;
  }

  /// Import from JSON
  factory Box.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final splitStr = json['split'] as String?;
    final size = json['size'] as int?;
    final stretch = json['stretch'] as bool? ?? false;

    SplitDirection? split;
    if (splitStr != null) {
      split = splitStr == 'horizontal'
          ? SplitDirection.horizontal
          : SplitDirection.vertical;
    }

    List<Box>? children;
    if (json['children'] != null) {
      children = (json['children'] as List)
          .map((c) => Box.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return Box(
      name: name,
      split: split,
      size: size,
      stretch: stretch,
      children: children,
    );
  }
}
