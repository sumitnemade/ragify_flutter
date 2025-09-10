// Stub file for SQLite on web platform
// This file provides empty implementations for web compatibility

class Database {
  Future<void> close() async {}
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return [];
  }

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return 0;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? whereClause,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return 0;
  }

  Future<int> delete(
    String table, {
    String? whereClause,
    List<dynamic>? whereArgs,
  }) async {
    return 0;
  }
}

enum ConflictAlgorithm { replace, rollback, abort, fail, ignore }

Future<Database> openDatabase(
  String path, {
  int? version,
  OnDatabaseConfigure? onConfigure,
  OnDatabaseCreate? onCreate,
  OnDatabaseVersionChange? onVersionChange,
  OnDatabaseOpen? onOpen,
  bool readOnly = false,
  bool singleInstance = true,
}) async {
  return Database();
}

typedef OnDatabaseConfigure = Future<void> Function(Database db);
typedef OnDatabaseCreate = Future<void> Function(Database db, int version);
typedef OnDatabaseVersionChange =
    Future<void> Function(Database db, int oldVersion, int newVersion);
typedef OnDatabaseOpen = Future<void> Function(Database db);
