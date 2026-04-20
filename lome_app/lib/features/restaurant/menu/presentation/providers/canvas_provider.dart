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
      selectedElementId:
          clearSelection ? null : (selectedElementId ?? this.selectedElementId),
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

  void updateElement(String id, CanvasElement Function(CanvasElement) updater) {
    _pushUndo();
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

  /// Push undo snapshot when drag starts.
  void beginDrag() => _pushUndo();

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

  void sendToBack(String id) {
    _pushUndo();
    final minZ = state.elements.fold<int>(0, (v, e) => e.zIndex < v ? e.zIndex : v) - 1;
    state = state.copyWith(
      elements: state.elements
          .map((e) => e.id == id ? e.copyWith(zIndex: minZ) : e)
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
