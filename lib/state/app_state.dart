import 'dart:math';
import 'package:flutter/material.dart';
import '../models/egg.dart';

class AppState extends ChangeNotifier {
  final List<Egg> _eggs = List.generate(
    8,
        (i) => Egg(
      id: i + 1,
      tag: 'Batch-${i + 1}',
      createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(30))),
      weight: 50 + Random().nextInt(150),
      synced: i % 3 == 0,
    ),
  );

  final List<int> _syncQueue = [];

  List<Egg> get eggs => List.unmodifiable(_eggs);
  List<int> get syncQueue => List.unmodifiable(_syncQueue);

  void addEgg(Egg egg) {
    _eggs.insert(0, egg);
    _syncQueue.add(egg.id);
    notifyListeners();
  }

  void updateEgg(Egg updated) {
    final idx = _eggs.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _eggs[idx] = updated;
      if (!updated.synced && !_syncQueue.contains(updated.id)) _syncQueue.add(updated.id);
      notifyListeners();
    }
  }

  void markSynced(int id) {
    final idx = _eggs.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _eggs[idx] = _eggs[idx].copyWith(synced: true);
    }
    _syncQueue.remove(id);
    notifyListeners();
  }

  Future<void> performMockSync({Duration perItem = const Duration(seconds: 1)}) async {
    final toSync = List<int>.from(_syncQueue);
    for (final id in toSync) {
      await Future.delayed(perItem);
      markSynced(id);
    }
  }

  List<Egg> search(String q) {
    if (q.isEmpty) return eggs;
    return eggs.where((e) => e.tag.toLowerCase().contains(q.toLowerCase())).toList();
  }
}
