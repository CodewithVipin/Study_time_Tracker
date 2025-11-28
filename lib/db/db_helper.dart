// ignore_for_file: depend_on_referenced_packages

/* ------------------- DATABASE HELPER (SQFLITE) ------------------- */

import 'dart:io';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('study_tracker.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<int> updateSubjectName(int id, String name) async {
    final db = await database;
    return await db.update(
      'subjects',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future _onCreate(Database db, int version) async {
    // subjects table: id, name, seconds
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        seconds INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // history table: id, subjectId, date(YYYY-MM-DD), seconds (total seconds studied on that date for that subject)
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subjectId INTEGER NOT NULL,
        date TEXT NOT NULL,
        seconds INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(subjectId) REFERENCES subjects(id)
      );
    ''');
  }

  // subjects CRUD
  Future<int> insertSubject(String name) async {
    final db = await database;
    return await db.insert('subjects', {'name': name, 'seconds': 0});
  }

  Future<List<Map<String, dynamic>>> getAllSubjectsRows() async {
    final db = await database;
    return await db.query('subjects', orderBy: 'id ASC');
  }

  Future<int> updateSubjectSeconds(int id, int seconds) async {
    final db = await database;
    return await db.update(
      'subjects',
      {'seconds': seconds},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    // also delete history rows for this subject
    await db.delete('history', where: 'subjectId = ?', whereArgs: [id]);
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> resetSubjectSeconds(int id) async {
    final db = await database;
    // keep history intact, only reset subject total
    return await db.update(
      'subjects',
      {'seconds': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // history helpers

  // Add seconds to history for today's date (insert if missing, else update)
  Future<void> addSecondsToHistory(int subjectId, int secsToAdd) async {
    if (secsToAdd <= 0) return;
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // check if a row exists for subjectId + today
    final rows = await db.query(
      'history',
      where: 'subjectId = ? AND date = ?',
      whereArgs: [subjectId, today],
    );

    if (rows.isEmpty) {
      await db.insert('history', {
        'subjectId': subjectId,
        'date': today,
        'seconds': secsToAdd,
      });
    } else {
      final existing = rows.first;
      final current = (existing['seconds'] as int);
      await db.update(
        'history',
        {'seconds': current + secsToAdd},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    }
  }

  // get aggregated history by date (sum of seconds across subjects)
  Future<List<Map<String, dynamic>>> getHistoryGroupedByDate() async {
    final db = await database;
    // sum seconds grouped by date
    final res = await db.rawQuery('''
      SELECT date, SUM(seconds) as totalSeconds
      FROM history
      GROUP BY date
      ORDER BY date DESC
    ''');
    return res;
  }

  // get per-subject breakdown for a given date
  Future<List<Map<String, dynamic>>> getHistoryForDate(String date) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT h.subjectId, s.name, h.seconds
      FROM history h
      JOIN subjects s ON s.id = h.subjectId
      WHERE h.date = ?
      ORDER BY h.seconds DESC
    ''',
      [date],
    );

    return res;
  }

  // get subject totals (from subjects table)
  Future<List<Map<String, dynamic>>> getSubjectTotals() async {
    final db = await database;
    return await db.query('subjects', orderBy: 'seconds DESC');
  }
}
