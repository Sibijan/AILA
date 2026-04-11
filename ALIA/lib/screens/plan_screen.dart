import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PlanScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PlanScreen({super.key, required this.user});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/plan/${widget.user['id']}'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _tasks = data is List ? data : []; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach backend'; _loading = false; });
    }
  }

  Map<String, List<dynamic>> _groupByDate() {
    final Map<String, List<dynamic>> grouped = {};
    for (final task in _tasks) {
      final date = task['scheduled_date'] ?? 'No date';
      grouped.putIfAbsent(date, () => []).add(task);
    }
    return grouped;
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (dt == today) return 'Today';
      if (dt == tomorrow) return 'Tomorrow';
      return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlan,
          color: Colors.white,
          backgroundColor: Colors.black,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plan', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                      )),
                      const SizedBox(height: 4),
                      Text('Your scheduled tasks', style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 14,
                      )),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(child: Text(_error!,
                    style: const TextStyle(color: Colors.white54))),
                )
              else if (_tasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                        color: Colors.white24, size: 48),
                      SizedBox(height: 12),
                      Text('No scheduled tasks',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Add tasks with a date and time',
                        style: TextStyle(color: Colors.white24, fontSize: 13)),
                    ],
                  )),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final date = dates[i];
                      final tasks = grouped[date]!;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(date), style: const TextStyle(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700,
                            )),
                            const SizedBox(height: 12),
                            ...tasks.map((task) => _PlanTaskCard(task: task)),
                          ],
                        ),
                      );
                    },
                    childCount: dates.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _PlanTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDone = task['status'] == 'done';
    final time = task['scheduled_time'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        if (time.isNotEmpty) ...[
          Text(time, style: const TextStyle(
            color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 16),
          Container(width: 1, height: 36, color: Colors.white12),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Text(
            task['name'],
            style: TextStyle(
              color: isDone ? Colors.white38 : Colors.white,
              fontSize: 15, fontWeight: FontWeight.w500,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white38,
            ),
          ),
        ),
        if (isDone)
          const Icon(Icons.check, color: Colors.white24, size: 16),
      ]),
    );
  }
}