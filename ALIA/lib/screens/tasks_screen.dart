import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

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
      final res = await http.get(Uri.parse('$baseUrl/tasks'))
          .timeout(const Duration(seconds: 5));
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
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Task', style: GoogleFonts.syne(color: Colors.white)),
        content: const Text('Are you sure you want to delete this task?',
          style: TextStyle(color: Color(0xFF8888AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF55557A)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFF87171)))),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          color: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFF16162A),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Tasks', style: GoogleFonts.syne(
                        fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                      IconButton(
                        onPressed: _loadTasks,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))),
                )
              else if (_tasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📋', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No tasks yet', style: TextStyle(color: Color(0xFF55557A), fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Tap Add to create your first task',
                        style: TextStyle(color: Color(0xFF3D3D5E), fontSize: 13)),
                    ],
                  )),
                )
              else ...[
                // ── Pending ──
                if (pending.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SectionLabel(label: 'Pending', count: pending.length)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TaskCard(task: pending[i], onDone: _markDone, onDelete: _deleteTask),
                      childCount: pending.length,
                    ),
                  ),
                ],

                // ── Done ──
                if (done.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _SectionLabel(label: 'Completed', count: done.length)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TaskCard(task: done[i], onDone: _markDone, onDelete: _deleteTask),
                      childCount: done.length,
                    ),
                  ),
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
        Text(label, style: GoogleFonts.syne(
          fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFC4B5FD),
        )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: const TextStyle(
            color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w700,
          )),
        ),
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
    final priority = task['priority'] as int;
    final emoji = priorityEmojis[priority] ?? '⚪';
    final label = priorityLabels[priority] ?? '$priority';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? const Color(0xFF1E3A2A) : const Color(0xFF252540),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: isDone ? null : () => onDone(task['id']),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? const Color(0xFF1E3A2A) : const Color(0xFF1E1E38),
                border: Border.all(
                  color: isDone ? const Color(0xFF34D399) : const Color(0xFF3D3D5E),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 16)
                  : null,
            ),
          ),
          title: Text(
            task['name'],
            style: TextStyle(
              color: isDone ? const Color(0xFF55557A) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0xFF55557A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Text('$emoji $label', style: const TextStyle(
                color: Color(0xFF8888AA), fontSize: 12,
              )),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: const Color(0xFF2D2D4E)),
              const SizedBox(width: 8),
              Text('#${task['id']}', style: const TextStyle(
                color: Color(0xFF3D3D5E), fontSize: 12,
              )),
            ]),
          ),
          trailing: IconButton(
            onPressed: () => onDelete(task['id']),
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF3D3D5E), size: 20),
          ),
        ),
      ),
    );
  }
}
