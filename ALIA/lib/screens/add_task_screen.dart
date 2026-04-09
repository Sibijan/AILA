import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _nameController = TextEditingController();
  int _selectedPriority = 1;
  bool _loading = false;

  final List<Map<String, dynamic>> _priorities = [
    {'value': 1, 'label': 'High', 'emoji': '🔴', 'desc': 'Do this first', 'color': Color(0xFFF87171)},
    {'value': 2, 'label': 'Medium', 'emoji': '🟡', 'desc': 'Do this today', 'color': Color(0xFFFBBF24)},
    {'value': 3, 'label': 'Low', 'emoji': '🟢', 'desc': 'When you have time', 'color': Color(0xFF34D399)},
  ];

  Future<void> _addTask() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a task name'),
          backgroundColor: const Color(0xFF16162A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'priority': _selectedPriority}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        _nameController.clear();
        setState(() { _selectedPriority = 1; _loading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('✅  '),
                Text('"$name" added successfully!'),
              ]),
              backgroundColor: const Color(0xFF1E3A2A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add task. Check your connection.'),
            backgroundColor: const Color(0xFF3D1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Text('Add Task', style: GoogleFonts.syne(
                fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
              )),
              const SizedBox(height: 4),
              const Text('What do you need to get done?',
                style: TextStyle(color: Color(0xFF55557A), fontSize: 14)),
              const SizedBox(height: 32),

              // ── Task Name ──
              Text('Task Name', style: GoogleFonts.dmSans(
                color: const Color(0xFF8888AA), fontSize: 13, fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'e.g. Study Flutter, Go for a run…',
                  prefixIcon: Icon(Icons.edit_outlined, color: Color(0xFF7C3AED), size: 20),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),

              // ── Priority ──
              Text('Priority', style: GoogleFonts.dmSans(
                color: const Color(0xFF8888AA), fontSize: 13, fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 12),
              ..._priorities.map((p) => _PriorityTile(
                emoji: p['emoji'],
                label: p['label'],
                desc: p['desc'],
                accentColor: p['color'],
                isSelected: _selectedPriority == p['value'],
                onTap: () => setState(() => _selectedPriority = p['value']),
              )),
              const SizedBox(height: 36),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    disabledBackgroundColor: const Color(0xFF3D2080),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Add Task', style: GoogleFonts.syne(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final String emoji, label, desc;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityTile({
    required this.emoji, required this.label, required this.desc,
    required this.accentColor, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.5) : const Color(0xFF252540),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              color: isSelected ? accentColor : Colors.white,
              fontWeight: FontWeight.w600, fontSize: 14,
            )),
            Text(desc, style: const TextStyle(color: Color(0xFF55557A), fontSize: 12)),
          ]),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
        ]),
      ),
    );
  }
}
