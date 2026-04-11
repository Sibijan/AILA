import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class TasksScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const TasksScreen({super.key, required this.user});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/tasks/${widget.user['id']}'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        setState(() { _tasks = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _error = 'Server error'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach backend'; _loading = false; });
    }
  }

  Future<void> _markDone(int id) async {
    await http.put(Uri.parse('$baseUrl/tasks/$id'));
    _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure?', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.black))),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('$baseUrl/tasks/$id'));
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _tasks.where((t) => t['status'] != 'done').toList();
    final done = _tasks.where((t) => t['status'] == 'done').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          color: Colors.black,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Tasks', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black,
                      )),
                      IconButton(
                        onPressed: _loadTasks,
                        icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(child: Text(_error!, style: const TextStyle(color: Colors.black54))),
                )
              else if (_tasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_box_outline_blank, color: Colors.black26, size: 48),
                      SizedBox(height: 12),
                      Text('No tasks yet', style: TextStyle(color: Colors.black54, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Tap Add to create your first task',
                        style: TextStyle(color: Colors.black26, fontSize: 13)),
                    ],
                  )),
                )
              else ...[
                if (pending.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SectionLabel(label: 'Pending', count: pending.length)),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _TaskCard(task: pending[i], onDone: _markDone, onDelete: _deleteTask),
                    childCount: pending.length,
                  )),
                ],
                if (done.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SectionLabel(label: 'Completed', count: done.length)),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _TaskCard(task: done[i], onDone: _markDone, onDelete: _deleteTask),
                    childCount: done.length,
                  )),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(children: [
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54,
          letterSpacing: 1,
        )),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(color: Colors.black26, fontSize: 13)),
      ]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Future<void> Function(int) onDone;
  final Future<void> Function(int) onDelete;

  const _TaskCard({required this.task, required this.onDone, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDone = task['status'] == 'done';
    final date = task['scheduled_date'] ?? '';
    final time = task['scheduled_time'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: GestureDetector(
            onTap: isDone ? null : () => onDone(task['id']),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.black38 : Colors.black, width: 1.5),
                color: isDone ? Colors.black12 : Colors.transparent,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.black54, size: 14)
                  : null,
            ),
          ),
          title: Text(
            task['name'],
            style: TextStyle(
              color: isDone ? Colors.black38 : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: Colors.black38,
            ),
          ),
          subtitle: date.isNotEmpty || time.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('$date  $time'.trim(),
                    style: const TextStyle(color: Colors.black38, fontSize: 12)),
                )
              : null,
          trailing: IconButton(
            onPressed: () => onDelete(task['id']),
            icon: const Icon(Icons.close, color: Colors.black, size: 18),
          ),
        ),
      ),
    );
  }
}