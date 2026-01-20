import 'package:flutter/material.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../models/vaccine.dart';
import 'database_helper.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Chicken> _chickens = [];
  List<Egg> _eggs = [];
  List<Vaccine> _vaccines = [];
  bool _isLoading = false;
  bool _isDarkMode = false;

  List<Chicken> get chickens => _chickens;
  List<Egg> get eggs => _eggs;
  List<Vaccine> get vaccines => _vaccines;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;

  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ==================== CHICKEN OPERATIONS ====================

  Future<void> loadChickens() async {
    _isLoading = true;
    notifyListeners();

    try {
      _chickens = await _db.getAllChickens();
    } catch (e) {
      debugPrint('Error loading chickens: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChicken(Chicken chicken) async {
    try {
      await _db.insertChicken(chicken);
      await loadChickens();
    } catch (e) {
      debugPrint('Error adding chicken: $e');
      rethrow;
    }
  }

  Future<void> updateChicken(Chicken chicken) async {
    try {
      await _db.updateChicken(chicken);
      await loadChickens();
    } catch (e) {
      debugPrint('Error updating chicken: $e');
      rethrow;
    }
  }

  Future<void> deleteChicken(int id) async {
    try {
      await _db.deleteChicken(id);
      await loadChickens();
    } catch (e) {
      debugPrint('Error deleting chicken: $e');
      rethrow;
    }
  }

  Future<List<Chicken>> searchChickens(String query) async {
    try {
      return await _db.searchChickens(query);
    } catch (e) {
      debugPrint('Error searching chickens: $e');
      return [];
    }
  }

  Future<Map<String, int>> getChickenStats() async {
    try {
      return await _db.getChickenStats();
    } catch (e) {
      debugPrint('Error getting chicken stats: $e');
      return {};
    }
  }

  // ==================== EGG OPERATIONS ====================

  Future<void> loadEggs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _eggs = await _db.getAllEggs();
    } catch (e) {
      debugPrint('Error loading eggs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEgg(Egg egg) async {
    try {
      await _db.insertEgg(egg);
      await loadEggs();
    } catch (e) {
      debugPrint('Error adding egg: $e');
      rethrow;
    }
  }

  Future<void> updateEgg(Egg egg) async {
    try {
      await _db.updateEgg(egg);
      await loadEggs();
    } catch (e) {
      debugPrint('Error updating egg: $e');
      rethrow;
    }
  }

  Future<void> deleteEgg(int id) async {
    try {
      await _db.deleteEgg(id);
      await loadEggs();
    } catch (e) {
      debugPrint('Error deleting egg: $e');
      rethrow;
    }
  }

  Future<List<Egg>> getEggsByChicken(int chickenId) async {
    try {
      return await _db.getEggsByChicken(chickenId);
    } catch (e) {
      debugPrint('Error getting eggs by chicken: $e');
      return [];
    }
  }

  Future<int> getTotalEggCount() async {
    try {
      return await _db.getTotalEggCount();
    } catch (e) {
      debugPrint('Error getting total egg count: $e');
      return 0;
    }
  }

  Future<Map<int, int>> getEggProductionByChicken() async {
    try {
      return await _db.getEggProductionByChicken();
    } catch (e) {
      debugPrint('Error getting egg production by chicken: $e');
      return {};
    }
  }

  // ==================== VACCINE OPERATIONS ====================

  Future<void> loadVaccines() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vaccines = await _db.getAllVaccines();
    } catch (e) {
      debugPrint('Error loading vaccines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVaccine(Vaccine vaccine) async {
    try {
      await _db.insertVaccine(vaccine);
      await loadVaccines();
    } catch (e) {
      debugPrint('Error adding vaccine: $e');
      rethrow;
    }
  }

  Future<void> updateVaccine(Vaccine vaccine) async {
    try {
      await _db.updateVaccine(vaccine);
      await loadVaccines();
    } catch (e) {
      debugPrint('Error updating vaccine: $e');
      rethrow;
    }
  }

  Future<void> deleteVaccine(int id) async {
    try {
      await _db.deleteVaccine(id);
      await loadVaccines();
    } catch (e) {
      debugPrint('Error deleting vaccine: $e');
      rethrow;
    }
  }

  Future<List<Vaccine>> getDueVaccines() async {
    try {
      return await _db.getDueVaccines();
    } catch (e) {
      debugPrint('Error getting due vaccines: $e');
      return [];
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> initializeApp() async {
    await loadChickens();
    await loadEggs();
    await loadVaccines();
  }

  Future<void> loadDummyData() async {
    try {
      await _db.insertDummyData();
      await initializeApp();
    } catch (e) {
      debugPrint('Error loading dummy data: $e');
      rethrow;
    }
  }
}
