import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'login_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final int userId;
  const AppointmentsScreen({super.key, required this.userId});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _tag = 'AppointmentsScreen';

  List<Appointment> _appointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    AppLogger.info(_tag, 'Loading appointments for user ${widget.userId}');
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getMyAppointments();
      setState(() { _appointments = data; _loading = false; });
      AppLogger.debug(_tag, 'Loaded ${data.length} appointments');
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired: $e');
      _redirectToLogin();
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error loading appointments', e);
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error loading appointments', e);
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _cancel(Appointment appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Cancel ${appt.service.name} on ${appt.formattedDate} at ${appt.formattedTime}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    AppLogger.info(_tag, 'Cancelling appointment ${appt.id}');
    try {
      await ApiService.cancelAppointment(appt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled')),
      );
      _loadAppointments();
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired on cancel: $e');
      _redirectToLogin();
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error cancelling appointment', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error cancelling appointment ${appt.id}', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAppointments),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadAppointments)
              : _appointments.isEmpty
                  ? const _EmptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, i) =>
                          _AppointmentCard(appt: _appointments[i], onCancel: _cancel),
                    ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No appointments yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final void Function(Appointment) onCancel;
  const _AppointmentCard({required this.appt, required this.onCancel});

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'confirmed' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.orange,
      };

  IconData _statusIcon(String status) => switch (status.toLowerCase()) {
        'confirmed' => Icons.check_circle_outline,
        'cancelled' => Icons.cancel_outlined,
        _ => Icons.hourglass_empty,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(appt.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE91E8C),
                  child: Icon(Icons.spa, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appt.service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(appt.status), size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        appt.status[0].toUpperCase() + appt.status.substring(1),
                        style: TextStyle(
                            fontSize: 12, color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(appt.formattedDate, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(appt.formattedTime, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (appt.notes != null && appt.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.notes, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(appt.notes!,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NPR ${appt.service.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFFE91E8C), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (appt.status.toLowerCase() != 'cancelled')
                  TextButton.icon(
                    onPressed: () => onCancel(appt),
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
