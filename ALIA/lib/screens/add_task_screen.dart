import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AddTaskScreen({super.key, required this.user});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _addTask() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { _showSnack('Please enter a task name'); return; }
    if (_selectedDate == null) { _showSnack('Please select a date'); return; }
    if (_selectedTime == null) { _showSnack('Please select a time'); return; }

    setState(() => _loading = true);

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.user['id'],
          'name': name,
          'scheduled_date': dateStr,
          'scheduled_time': timeStr,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final scheduledDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        print('Scheduling notification for: $scheduledDateTime');
        print('Reminder time: ${scheduledDateTime.subtract(const Duration(hours: 2))}');
        print('Current time: ${DateTime.now()}');

        await NotificationService.scheduleTaskReminder(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          taskName: name,
          scheduledDateTime: scheduledDateTime,
        );

        print('Notification scheduled!');

        _nameController.clear();
        setState(() { _selectedDate = null; _selectedTime = null; _loading = false; });
        _showSnack('Task added! You\'ll be reminded 2 hours before.');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
      _showSnack('Failed to add task');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Task', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black,
              )),
              const SizedBox(height: 4),
              Text('What do you need to get done?', style: TextStyle(
                color: Colors.black.withOpacity(0.4), fontSize: 14,
              )),
              const SizedBox(height: 36),

              _Label('Task Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. Study Flutter, Go for a run…',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black38),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              _Label('Date'),
              const SizedBox(height: 8),
              _PickerButton(
                icon: Icons.calendar_today_outlined,
                label: _selectedDate == null
                    ? 'Select date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                onTap: _pickDate,
                hasValue: _selectedDate != null,
              ),
              const SizedBox(height: 16),

              _Label('Time'),
              const SizedBox(height: 8),
              _PickerButton(
                icon: Icons.access_time_outlined,
                label: _selectedTime == null
                    ? 'Select time'
                    : _selectedTime!.format(context),
                onTap: _pickTime,
                hasValue: _selectedTime != null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Task', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      color: Colors.black.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600,
    ));
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  const _PickerButton({
    required this.icon, required this.label,
    required this.onTap, required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasValue ? Colors.black38 : Colors.black12),
        ),
        child: Row(children: [
          Icon(icon, color: hasValue ? Colors.black : Colors.black38, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: hasValue ? Colors.black : Colors.black38, fontSize: 15,
          )),
        ]),
      ),
    );
  }
}