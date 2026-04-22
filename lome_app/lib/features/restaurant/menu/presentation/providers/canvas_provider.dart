import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/canvas_element.dart';

// ---------------------------------------------------------------------------
// Canvas State
// ---------------------------------------------------------------------------

@immutable
class CanvasState {
  final List<CanvasElement> elements;
  final String? selectedElementId;
  final String backgroundColor;
  final bool hasUnsavedChanges;
  final bool showGrid;

  const CanvasState({
    this.elements = const [],
    this.selectedElementId,
    this.backgroundColor = '#FFFFFF',
    this.hasUnsavedChanges = false,
    this.showGrid = false,
  });

  CanvasState copyWith({
    List<CanvasElement>? elements,
    String? selectedElementId,
    bool clearSelection = false,
    String? backgroundColor,
    bool? hasUnsavedChanges,
    bool? showGrid,
  }) {
    return CanvasState(
      elements: elements ?? this.elements,
      selectedElementId: clearSelection
          ? null
          : (selectedElementId ?? this.selectedElementId),
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      showGrid: showGrid ?? this.showGrid,
    );
  }

  CanvasElement? get selectedElement {
    if (selectedElementId == null) return null;
    final idx = elements.indexWhere((e) => e.id == selectedElementId);
    return idx == -1 ? null : elements[idx];
  }

  List<CanvasElement> get sortedElements {
    final sorted = List<CanvasElement>.from(elements);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sorted;
  }
}

// ---------------------------------------------------------------------------
// Canvas Notifier
// ---------------------------------------------------------------------------

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  // Undo / redo stacks
  final List<CanvasState> _undoStack = [];
  final List<CanvasState> _redoStack = [];
  static const _maxHistory = 30;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndo() {
    _undoStack.add(state);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state);
    state = _undoStack.removeLast();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state);
    state = _redoStack.removeLast();
  }

  // ---- Element operations --------------------------------------------------

  void addElement(CanvasElement element) {
    _pushUndo();
    state = state.copyWith(
      elements: [...state.elements, element],
      selectedElementId: element.id,
      hasUnsavedChanges: true,
    );
  }

  void removeElement(String id) {
    _pushUndo();
    state = state.copyWith(
      elements: state.elements.where((e) => e.id != id).toList(),
      clearSelection: state.selectedElementId == id,
      hasUnsavedChanges: true,
    );
  }

  void removeElements(List<String> ids) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _pushUndo();
    state = state.copyWith(
      elements: state.elements.where((e) => !idSet.contains(e.id)).toList(),
      clearSelection: state.selectedElementId != null && idSet.contains(state.selectedElementId),
      hasUnsavedChanges: true,
    );
  }

  void duplicateElement(String id) {
    final original = state.elements.where((e) => e.id == id).firstOrNull;
    if (original == null) return;
    _pushUndo();
    final copy = CanvasElement(
      id: UniqueKey().toString(),
      type: original.type,
      x: original.x + 15,
      y: original.y + 15,
      width: original.width,
      height: original.height,
      rotation: original.rotation,
      zIndex: _nextZIndex,
      locked: false,
      props: Map<String, dynamic>.from(original.props),
    );
    state = state.copyWith(
      elements: [...state.elements, copy],
      selectedElementId: copy.id,
      hasUnsavedChanges: true,
    );
  }

  List<String> duplicateElements(List<String> ids) {
    if (ids.isEmpty) return const [];
    final idSet = ids.toSet();
    final originals = state.sortedElements.where((e) => idSet.contains(e.id)).toList();
    if (originals.isEmpty) return const [];

    _pushUndo();
    final nextBase = _nextZIndex;
    final copies = <CanvasElement>[];

    for (var i = 0; i < originals.length; i++) {
      final original = originals[i];
      copies.add(
        CanvasElement(
          id: UniqueKey().toString(),
          type: original.type,
          x: original.x + 18,
          y: original.y + 18,
          width: original.width,
          height: original.height,
          rotation: original.rotation,
          zIndex: nextBase + i,
          locked: false,
          props: Map<String, dynamic>.from(original.props),
        ),
      );
    }

    state = state.copyWith(
      elements: [...state.elements, ...copies],
      selectedElementId: copies.first.id,
      hasUnsavedChanges: true,
    );
    return copies.map((e) => e.id).toList();
  }

  void updateElement(String id, CanvasElement Function(CanvasElement) updater) {
    _pushUndo();
    state = state.copyWith(
      elements: state.elements.map((e) => e.id == id ? updater(e) : e).toList(),
      hasUnsavedChanges: true,
    );
  }

  /// Live update for high-frequency UI interactions such as typing/sliders.
  /// Caller is responsible for pushing undo before the interaction starts.
  void updateElementLive(
    String id,
    CanvasElement Function(CanvasElement) updater,
  ) {
    state = state.copyWith(
      elements: state.elements.map((e) => e.id == id ? updater(e) : e).toList(),
      hasUnsavedChanges: true,
    );
  }

  /// Lightweight move – does NOT push undo (called per pan frame).
  void moveElement(String id, double dx, double dy) {
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (e.id != id || e.locked) return e;
        return e.copyWith(
          x: (e.x + dx).clamp(-e.width / 2, kCanvasWidth - e.width / 2),
          y: (e.y + dy).clamp(-e.height / 2, kCanvasHeight - e.height / 2),
        );
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  void moveElements(List<String> ids, double dx, double dy) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (!idSet.contains(e.id) || e.locked) return e;
        return e.copyWith(
          x: (e.x + dx).clamp(-e.width / 2, kCanvasWidth - e.width / 2),
          y: (e.y + dy).clamp(-e.height / 2, kCanvasHeight - e.height / 2),
        );
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  /// Push undo snapshot when drag starts.
  void beginDrag() => _pushUndo();

  void rotateElement(String id, double angleDeg) {
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (e.id != id || e.locked) return e;
        return e.copyWith(rotation: angleDeg % 360);
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  void resizeElement(String id, double w, double h) {
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (e.id != id || e.locked) return e;
        return e.copyWith(
          width: w.clamp(30, kCanvasWidth),
          height: h.clamp(20, kCanvasHeight),
        );
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  void selectElement(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedElementId: id);
    }
  }

  void bringToFront(String id) {
    _pushUndo();
    final maxZ = _nextZIndex;
    state = state.copyWith(
      elements: state.elements
          .map((e) => e.id == id ? e.copyWith(zIndex: maxZ) : e)
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void bringToFrontMany(List<String> ids) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _pushUndo();
    var nextZ = _nextZIndex;
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (!idSet.contains(e.id)) return e;
        final updated = e.copyWith(zIndex: nextZ);
        nextZ += 1;
        return updated;
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  void sendToBack(String id) {
    _pushUndo();
    final minZ =
        state.elements.fold<int>(0, (v, e) => e.zIndex < v ? e.zIndex : v) - 1;
    state = state.copyWith(
      elements: state.elements
          .map((e) => e.id == id ? e.copyWith(zIndex: minZ) : e)
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void sendToBackMany(List<String> ids) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _pushUndo();
    var nextZ =
        state.elements.fold<int>(0, (v, e) => e.zIndex < v ? e.zIndex : v) -
        ids.length;
    state = state.copyWith(
      elements: state.elements.map((e) {
        if (!idSet.contains(e.id)) return e;
        final updated = e.copyWith(zIndex: nextZ);
        nextZ += 1;
        return updated;
      }).toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsLeft(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final left = selected.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    state = state.copyWith(
      elements: state.elements
          .map((e) => idSet.contains(e.id) ? e.copyWith(x: left) : e)
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsCenterX(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final left = selected.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    final right = selected
        .map((e) => e.x + e.width)
        .reduce((a, b) => a > b ? a : b);
    final center = (left + right) / 2;
    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => idSet.contains(e.id)
                ? e.copyWith(x: center - e.width / 2)
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsRight(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final right = selected
        .map((e) => e.x + e.width)
        .reduce((a, b) => a > b ? a : b);
    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => idSet.contains(e.id)
                ? e.copyWith(x: right - e.width)
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsTop(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final top = selected.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    state = state.copyWith(
      elements: state.elements
          .map((e) => idSet.contains(e.id) ? e.copyWith(y: top) : e)
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsMiddleY(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final top = selected.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final bottom = selected
        .map((e) => e.y + e.height)
        .reduce((a, b) => a > b ? a : b);
    final center = (top + bottom) / 2;
    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => idSet.contains(e.id)
                ? e.copyWith(y: center - e.height / 2)
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void alignElementsBottom(List<String> ids) {
    if (ids.length < 2) return;
    final idSet = ids.toSet();
    final selected = state.elements.where((e) => idSet.contains(e.id)).toList();
    if (selected.length < 2) return;
    _pushUndo();
    final bottom = selected
        .map((e) => e.y + e.height)
        .reduce((a, b) => a > b ? a : b);
    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => idSet.contains(e.id)
                ? e.copyWith(y: bottom - e.height)
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void distributeElementsHorizontally(List<String> ids) {
    if (ids.length < 3) return;
    final idSet = ids.toSet();
    final selected = state.elements
        .where((e) => idSet.contains(e.id))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    if (selected.length < 3) return;
    _pushUndo();
    final left = selected.first.x;
    final right = selected.last.x + selected.last.width;
    final totalWidth = selected.fold<double>(0, (sum, e) => sum + e.width);
    final gap = (right - left - totalWidth) / (selected.length - 1);

    final positions = <String, double>{};
    var cursor = left;
    for (final element in selected) {
      positions[element.id] = cursor;
      cursor += element.width + gap;
    }

    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => positions.containsKey(e.id)
                ? e.copyWith(x: positions[e.id])
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  void distributeElementsVertically(List<String> ids) {
    if (ids.length < 3) return;
    final idSet = ids.toSet();
    final selected = state.elements
        .where((e) => idSet.contains(e.id))
        .toList()
      ..sort((a, b) => a.y.compareTo(b.y));
    if (selected.length < 3) return;
    _pushUndo();
    final top = selected.first.y;
    final bottom = selected.last.y + selected.last.height;
    final totalHeight = selected.fold<double>(0, (sum, e) => sum + e.height);
    final gap = (bottom - top - totalHeight) / (selected.length - 1);

    final positions = <String, double>{};
    var cursor = top;
    for (final element in selected) {
      positions[element.id] = cursor;
      cursor += element.height + gap;
    }

    state = state.copyWith(
      elements: state.elements
          .map(
            (e) => positions.containsKey(e.id)
                ? e.copyWith(y: positions[e.id])
                : e,
          )
          .toList(),
      hasUnsavedChanges: true,
    );
  }

  int get _nextZIndex =>
      state.elements.fold<int>(0, (v, e) => e.zIndex > v ? e.zIndex : v) + 1;

  // ---- Canvas operations ---------------------------------------------------

  void setBackground(String hex) {
    _pushUndo();
    state = state.copyWith(backgroundColor: hex, hasUnsavedChanges: true);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void clearCanvas() {
    _pushUndo();
    state = state.copyWith(
      elements: [],
      clearSelection: true,
      hasUnsavedChanges: true,
    );
  }

  // ---- Template application ------------------------------------------------

  void applyTemplate(List<CanvasElement> elements, String background) {
    _pushUndo();
    state = CanvasState(
      elements: elements,
      backgroundColor: background,
      hasUnsavedChanges: true,
      showGrid: state.showGrid,
    );
  }

  // ---- Persistence ---------------------------------------------------------

  void loadFromJson(Map<String, dynamic> json) {
    final raw = json['canvasElements'] as List<dynamic>? ?? [];
    final bg = json['canvasBackground'] as String? ?? '#FFFFFF';
    state = CanvasState(
      elements: raw
          .map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      backgroundColor: bg,
    );
    _undoStack.clear();
    _redoStack.clear();
  }

  Map<String, dynamic> toJson() => {
    'canvasElements': state.elements.map((e) => e.toJson()).toList(),
    'canvasBackground': state.backgroundColor,
  };

  void markSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final canvasProvider =
    StateNotifierProvider.autoDispose<CanvasNotifier, CanvasState>(
      (ref) => CanvasNotifier(),
    );

final selectedCanvasElementProvider = Provider.autoDispose<CanvasElement?>(
  (ref) => ref.watch(canvasProvider).selectedElement,
);
