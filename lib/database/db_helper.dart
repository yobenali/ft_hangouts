import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';
import '../models/message.dart';

class DatabaseHelper {
  
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ft_hangouts.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        note TEXT,
        photo_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER NOT NULL,
        body TEXT NOT NULL,
        is_sent INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE contacts ADD COLUMN photo_path TEXT',
    );
  }
}
  // ─── CONTACT METHODS ───────────────────────────────

  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<Contact>> getContacts() async {
    final db = await database;
    final maps = await db.query('contacts');
    return maps.map((m) => Contact.fromMap(m)).toList();
  }

  Future<void> updateContact(Contact contact) async {
    final db = await database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── MESSAGE METHODS ───────────────────────────────
  Future<bool> messageExists({
    required int contactId,
    required String body,
    required int isSent,
    required String timestamp,
  }) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'contact_id = ? AND body = ? AND is_sent = ?',
      whereArgs: [contactId, body, isSent],
    );
    return result.isNotEmpty;
  }
  
  Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap());
  }

  // Remove all duplicate messages — keep only one copy of each
  Future<void> removeDuplicateMessages() async {
    final db = await database;
    await db.execute('''
      DELETE FROM messages
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM messages
        GROUP BY contact_id, body, is_sent
      )
    ''');
  }

  Future<List<Message>> getMessages(int contactId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Message.fromMap(m)).toList();
  }
  // Find a contact by phone number — handles +212 and 06 formats
  Future<Contact?> findContactByPhone(String phone) async {
    final db = await database;
    final clean = phone.trim().replaceAll(' ', '').replaceAll('-', '');

    // Build all possible formats
    final variants = <String>[clean];
    if (clean.startsWith('+212')) {
      variants.add('0' + clean.substring(4));
    }
    if (clean.startsWith('0') && clean.length >= 9) {
      variants.add('+212' + clean.substring(1));
    }
    if (clean.startsWith('0')) {
      variants.add(clean.substring(1));
    }

    for (final variant in variants) {
      final result = await db.query(
        'contacts',
        where: 'phone = ?',
        whereArgs: [variant],
      );
      if (result.isNotEmpty) {
        return Contact.fromMap(result.first);
      }
    }
    return null; // not found
  }
}
