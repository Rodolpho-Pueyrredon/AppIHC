import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static Database? _database;
  static Future<Database>? _initFuture;

  static const _assetPath = 'assets/db/AppIHC.db';
  static const _dbFileName = 'AppIHC.db';

  static Future<Database> get instance async {
    if (_database != null) {
      return _database!;
    }

    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _init();

    try {
      _database = await _initFuture;
      return _database!;
    } finally {
      _initFuture = null;
    }
  }

  static Future<Database> _init() async {
    final factory = _databaseFactory();
    final databasesPath = await _getDatabasesPath(factory);
    final dbPath = p.join(databasesPath, _dbFileName);
    final exists = await _databaseExists(factory, dbPath);

    if (!exists) {
      await Directory(p.dirname(dbPath)).create(recursive: true);

      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    return _openDatabase(factory, dbPath);
  }

  static Future<void> replaceDatabaseFromAsset() async {
    final factory = _databaseFactory();
    final databasesPath = await _getDatabasesPath(factory);
    final dbPath = p.join(databasesPath, _dbFileName);

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }

    final byteData = await rootBundle.load(_assetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    await Directory(p.dirname(dbPath)).create(recursive: true);
    await File(dbPath).writeAsBytes(bytes, flush: true);

    _database = await _openDatabase(factory, dbPath);
  }

  static DatabaseFactory _databaseFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }

    return databaseFactory;
  }

  static Future<String> _getDatabasesPath(DatabaseFactory factory) {
    if (factory == databaseFactoryFfi) {
      return databaseFactoryFfi.getDatabasesPath();
    }

    return getDatabasesPath();
  }

  static Future<bool> _databaseExists(DatabaseFactory factory, String path) {
    if (factory == databaseFactoryFfi) {
      return databaseFactoryFfi.databaseExists(path);
    }

    return databaseExists(path);
  }

  static Future<Database> _openDatabase(DatabaseFactory factory, String path) {
    if (factory == databaseFactoryFfi) {
      return databaseFactoryFfi.openDatabase(path);
    }

    return openDatabase(
      path,
      readOnly: false,
    );
  }
}
