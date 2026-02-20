import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data_model.dart';
import 'trip_model.dart';
import 'snapshot_model.dart';

const nameDB = "travel_stories.db";

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB(nameDB);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  ///  ------- TABLES ----------

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE trips (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      created_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE snapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL,
      latitude REAL,
      longitude REAL,
      timestamp TEXT NOT NULL,
      memo TEXT,
      photo_paths TEXT,      -- Storing JSON string here
      marker_color INTEGER,  -- Storing 0xFF4286f4
      marker_icon TEXT,
      line_style TEXT,
      FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
    )
  ''');
  }

  ///  ------- QUERIES ----------

  /// C - Create adds entry to database
  Future<int> create(DataModel item) async {
    final db = await instance.database;
    // The conflictAlgorithm replaces the record if the ID already exists
    return await db.insert(item.tableName, item.toMap());
  }

  /// R - Read All
  Future<List<Trip>> readAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips');

    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<List<Snapshot>> readAllSnapshots() async {
    final db = await instance.database;
    final result = await db.query('snapshots');

    return result.map((json) => Snapshot.fromMap(json)).toList();
  }

  /// R - Read Specific
  Future<List<Snapshot>> readTripSnapshots(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'snapshots',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at ASC',
    );
    return result.map((json) => Snapshot.fromMap(json)).toList();
  }

  /// R - Read Single
  Future<Trip?> readTrip(int id) async {
    final db = await instance.database;

    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Snapshot?> readSnapshot(int id) async {
    final db = await instance.database;
    final maps = await db.query('snapshots', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Snapshot.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // U - Update
  Future<int> update(DataModel item) async {
    final db = await instance.database;
    return db.update(
      item.tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // D - Delete
  Future<int> delete(DataModel item) async {
    final db = await instance.database;
    return await db.delete(
      item.tableName,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTrip(int tripId) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  Future<int> deleteSnapshot(int snapshotId) async {
    final db = await instance.database;
    return await db.delete(
      'snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
