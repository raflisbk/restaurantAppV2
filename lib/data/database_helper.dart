import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/restaurant.dart';
import 'storage_interface.dart';

class DatabaseHelper implements StorageInterface {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal() {
    _instance = this;
  }

  factory DatabaseHelper() => _instance ?? DatabaseHelper._internal();

  static const String _tblFavorites = 'favorites';

  Future<Database> _db() async {
    return _database ??= await _initDb();
  }

  Future<Database> _initDb() async {
    final path = await getDatabasesPath();
    final databasePath = '$path/restaurant.db';

    var db = await openDatabase(databasePath, version: 1, onCreate: _onCreate);
    return db;
  }

  @override
  Future<void> initialize() async {
    try {
      await _db();
      debugPrint('SQLite database berhasil diinisialisasi');
    } catch (e) {
      debugPrint('Gagal menginisialisasi SQLite: $e');
      rethrow;
    }
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tblFavorites (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        pictureId TEXT,
        city TEXT,
        rating REAL
      )
    ''');
  }

  @override
  Future<void> insertFavorite(Restaurant restaurant) async {
    final db = await _db();
    await db.insert(_tblFavorites, {
      'id': restaurant.id,
      'name': restaurant.name,
      'description': restaurant.description,
      'pictureId': restaurant.pictureId,
      'city': restaurant.city,
      'rating': restaurant.rating,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Restaurant>> getFavorites() async {
    final db = await _db();
    List<Map<String, dynamic>> results = await db.query(_tblFavorites);

    return results
        .map(
          (res) => Restaurant(
            id: res['id'],
            name: res['name'],
            description: res['description'],
            pictureId: res['pictureId'],
            city: res['city'],
            rating: res['rating'],
          ),
        )
        .toList();
  }

  @override
  Future<Restaurant?> getFavoriteById(String id) async {
    final db = await _db();
    List<Map<String, dynamic>> results = await db.query(
      _tblFavorites,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return Restaurant(
        id: results.first['id'],
        name: results.first['name'],
        description: results.first['description'],
        pictureId: results.first['pictureId'],
        city: results.first['city'],
        rating: results.first['rating'],
      );
    } else {
      return null;
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    final db = await _db();
    await db.delete(_tblFavorites, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> isFavorite(String id) async {
    final db = await _db();
    List<Map<String, dynamic>> results = await db.query(
      _tblFavorites,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty;
  }
}
