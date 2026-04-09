import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import '../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/productivity'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        setState(() { _stats = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _error = 'Server error'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Cannot reach backend.\nCheck your IP in constants.dart'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayName = days[now.weekday - 1];
    final dateStr = '$dayName, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFF16162A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFA78BFA), Color(0xFF60A5FA), Color(0xFF34D399)],
                          ).createShader(bounds),
                          child: Text('AILA', style: GoogleFonts.syne(
                            fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white,
                          )),
                        ),
                        Text(dateStr, style: const TextStyle(
                          color: Color(0xFF55557A), fontSize: 13,
                        )),
                      ],
                    ),
                    const Text('🧠', style: TextStyle(fontSize: 36)),
                  ],
                ),
                const SizedBox(height: 32),

                if (_loading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _loadStats)
                else ...[
                  // ── Productivity Ring ──
                  Center(
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 90,
                          lineWidth: 12,
                          percent: ((_stats!['productivity'] as int) / 100).clamp(0.0, 1.0),
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${_stats!['productivity']}%',
                                style: GoogleFonts.syne(
                                  fontSize: 28, fontWeight: FontWeight.w800,
                                  color: _scoreColor(_stats!['productivity']),
                                )),
                              const SizedBox(height: 2),
                              Text('productivity', style: TextStyle(
                                color: Colors.white.withOpacity(0.4), fontSize: 11,
                              )),
                            ],
                          ),
                          progressColor: _scoreColor(_stats!['productivity']),
                          backgroundColor: const Color(0xFF1E1E38),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 800,
                        ),
                        const SizedBox(height: 12),
                        Text(_scoreLabel(_stats!['productivity']),
                          style: TextStyle(
                            color: _scoreColor(_stats!['productivity']),
                            fontSize: 14, fontWeight: FontWeight.w600,
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Stats Row ──
                  Row(children: [
                    _StatCard(label: 'Total', value: '${_stats!['total_tasks']}', icon: '📋'),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Done', value: '${_stats!['completed_tasks']}', icon: '✅'),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Pending',
                      value: '${(_stats!['total_tasks'] as int) - (_stats!['completed_tasks'] as int)}',
                      icon: '⏳',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // ── Tip Card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1040), Color(0xFF16162A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3D2080)),
                    ),
                    child: Row(children: [
                      const Text('💡', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pro Tip', style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700, color: const Color(0xFFC4B5FD),
                          )),
                          const SizedBox(height: 4),
                          const Text(
                            'Set High priority tasks for the most important things. Your daily plan orders them automatically.',
                            style: TextStyle(color: Color(0xFF8888AA), fontSize: 13, height: 1.4),
                          ),
                        ],
                      )),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF34D399);
    if (score >= 40) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  String _scoreLabel(int score) {
    if (score >= 70) return '🔥 Crushing it!';
    if (score >= 40) return '📈 Good progress';
    return '💪 Keep going!';
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF252540)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.syne(
            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF55557A), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D1A1A)),
      ),
      child: Column(children: [
        const Text('⚠️', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFF87171), height: 1.5)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
          child: const Text('Retry'),
        ),
      ]),
    );
  }
}
