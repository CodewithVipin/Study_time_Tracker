// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_time_tracker/db/db_helper.dart';
import 'package:study_time_tracker/model/study_subject.dart';
import 'package:study_time_tracker/screens/records_screen.dart';
import 'package:study_time_tracker/theme/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBHelper db = DBHelper.instance;
  final List<StudySubject> subjects = [];
  StudySubject? activeSubject;
  Timer? masterTimer;

  final Map<int, int> _pendingHistoryAdds = {};

  /* ---------------- SHORT NAME FUNCTION ---------------- */
  String shortName(String name) {
    if (name.length <= 7) return name;
    return "${name.substring(0, 7)}…";
  }

  @override
  void initState() {
    super.initState();
    _loadSubjectsFromDb();

    masterTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeSubject != null) {
        setState(() => activeSubject!.seconds++);

        if (activeSubject!.id != null) {
          db.updateSubjectSeconds(activeSubject!.id!, activeSubject!.seconds);

          _pendingHistoryAdds.update(
            activeSubject!.id!,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
        }
      }
    });

    Timer.periodic(const Duration(seconds: 10), (_) => _flushPendingHistory());
  }

  @override
  void dispose() {
    masterTimer?.cancel();
    _flushPendingHistory();
    super.dispose();
  }

  Future<void> _flushPendingHistory() async {
    final entries = Map<int, int>.from(_pendingHistoryAdds);
    _pendingHistoryAdds.clear();

    for (final entry in entries.entries) {
      await db.addSecondsToHistory(entry.key, entry.value);
    }
  }

  Future<void> _loadSubjectsFromDb() async {
    final rows = await db.getAllSubjectsRows();

    if (rows.isEmpty) {
      final seed = ['English', 'Math', 'Science', 'Hindi', 'Computer', 'GK'];
      for (final name in seed) {
        final id = await db.insertSubject(name);
        subjects.add(StudySubject(id: id, name: name, seconds: 0));
      }
    } else {
      subjects.clear();
      subjects.addAll(rows.map((r) => StudySubject.fromRow(r)));
    }

    setState(() {});
  }

  void onSubjectTap(StudySubject tapped) {
    setState(() {
      if (activeSubject == tapped) {
        tapped.isRunning = false;
        activeSubject = null;
      } else {
        if (activeSubject != null) {
          activeSubject!.isRunning = false;
        }
        tapped.isRunning = true;
        activeSubject = tapped;
      }
    });
  }

  Future<void> _addCustomSubjectDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Subject name'),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              final id = await db.insertSubject(text);
              setState(
                () =>
                    subjects.add(StudySubject(id: id, name: text, seconds: 0)),
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editSubjectName(StudySubject s) async {
    final controller = TextEditingController(text: s.name);

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Subject Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (yes == true) {
      final newName = controller.text.trim();
      if (newName.isEmpty) return;

      await db.updateSubjectName(s.id!, newName);

      setState(() => s.name = newName);
    }
  }

  Future<void> _confirmResetSubject(StudySubject s) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Subject Timer'),
        content: Text('Reset timer for "${s.name}"?'),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (yes == true) {
      await db.resetSubjectSeconds(s.id!);

      setState(() {
        s.seconds = 0;
        s.isRunning = false;
        if (activeSubject == s) activeSubject = null;
      });
    }
  }

  Future<void> _deleteSubjectConfirm(StudySubject s) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Subject"),
        content: Text('Delete "${s.name}" permanently?'),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (yes == true) {
      await db.deleteSubject(s.id!);
      setState(() {
        subjects.remove(s);
        if (activeSubject == s) activeSubject = null;
      });
    }
  }

  Future<void> _resetAllSubjects() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset All Timers"),
        content: const Text("Reset all subjects to 0?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Reset All"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (yes == true) {
      activeSubject = null;

      for (final s in subjects) {
        s.seconds = 0;
        s.isRunning = false;
        await db.resetSubjectSeconds(s.id!);
      }

      _pendingHistoryAdds.clear();
      setState(() {});
    }
  }

  int get totalSeconds => subjects.fold(0, (sum, s) => sum + s.seconds);

  String formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  void openRecordsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsScreen()),
    );
  }

  /* ------------------------- UI START ------------------------- */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Time Tracker"),
        leading: IconButton(
          icon: Icon(themeProvider.isDark ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => themeProvider.toggleTheme(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: openRecordsScreen,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.builder(
          itemCount: subjects.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 130,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) {
            final s = subjects[i];
            final isActive = s.isRunning;

            return GestureDetector(
              onTap: () => onSubjectTap(s),
              onLongPress: () => _confirmResetSubject(s),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isActive ? 2 : 1,
                  ),
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TOP: Subject name + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            shortName(s.name),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') await _editSubjectName(s);
                            if (v == 'reset') await _confirmResetSubject(s);
                            if (v == 'delete') await _deleteSubjectConfirm(s);
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text("Edit Name"),
                            ),
                            PopupMenuItem(value: 'reset', child: Text("Reset")),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                      ],
                    ),

                    /// BOTTOM: Timer + icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatTime(s.seconds),
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceVariant,
                          ),
                          child: Icon(
                            isActive ? Icons.pause : Icons.play_arrow,
                            size: 22,
                            color: isActive
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomSubjectDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Subject"),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          height: 90,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.35),
                  width: 1.5,
                ),
              ),

              child: Row(
                children: [
                  /// TOTAL TIME
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Study Time",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatTime(totalSeconds),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RUNNING STATUS + CURRENT SUBJECT
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activeSubject != null ? "Running" : "Paused",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: activeSubject != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// active subject name (shortened)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activeSubject != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeSubject != null
                              ? shortName(activeSubject!.name)
                              : "—",
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: activeSubject != null
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// RESET ALL BUTTON
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text("Reset All"),
                      onPressed: _resetAllSubjects,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
