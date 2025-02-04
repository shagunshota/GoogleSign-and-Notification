import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notifications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notification TEXT,
        isRead INTEGER DEFAULT 0
      )
    ''');
  }

  // Insert new notification
  Future<int> insertNotification(String notification) async {
    final db = await instance.database;
    return await db.insert('notifications', {'notification': notification, 'isRead': 0});
  }

  // Get all notifications
  Future<List<String>> getNotifications() async {
    final db = await instance.database;
    final result = await db.query('notifications', orderBy: 'id DESC');
    return result.map((row) => row['notification'] as String).toList();
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final db = await instance.database;
    final result = await db.query('notifications', where: 'isRead = 0');
    return result.length;
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(int id) async {
    final db = await instance.database;
    await db.update('notifications', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Delete the oldest notification
  Future<void> deleteOldestNotification() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT MIN(id) FROM notifications');
    await db.delete('notifications', where: 'id = ?', whereArgs: [result[0]['MIN(id)']]);
  }
  // DatabaseHelper.dart

  Future<int> getNotificationId(String notification) async {
    final db = await instance.database;
    final result = await db.query(
      'notifications',
      where: 'notification = ?',
      whereArgs: [notification],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      throw Exception("Notification not found");
    }
  }


  // Get notification count
  Future<int> getNotificationCount() async {
    final db = await instance.database;
    final result = await db.query('notifications');
    return result.length;
  }
}
