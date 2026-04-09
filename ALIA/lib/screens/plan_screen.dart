import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<dynamic> _plan = [];
  bool _loading = false;
  bool _generated = false;
  String? _error;

  Future<void> _generatePlan() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/plan'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() { _plan = data; _loading = false; _generated = true; });
        } else {
          setState(() { _error = 'No tasks to plan'; _loading = false; _generated = true; });
        }
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach backend'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Text('Daily Plan', style: GoogleFonts.syne(
                fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
              )),
              const SizedBox(height: 4),
              Text('${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                style: const TextStyle(color: Color(0xFF55557A), fontSize: 14)),
              const SizedBox(height: 28),

              // ── Generate Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _generatePlan,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_generated ? 'Regenerate Plan' : 'Generate My Plan',
                    style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              if (_error != null)
                Center(child: Column(children: [
                  const Text('📭', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFF55557A))),
                ]))
              else if (_generated && _plan.isNotEmpty) ...[
                Row(children: [
                  Text('Your Schedule', style: GoogleFonts.syne(
                    fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFC4B5FD),
                  )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_plan.length} tasks', style: const TextStyle(
                      color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w700,
                    )),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Timeline ──
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plan.length,
                  itemBuilder: (ctx, i) {
                    final item = _plan[i];
                    final isLast = i == _plan.length - 1;
                    return _TimelineItem(
                      time: item['time'],
                      task: item['task'],
                      index: i,
                      isLast: isLast,
                    );
                  },
                ),
              ] else if (!_generated) ...[
                // ── Empty state ──
                Center(
                  child: Column(children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16162A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF252540)),
                      ),
                      child: const Center(child: Text('🗓️', style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 20),
                    Text('Ready to plan your day?', style: GoogleFonts.syne(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the button above to generate\na time-blocked schedule from your tasks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF55557A), height: 1.6, fontSize: 14),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time, task;
  final int index;
  final bool isLast;

  const _TimelineItem({
    required this.time, required this.task,
    required this.index, required this.isLast,
  });

  static const List<Color> _colors = [
    Color(0xFF7C3AED), Color(0xFF3B82F6), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline line ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(child: Container(
                    width: 2,
                    color: const Color(0xFF1E1E38),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  )),
              ],
            ),
          ),

          // ── Card ──
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF252540)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 4),
                  Text(task, style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
