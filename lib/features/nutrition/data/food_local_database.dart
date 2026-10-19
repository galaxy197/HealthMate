import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nutrition_models.dart';

/// Local SQLite database for food catalog caching
/// Stores USDA foods, user foods, and search history
class FoodLocalDatabase {
  static final FoodLocalDatabase instance = FoodLocalDatabase._init();
  static Database? _database;

  FoodLocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('healthmate_foods.db');
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
    // Food catalog table
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        fdc_id INTEGER,
        name TEXT NOT NULL,
        name_normalized TEXT NOT NULL,
        category TEXT NOT NULL,
        data_source TEXT NOT NULL,
        kcal REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL,
        source_label TEXT NOT NULL,
        is_estimated INTEGER NOT NULL,
        brand TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Full-text search index
    await db.execute('''
      CREATE INDEX idx_foods_name ON foods(name_normalized)
    ''');

    await db.execute('''
      CREATE INDEX idx_foods_fdc ON foods(fdc_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_foods_source ON foods(data_source)
    ''');

    // Recently searched/used foods
    await db.execute('''
      CREATE TABLE recent_foods (
        food_id TEXT PRIMARY KEY,
        last_used INTEGER NOT NULL,
        use_count INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_recent_last_used ON recent_foods(last_used DESC)
    ''');
  }

  /// Normalize text for search
  String _normalize(String text) {
    return text.toLowerCase().trim();
  }

  /// Insert or update food in cache
  Future<void> cacheFood(FoodCatalogItem food) async {
    final db = await database;

    await db.insert(
      'foods',
      {
        'id': food.id,
        'fdc_id': food.fdcId,
        'name': food.name,
        'name_normalized': _normalize(food.name),
        'category': food.category,
        'data_source': food.dataSource.wireValue,
        'kcal': food.kcalPer100g ?? food.nutritionPer100g.kcal,
        'protein': food.proteinGPer100g ?? food.nutritionPer100g.proteinG,
        'carbs': food.carbsGPer100g ?? food.nutritionPer100g.carbsG,
        'fat': food.fatGPer100g ?? food.nutritionPer100g.fatG,
        'fiber': food.fiberGPer100g ?? food.nutritionPer100g.fiberG,
        'source_label': food.sourceLabel,
        'is_estimated': food.isEstimated ? 1 : 0,
        'brand': food.brand,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch insert foods
  Future<void> cacheFoodsBatch(List<FoodCatalogItem> foods) async {
    final db = await database;
    final batch = db.batch();

    for (final food in foods) {
      batch.insert(
        'foods',
        {
          'id': food.id,
          'fdc_id': food.fdcId,
          'name': food.name,
          'name_normalized': _normalize(food.name),
          'category': food.category,
          'data_source': food.dataSource.wireValue,
          'kcal': food.kcalPer100g ?? food.nutritionPer100g.kcal,
          'protein': food.proteinGPer100g ?? food.nutritionPer100g.proteinG,
          'carbs': food.carbsGPer100g ?? food.nutritionPer100g.carbsG,
          'fat': food.fatGPer100g ?? food.nutritionPer100g.fatG,
          'fiber': food.fiberGPer100g ?? food.nutritionPer100g.fiberG,
          'source_label': food.sourceLabel,
          'is_estimated': food.isEstimated ? 1 : 0,
          'brand': food.brand,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Search foods in local cache
  Future<List<FoodCatalogItem>> searchFoods(
    String query, {
    int limit = 25,
    FoodDataSource? filterSource,
  }) async {
    if (query.trim().isEmpty) return [];

    final db = await database;
    final normalized = _normalize(query);

    final where = StringBuffer('name_normalized LIKE ?');
    final whereArgs = <Object>['%$normalized%'];

    if (filterSource != null) {
      where.write(' AND data_source = ?');
      whereArgs.add(filterSource.wireValue);
    }

    final results = await db.query(
      'foods',
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: 'cached_at DESC',
      limit: limit,
    );

    return results.map(_foodFromMap).toList();
  }

  /// Get food by ID
  Future<FoodCatalogItem?> getFoodById(String id) async {
    final db = await database;

    final results = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _foodFromMap(results.first);
  }

  /// Get food by FDC ID
  Future<FoodCatalogItem?> getFoodByFdcId(int fdcId) async {
    final db = await database;

    final results = await db.query(
      'foods',
      where: 'fdc_id = ?',
      whereArgs: [fdcId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _foodFromMap(results.first);
  }

  /// Get recently used foods
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20}) async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT f.*
      FROM foods f
      INNER JOIN recent_foods r ON f.id = r.food_id
      ORDER BY r.last_used DESC
      LIMIT ?
    ''', [limit]);

    return results.map(_foodFromMap).toList();
  }

  /// Mark food as used (for recent list)
  Future<void> markFoodUsed(String foodId) async {
    final db = await database;

    await db.insert(
      'recent_foods',
      {
        'food_id': foodId,
        'last_used': DateTime.now().millisecondsSinceEpoch,
        'use_count': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Clean old cache entries (older than 7 days)
  Future<void> cleanOldCache() async {
    final db = await database;
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;

    await db.delete(
      'foods',
      where: 'cached_at < ? AND data_source = ?',
      whereArgs: [weekAgo, FoodDataSource.usda.wireValue],
    );
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM foods'),
    ) ?? 0;

    final usda = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM foods WHERE data_source = ?',
        [FoodDataSource.usda.wireValue],
      ),
    ) ?? 0;

    final local = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM foods WHERE data_source = ?',
        [FoodDataSource.local.wireValue],
      ),
    ) ?? 0;

    final user = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM foods WHERE data_source = ?',
        [FoodDataSource.user.wireValue],
      ),
    ) ?? 0;

    return {
      'total': total,
      'usda': usda,
      'local': local,
      'user': user,
    };
  }

  FoodCatalogItem _foodFromMap(Map<String, Object?> map) {
    final dataSourceStr = map['data_source'] as String;
    final dataSource = FoodDataSource.values.firstWhere(
      (s) => s.wireValue == dataSourceStr,
      orElse: () => FoodDataSource.local,
    );

    return FoodCatalogItem(
      id: map['id'] as String,
      fdcId: map['fdc_id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      servingBasis: ServingBasis.per100g,
      kcalPer100g: (map['kcal'] as num).toDouble(),
      proteinGPer100g: (map['protein'] as num).toDouble(),
      carbsGPer100g: (map['carbs'] as num).toDouble(),
      fatGPer100g: (map['fat'] as num).toDouble(),
      fiberGPer100g: map['fiber'] != null ? (map['fiber'] as num).toDouble() : null,
      sourceLabel: map['source_label'] as String,
      isEstimated: (map['is_estimated'] as int) == 1,
      brand: map['brand'] as String?,
      dataSource: dataSource,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['cached_at'] as int,
      ),
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
