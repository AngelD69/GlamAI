import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'login_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final int userId;
  final Service service;

  const BookAppointmentScreen({
    super.key,
    required this.userId,
    required this.service,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const _tag = 'BookAppointmentScreen';

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _book() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    AppLogger.info(_tag,
        'Booking service ${widget.service.id} on ${_formatDate(_selectedDate!)} at ${_formatTime(_selectedTime!)}');
    setState(() => _loading = true);

    try {
      await ApiService.createAppointment(
        serviceId: widget.service.id,
        date: _formatDate(_selectedDate!),
        time: _formatTime(_selectedTime!),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      AppLogger.info(_tag, 'Appointment booked successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired: $e');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ValidationException catch (e) {
      AppLogger.warning(_tag, 'Validation error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error booking appointment', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error booking appointment', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.service.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.spa, color: Color(0xFFE91E8C)),
                title: Text(widget.service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: widget.service.description != null
                    ? Text(widget.service.description!)
                    : null,
                trailing: Text(
                  'NPR ${widget.service.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFFE91E8C), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDate == null
                  ? 'Choose date'
                  : _formatDate(_selectedDate!)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFFE91E8C)),
                foregroundColor: const Color(0xFFE91E8C),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(_selectedTime == null
                  ? 'Choose time'
                  : _selectedTime!.format(context)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFFE91E8C)),
                foregroundColor: const Color(0xFFE91E8C),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requests...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
