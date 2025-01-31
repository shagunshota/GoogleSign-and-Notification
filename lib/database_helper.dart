import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notifications.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertNotification(String message) async {
    final db = await database;
    await db.insert('notifications', {'message': message});
  }

  Future<List<String>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> notifications = await db.query('notifications', orderBy: 'id DESC');

    return List.generate(notifications.length, (i) {
      return notifications[i]['message'] as String;
    });
  }

  Future<void> deleteOldestNotification() async {
    final db = await database;
    await db.delete('notifications', where: 'id = (SELECT MIN(id) FROM notifications)');
  }

  Future<int> getNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
