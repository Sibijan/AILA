import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import '../constants.dart';
import '../services/session.dart';
import 'ai_chat_screen.dart'; // ✅ NEW IMPORT

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/productivity/${widget.user['id']}'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot reach backend.';
        _loading = false;
      });
    }
  }

  void _logout() async {
    await Session.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _LoginRedirect()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final dateStr =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: Colors.white,

      // 🔥 AILA FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatScreen()),
          );
        },
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: Colors.black,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI LIFE ASSIST',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 2,
                            )),
                        Text(dateStr,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.4),
                              fontSize: 13,
                            )),
                      ],
                    ),
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Text(
                            widget.user['name']
                                .toString()
                                .split(' ')[0],
                            style: const TextStyle(
                                color: Colors.black, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.logout,
                              color: Colors.black38, size: 14),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (_loading)
                  const Center(
                      child: CircularProgressIndicator(color: Colors.black))
                else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _loadStats)
                else ...[
                  Center(
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 90,
                          lineWidth: 10,
                          percent: ((_stats!['productivity'] as int) / 100)
                              .clamp(0.0, 1.0),
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${_stats!['productivity']}%',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  )),
                              Text('productivity',
                                  style: TextStyle(
                                    color:
                                        Colors.black.withOpacity(0.4),
                                    fontSize: 11,
                                  )),
                            ],
                          ),
                          progressColor: Colors.black,
                          backgroundColor: Colors.black12,
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 800,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _scoreLabel(_stats!['productivity']),
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(children: [
                    _StatCard(
                        label: 'Total',
                        value: '${_stats!['total_tasks']}'),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Done',
                        value: '${_stats!['completed_tasks']}'),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Pending',
                      value:
                          '${(_stats!['total_tasks'] as int) - (_stats!['completed_tasks'] as int)}',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.black54, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Add tasks with a date and time to schedule your day automatically.',
                          style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
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

  String _scoreLabel(int score) {
    if (score >= 70) return '🔥 Crushing it!';
    if (score >= 40) return '📈 Good progress';
    return '💪 Keep going!';
  }
}

class _LoginRedirect extends StatefulWidget {
  const _LoginRedirect();
  @override
  State<_LoginRedirect> createState() => _LoginRedirectState();
}

class _LoginRedirectState extends State<_LoginRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _LoginScreenImport()),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.white);
}

class _LoginScreenImport extends StatelessWidget {
  const _LoginScreenImport();
  @override
  Widget build(BuildContext context) {
    return const _LoginPlaceholder();
  }
}

class _LoginPlaceholder extends StatelessWidget {
  const _LoginPlaceholder();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.white);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 12)),
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
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Icon(Icons.wifi_off, color: Colors.black54, size: 36),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black),
            foregroundColor: Colors.black,
          ),
          child: const Text('Retry'),
        ),
      ]),
    );
  }
}