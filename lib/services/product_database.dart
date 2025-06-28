import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:skincare/models/product.dart';
import 'dart:developer';

class ProductDatabase {
  static final ProductDatabase instance = ProductDatabase._init();
  static Database? _database;
  ProductDatabase._init();

  Future<Database> get database async => _database ??= await _initDB();

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'products.db');
    return openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        intervalDays INTEGER,
        instructions TEXT,
        imagePath TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE routine_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        routine TEXT, -- 'morning' or 'night'
        routineOrder INTEGER,
        lastUsed TEXT,
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute("ALTER TABLE products ADD COLUMN imagePath TEXT;");
    }
  }

  Future<void> addProductToRoutine(
    Product product,
    SkincareTime routine,
  ) async {
    log("DATABASE ACCESS addProductToRoutine");
    final db = await instance.database;
    // Get the current max order for this routine
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(routineOrder) as maxOrder FROM routine_products WHERE routine = ?',
      [routine.name],
    );
    final maxOrder = maxOrderResult.first['maxOrder'] as int? ?? -1;
    await db.insert('routine_products', {
      'productId': product.id,
      'routine': routine.name,
      'routineOrder': maxOrder + 1,
      'lastUsed': DateTime(2000).toIso8601String(),
    });
  }

  Future<void> removeProductFromRoutine(
    Product product,
    SkincareTime routine,
  ) async {
    log("DATABASE ACCESS removeProductFromRoutine");
    final db = await instance.database;
    await db.delete(
      'routine_products',
      where: 'productId = ? AND routine = ?',
      whereArgs: [product.id, routine.name],
    );
  }

  Future<List<Product>> getAllProducts() async {
    log("DATABASE ACCESS getAllProducts");
    final db = await instance.database;
    final result = await db.query('products');
    return result.map(Product.fromMap).toList();
  }

  Future<int> addProduct(Product product, List<SkincareTime> routines) async {
    log("DATABASE ACCESS addProduct");
    final db = await instance.database;
    // Insert product and get its id
    final productId = await db.insert('products', product.toMap());
    // Add to routines
    for (final routine in routines) {
      // Get the current max order for this routine
      final maxOrderResult = await db.rawQuery(
        'SELECT MAX(routineOrder) as maxOrder FROM routine_products WHERE routine = ?',
        [routine.name],
      );
      final maxOrder = maxOrderResult.first['maxOrder'] as int? ?? -1;
      await db.insert('routine_products', {
        'productId': productId,
        'routine': routine.name,
        'routineOrder': maxOrder + 1,
        'lastUsed': DateTime(2000).toIso8601String(),
      });
    }
    return productId;
  }

  Future<int> updateProduct(Product product) async {
    log("DATABASE ACCESS updateProduct");
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> getProductsForRoutine(SkincareTime routine) async {
    log("DATABASE ACCESS getProductsForRoutine");
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT p.* FROM products p
      INNER JOIN routine_products rp ON p.id = rp.productId
      WHERE rp.routine = ?
      ORDER BY rp.routineOrder ASC
    ''',
      [routine.name],
    );
    return result.map(Product.fromMap).toList();
  }

  Future<List<Routine>> getRoutinesForTime(SkincareTime time) async {
    log("DATABASE ACCESS getRoutinesForTime");
    final db = await instance.database;
    final result = await db.query(
      'routine_products',
      where: 'routine = ?',
      whereArgs: [time.name],
      orderBy: 'routineOrder ASC',
    );
    if (result.isEmpty) return [];
    List<Routine> routines = [];
    for (final map in result) {
      final mutableMap = Map<String, dynamic>.from(map);
      final product = await getProductFromId(mutableMap['productId'] as int);
      final routine = Routine(
        productId: map['productId'] as int,
        routine: SkincareTime.values.firstWhere(
          (e) => e.name == map['routine'],
        ),
        routineOrder: map['routineOrder'] as int,
        lastUsed: DateTime.parse(map['lastUsed'] as String),
        product: product,
      );
      routines.add(routine);
    }
    routines.sort((a, b) => a.routineOrder.compareTo(b.routineOrder));
    return routines;
  }

  Future<Product> getProductFromId(int id) async {
    log("DATABASE ACCESS getProductFromId");
    final db = await instance.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) throw Exception('Product not found');
    return Product.fromMap(result.first);
  }

  Future<List<Routine>> getRoutinesForProduct(Product product) async {
    log("DATABASE ACCESS getRoutinesForProduct");
    final db = await instance.database;
    final result = await db.query(
      'routine_products',
      where: 'productId = ?',
      whereArgs: [product.id],
    );
    if (result.isEmpty) return [];
    return result.map((map) {
      return Routine(
        productId: map['productId'] as int,
        routine: SkincareTime.values.firstWhere(
          (e) => e.name == map['routine'],
        ),
        routineOrder: map['routineOrder'] as int,
        lastUsed: DateTime.parse(map['lastUsed'] as String),
        product: product,
      );
    }).toList();
  }

  Future<void> updateRoutineOrder(
    SkincareTime routine,
    List<Product> products,
  ) async {
    log("DATABASE ACCESS updateRoutineOrder");
    final db = await instance.database;
    for (int i = 0; i < products.length; i++) {
      await db.update(
        'routine_products',
        {'routineOrder': i},
        where: 'productId = ? AND routine = ?',
        whereArgs: [products[i].id, routine.name],
      );
    }
  }

  Future<void> completeRoutine(SkincareTime routine) async {
    log("DATABASE ACCESS completeRoutine");
    final db = await instance.database;
    final now = DateTime.now();
    await db.update(
      'routine_products',
      {'lastUsed': now.toIso8601String()},
      where: 'routine = ?',
      whereArgs: [routine.name],
    );
  }

  Future<void> deleteProduct(Product product) async {
    log("DATABASE ACCESS deleteProduct");
    final db = await instance.database;
    // Delete from routine_products first
    await db.delete(
      'routine_products',
      where: 'productId = ?',
      whereArgs: [product.id],
    );
    // Then delete from products
    await db.delete('products', where: 'id = ?', whereArgs: [product.id]);
  }

  Future<List<Product>> getUnusedProducts() async {
    log("DATABASE ACCESS getUnusedProducts");
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT * FROM products
      WHERE id NOT IN (SELECT productId FROM routine_products)
    ''');
    return result.map(Product.fromMap).toList();
  }

  Future<String> exportDatabase() async {
    log("DATABASE ACCESS exportDatabase");
    final db = await instance.database;
    // Dump the contents
    final List<Map<String, dynamic>> products = await db.query('products');
    final List<Map<String, dynamic>> routines = await db.query(
      'routine_products',
    );
    // Convert to JSON
    final String json = jsonEncode({
      'products': products.map((p) => Product.fromMap(p).toJson()).toList(),
      'routines': routines.map((r) => Routine.fromMap(r).toJson()).toList(),
    });

    var downloadsDir = (await getDownloadsDirectory())?.path;
    if (downloadsDir == null) {
      downloadsDir = (await getApplicationDocumentsDirectory()).path;
      log(
        "Downloads directory not found, using application documents directory: $downloadsDir",
      );
    }
    final file = await Utils.writeDownloadFile('skincare_export.json', json);
    final filePath = file.path;
    log("Database exported to $filePath");
    return filePath;
  }

  Future<void> importDatabase(String jsonPath) async {
    log("DATABASE ACCESS importDatabase");
    final db = await instance.database;
    // Read the JSON file
    final file = File(jsonPath);
    if (!file.existsSync()) {
      throw Exception('JSON file not found at $jsonPath');
    }
    final jsonString = file.readAsStringSync();
    // Decode the JSON
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    // Insert products
    final products = jsonData['products'] as List<dynamic>;
    for (final product in products) {
      final productMap = product as Map<String, dynamic>;
      final newProduct = Product.fromMap(productMap);
      // Insert product into the database
      await db.insert('products', newProduct.toMap());
      // Insert routines for this product
      final routines = jsonData['routines'] as List<dynamic>;
      for (final routine in routines) {
        final routineMap = routine as Map<String, dynamic>;
        if (routineMap['productId'] == newProduct.id) {
          final routineTime = SkincareTime.values.firstWhere(
            (e) => e.name == routineMap['routine'],
          );
          routineMap['routine'] = routineTime.name;
          await db.insert('routine_products', routineMap);
        }
      }
    }
  }
}
