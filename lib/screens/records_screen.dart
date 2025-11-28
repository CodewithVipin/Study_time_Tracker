// ignore_for_file: unnecessary_brace_in_string_interps, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_time_tracker/db/db_helper.dart';

/* ------------------- RECORDS / HISTORY SCREEN ------------------- */

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final DBHelper db = DBHelper.instance;

  late Future<List<Map<String, dynamic>>> _subjectTotalsFuture;
  late Future<List<Map<String, dynamic>>> _historyByDateFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _subjectTotalsFuture = db.getSubjectTotals();
    _historyByDateFuture = db.getHistoryGroupedByDate();
    setState(() {});
  }

  String formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  /* ------------------- BY SUBJECT TAB (Filtered) ------------------- */
  Widget _buildBySubjectTab(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _subjectTotalsFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // FILTER: only subjects with non-zero time
        final rows = (snap.data ?? [])
            .where((r) => (r['seconds'] ?? 0) > 0)
            .toList();

        if (rows.isEmpty) {
          return Center(
            child: Text(
              "No study activity yet.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final r = rows[i];
            final name = r['name'];
            final seconds = r['seconds'];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  "Total study time",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Text(
                  formatTime(seconds),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* ------------------- BY DATE TAB (Filtered) ------------------- */
  Widget _buildByDateTab(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyByDateFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text("No history found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final r = rows[i];
            final date = r['date'];
            final total = r['totalSeconds'];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(
                  DateFormat.yMMMMd().format(DateTime.parse(date)),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  "Total: ${formatTime(total)}",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: db.getHistoryForDate(date),
                    builder: (context, snap2) {
                      if (!snap2.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      // FILTER subjects having time > 0
                      final rows2 = (snap2.data ?? [])
                          .where((row) => (row['seconds'] ?? 0) > 0)
                          .toList();

                      if (rows2.isEmpty) {
                        return const ListTile(
                          title: Text("No data for this date"),
                        );
                      }

                      return Column(
                        children: rows2.map((row) {
                          final name = row['name'];
                          final seconds = row['seconds'];

                          return ListTile(
                            leading: Icon(
                              Icons.book_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(name),
                            trailing: Text(
                              formatTime(seconds),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ------------------- BUILD UI ------------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Records'),
          elevation: 2,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.subject), text: "By Subject"),
              Tab(icon: Icon(Icons.calendar_today), text: "By Date"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
              tooltip: "Reload",
            ),
          ],
        ),

        // ---------- MAIN TAB CONTENT ----------
        body: TabBarView(
          children: [_buildBySubjectTab(context), _buildByDateTab(context)],
        ),
      ),
    );
  }
}
