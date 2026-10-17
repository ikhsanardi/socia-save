import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentSelectionNotifier extends StateNotifier<Set<int>> {
  ContentSelectionNotifier() : super({});

  void toggle(int id) {
    if (state.contains(id)) {
      final newSet = Set<int>.from(state);
      newSet.remove(id);
      state = newSet;
    } else {
      state = {...state, id};
    }
  }

  void selectAll(List<int> visibleIds) {
    if (state.length == visibleIds.length &&
        visibleIds.every((id) => state.contains(id))) {
      state = {};
    } else {
      state = visibleIds.toSet();
    }
  }

  void clear() {
    if (state.isNotEmpty) {
      state = {};
    }
  }
}

final contentSelectionProvider =
    StateNotifierProvider<ContentSelectionNotifier, Set<int>>((ref) {
  return ContentSelectionNotifier();
});
