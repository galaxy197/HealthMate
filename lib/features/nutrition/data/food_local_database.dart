import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nutrition_models.dart';
import '../models/extra_nutrients.dart';
import '../models/food_catalog_search.dart';

/// Local SQLite database for food catalog caching
/// Public catalogue cache only. Private foods remain in UID-scoped Firestore.
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
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE foods ADD COLUMN metadata TEXT');
          await db.execute(
            "DELETE FROM recent_foods WHERE food_id IN (SELECT id FROM foods WHERE substr(id,1,3)='vn_')",
          );
          await db.execute(
            "DELETE FROM foods WHERE data_source='local' AND substr(id,1,3)='vn_'",
          );
        }
        if (oldVersion < 2) {
          // Public USDA rows written by the old parser can contain false zeros.
          // Invalidate those cache rows only; no journal/private food is deleted.
          await db.execute(
            "DELETE FROM recent_foods WHERE food_id IN (SELECT id FROM foods WHERE data_source = 'usda')",
          );
          await db.delete(
            'foods',
            where: 'data_source = ?',
            whereArgs: ['usda'],
          );
        }
      },
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
        metadata TEXT,
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
    return normalizeFoodSearch(text);
  }

  /// Insert or update food in cache
  Future<void> cacheFood(FoodCatalogItem food) async {
    _requirePublic(food);
    if (!_cacheable(food)) return;
    final db = await database;

    await db.insert('foods', {
      'id': food.id,
      'metadata': _metadata(food),
      'fdc_id': food.fdcId,
      'name': food.name,
      'name_normalized': _normalize(
        [food.name, ...food.alternateNames].join(' '),
      ),
      'category': food.category,
      'data_source': food.dataSource.wireValue,
      'kcal': food.kcalPer100g ?? food.nutritionPer100g.kcal,
      'protein': food.proteinGPer100g ?? food.nutritionPer100g.proteinG,
      'carbs': food.carbsGPer100g ?? food.nutritionPer100g.carbsG,
      'fat': food.fatGPer100g ?? food.nutritionPer100g.fatG,
      'fiber': food.nutritionPer100g.fiberKnown
          ? food.nutritionPer100g.fiberG
          : null,
      'source_label': food.sourceLabel,
      'is_estimated': food.isEstimated ? 1 : 0,
      'brand': food.brand,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Batch insert foods
  Future<void> cacheFoodsBatch(List<FoodCatalogItem> foods) async {
    for (final food in foods) {
      _requirePublic(food);
    }
    final complete = foods.where(_cacheable).toList();
    if (complete.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (final food in complete) {
      batch.insert('foods', {
        'id': food.id,
        'metadata': _metadata(food),
        'fdc_id': food.fdcId,
        'name': food.name,
        'name_normalized': _normalize(
          [food.name, ...food.alternateNames].join(' '),
        ),
        'category': food.category,
        'data_source': food.dataSource.wireValue,
        'kcal': food.kcalPer100g ?? food.nutritionPer100g.kcal,
        'protein': food.proteinGPer100g ?? food.nutritionPer100g.proteinG,
        'carbs': food.carbsGPer100g ?? food.nutritionPer100g.carbsG,
        'fat': food.fatGPer100g ?? food.nutritionPer100g.fatG,
        'fiber': food.nutritionPer100g.fiberKnown
            ? food.nutritionPer100g.fiberG
            : null,
        'source_label': food.sourceLabel,
        'is_estimated': food.isEstimated ? 1 : 0,
        'brand': food.brand,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
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

    final where = StringBuffer(
      "data_source IN ('local','usda') AND name_normalized LIKE ?",
    );
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
      where: "id = ? AND data_source IN ('local','usda')",
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
      where: "fdc_id = ? AND data_source IN ('local','usda')",
      whereArgs: [fdcId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _foodFromMap(results.first);
  }

  /// Get recently used foods
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20}) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT f.*
      FROM foods f
      INNER JOIN recent_foods r ON f.id = r.food_id
      WHERE f.data_source IN ('local','usda')
      ORDER BY r.last_used DESC
      LIMIT ?
    ''',
      [limit],
    );

    return results.map(_foodFromMap).toList();
  }

  /// Mark food as used (for recent list)
  Future<void> markFoodUsed(String foodId) async {
    final db = await database;

    await db.insert('recent_foods', {
      'food_id': foodId,
      'last_used': DateTime.now().millisecondsSinceEpoch,
      'use_count': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

    final total =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM foods'),
        ) ??
        0;

    final usda =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM foods WHERE data_source = ?',
            [FoodDataSource.usda.wireValue],
          ),
        ) ??
        0;

    final local =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM foods WHERE data_source = ?',
            [FoodDataSource.local.wireValue],
          ),
        ) ??
        0;

    final user =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM foods WHERE data_source = ?',
            [FoodDataSource.user.wireValue],
          ),
        ) ??
        0;

    return {'total': total, 'usda': usda, 'local': local, 'user': user};
  }

  FoodCatalogItem _foodFromMap(Map<String, Object?> map) {
    final metadata = map['metadata'] is String
        ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
        : <String, dynamic>{};
    final dataSourceStr = map['data_source'] as String;
    final dataSource = FoodDataSource.values.firstWhere(
      (s) => s.wireValue == dataSourceStr,
      orElse: () => FoodDataSource.local,
    );

    return FoodCatalogItem(
      id: map['id'] as String,
      fdcId: map['fdc_id'] as int?,
      name: map['name'] as String,
      alternateNames: (metadata['aliases'] as List? ?? []).cast<String>(),
      defaultServingGrams:
          (metadata['defaultGrams'] as num?)?.toDouble() ?? 100,
      servingLabel: metadata['servingLabel'] as String?,
      servingGrams: (metadata['servingGrams'] as num?)?.toDouble(),
      extraNutrientsPer100g: readExtraNutrients(metadata['extraNutrients']),
      category: map['category'] as String,
      servingBasis: ServingBasis.per100g,
      kcalPer100g: (map['kcal'] as num).toDouble(),
      proteinGPer100g: (map['protein'] as num).toDouble(),
      carbsGPer100g: (map['carbs'] as num).toDouble(),
      fatGPer100g: (map['fat'] as num).toDouble(),
      fiberGPer100g: map['fiber'] != null
          ? (map['fiber'] as num).toDouble()
          : null,
      sourceLabel: map['source_label'] as String,
      isEstimated: (map['is_estimated'] as int) == 1,
      brand: map['brand'] as String?,
      dataSource: dataSource,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at'] as int),
    );
  }

  String _metadata(FoodCatalogItem f) => jsonEncode({
    'aliases': f.alternateNames,
    'defaultGrams': f.defaultServingGrams,
    'servingLabel': f.servingLabel,
    'servingGrams': f.servingGrams,
    'extraNutrients': f.nutritionPer100g.extraNutrients,
  });

  void _requirePublic(FoodCatalogItem food) {
    if (food.dataSource == FoodDataSource.user) {
      throw ArgumentError(
        'Private foods must use their UID-scoped repository.',
      );
    }
  }

  bool _cacheable(FoodCatalogItem food) =>
      food.hasNutritionData && food.nutritionPer100g.hasCompleteMacros;

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
