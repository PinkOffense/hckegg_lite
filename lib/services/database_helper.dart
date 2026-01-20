import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chicken.dart';
import '../models/egg.dart';
import '../models/vaccine.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chicken_coop.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Chickens table
    await db.execute('''
      CREATE TABLE chickens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        breed TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        photo_path TEXT,
        sex TEXT NOT NULL,
        color TEXT,
        parent_male TEXT,
        parent_female TEXT,
        health_notes TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Eggs table
    await db.execute('''
      CREATE TABLE eggs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chicken_id INTEGER NOT NULL,
        lay_date TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        is_clutch INTEGER NOT NULL DEFAULT 0,
        expected_hatch_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chicken_id) REFERENCES chickens (id) ON DELETE CASCADE
      )
    ''');

    // Vaccines table
    await db.execute('''
      CREATE TABLE vaccines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chicken_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        vaccination_date TEXT NOT NULL,
        next_due_date TEXT,
        administered_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (chicken_id) REFERENCES chickens (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== CHICKEN OPERATIONS ====================

  Future<int> insertChicken(Chicken chicken) async {
    final db = await database;
    return await db.insert('chickens', chicken.toMap());
  }

  Future<List<Chicken>> getAllChickens() async {
    final db = await database;
    final result = await db.query('chickens', orderBy: 'name ASC');
    return result.map((map) => Chicken.fromMap(map)).toList();
  }

  Future<Chicken?> getChicken(int id) async {
    final db = await database;
    final result = await db.query(
      'chickens',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Chicken.fromMap(result.first);
  }

  Future<List<Chicken>> searchChickens(String query) async {
    final db = await database;
    final result = await db.query(
      'chickens',
      where: 'name LIKE ? OR breed LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Chicken.fromMap(map)).toList();
  }

  Future<List<Chicken>> getChickensByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'chickens',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'name ASC',
    );
    return result.map((map) => Chicken.fromMap(map)).toList();
  }

  Future<List<Chicken>> getChickensBySex(String sex) async {
    final db = await database;
    final result = await db.query(
      'chickens',
      where: 'sex = ?',
      whereArgs: [sex],
      orderBy: 'name ASC',
    );
    return result.map((map) => Chicken.fromMap(map)).toList();
  }

  Future<int> updateChicken(Chicken chicken) async {
    final db = await database;
    return await db.update(
      'chickens',
      chicken.toMap(),
      where: 'id = ?',
      whereArgs: [chicken.id],
    );
  }

  Future<int> deleteChicken(int id) async {
    final db = await database;
    return await db.delete(
      'chickens',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getChickenStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chickens'),
    ) ?? 0;
    final healthy = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chickens WHERE status = ?', ['Saudável']),
    ) ?? 0;
    final laying = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chickens WHERE status = ?', ['Botando']),
    ) ?? 0;
    final males = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chickens WHERE sex = ?', ['Macho']),
    ) ?? 0;
    final females = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chickens WHERE sex = ?', ['Fêmea']),
    ) ?? 0;

    return {
      'total': total,
      'healthy': healthy,
      'laying': laying,
      'males': males,
      'females': females,
    };
  }

  // ==================== EGG OPERATIONS ====================

  Future<int> insertEgg(Egg egg) async {
    final db = await database;
    return await db.insert('eggs', egg.toMap());
  }

  Future<List<Egg>> getAllEggs() async {
    final db = await database;
    final result = await db.query('eggs', orderBy: 'lay_date DESC');
    return result.map((map) => Egg.fromMap(map)).toList();
  }

  Future<List<Egg>> getEggsByChicken(int chickenId) async {
    final db = await database;
    final result = await db.query(
      'eggs',
      where: 'chicken_id = ?',
      whereArgs: [chickenId],
      orderBy: 'lay_date DESC',
    );
    return result.map((map) => Egg.fromMap(map)).toList();
  }

  Future<List<Egg>> getEggsInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'eggs',
      where: 'lay_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'lay_date DESC',
    );
    return result.map((map) => Egg.fromMap(map)).toList();
  }

  Future<int> getTotalEggCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM eggs',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<int, int>> getEggProductionByChicken() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT chicken_id, SUM(quantity) as total FROM eggs GROUP BY chicken_id',
    );
    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['chicken_id'] as int,
        row['total'] as int,
      )),
    );
  }

  Future<int> updateEgg(Egg egg) async {
    final db = await database;
    return await db.update(
      'eggs',
      egg.toMap(),
      where: 'id = ?',
      whereArgs: [egg.id],
    );
  }

  Future<int> deleteEgg(int id) async {
    final db = await database;
    return await db.delete(
      'eggs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== VACCINE OPERATIONS ====================

  Future<int> insertVaccine(Vaccine vaccine) async {
    final db = await database;
    return await db.insert('vaccines', vaccine.toMap());
  }

  Future<List<Vaccine>> getAllVaccines() async {
    final db = await database;
    final result = await db.query('vaccines', orderBy: 'vaccination_date DESC');
    return result.map((map) => Vaccine.fromMap(map)).toList();
  }

  Future<List<Vaccine>> getVaccinesByChicken(int chickenId) async {
    final db = await database;
    final result = await db.query(
      'vaccines',
      where: 'chicken_id = ?',
      whereArgs: [chickenId],
      orderBy: 'vaccination_date DESC',
    );
    return result.map((map) => Vaccine.fromMap(map)).toList();
  }

  Future<List<Vaccine>> getDueVaccines() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'vaccines',
      where: 'next_due_date IS NOT NULL AND next_due_date <= ?',
      whereArgs: [now],
      orderBy: 'next_due_date ASC',
    );
    return result.map((map) => Vaccine.fromMap(map)).toList();
  }

  Future<int> updateVaccine(Vaccine vaccine) async {
    final db = await database;
    return await db.update(
      'vaccines',
      vaccine.toMap(),
      where: 'id = ?',
      whereArgs: [vaccine.id],
    );
  }

  Future<int> deleteVaccine(int id) async {
    final db = await database;
    return await db.delete(
      'vaccines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> insertDummyData() async {
    // Insert dummy chickens
    await insertChicken(Chicken(
      name: 'Galinha Pintadinha',
      breed: 'Plymouth Rock',
      birthDate: DateTime.now().subtract(const Duration(days: 365)),
      sex: 'Fêmea',
      color: 'Branco e Preto',
      status: 'Botando',
      healthNotes: 'Saudável e ativa',
    ));

    await insertChicken(Chicken(
      name: 'Dona Clotilde',
      breed: 'Leghorn',
      birthDate: DateTime.now().subtract(const Duration(days: 730)),
      sex: 'Fêmea',
      color: 'Branco',
      status: 'Saudável',
      healthNotes: 'Galinha experiente',
    ));

    await insertChicken(Chicken(
      name: 'Galo Carijó',
      breed: 'Caipira',
      birthDate: DateTime.now().subtract(const Duration(days: 500)),
      sex: 'Macho',
      color: 'Marrom e Preto',
      status: 'Saudável',
      healthNotes: 'Líder do galinheiro',
    ));

    await insertChicken(Chicken(
      name: 'Maria Frangolina',
      breed: 'Rhode Island Red',
      birthDate: DateTime.now().subtract(const Duration(days: 200)),
      sex: 'Fêmea',
      color: 'Vermelho',
      status: 'Botando',
      healthNotes: 'Boa produtora',
    ));

    // Insert dummy eggs
    final chickens = await getAllChickens();
    if (chickens.isNotEmpty) {
      for (var chicken in chickens.where((c) => c.sex == 'Fêmea')) {
        if (chicken.id != null) {
          for (int i = 0; i < 5; i++) {
            await insertEgg(Egg(
              chickenId: chicken.id!,
              layDate: DateTime.now().subtract(Duration(days: i)),
              quantity: 1,
            ));
          }
        }
      }
    }

    // Insert dummy vaccines
    if (chickens.isNotEmpty) {
      await insertVaccine(Vaccine(
        name: 'Newcastle',
        description: 'Vacina contra doença de Newcastle',
        vaccinationDate: DateTime.now().subtract(const Duration(days: 30)),
        nextDueDate: DateTime.now().add(const Duration(days: 90)),
        administeredBy: 'Veterinário Local',
      ));

      await insertVaccine(Vaccine(
        name: 'Marek',
        description: 'Vacina contra doença de Marek',
        vaccinationDate: DateTime.now().subtract(const Duration(days: 60)),
        nextDueDate: DateTime.now().add(const Duration(days: 305)),
        administeredBy: 'Veterinário Local',
      ));
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
